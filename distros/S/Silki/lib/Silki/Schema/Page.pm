package Silki::Schema::Page;
{
  $Silki::Schema::Page::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Encode qw( decode );
use Fey::Object::Iterator::FromSelect;
use Fey::Placeholder;
use List::AllUtils qw( first );
use Silki::Config;
use Silki::I18N qw( loc );
use Silki::Schema::PageRevision;
use Silki::Schema;
use Silki::Schema::File;
use Silki::Schema::PageTag;
use Silki::Schema::Tag;
use Silki::Schema::Wiki;
use Silki::Types qw( ArrayRef Bool Int Str );
use URI::Escape qw( uri_escape_utf8 uri_unescape );

use Fey::ORM::Table;
use MooseX::ClassAttribute;
use MooseX::Params::Validate qw( validated_list pos_validated_list );

with 'Silki::Role::Schema::URIMaker';

with 'Silki::Role::Schema::SystemLogger' => { methods => ['delete'] };

with 'Silki::Role::Schema::DataValidator' => {
    steps => [
        '_title_is_valid',
        '_title_is_unique',
        '_build_uri_path',
    ],
};

my $Schema = Silki::Schema->Schema();

has_policy 'Silki::Schema::Policy';

has_table( $Schema->table('Page') );

has_one( $Schema->table('User') );

has_one wiki => (
    table   => $Schema->table('Wiki'),
    handles => ['domain'],
);

has_many tags => (
    table       => $Schema->table('Tag'),
    select      => __PACKAGE__->_TagsSelect(),
    bind_params => sub { $_[0]->page_id() },
);

has revision_count => (
    metaclass   => 'FromSelect',
    is          => 'ro',
    isa         => Int,
    lazy        => 1,
    select      => __PACKAGE__->_RevisionCountSelect(),
    bind_params => sub { $_[0]->page_id() },
    clearer     => '_clear_revision_count',
);

class_has _RevisionsSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildRevisionsSelect',
);

has_one most_recent_revision => (
    table       => $Schema->table('PageRevision'),
    select      => __PACKAGE__->_MostRecentRevisionSelect(),
    bind_params => sub { $_[0]->page_id() },
    handles     => {
        content                => 'content',
        last_modified_datetime => 'creation_datetime',
    },
);

has_one first_revision => (
    table       => $Schema->table('PageRevision'),
    select      => __PACKAGE__->_FirstRevisionSelect(),
    bind_params => sub { $_[0]->page_id(), 1 },
    handles     => {
        creation_datetime => 'creation_datetime',
    },
);

query incoming_link_count => (
    select      => __PACKAGE__->_IncomingLinkCountSelect(),
    bind_params => sub { $_[0]->page_id() },
);

has_many incoming_links => (
    table       => $Schema->table('Page'),
    select      => __PACKAGE__->_IncomingLinkSelect(),
    bind_params => sub { $_[0]->page_id() },
);

query file_count => (
    select      => __PACKAGE__->_FileCountSelect(),
    bind_params => sub { $_[0]->page_id() },
);

has_many files => (
    table       => $Schema->table('File'),
    select      => __PACKAGE__->_FileSelect(),
    bind_params => sub { $_[0]->page_id() },
);

has is_front_page => (
    is       => 'ro',
    isa      => Bool,
    lazy     => 1,
    init_arg => undef,
    default  => sub { $_[0]->title() eq $_[0]->wiki()->front_page_title() },
);

class_has _PageViewInsert => (
    is      => 'ro',
    isa     => 'Fey::SQL::Insert',
    lazy    => 1,
    builder => '_BuildPageViewInsert',
);

class_has _PendingPageLinkSelectSQL => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildPendingPageLinkSelectSQL',
);

class_has _PendingPageLinkDeleteSQL => (
    is      => 'ro',
    isa     => 'Fey::SQL::Delete',
    lazy    => 1,
    builder => '_BuildPendingPageLinkDeleteSQL',
);

with 'Silki::Role::Schema::Serializes' => {
    skip => ['cached_content'],
};

sub _base_uri_path {
    my $self = shift;

    return $self->wiki()->_base_uri_path() . '/page/' . $self->uri_path();
}

