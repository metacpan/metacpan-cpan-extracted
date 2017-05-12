package Silki::Schema::Wiki;
{
  $Silki::Schema::Wiki::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;
use autodie;

use Archive::Tar::Wrapper;
use Data::Dumper qw( Dumper );
use DateTime::Format::Pg;
use Fey::Literal;
use Fey::Object::Iterator::FromSelect;
use Fey::SQL;
use File::Spec;
use List::AllUtils qw( uniq );
use Path::Class qw( dir file );
use Silki::Config;
use Silki::I18N qw( loc );
use Silki::JSON;
use Silki::Schema;
use Silki::Schema::Account;
use Silki::Schema::Domain;
use Silki::Schema::File;
use Silki::Schema::Page;
use Silki::Schema::Permission;
use Silki::Schema::Role;
use Silki::Schema::TextSearchResult;
use Silki::Schema::UserWikiRole;
use Silki::Schema::WantedPage;
use Silki::Schema::WikiRolePermission;
use Silki::Wiki::Exporter;
use Silki::Wiki::Importer;
use Silki::Types qw( Bool CodeRef File HashRef Int Str ValidPermissionType );

use Fey::ORM::Table;
use MooseX::ClassAttribute;
use MooseX::Params::Validate qw( pos_validated_list validated_list );

with 'Silki::Role::Schema::URIMaker';

with 'Silki::Role::Schema::SystemLogger' =>
    { methods => [ 'insert', 'delete' ] };

with 'Silki::Role::Schema::DataValidator' => {
    steps => [
        '_title_is_unique',
        '_title_is_valid',
        '_short_name_is_unique',
    ],
};

my $Schema = Silki::Schema->Schema();

has_policy 'Silki::Schema::Policy';

has_table( $Schema->table('Wiki') );

has_one( $Schema->table('Domain') );

has_one creator => ( table => $Schema->table('User') );

has_many pages => (
    table    => $Schema->table('Page'),
    order_by => [ $Schema->table('Page')->column('title') ],
);

has permissions => (
    is       => 'ro',
    isa      => HashRef [ HashRef [Bool] ],
    lazy     => 1,
    builder  => '_build_permissions',
    init_arg => undef,
    clearer  => '_clear_permissions',
);

has non_member_can_edit => (
    is       => 'ro',
    isa      => Bool,
    lazy     => 1,
    builder  => '_build_non_member_can_edit',
    init_arg => undef,
    clearer  => '_clear_non_member_can_edit',
);

has permissions_name => (
    is       => 'ro',
    isa      => Str,
    lazy     => 1,
    builder  => '_build_permissions_name',
    init_arg => undef,
    clearer  => '_clear_permissions_name',
);

has front_page_title => (
    is       => 'ro',
    isa      => Str,
    lazy     => 1,
    init_arg => 1,
    builder  => '_build_front_page_title',
);

class_has _RecentChangesSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildRecentChangesSelect',
);

class_has _DistinctRecentChangesSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildDistinctRecentChangesSelect',
);

class_has _FilesSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildFilesSelect',
);

class_has _OrphanedPagesSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildOrphanedPagesSelect',
);

class_has _WantedPagesSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildWantedPagesSelect',
);

class_has _RecentlyViewedPagesSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildRecentlyViewedPagesSelect',
);

class_has _MembersSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildMembersSelect',
);

class_has _ActiveUsersSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildActiveUsersSelect',
);

class_has _PagesByTagSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildPagesByTagSelect',
);

class_has _PagesByTagCountSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildPagesByTagCountSelect',
);

class_has _PopularTagsSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildPopularTagsSelect',
);

class_has _PagesEditedByUserSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildPagesEditedByUserSelect',
);

class_has _PagesEditedByUserCountSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildPagesEditedByUserCountSelect',
);

class_has _PagesCreatedByUserSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildPagesCreatedByUserSelect',
);

class_has _PagesCreatedByUserCountSelect => (
    is      => 'ro',
    does    => 'Fey::Role::SQL::ReturnsData',
    lazy    => 1,
    builder => '_BuildPagesCreatedByUserCountSelect',
);

class_has _PublicWikiCountSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildPublicWikiCountSelect',
);

class_has _PublicWikiSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildPublicWikiSelect',
);

class_has _AllWikiSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildAllWikiSelect',
);

class_has _MaxRevisionSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildMaxRevisionSelect',
);

class_has _MinRevisionSelect => (
    is      => 'ro',
    isa     => 'Fey::SQL::Select',
    lazy    => 1,
    builder => '_BuildMinRevisionSelect',
);

query revision_count => (
    select      => __PACKAGE__->_DistinctRevisionCountSelect(),
    bind_params => sub { $_[0]->wiki_id() },
);

query tag_count => (
    select      => __PACKAGE__->_TagCountSelect(),
    bind_params => sub { $_[0]->wiki_id() },
);

query page_count => (
    select      => __PACKAGE__->_PageCountSelect(),
    bind_params => sub { $_[0]->wiki_id() },
);

query orphaned_page_count => (
    select      => __PACKAGE__->_OrphanedPageCountSelect(),
    bind_params => sub { $_[0]->wiki_id(), $_[0]->front_page_title() },
);

