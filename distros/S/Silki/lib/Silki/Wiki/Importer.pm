package Silki::Wiki::Importer;
{
  $Silki::Wiki::Importer::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Archive::Tar::Wrapper;
use File::Slurp qw( read_file );
use Path::Class qw( dir );
use Silki::I18N qw( loc );
use Silki::JSON;
use Silki::Schema::Domain;
use Silki::Schema::User;
use Silki::Schema::Wiki;
use Silki::Types qw( ArrayRef Bool Dir HashRef Tarball );

use Moose;
use MooseX::SemiAffordanceAccessor;

with 'Silki::Role::OptionalLog';

has user => (
    is      => 'ro',
    isa     => 'Silki::Schema::User',
    lazy    => 1,
    default => sub { Silki::Schema::User->SystemUser() },
);

has domain => (
    is      => 'ro',
    isa     => 'Silki::Schema::Domain',
    lazy    => 1,
    default => sub { Silki::Schema::Domain->DefaultDomain() },
);

has fast => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has _tarball => (
    is       => 'ro',
    isa      => Tarball,
    init_arg => 'tarball',
    required => 1,
    coerce   => 1,
);

has _archive => (
    is       => 'ro',
    isa      => 'Archive::Tar::Wrapper',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_archive',
);

has _export_root_dir => (
    is       => 'ro',
    isa      => Dir,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_export_root_dir',
);

has _wiki => (
    is  => 'rw',
    isa => 'Silki::Schema::Wiki',
);

has _user_id_map => (
    traits   => ['Hash'],
    is       => 'bare',
    isa      => HashRef,
    init_arg => undef,
    default  => sub { {} },
    handles  => {
        _new_user_id_for     => 'get',
        _set_user_id_mapping => 'set',
    },
);

has _page_id_map => (
    traits   => ['Hash'],
    is       => 'bare',
    isa      => HashRef,
    init_arg => undef,
    default  => sub { {} },
    handles  => {
        _new_page_id_for     => 'get',
        _set_page_id_mapping => 'set',
    },
);

has _pending_invitations => (
    traits   => ['Array'],
    is       => 'bare',
    isa      => ArrayRef,
    init_arg => undef,
    default  => sub { [] },
    handles  => {
        _users_to_invite        => 'elements',
        _add_pending_invitation => 'push',
    },
);

sub imported_wiki {
    my $self = shift;

    $self->_import();

    return $self->_wiki();
}

sub _import {
    my $self = shift;

    $self->_disable_pg_triggers()
        if $self->fast();

    eval {
        Silki::Schema->RunInTransaction(
            sub {
                $self->_create_wiki();
                $self->_import_users();
                $self->_import_pages();
                $self->_import_files();
            }
        );
    };

    my $e = $@;

    $self->_enable_pg_triggers() if $self->fast();

    die $e if $e;

    $self->_rebuild_searchable_text() if $self->fast();

    # invite users
}

sub _build_archive {
    my $self = shift;

    $self->_maybe_log( loc('Reading the tarball (this may take a while)') );

    my $arch = Archive::Tar::Wrapper->new();
    $arch->read( $self->_tarball() );

    return $arch;
}

sub _create_wiki {
    my $self = shift;

    my $wiki_data = Silki::JSON->Decode(
        scalar read_file(
            $self->_find_file_in_archive('wiki.json')->stringify()
        )
    );

    if ( Silki::Schema::Wiki->new( title => $wiki_data->{title} ) ) {
        die loc(
            'There is already a wiki with this title (%1)',
            $wiki_data->{title}
        );
    }

    if ( Silki::Schema::Wiki->new( short_name => $wiki_data->{short_name} ) )
    {
        die loc(
            'There is already a wiki with this short_name (%1)',
            $wiki_data->{short_name}
        );
    }

    $self->_maybe_log(
        loc( 'Creating a new wiki (%1)', $wiki_data->{title} ) );

    my $wiki = Silki::Schema::Wiki->insert(
        title              => $wiki_data->{title},
        short_name         => $wiki_data->{short_name},
        user               => $self->user(),
        domain_id          => $self->domain()->domain_id(),
        skip_default_pages => 1,
    );

    my $perm_data = Silki::JSON->Decode(
        scalar read_file(
            $self->_find_file_in_archive('permissions.json')->stringify()
        )
    );

    my %set = map { $_ => [ keys %{ $perm_data->{$_} } ] } keys %{$perm_data};

    $wiki->_set_permissions_from_set( \%set );

    $self->_set_wiki($wiki);

    return;
}

sub _import_users {
    my $self = shift;

    my $user_count = 0;

    for my $data (
        map  { Silki::JSON->Decode( scalar read_file( $_->stringify() ) ) }
        grep { !$_->is_dir() }
        $self->_export_root_dir()->subdir('users')->children()
        ) {

        $self->_import_user($data);

        $user_count++;

        if ( $user_count % 10 == 0 ) {
            $self->_maybe_log(
                loc( 'Imported %quant( %1, user, users )', $user_count ) );
        }
    }

    if ( $user_count % 10 != 0 ) {
        $self->_maybe_log(
            loc( 'Imported %quant( %1, user, users )', $user_count ) );
    }
}

sub _import_user {
    my $self = shift;
    my $data = shift;

    my $user
        = Silki::Schema::User->new( email_address => $data->{email_address} )
        || Silki::Schema::User->new( username => $data->{username} );

    my $role = delete $data->{role_in_wiki};

    my $orig_user_id = delete $data->{user_id};

    if ($user) {
        $self->_maybe_log(
            loc(
                'Skipping user already in system (%1)', $user->email_address()
            )
        );
    }
    elsif ( $data->{is_system_user} ) {
        die loc(
            'Found a system user that does not exist in this system (%1)!',
            $data->{username}
        );
    }
    else {
        delete @{$data}{
            qw(
                is_system_user
                creation_datetime
                last_modified_datetime
                )
            };

        $user = Silki::Schema::User->insert(
            %{$data},
            requires_activation => 1,
            user                => $self->user(),
        );

        if ( $data->{openid_uri} ) {
            $user->update(
                openid_uri => $data->{openid_uri},
                user       => $self->user(),
            );
        }
    }

    if ($role) {
        $self->_wiki()->add_user(
            user => $user,
            role => Silki::Schema::Role->$role(),
        );

        $self->_add_pending_invitation($user);
    }

    $self->_set_user_id_mapping( $orig_user_id => $user->user_id() );

    return;
}

sub _import_pages {
    my $self = shift;

    my $page_count     = 0;
    my $revision_count = 0;

    for my $page_dir ( grep { $_->is_dir() }
        $self->_export_root_dir()->subdir('pages')->children() ) {

        my $page_data = Silki::JSON->Decode(
            scalar read_file( $page_dir->file('page.json')->stringify() ) );

        my $old_page_id = delete $page_data->{page_id};

        my $page = Silki::Schema::Page->insert(
            %{$page_data},
            wiki_id => $self->_wiki()->wiki_id(),
            user_id => $self->_new_user_id_for( $page_data->{user_id} ),
        );

        $self->_set_page_id_mapping( $old_page_id => $page->page_id() );

        $page_count++;

        my @revision_files = sort {
            my ($arev) = $a->basename() =~ /revision-(\d+)/;
            my ($brev) = $b->basename() =~ /revision-(\d+)/;
            $arev <=> $brev
            }
            grep { !$_->is_dir() && $_->basename() =~ /revision-\d+/ }
            $page_dir->children();

        for my $revision_file (@revision_files) {
            my $rev_data = Silki::JSON->Decode(
                scalar read_file( $revision_file->stringify() ) );

            delete @{$rev_data}{qw( page_id revision_number )};

            local $Silki::Schema::PageRevision::SkipPostChangeHack
                = $revision_file eq $revision_files[-1] ? 0 : 1;

            $page->add_revision(
                %{$rev_data},
                user_id => $self->_new_user_id_for( $rev_data->{user_id} ),
            );

            $revision_count++;

            if ( $revision_count % 20 == 0 ) {
                $self->_maybe_log(
                    loc(
                        'Imported %quant( %1, revision, revisions ) (%quant( %2, page, pages ))',
                        $revision_count,
                        $page_count
                    )
                );
            }
        }
    }

    if ( $revision_count % 20 != 0 ) {
        $self->_maybe_log(
            loc(
                'Imported %quant( %1, revision, revisions ) (%quant( %2, page, pages ))',
                $revision_count,
                $page_count
            )
        );
    }
}

sub _import_files {
    my $self = shift;

    my $file_count = 0;

    return unless -d $self->_export_root_dir()->subdir('files');

    for my $file_dir ( grep { $_->is_dir() }
        $self->_export_root_dir()->subdir('files')->children() ) {

        my $data = Silki::JSON->Decode(
            scalar read_file( $file_dir->file('file.json')->stringify() ) );

        delete $data->{file_id};

        my $data_file = $file_dir->file( $data->{filename} );

        my $file = Silki::Schema::File->insert(
            %{$data},
            file_size => -s $data_file,
            contents  => scalar read_file( $data_file->stringify() ),
            page_id   => $self->_new_page_id_for( $data->{page_id} ),
        );

        $file_count++;

        if ( $file_count % 10 == 0 ) {
            $self->_maybe_log(
                loc( 'Imported %quant( %1, file, files )', $file_count ) );
        }
    }

    if ( $file_count % 10 != 0 ) {
        $self->_maybe_log(
            loc( 'Imported %quant( %1, file, files )', $file_count ) );
    }
}

sub _find_file_in_archive {
    my $self = shift;

    $self->_export_root_dir()->file(@_);
}

sub _build_export_root_dir {
    my $self = shift;

    my $tardir = dir( $self->_archive()->tardir() );

    my ($dir) = ( glob( $tardir->subdir('export-of-*') ) )[0];

    return dir($dir);
}

sub _disable_pg_triggers {
    my $self = shift;

    my $dbh = Silki::Schema->DBIManager()->default_source()->dbh();

    $dbh->do(q{ALTER TABLE "Page" DISABLE TRIGGER USER});
    $dbh->do(q{ALTER TABLE "PageRevision" DISABLE TRIGGER USER});
}

sub _enable_pg_triggers {
    my $self = shift;

    my $dbh = Silki::Schema->DBIManager()->default_source()->dbh();

    $dbh->do(q{ALTER TABLE "Page" ENABLE TRIGGER USER});
    $dbh->do(q{ALTER TABLE "PageRevision" ENABLE TRIGGER USER});
}

sub _rebuild_searchable_text {
    my $self = shift;

    my $sql = <<'EOF';
INSERT INTO "PageSearchableText"
  (page_id, ts_text)
SELECT pages.page_id,
       setweight(to_tsvector('pg_catalog.english', pages.title), 'A') ||
       setweight(to_tsvector('pg_catalog.english', pages.content), 'B')
  FROM ( SELECT p.page_id, p.title, pr.content
           FROM "Page" AS p, "PageRevision" AS pr
          WHERE revision_number =
                ( SELECT MAX(revision_number)
                    FROM "PageRevision"
                   WHERE page_id = p.page_id )
            AND p.page_id = pr.page_id
            AND p.wiki_id = ?
       ) AS pages
EOF

    my $dbh = Silki::Schema->DBIManager()->default_source()->dbh();

    $dbh->do( $sql, {}, $self->_wiki()->wiki_id() );
}

__PACKAGE__->meta()->make_immutable();

1;