around insert => sub {
    my $orig  = shift;
    my $class = shift;

    my $page = $class->$orig(@_);

    my $select = $class->_PendingPageLinkSelectSQL();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    # XXX - hack but it should work fine
    my $select_sql = $select->sql($dbh) . ' FOR UPDATE';

    my $delete = $class->_PendingPageLinkDeleteSQL();

    my $update_links = sub {
        my $links = $dbh->selectcol_arrayref(
            $select_sql,
            {},
            $page->wiki_id(),
            $page->title(),
        );

        return unless @{$links};

        $dbh->do(
            $delete->sql($dbh),
            {},
            $page->wiki_id(),
            $page->title(),
        );

        my @new_links
            = map { { from_page_id => $_, to_page_id => $page->page_id(), } }
            @{$links};

        Silki::Schema::PageLink->insert_many(@new_links);
    };

    Silki::Schema->RunInTransaction($update_links);

    return $page;
};

sub _BuildPendingPageLinkSelectSQL {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $select
        ->select( $Schema->table('PendingPageLink')->column('from_page_id') )
        ->from( $Schema->table('PendingPageLink') )
        ->where( $Schema->table('PendingPageLink')->column('to_wiki_id'),
                 '=', Fey::Placeholder->new() )
        ->and  ( $Schema->table('PendingPageLink')->column('to_page_title'),
                 '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _BuildPendingPageLinkDeleteSQL {
    my $delete = Silki::Schema->SQLFactoryClass()->new_delete();

    #<<<
    $delete
        ->delete()
        ->from( $Schema->table('PendingPageLink') )
        ->where( $Schema->table('PendingPageLink')->column('to_wiki_id'),
                 '=', Fey::Placeholder->new() )
        ->and  ( $Schema->table('PendingPageLink')->column('to_page_title'),
                 '=', Fey::Placeholder->new() );
    #>>>
    return $delete;
}

sub insert_with_content {
    my $class = shift;
    my %p     = @_;

    my %page_p = (
        map { $_ => delete $p{$_} }
        grep { exists $p{$_} }
        map  { $_->name() } $class->Table()->columns()
    );

    my $page;
    $class->SchemaClass()->RunInTransaction(
        sub {
            $page = $class->insert(%page_p);

            $page->add_revision(
                %p,
                user_id => $page->user_id(),
            );
        }
    );

    return $page;
}

sub _system_log_values_for_delete {
    my $self = shift;

    my $revision = $self->most_recent_revision();

    my $msg
        = 'Deleted page, '
        . $self->title()
        . ', in wiki '
        . $self->wiki()->title();

    return (
        wiki_id   => $self->wiki_id(),
        message   => $msg,
        data_blob => {
            title     => $self->title(),
            revisions => ( $revision ? $revision->revision_number() : 0 ),
            content   => ( $revision ? $revision->content() : undef ),
        },
    );
}

sub _title_is_valid {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return
        if !$is_insert
            && !exists $p->{title};

    if ( $p->{title} =~ /\)\)/ ) {
        return {
            message => loc(
                q{Page titles cannot contain the characters "))", since this conflicts with the wiki link syntax.}
            ),
        };
    }

    if ( $p->{title} =~ /\// ) {
        return {
            message => loc(
                q{Page titles cannot contain a slash (/), since this conflicts with the syntax to link to another wiki.}
            ),
        };
    }

    return;
}

sub _title_is_unique {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return unless exists $p->{title};

    my $wiki_id = $p->{wiki_id};
    $wiki_id = $self->wiki_id()
        unless $wiki_id || $is_insert;

    return unless $wiki_id;

    my $page = __PACKAGE__->new( title => $p->{title}, wiki_id => $wiki_id );

    return unless $page;

    return if !$is_insert && $page->page_id() == $self->page_id();

    return {
        message => loc(
            q{The page title you have chosen (%1) is already in use in this wiki.},
            $p->{title}
        ),
    };
}

sub _build_uri_path {
    my $self = shift;
    my $p    = shift;

    return unless exists $p->{title};

    $p->{uri_path} = $self->TitleToURIPath( $p->{title} );

    return;
}

sub add_revision {
    my $self = shift;
    my %p    = @_;

    my $revision = $self->most_recent_revision();
    my $revision_number = $revision ? $revision->revision_number() + 1 : 1;

    $self->_clear_most_recent_revision();
    $self->_clear_revision_count();

    return Silki::Schema::PageRevision->insert(
        %p,
        revision_number => $revision_number,
        page_id         => $self->page_id(),
    );
}