query wanted_page_count => (
    select      => __PACKAGE__->_WantedPageCountSelect(),
    bind_params => sub { $_[0]->wiki_id() },
);

query member_count => (
    select      => __PACKAGE__->_MemberCountSelect(),
    bind_params => sub { $_[0]->wiki_id() },
);

query file_count => (
    select      => __PACKAGE__->_FileCountSelect(),
    bind_params => sub { $_[0]->wiki_id() },
);

with 'Silki::Role::Schema::Serializes';

my $FrontPage = <<'EOF';
Welcome to your new wiki.

A wiki is a set of web pages that can be read and edited by a group of people. You use simple syntax to add things like *italics* and **bold** to the text. Wikis are designed to make linking to other pages easy.

For more information about wikis in general and Silki in particular, click on the Help link in the upper right.

You can also play around on the ((Scratch Pad)) page.
EOF

my $Scratch = <<'EOF';
Feel free experiment with the wiki here.
EOF

around insert => sub {
    my $orig  = shift;
    my $class = shift;
    my %p     = @_;

    if ( !exists $p{short_name} ) {
        my $name = $p{title};
        $name =~ s/ +/-/g;
        $p{short_name} = lc $name;
    }

    $p{user_id} = $p{user}->user_id();

    $p{account_id} = Silki::Schema::Account->DefaultAccount()->account_id();

    my $wiki;

    my $skip_default = delete $p{skip_default_pages};

    $class->SchemaClass()->RunInTransaction(
        sub {
            $wiki = $class->$orig(%p);

            unless ($skip_default) {
                Silki::Schema::Page->insert_with_content(
                    title          => 'Front Page',
                    content        => $FrontPage,
                    wiki_id        => $wiki->wiki_id(),
                    user_id        => $wiki->user_id(),
                    can_be_renamed => 0,
                );

                Silki::Schema::Page->insert_with_content(
                    title          => 'Scratch Pad',
                    content        => $Scratch,
                    wiki_id        => $wiki->wiki_id(),
                    user_id        => $wiki->user_id(),
                    can_be_renamed => 0,
                );
            }
        }
    );

    return $wiki;
};

sub _system_log_values_for_insert {
    my $class = shift;
    my %p     = @_;

    my $msg = 'Created wiki: ' . $p{title};

    return (
        message   => $msg,
        data_blob => \%p,
    );
}

sub _system_log_values_for_delete {
    my $self = shift;

    my $msg = 'Deleted wiki: ' . $self->title();

    return (
        message => $msg,
    );
}

sub _title_is_unique {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return
        if !$is_insert && exists $p->{title} && $p->{title} eq $self->title();

    return unless __PACKAGE__->new( title => $p->{title} );

    return {
        field   => 'title',
        message => loc(
            'The title you provided is already in use by another wiki.'
        ),
    };
}

sub _title_is_valid {
    my $self = shift;
    my $p    = shift;

    return unless exists $p->{title};

    if ( $p->{title} =~ /\)\)/ ) {
        return {
            message => loc(
                q{Wiki titles cannot contain the characters "))", since this conflicts with the wiki link syntax.}
            ),
        };
    }

    if ( $p->{title} =~ /\// ) {
        return {
            message => loc(
                q{Wiki titles cannot contain a slash (/), since this conflicts with the syntax to link to another wiki.}
            ),
        };
    }

    return;
}

sub _short_name_is_unique {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return
        if !$is_insert
            && exists $p->{short_name}
            && $p->{short_name} eq $self->short_name();

    return unless __PACKAGE__->new( short_name => $p->{short_name} );

    return {
        message => loc(
            'The title you provided generates the same URI as an existing wiki.'
        ),
    };
}

sub _base_uri_path {
    my $self = shift;

    return '/wiki/' . $self->short_name();
}

sub uri_for_member {
    my $self = shift;
    my $user = shift;
    my $view = shift;

    my $view_base = 'user/' . $user->user_id();
    $view_base .= q{/} . $view if defined $view;

    return $self->uri( view => $view_base );
}

sub add_user {
    my $self = shift;
    my ( $user, $role ) = validated_list(
        \@_,
        user => { isa => 'Silki::Schema::User' },
        role => {
            isa     => 'Silki::Schema::Role',
            default => Silki::Schema::Role->Member(),
        },
    );

    return if $user->is_system_user();

    return if $role->name() eq 'Guest' || $role->name() eq 'Authenticated';

    my $uwr = Silki::Schema::UserWikiRole->new(
        user_id => $user->user_id(),
        wiki_id => $self->wiki_id(),
    );

    if ($uwr) {
        $uwr->update( role_id => $role->role_id() );
    }
    else {
        Silki::Schema::UserWikiRole->insert(
            user_id => $user->user_id(),
            wiki_id => $self->wiki_id(),
            role_id => $role->role_id(),
        );
    }

    return;
}

sub remove_user {
    my $self = shift;
    my ($user) = validated_list(
        \@_,
        user => { isa => 'Silki::Schema::User' },
    );

    return if $user->is_system_user();

    my $uwr = Silki::Schema::UserWikiRole->new(
        user_id => $user->user_id(),
        wiki_id => $self->wiki_id(),
    );

    $uwr->delete() if $uwr;

    return;
}

