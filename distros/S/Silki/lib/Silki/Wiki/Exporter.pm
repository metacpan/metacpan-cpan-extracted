package Silki::Wiki::Exporter;
{
  $Silki::Wiki::Exporter::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Archive::Tar::Wrapper;
use File::Slurp qw( write_file );
use File::Spec;
use File::Temp qw( tempdir );
use Path::Class qw( file );
use Silki::I18N qw( loc );
use Silki::JSON;
use Silki::Schema::Wiki;
use Silki::Types qw( Dir HashRef Tarball );

use Moose;
use MooseX::SemiAffordanceAccessor;

with 'Silki::Role::OptionalLog';

has _wiki => (
    is       => 'ro',
    isa      => 'Silki::Schema::Wiki',
    init_arg => 'wiki',
    required => 1,
);

has tarball => (
    is       => 'ro',
    isa      => Tarball,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_tarball',
);

has _dir => (
    is       => 'ro',
    isa      => Dir,
    init_arg => undef,
    lazy     => 1,
    default  => sub { 'export-of-' . $_[0]->_wiki()->short_name() },
    coerce   => 1,
);

has _archive => (
    is       => 'ro',
    isa      => 'Archive::Tar::Wrapper',
    init_arg => undef,
    lazy     => 1,
    default  => sub { Archive::Tar::Wrapper->new() },
);

has _user_ids_from_pages => (
    traits   => ['Hash'],
    is       => 'bare',
    isa      => HashRef,
    init_arg => undef,
    default  => sub { {} },
    handles  => {
        _user_ids_from_pages      => 'keys',
        _add_user_id_from_page    => 'set',
        _delete_user_id_from_page => 'delete',
    },
);

use constant EXPORT_FORMAT_VERSION => 1;

# Exists for the benefit of the test code
sub _export_format_version {
    return EXPORT_FORMAT_VERSION;
}

sub _build_tarball {
    my $self = shift;

    $self->_add_to_archive(
        $self->_dir()->file('export-metadata.json'), {
            silki_version         => Silki->VERSION(),
            export_format_version => EXPORT_FORMAT_VERSION,
        },
    );

    $self->_add_to_archive(
        $self->_dir()->file('wiki.json'),
        $self->_wiki()->serialize(),
    );

    $self->_add_to_archive(
        $self->_dir()->file('permissions.json'),
        $self->_wiki()->permissions(),
    );

    $self->_add_pages_to_archive();
    $self->_add_users_to_archive();
    $self->_add_files_to_archive();

    my $tarball = file(
        tempdir( CLEANUP => 1 ),
        'export-of-' . $self->_wiki()->short_name() . '.tar.gz'
    );

    $self->_maybe_log( loc('Creating the tarball (this may take a while).') );

    $self->_archive()->write( $tarball, 'compress' );

    return $tarball;
}

sub _add_pages_to_archive {
    my $self = shift;

    my $revision_count = 0;

    my $pages = $self->_wiki()->pages();

    my %users;

    while ( my $page = $pages->next() ) {

        my $page_dir = $self->_dir()->subdir( 'pages', $page->uri_path() );

        $self->_add_to_archive(
            $page_dir->file('page.json'),
            $page->serialize,
        );

        my $revisions = $page->revisions();
        while ( my $revision = $revisions->next() ) {

            my $revision_file = $page_dir->file(
                'revision-' . $revision->revision_number() . '.json' );

            $self->_add_to_archive(
                $page_dir->file(
                    'revision-' . $revision->revision_number() . '.json'
                ),
                $revision->serialize,
            );

            $revision_count++;

            if ( $revision_count % 50 == 0 ) {
                $self->_maybe_log(
                    loc(
                        'Exported %1 revisions (of %quant( %2, page, pages ))',
                        $revision_count,
                        $pages->index(),
                    )
                );
            }

            $self->_add_user_id_from_page( $revision->user_id(), 1 );
        }
    }

    if ( $revision_count % 50 != 0 ) {
        $self->_maybe_log(
            loc(
                'Exported %1 revisions (of %quant( %2, page, pages ))',
                $revision_count,
                $pages->index(),
            )
        );
    }
}

sub _add_users_to_archive {
    my $self = shift;

    my $user_count = 0;

    my $members = $self->_wiki()->members();
    while ( my ( $user, $role ) = $members->next() ) {

        $self->_delete_user_id_from_page( $user->user_id() );

        my $ser = $user->serialize();
        $ser->{role_in_wiki} = $role->name();

        $self->_add_to_archive(
            $self->_dir()
                ->file( 'users', 'user-' . $user->user_id() . '.json' ),
            $ser,
        );

        $user_count++;

        if ( $user_count % 20 == 0 ) {
            $self->_maybe_log(
                loc(
                    'Exported %quant( %1, user, users )',
                    $user_count,
                )
            );
        }
    }

    for my $user ( map { Silki::Schema::User->new( user_id => $_ ) }
        $self->_user_ids_from_pages() ) {

        $self->_add_to_archive(
            $self->_dir()
                ->file( 'users', 'user-' . $user->user_id() . '.json' ),
            $user->serialize(),
        );

        $user_count++;

        if ( $user_count % 20 == 0 ) {
            $self->_maybe_log(
                loc(
                    'Exported %quant( %1, user, users )',
                    $user_count,
                )
            );
        }
    }

    if ( $user_count % 20 != 0 ) {
        $self->_maybe_log(
            loc(
                'Exported %quant( %1, user, users )',
                $user_count,
            )
        );
    }
}

sub _add_files_to_archive {
    my $self = shift;

    my $files = $self->_wiki()->files();

    while ( my $file = $files->next() ) {
        my $dir
            = $self->_dir()->subdir( 'files', 'file-' . $file->file_id() );

        $self->_add_to_archive(
            $dir->file('file.json'),
            $file->serialize(),
        );

        $self->_archive->add(
            $dir->file( $file->filename() ),
            \( $file->contents() ),
        );

        if ( $files->index() % 20 == 0 ) {
            $self->_maybe_log(
                loc(
                    'Exported %quant( %1, file, files )',
                    $files->index(),
                )
            );
        }
    }
}

sub _add_to_archive {
    my $self = shift;
    my $path = shift;
    my $data = shift;

    $self->_archive()->add(
        $path,
        \( Silki::JSON->Encode($data) ),
        { binmode => ':utf8' }
    );

    return;
}

__PACKAGE__->meta()->make_immutable();

1;