sub add_file {
    my $self = shift;
    my ($file) = pos_validated_list( \@_, { isa => 'Silki::Schema::File' } );

    my $last_rev    = $self->most_recent_revision();
    my $new_content = $last_rev->content();

    $new_content =~ s/\n*$/\n\n/;
    $new_content .= '{{file:' . $file->filename() . '}}';
    $new_content .= "\n";

    $self->add_revision(
        content => $new_content,
        user_id => Silki::Schema::User->SystemUser()->user_id(),
        comment =>
            loc( 'Adding a link to a new file: %1', $file->filename() ),
    );

    return;
}

sub rename {
    my $self = shift;
    my ($title) = pos_validated_list( \@_, { isa => Str } );

    return if $title eq $self->title();

    die 'Cannot rename this page - ', $self->title(), "\n"
        unless $self->can_be_renamed();

    my $links = $self->incoming_links();

    # XXX - there's a small race condition here, because there's a window
    # between reading the content of the linking pages and updating it. This
    # could be fixed by moving the read into the transaction and doing a
    # SELECT ... FOR UPDATE, I think
    my @pages;
    while ( my $page = $links->next() ) {
        push @pages,
            [
            $page,
            $page->rewritten_content_for_rename( $self->title(), $title )
            ];
    }

    my $update_title = sub {
        my $old_title = $self->title();

        $self->update( title => $title );

        for my $pair (@pages) {
            my ( $page, $content ) = @{$pair};

            $page->add_revision(
                content => $content,
                user_id => Silki::Schema::User->SystemUser()->user_id(),
                comment => loc(
                    'Updating links because a page is being renamed from %1 to %2',
                    $old_title, $title
                ),
            );
        }
    };

    Silki::Schema->RunInTransaction($update_title);
}

sub rewritten_content_for_rename {
    my $self     = shift;
    my $old_name = shift;
    my $new_name = shift;

    my $content = $self->content();

    $content =~ s/\Q(($old_name))/(($new_name))/g;

    return $content;
}

sub record_view {
    my $self = shift;
    my ($user) = pos_validated_list( \@_, { isa => 'Silki::Schema::User' } );

    my $insert = $self->_PageViewInsert();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($insert)->dbh();

    $dbh->do( $insert->sql($dbh), {}, $self->page_id(), $user->user_id() );

    return;
}

sub _BuildPageViewInsert {
    my $class = shift;

    my $page_view_t = $Schema->table('PageView');

    my $insert = Silki::Schema->SQLFactoryClass()->new_insert();

    #<<<
    $insert
        ->insert()
        ->into( $page_view_t->columns( 'page_id', 'user_id' ) )
        ->values( page_id => Fey::Placeholder->new(),
                  user_id => Fey::Placeholder->new(),
                );
    #>>>
    return $insert;
}

sub TitleToURIPath {
    my $class = shift;
    my $title = shift;

    # This is the default list of safe characters, except we also escape
    # underscores. This lets us replace escaped spaces (%20) with underscores
    # after URI-escaping, making for much friendlier paths.
    my $escaped = uri_escape_utf8( $title, q{^A-Za-z0-9-.!~*'()"} );

    $escaped =~ s/%20/_/g;

    return $escaped;
}

sub URIPathToTitle {
    my $class = shift;
    my $path  = shift;

    $path =~ s/_/%20/g;

    return decode( 'utf-8', uri_unescape($path) );
}

sub _TagsSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $select->select( $Schema->table('Tag') )
           ->from( $Schema->tables( 'PageTag', 'Tag' ) )
           ->where( $Schema->table('PageTag')->column('page_id'), '=',
                    Fey::Placeholder->new() )
           ->order_by( $Schema->table('Tag')->column('tag') );
    #>>>
    return $select;
}

sub _MostRecentRevisionSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $select
        ->select( $Schema->table('PageRevision') )
        ->from( $Schema->table('PageRevision') )
        ->where( $Schema->table('PageRevision')->column('page_id'),
                 '=', Fey::Placeholder->new() )
        ->order_by( $Schema->table('PageRevision')->column('revision_number'),
                    'DESC' )
        ->limit(1);
    #>>>
    return $select;
}