sub _build_permissions {
    my $self = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $select
        ->select( $Schema->table('Role')->column('name'),
                  $Schema->table('Permission')->column('name'),
                )
        ->from( $Schema->table('Permission'),
                $Schema->table('WikiRolePermission') )
        ->from( $Schema->table('Role'),
                $Schema->table('WikiRolePermission') )
        ->where( $Schema->table('WikiRolePermission')->column('wiki_id'),
                 '=', $self->wiki_id() );
    #>>>
    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    my %perms;
    for my $row (
        @{
            $dbh->selectall_arrayref(
                $select->sql($dbh), {}, $select->bind_params()
            )
        }
        ) {
        $perms{ $row->[0] }{ $row->[1] } = 1;
    }

    return \%perms;
}

sub _build_non_member_can_edit {
    my $self = shift;

    my $permissions = $self->permissions();

    return $permissions->{Guest}{Edit} || $permissions->{Authenticated}{Edit};
}

{
    my %Sets = (
        'public' => {
            Guest         => [qw( Read Edit )],
            Authenticated => [qw( Read Edit )],
            Member        => [qw( Read Edit Upload )],
            Admin         => [qw( Read Edit Delete Upload Invite Manage )],
        },
        'public-authenticate-to-edit' => {
            Guest         => [qw( Read )],
            Authenticated => [qw( Read Edit )],
            Member        => [qw( Read Edit Upload )],
            Admin         => [qw( Read Edit Delete Upload Invite Manage )],
        },
        'public-read-only' => {
            Guest         => [qw( Read )],
            Authenticated => [qw( Read )],
            Member        => [qw( Read Edit Upload )],
            Admin         => [qw( Read Edit Delete Upload Invite Manage )],
        },
        'private' => {
            Guest         => [],
            Authenticated => [],
            Member        => [qw( Read Edit Upload )],
            Admin         => [qw( Read Edit Delete Upload Invite Manage )],
        },
    );

    sub set_permissions {
        my $self = shift;
        my ($type)
            = pos_validated_list( \@_, { isa => ValidPermissionType } );

        $self->_set_permissions_from_set( $Sets{$type} );
    }

    my %SetsAsHashes;
    for my $name ( keys %Sets ) {
        for my $role ( keys %{ $Sets{$name} } ) {
            next unless @{ $Sets{$name}{$role} };
            $SetsAsHashes{$name}{$role}
                = { map { $_ => 1 } @{ $Sets{$name}{$role} } };
        }
    }

    sub _build_permissions_name {
        my $self = shift;

        local $Data::Dumper::Sortkeys = 1;
        my $perms = Dumper( $self->permissions() );

        for my $name ( keys %SetsAsHashes ) {
            return $name if $perms eq Dumper( $SetsAsHashes{$name} );
        }

        return 'custom';
    }
}

{
    my $Delete = Silki::Schema->SQLFactoryClass()->new_delete();

    #<<<
    $Delete
        ->delete()
        ->from( $Schema->table('WikiRolePermission') )
        ->where( $Schema->table('WikiRolePermission')->column('wiki_id'),
                 '=', Fey::Placeholder->new() );
    #>>>
    sub _set_permissions_from_set {
        my $self = shift;
        my $set  = shift;

        my @inserts;
        for my $role_name ( keys %{$set} ) {
            my $role = Silki::Schema::Role->$role_name();

            for my $perm_name ( @{ $set->{$role_name} } ) {
                my $perm = Silki::Schema::Permission->$perm_name();

                push @inserts, {
                    wiki_id       => $self->wiki_id(),
                    role_id       => $role->role_id(),
                    permission_id => $perm->permission_id(),
                    };
            }
        }

        my $dbh = Silki::Schema->DBIManager()->source_for_sql($Delete)->dbh();
        my $trans = sub {
            $dbh->do( $Delete->sql($dbh), {}, $self->wiki_id() );
            Silki::Schema::WikiRolePermission->insert_many(@inserts);
        };

        Silki::Schema->RunInTransaction($trans);

        $self->_clear_permissions();
        $self->_clear_permissions_name();
        $self->_clear_non_member_can_edit();

        return;
    }
}

sub _build_front_page_title {
    my $self = shift;

    # XXX - needs i18n
    return 'Front Page';
}

sub _RevisionCountSelect {
    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ( $page_t, $page_revision_t )
        = $Schema->tables( 'Page', 'PageRevision' );

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_revision_t->column('page_id')
    );

    #<<<
    $select
        ->select($count)->from( $page_t, $page_revision_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _DistinctRevisionCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ( $page_t, $page_revision_t )
        = $Schema->tables( 'Page', 'PageRevision' );

    my $max_revision = $class->_MaxRevisionSelect();

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_revision_t->column('page_id'),
    );

    my $count_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $count_select
        ->select($count)
        ->from( $page_t, $page_revision_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_revision_t->column('revision_number'),
                 '=', $max_revision );
    #>>>
    return $count_select;
}

sub revisions {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_DistinctRecentChangesSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => [ 'Silki::Schema::Page', 'Silki::Schema::PageRevision' ],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $self->wiki_id() ],
    );
}

sub _BuildRecentChangesSelect {
    my $class = shift;

    my $page_t = $Schema->table('Page');

    my $pages_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $pages_select
        ->select( $page_t, $Schema->table('PageRevision') )
        ->from( $page_t, $Schema->table('PageRevision') )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->order_by(
            $Schema->table('PageRevision')->column('creation_datetime'), 'DESC',
            $Schema->table('Page')->column('title'),                     'ASC',
        );
    #>>>
    return $pages_select;
}

# This gets recently changed pages but only shows each page once, in its most
# recent revision.
sub _BuildDistinctRecentChangesSelect {
    my $class = shift;

    my ( $page_t, $page_revision_t )
        = $Schema->tables( 'Page', 'PageRevision' );

    my $max_func = Fey::Literal::Function->new(
        'MAX',
        $Schema->table('PageRevision')->column('revision_number')
    );

    my $max_revision = $class->_MaxRevisionSelect();

    my $pages_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $pages_select
        ->select( $page_t, $Schema->table('PageRevision') )
        ->from( $page_t, $Schema->table('PageRevision') )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and  (
            $Schema->table('PageRevision')->column('revision_number'),
            '=', $max_revision
        )->order_by(
            $Schema->table('PageRevision')->column('creation_datetime'), 'DESC',
            $page_t->column('title'),                                    'ASC',
        );
    #>>>
    return $pages_select;
}

sub orphaned_pages {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_OrphanedPagesSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => [ 'Silki::Schema::Page', 'Silki::Schema::PageRevision' ],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $self->wiki_id(), $self->front_page_title() ],
    );
}

sub _PageCountSelect {
    my $class = shift;

    my $page_t = $Schema->table('Page');

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_t->column('page_id')
    );

    my $pages_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $pages_select
        ->select($count)
        ->from($page_t)
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $pages_select;
}

sub _OrphanedPageCountSelect {
    my $class = shift;

    my $page_link_t = $Schema->table('PageLink');

    my $linked_pages = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $linked_pages
        ->select( $page_link_t->column('to_page_id') )
        ->from( $page_link_t );
    #>>>
    my $page_t = $Schema->table('Page');

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_t->column('page_id')
    );

    my $pages_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $pages_select
        ->select($count)
        ->from($page_t)
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and( $page_t->column( 'title' ), '!=', Fey::Placeholder->new() )
        ->and( $page_t->column('page_id'), 'NOT IN', $linked_pages );
    #>>>
    return $pages_select;
}

sub _BuildOrphanedPagesSelect {
    my $class = shift;

    my $page_link_t = $Schema->table('PageLink');

    my $linked_pages = Silki::Schema->SQLFactoryClass()->new_select();
    $linked_pages->select( $page_link_t->column('to_page_id') )
        ->from($page_link_t);

    my $page_t = $Schema->table('Page');

    my $pages_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $pages_select
        ->select($page_t)
        ->from($page_t)
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and( $page_t->column( 'title' ), '!=', Fey::Placeholder->new() )
        ->and( $page_t->column('page_id'), 'NOT IN', $linked_pages )
        ->order_by(
            $page_t->column('title'), 'ASC',
        );
    #>>>
    return $pages_select;
}

sub _WantedPageCountSelect {
    my $class = shift;

    my $pending_page_link_t = $Schema->table('PendingPageLink');

    my $distinct = Fey::Literal::Term->new(
        'DISTINCT ',
        $pending_page_link_t->column('to_page_title')
    );
    my $count = Fey::Literal::Function->new( 'COUNT', $distinct );

    my $wanted_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $wanted_select
        ->select($count)
        ->from($pending_page_link_t)
        ->where( $pending_page_link_t->column('to_wiki_id'), '=',
                 Fey::Placeholder->new() );
    #>>>
    return $wanted_select;
}

sub wanted_pages {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_WantedPagesSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::WantedPage'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params   => [ $self->wiki_id() ],
        attribute_map => {
            0 => {
                class     => 'Silki::Schema::WantedPage',
                attribute => 'title',
            },
            1 => {
                class     => 'Silki::Schema::WantedPage',
                attribute => 'wiki_id',
            },
            2 => {
                class     => 'Silki::Schema::WantedPage',
                attribute => 'wanted_count',
            },
        },
    );
}

sub _BuildWantedPagesSelect {
    my $class = shift;

    my $pending_page_link_t = $Schema->table('PendingPageLink');

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $pending_page_link_t->column('from_page_id')
    );

    my $wanted_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $wanted_select
        ->select( $pending_page_link_t->columns( 'to_page_title', 'to_wiki_id' ), $count )
        ->from( $pending_page_link_t )
        ->where( $pending_page_link_t->column('to_wiki_id'), '=', Fey::Placeholder->new() )
        ->group_by( $pending_page_link_t->columns( 'to_page_title', 'to_wiki_id' ) )
        ->order_by(
            $count, 'DESC',
            $pending_page_link_t->column('to_page_title'), 'ASC',
        );
    #>>>
    return $wanted_select;
}