sub _FirstRevisionSelect {
    my $self = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $select
        ->select( $Schema->table('PageRevision') )
        ->from( $Schema->table('PageRevision') )
        ->where( $Schema->table('PageRevision')->column('page_id'),
                 '=', Fey::Placeholder->new() )
        ->and( $Schema->table('PageRevision')->column('revision_number'),
               '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _IncomingLinkCountSelect {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $page_link_t = $Schema->table('PageLink');

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_link_t->column('from_page_id')
    );

    #<<<
    $select
        ->select($count)->from($page_link_t)
        ->where( $page_link_t->column('to_page_id'), '=',
                 Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _IncomingLinkSelect {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ( $page_t, $page_link_t ) = $Schema->tables( 'Page', 'PageLink' );

    my ($fk)
        = first { $_->has_column( $page_link_t->column('from_page_id') ) }

    $Schema->foreign_keys_between_tables( $page_t, $page_link_t );

    #<<<
    $select
        ->select($page_t)->from( $page_t, $page_link_t, $fk )
        ->where( $page_link_t->column('to_page_id'), '=',
                 Fey::Placeholder->new() )->order_by( $page_t->column('title') );
    #>>>
    return $select;
}

sub _FileCountSelect {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $file_t = $Schema->table('File');
    my $count  = Fey::Literal::Function->new(
        'COUNT',
        $file_t->column('file_id')
    );

    #<<<
    $select
        ->select($count)
        ->from($file_t)
        ->where( $file_t->column('page_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _FileSelect {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $file_t = $Schema->table('File');

    #<<<
    $select
        ->select($file_t)
        ->from( $file_t )
        ->where( $file_t->column('page_id'), '=', Fey::Placeholder->new() )
        ->order_by( $file_t->column('filename') );
    #>>>
    return $select;
}

sub _RevisionCountSelect {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $page_revision_t = $Schema->table('PageRevision');

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_revision_t->column('page_id')
    );

    #<<<
    $select
        ->select($count)->from($page_revision_t)
        ->where( $page_revision_t->column('page_id'), '=',
                 Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub revisions {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_RevisionsSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::PageRevision'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $self->page_id() ],
    );
}

sub _BuildRevisionsSelect {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $page_revision_t = $Schema->table('PageRevision');

    #<<<
    $select
        ->select($page_revision_t)->from($page_revision_t)
        ->where( $page_revision_t->column('page_id'), '=',
                 Fey::Placeholder->new() )
        ->order_by( $page_revision_t->column('revision_number'), 'DESC' );
    #>>>
    return $select;
}

sub add_tags {
    my $self = shift;
    my ($tags) = validated_list(
        \@_,
        tags => ArrayRef,
    );

    my @tag_ids;
    for my $tag_name ( @{$tags} ) {
        my %tag_p = (
            tag     => $tag_name,
            wiki_id => $self->wiki_id(),
        );

        my $tag;
        if ( $tag = Silki::Schema::Tag->new(%tag_p) ) {
            next
                if Silki::Schema::PageTag->new(
                page_id => $self->page_id(),
                tag_id  => $tag->tag_id(),
                );

            push @tag_ids, $tag->tag_id();
        }
        else {
            $tag = Silki::Schema::Tag->insert(%tag_p);

            push @tag_ids, $tag->tag_id();
        }
    }

    Silki::Schema::PageTag->insert_many(
        map { { page_id => $self->page_id(), tag_id => $_, } } @tag_ids )
        if @tag_ids;

    return;
}

sub delete_tag {
    my $self = shift;
    my ($tag_name) = pos_validated_list(
        \@_,
        Str,
    );

    my $tag = Silki::Schema::Tag->new(
        tag     => $tag_name,
        wiki_id => $self->wiki_id()
    ) or return;

    my $pt = Silki::Schema::PageTag->new(
        page_id => $self->page_id(),
        tag_id  => $tag->tag_id(),
    ) or return;

    $pt->delete();

    return;
}

sub PagesByWikiAndTitle {
    my $self   = shift;
    my $titles = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $page_t = $Schema->table('Page');

    #<<<
    $select
        ->select($page_t)
        ->from  ($page_t); #>>>

    my @keys = keys %{$titles};

    for my $wiki_id (@keys) {
        #<<<
        $select->where( '(' )
               ->and  ( $page_t->column('wiki_id'), '=', $wiki_id )
               ->and  ( $page_t->column('title'), 'IN', @{ $titles->{$wiki_id} } )
               ->and  ( ')' );
        #>>>
        $select->and('or')
            unless $wiki_id == $keys[-1];
    }

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::Page'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $select->bind_params() ],
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a page

__END__
=pod

=head1 NAME

Silki::Schema::Page - Represents a page

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