sub recently_viewed_pages {
    my $self = shift;
    my ( $cutoff, $limit, $offset ) = validated_list(
        \@_,
        cutoff => {
            isa     => 'DateTime',
            default => DateTime->today()->subtract( months => 1 )
        },
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_RecentlyViewedPagesSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::Page'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [
            $self->wiki_id(),
            DateTime::Format::Pg->format_datetime($cutoff)
        ],
    );
}

sub _BuildRecentlyViewedPagesSelect {
    my $class = shift;

    my ( $page_t, $page_view_t ) = $Schema->tables( 'Page', 'PageView' );

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_view_t->column('page_id')
    );

    my $viewed_select = Silki::Schema->SQLFactoryClass()->new_select();
    #<<<
    $viewed_select
        ->select( $page_t, $count )
        ->from( $page_t, $page_view_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_view_t->column('view_datetime'), '>=', Fey::Placeholder->new() )
        ->group_by( $page_t->columns() )
        ->order_by(
            $count, 'DESC',
            $page_t->column('title'), 'ASC',
        );
    #>>>
    return $viewed_select;
}

sub _MemberCountSelect {
    my $class = shift;

    my $uwr_t = $Schema->table('UserWikiRole');

    my $count
        = Fey::Literal::Function->new( 'COUNT', $uwr_t->column('user_id') );

    my $member_count_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $member_count_select
        ->select($count)
        ->from($uwr_t)
        ->where( $uwr_t->column('wiki_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $member_count_select;
}

sub _FileCountSelect {
    my $class = shift;

    my ( $file_t, $page_t ) = $Schema->tables( 'File', 'Page' );

    my $count
        = Fey::Literal::Function->new( 'COUNT', $file_t->column('file_id') );

    my $file_count_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $file_count_select
        ->select($count)
        ->from( $file_t, $page_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $file_count_select;
}

sub files {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_FilesSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::File'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $self->wiki_id() ],
    );
}

sub _BuildFilesSelect {
    my $class = shift;

    my ( $file_t, $page_t ) = $Schema->tables( 'File', 'Page' );

    my $files_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $files_select
        ->select($file_t)
        ->from( $file_t, $page_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->order_by( $file_t->column('filename'), 'ASC' );
    #>>>
    return $files_select;
}

sub members {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_MembersSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => [ 'Silki::Schema::User', 'Silki::Schema::Role' ],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $self->wiki_id() ],
    );
}

sub _BuildMembersSelect {
    my $class = shift;

    my $user_t = $Schema->table('User');
    my $uwr_t  = $Schema->table('UserWikiRole');
    my $role_t = $Schema->table('Role');

    my $members_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $members_select
        ->select( $user_t, $role_t )
        ->from( $user_t, $uwr_t )
        ->from( $uwr_t, $role_t )
        ->where( $uwr_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->order_by( $role_t->column('name'), 'ASC',
                    $user_t->column('display_name'), 'ASC',
                    $user_t->column('email_address'), 'ASC',
                  );
    #>>>
    return $members_select;
}

sub active_users {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_ActiveUsersSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::User'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $self->wiki_id(), $select->bind_params() ],
    );
}

sub _BuildActiveUsersSelect {
    my $class = shift;

    my $user_t          = $Schema->table('User');
    my $page_t          = $Schema->table('Page');
    my $page_revision_t = $Schema->table('PageRevision');

    my $username_or_display_name = Fey::Literal::Term->new(
        q{CASE WHEN display_name = '' THEN username ELSE display_name END});

    my $max = Fey::Literal::Function->new(
        'MAX',
        $page_revision_t->column('creation_datetime')
    );

    my $users_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $users_select
        ->select( $user_t, $username_or_display_name, $max )
        ->distinct()
        ->from( $user_t, $page_revision_t )
        ->from( $page_revision_t, $page_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->where( $user_t->column('is_system_user'), '=', 0 )
        ->where(
            $page_revision_t->column('creation_datetime'),
            '>=',
            DateTime::Format::Pg->format_datetime(
                DateTime->today()->subtract( months => 1 )
            )
        )
        ->group_by( $user_t->columns(), $username_or_display_name )
        ->order_by( $max, 'DESC', $username_or_display_name, );
    #>>>
    return $users_select;
}

# This is a rather complicated query. The end result is something like this ..
#
# SELECT
#   *,
#   TS_HEADLINE(title || E'\n' || content, "page") AS "headline"
# FROM
#  (
#     SELECT
#       "Page"."is_archived",
#       "Page"."page_id",
#       ...,
#       "PageRevision"."comment",
#       "PageRevision"."creation_datetime",
#       ...,
#       TS_RANK("PageSearchableText"."ts_text", "page") AS "rank"
#     FROM
#      "Page" JOIN "PageRevision" ON ("PageRevision"."page_id" = "Page"."page_id")
#             JOIN "PageSearchableText" ON ("PageSearchableText"."page_id" = "Page"."page_id")
#     WHERE
#      "PageSearchableText"."ts_text" @@ to_tsquery(?)
#       AND
#      "Page"."wiki_id" = ?
#       AND
#      "PageRevision"."revision_number" =
#          ( SELECT
#              MAX("PageRevision"."revision_number") AS "FUNCTION0"
#            FROM
#              "PageRevision"
#            WHERE
#              "PageRevision"."page_id" = "Page"."page_id" )
#     ORDER BY
#       "rank" DESC, "Page"."title" ASC
#     OFFSET 0
#  )
# AS "SUBSELECT0"
#
# Part of the reason for the complication is that we want to generate the
# headline (TS_HEADLINE) only after applying the OFFSET clause. If we don't do
# this, then we generate the headline for every match, regardless of how many
# are being displayed. See
# http://www.postgresql.org/docs/8.3/static/textsearch-controls.html#TEXTSEARCH-HEADLINE
# for details.
#
# The innermost select clause on PageRevision.revision_number ensures that
# we only retrieve the most recent revision for a page.

sub text_search {
    my $self = shift;
    my ( $query, $limit, $offset ) = validated_list(
        \@_,
        query  => { isa => Str },
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default => 0 },
    );

    my $page_t          = $Schema->table('Page');
    my $page_revision_t = $Schema->table('PageRevision');
    my $pst_t           = $Schema->table('PageSearchableText');

    my $max_revision = $self->_MaxRevisionSelect();

    my $ts_query = Fey::Literal::Function->new( 'TO_TSQUERY', $query );

    my $rank = Fey::Literal::Function->new(
        'TS_RANK',
        $pst_t->column('ts_text'),
        $ts_query,
    );

    $rank->set_alias_name('rank');

    my $search_select = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $search_select
        ->select( $page_t, $page_revision_t, $rank )
        ->from( $page_t, $page_revision_t )
        ->from( $page_t, $pst_t )
        ->where( $pst_t->column('ts_text'), '@@', $ts_query )
        ->and  ( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_revision_t->column('revision_number'),
                 '=', $max_revision )
        ->order_by( $rank, 'DESC',
                    $page_t->column('title'), 'ASC' );
    #>>>
    $search_select->limit( $limit, $offset );

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $marker = Silki::Schema::TextSearchResult->HighlightMarker();
    my $result = Fey::Literal::Function->new(
        'TS_HEADLINE',
        Fey::Literal::Term->new( q{title || E'\n' || content}, ),
        $ts_query,
        "StartSel = $marker, StopSel = $marker",
    );
    $result->set_alias_name('result');

    my $star = Fey::Literal::Term->new('*');
    $star->set_can_have_alias(0);

    #<<<
    $select
        ->select( $star, $result )
        ->from($search_select);
    #>>>
    my $x = 0;
    my %attribute_map;

    # This matches the order of the columns in the $search_select defined
    # above.
    for my $col_name ( sort map { $_->name() } $page_t->columns() ) {
        $attribute_map{ $x++ } = {
            class     => 'Silki::Schema::Page',
            attribute => $col_name,
        };
    }

    for my $col_name ( sort map { $_->name() } $page_revision_t->columns() ) {
        $attribute_map{ $x++ } = {
            class     => 'Silki::Schema::PageRevision',
            attribute => $col_name,
        };
    }

    # Need to skip the rank item in the row
    $attribute_map{ ++$x } = {
        class     => 'Silki::Schema::TextSearchResult',
        attribute => 'result',
    };

    return Fey::Object::Iterator::FromSelect->new(
        classes => [
            'Silki::Schema::Page',
            'Silki::Schema::PageRevision',
            'Silki::Schema::TextSearchResult'
        ],
        select => $select,
        dbh    => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params   => [ $self->wiki_id() ],
        attribute_map => \%attribute_map,
    );
}

sub pages_tagged {
    my $self = shift;
    my ( $tag_name, $limit, $offset ) = validated_list(
        \@_,
        tag    => { isa => Str },
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default => 0 },
    );

    my $tag = $self->_find_tag_by_name($tag_name)
        or return;

    my $select = $self->_PagesByTagSelect()->clone();

    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => [ 'Silki::Schema::Page', 'Silki::Schema::PageRevision' ],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $tag->tag_id() ],
    );
}

sub _BuildPagesByTagSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ( $page_t, $page_revision_t, $page_tag_t )
        = $Schema->tables( 'Page', 'PageRevision', 'PageTag' );

    my $max_revision = $class->_MaxRevisionSelect();

    #<<<
    $select
        ->select( $page_t, $page_revision_t )
        ->from( $page_t, $page_revision_t )
        ->from( $page_t, $page_tag_t )
        ->where( $page_tag_t->column('tag_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_revision_t->column('revision_number'),
                 '=', $max_revision )
        ->order_by( $page_t->column('title') );
    #>>>
    return $select;
}

sub pages_tagged_count {
    my $self = shift;
    my ($tag_name) = validated_list(
        \@_,
        tag => { isa => Str },
    );

    my $tag = $self->_find_tag_by_name($tag_name)
        or return 0;

    my $select = $self->_PagesByTagCountSelect();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    my $vals = $dbh->selectrow_arrayref(
        $select->sql($dbh),
        {},
        $tag->tag_id(),
    );

    return $vals ? $vals->[0] : 0;
}

sub _BuildPagesByTagCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ($page_tag_t) = $Schema->table('PageTag');

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_tag_t->column('page_id'),
    );

    #<<<
    $select
        ->select($count)
        ->from($page_tag_t)
        ->where( $page_tag_t->column('tag_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub _find_tag_by_name {
    my $self = shift;
    my $name = shift;

    return Silki::Schema::Tag->new(
        tag     => $name,
        wiki_id => $self->wiki_id(),
    );
}

sub popular_tags {
    my $self = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $self->_PopularTagsSelect()->clone();
    $select->limit( $limit, $offset );

    return Fey::Object::Iterator::FromSelect->new(
        classes => ['Silki::Schema::Tag'],
        select  => $select,
        dbh => Silki::Schema->DBIManager()->source_for_sql($select)->dbh(),
        bind_params => [ $self->wiki_id() ],
    );
}

sub _BuildPopularTagsSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ( $tag_t, $page_tag_t ) = $Schema->tables( 'Tag', 'PageTag' );

    my $count = Fey::Literal::Function->new(
        'COUNT',
        $page_tag_t->column('page_id'),
    );

    #<<<
    $select
        ->select( $tag_t, $count )
        ->from( $tag_t, $page_tag_t )
        ->where( $tag_t->column('wiki_id'), '=',
                 Fey::Placeholder->new() )
        ->group_by( $tag_t->columns() )
        ->order_by( $count,                'DESC',
                    $tag_t->column('tag'), 'ASC' );
    #>>>
    return $select;
}

sub _TagCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ( $page_t, $page_tag_t, $tag_t )
        = $Schema->tables( 'Page', 'PageTag', 'Tag' );

    my $distinct = Fey::Literal::Term->new(
        'DISTINCT ',
        $page_tag_t->column('tag_id'),
    );

    my $count = Fey::Literal::Function->new( 'COUNT', $distinct );

    #<<<
    $select
        ->select($count)
        ->from( $page_t, $page_tag_t )
        ->from( $page_tag_t, $tag_t )
        ->where( $tag_t->column('wiki_id'), '=',
                 Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub pages_edited_by_user {
    my $self = shift;
    my ( $user, $limit, $offset ) = validated_list(
        \@_,
        user   => { isa => 'Silki::Schema::User' },
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default => 0 },
    );

    my $select = $self->_PagesEditedByUserSelect()->clone();
    $select->limit( $limit, $offset );

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    return Fey::Object::Iterator::FromSelect->new(
        classes => [ 'Silki::Schema::Page', 'Silki::Schema::PageRevision' ],
        select  => $select,
        dbh     => $dbh,
        bind_params => [ $self->wiki_id(), $user->user_id() ],
    );
}

sub _BuildPagesEditedByUserSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ( $page_t, $page_revision_t )
        = $Schema->tables( 'Page', 'PageRevision' );

    my $max_revision = $class->_MaxRevisionSelect()->clone();
    $max_revision->and(
        $page_revision_t->column('user_id'), '=',
        Fey::Placeholder->new()
    );

    #<<<
    $select
        ->select( $page_t, $page_revision_t )
        ->from( $page_t, $page_revision_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_revision_t->column('revision_number'),
                 '=', $max_revision )
        ->order_by( $page_revision_t->column('creation_datetime'), 'DESC',
                    $page_t->column('title'), 'ASC' );
    #>>>
    return $select;
}

sub pages_edited_by_user_count {
    my $self = shift;
    my ($user) = pos_validated_list( \@_, { isa => 'Silki::Schema::User' } );

    my $select = $self->_PagesEditedByUserCountSelect();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    my $vals = $dbh->selectrow_arrayref(
        $select->sql($dbh),
        {},
        $self->wiki_id(), $user->user_id(),
    );

    return $vals ? $vals->[0] : 0;
}

sub _BuildPagesEditedByUserCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my ( $page_t, $page_revision_t )
        = $Schema->tables( 'Page', 'PageRevision' );

    my $distinct = Fey::Literal::Term->new(
        'DISTINCT ',
        Fey::Literal::Function->new(
            'COUNT', $page_revision_t->column('page_id')
        )
    );

    #<<<
    $select
        ->select($distinct)
        ->from( $page_t, $page_revision_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_revision_t->column('user_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub pages_created_by_user {
    my $self = shift;
    my ( $user, $limit, $offset ) = validated_list(
        \@_,
        user   => { isa => 'Silki::Schema::User' },
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default => 0 },
    );

    my $select = $self->_PagesCreatedByUserSelect()->clone();
    $select->limit( $limit, $offset );

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    return Fey::Object::Iterator::FromSelect->new(
        classes => [ 'Silki::Schema::Page', 'Silki::Schema::PageRevision' ],
        select  => $select,
        dbh     => $dbh,
        bind_params => [ $self->wiki_id(), $user->user_id() ],
    );
}

sub _BuildPagesCreatedByUserSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $min_revision = $class->_MinRevisionSelect();

    my ( $page_t, $page_revision_t )
        = $Schema->tables( 'Page', 'PageRevision' );

    #<<<
    $select
        ->select( $page_t, $page_revision_t )
        ->from( $page_t, $page_revision_t )
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_t->column('user_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_revision_t->column('revision_number'),
                 '=', $min_revision )
        ->order_by( $page_revision_t->column('creation_datetime'), 'DESC',
                    $page_t->column('title'), 'ASC' );
    #>>>
    return $select;
}

sub pages_created_by_user_count {
    my $self = shift;
    my ($user) = pos_validated_list( \@_, { isa => 'Silki::Schema::User' } );

    my $select = $self->_PagesCreatedByUserCountSelect();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    my $vals = $dbh->selectrow_arrayref(
        $select->sql($dbh),
        {},
        $self->wiki_id(), $user->user_id(),
    );

    return $vals ? $vals->[0] : 0;
}

sub _BuildPagesCreatedByUserCountSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $page_t = $Schema->table('Page');

    my $count
        = Fey::Literal::Function->new( 'COUNT', $page_t->column('page_id') );

    #<<<
    $select
        ->select($count)
        ->from($page_t)
        ->where( $page_t->column('wiki_id'), '=', Fey::Placeholder->new() )
        ->and  ( $page_t->column('user_id'), '=', Fey::Placeholder->new() );
    #>>>
    return $select;
}

sub PublicWikiCount {
    my $class = shift;

    my $select = $class->_PublicWikiCountSelect();

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    my $vals = $dbh->selectrow_arrayref(
        $select->sql($dbh), {},
        $select->bind_params()
    );

    return $vals ? $vals->[0] : 0;
}

sub PublicWikis {
    my $class = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $class->_PublicWikiSelect()->clone();
    $select->limit( $limit, $offset );

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    return Fey::Object::Iterator::FromSelect->new(
        classes     => 'Silki::Schema::Wiki',
        select      => $select,
        dbh         => $dbh,
        bind_params => [ $select->bind_params() ],
    );
}

{
    my $guest = Silki::Schema::Role->Guest();
    my $read  = Silki::Schema::Permission->Read();

    my ( $wiki_t, $wrp_t ) = $Schema->tables( 'Wiki', 'WikiRolePermission' );

    my $base = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $base
        ->from( $wiki_t, $wrp_t )
        ->where( $wrp_t->column('role_id'), '=', $guest->role_id() )
        ->and  ( $wrp_t->column('permission_id'), '=', $read->permission_id() );
    #>>>
    sub _BuildPublicWikiCountSelect {
        my $class = shift;

        my $select = $base->clone();

        my $distinct = Fey::Literal::Term->new(
            'DISTINCT ',
            $wiki_t->column('wiki_id')
        );
        my $count = Fey::Literal::Function->new( 'COUNT', $distinct );

        $select->select($count);

        return $select;
    }

    sub _BuildPublicWikiSelect {
        my $class = shift;

        my $select = $base->clone();

        $select->select($wiki_t)->distinct()
            ->order_by( $wiki_t->column('title') );

        return $select;
    }
}

sub All {
    my $class = shift;
    my ( $limit, $offset ) = validated_list(
        \@_,
        limit  => { isa => Int, optional => 1 },
        offset => { isa => Int, default  => 0 },
    );

    my $select = $class->_AllWikiSelect()->clone();
    $select->limit( $limit, $offset );

    my $dbh = Silki::Schema->DBIManager()->source_for_sql($select)->dbh();

    return Fey::Object::Iterator::FromSelect->new(
        classes     => 'Silki::Schema::Wiki',
        select      => $select,
        dbh         => $dbh,
        bind_params => [ $select->bind_params() ],
    );
}

sub _BuildAllWikiSelect {
    my $class = shift;

    my $select = Silki::Schema->SQLFactoryClass()->new_select();

    my $wiki_t = $Schema->table('Wiki');

    #<<<
    $select
        ->select($wiki_t)
        ->from($wiki_t)
        ->order_by( $wiki_t->column('title') );
    #>>>
    return $select;
}

sub _BuildMaxRevisionSelect {
    my $class = shift;

    my ( $page_t, $page_revision_t )
        = $Schema->tables( 'Page', 'PageRevision' );

    my $max_func = Fey::Literal::Function->new(
        'MAX',
        $page_revision_t->column('revision_number'),
    );

    my $max_revision = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $max_revision
        ->select($max_func)
        ->from( $Schema->table('PageRevision') )
        ->where( $Schema->table('PageRevision')->column('page_id'),
                 '=', $page_t->column('page_id')
               );
    #>>>
    return $max_revision;
}

sub _BuildMinRevisionSelect {
    my $class = shift;

    my ( $page_t, $page_revision_t )
        = $Schema->tables( 'Page', 'PageRevision' );

    my $min_func = Fey::Literal::Function->new(
        'MIN',
        $page_revision_t->column('revision_number'),
    );

    my $min_revision = Silki::Schema->SQLFactoryClass()->new_select();

    #<<<
    $min_revision
        ->select($min_func)
        ->from( $Schema->table('PageRevision') )
        ->where( $Schema->table('PageRevision')->column('page_id'),
                 '=', $page_t->column('page_id')
               );
    #>>>
    return $min_revision;
}

sub export {
    my $self = shift;

    return Silki::Wiki::Exporter->new(
        @_,
        wiki => $self,
    )->tarball();
}

sub import_tarball {
    my $self = shift;

    return Silki::Wiki::Importer->new(
        @_,
    )->imported_wiki();
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a wiki

__END__
=pod

=head1 NAME

Silki::Schema::Wiki - Represents a wiki

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

