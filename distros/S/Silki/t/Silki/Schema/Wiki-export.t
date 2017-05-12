use strict;
use warnings;

use Test::Most;

use lib 't/lib';
use Silki::Test::RealSchema;

use Archive::Tar::Wrapper;
use File::Slurp qw( read_file );
use Path::Class qw( dir file );
use Silki;
use Silki::JSON;
use Silki::Schema::Page;
use Silki::Schema::User;
use Silki::Schema::Wiki;
use Silki::Wiki::Exporter;

my $user = Silki::Schema::User->GuestUser();
my $wiki = Silki::Schema::Wiki->new( title => 'First Wiki' );

my $fp = Silki::Schema::Page->new(
    title   => 'Front Page',
    wiki_id => $wiki->wiki_id(),
);

$fp->add_revision(
    content => 'Spanking new content!',
    user_id => $user->user_id(),
);

my $text  = "Some random text\nin this file.\n";
my $file1 = Silki::Schema::File->insert(
    filename  => 'test.txt',
    mime_type => 'text/plain',
    file_size => length $text,
    contents  => $text,
    user_id   => $user->user_id(),
    page_id   => $fp->page_id(),
);

my $jpg   = read_file('t/share/data/test.jpg');
my $file2 = Silki::Schema::File->insert(
    filename  => 'test.jpg',
    mime_type => 'image/jpeg',
    file_size => length $jpg,
    contents  => $jpg,
    user_id   => $user->user_id(),
    page_id   => $fp->page_id(),
);

$fp->add_file($_) for $file1, $file2;

{
    my @pages = map { _data_for_page($_) } $wiki->pages()->all();

    my @users = sort { $a->{display_name} cmp $b->{display_name} }
        map { _data_for_user( $wiki, $_ ) } Silki::Schema::User->All()->all();

    my @files = sort { $a->{filename} cmp $b->{filename} }
        map { _data_for_file($_) } $wiki->files()->all();

    my %expect = (
        wiki        => $wiki->serialize(),
        permissions => $wiki->permissions(),
        pages       => \@pages,
        users       => \@users,
        files       => \@files,
    );

    _test_archive( $wiki->export(), \%expect );
}

done_testing();

sub _data_for_page {
    my $page = shift;

    my $ser = $page->serialize();

    my $revisions = $page->revisions();

    while ( my $rev = $revisions->next() ) {
        push @{ $ser->{revisions} }, $rev->serialize();
    }

    return $ser;
}

sub _data_for_user {
    my $wiki = shift;
    my $user = shift;

    my $ser = $user->serialize();

    if ( $user->is_wiki_member($wiki) ) {
        $ser->{role_in_wiki} = $user->role_in_wiki($wiki)->name();
    }

    return $ser;
}

sub _data_for_file {
    my $file = shift;

    my $ser = $file->serialize();
    $ser->{contents} = $file->contents();

    return $ser;
}

sub _test_archive {
    my $tarball = shift;
    my $expect  = shift;

    my $tar = Archive::Tar::Wrapper->new();
    $tar->read($tarball);

    my $dir = dir( $tar->tardir() )->subdir('export-of-first-wiki');

    my $metadata = _get_one_json_file( $dir, 'export-metadata.json' );

    is_deeply(
        $metadata, {
            silki_version => Silki->VERSION,
            export_format_version =>
                Silki::Wiki::Exporter->_export_format_version(),
        },
        'export metadata in exported tarball'
    );

    my $wiki = _get_one_json_file( $dir, 'wiki.json' );

    is_deeply(
        $wiki,
        $expect->{wiki},
        'wiki data in exported tarball'
    );

    my $permissions = _get_one_json_file( $dir, 'permissions.json' );

    is_deeply(
        $permissions,
        $expect->{permissions},
        'permissions data in exported tarball'
    );

    is_deeply(
        _get_pages($dir),
        $expect->{pages},
        'pages in exported tarball'
    );

    is_deeply(
        _get_users($dir),
        $expect->{users},
        'users in exported tarball'
    );

    is_deeply(
        _get_files($dir),
        $expect->{files},
        'files in exported tarball'
    );
}

sub _get_one_json_file {
    my $dir      = shift;
    my $filename = shift;

    return Silki::JSON->Decode(
        scalar read_file( $dir->file($filename)->stringify() ) );
}

sub _get_pages {
    my $dir = shift;

    my %pages;
    my %revisions;

    my $pages_dir = $dir->subdir('pages');

    while ( my $entry = $pages_dir->next() ) {
        next unless -d $entry && $entry !~ /\.\./;

    FILE:
        while ( my $file = $entry->next() ) {
            next FILE unless -f $file;

            my $data = Silki::JSON->Decode( scalar read_file($file) );

            if ( $file =~ m{/([^/]+)/page\.json} ) {
                $pages{$1} = $data;
            }
            elsif ( $file =~ m{/([^/]+)/revision-\d+\.json} ) {
                push @{ $revisions{$1} }, $data;
            }
        }
    }

    my @combined;
    for my $uri_path ( sort keys %pages ) {
        if ( !exists $revisions{$uri_path} ) {
            fail("No revisions for page $pages{$uri_path}{title}");
            next;
        }

        my $page = $pages{$uri_path};
        $page->{revisions}
            = [ sort { $b->{revision_number} <=> $a->{revision_number} }
                @{ $revisions{$uri_path} } ];

        push @combined, $page;
    }

    return [ sort { $a->{title} cmp $b->{title} } @combined ];
}

sub _get_users {
    my $dir = shift;

    my $users_dir = $dir->subdir('users');

    my @users;
    while ( defined( my $file = $users_dir->next() ) ) {
        next unless -f $file;
        push @users, Silki::JSON->Decode( scalar read_file($file) );
    }

    return [ sort { $a->{display_name} cmp $b->{display_name} } @users ];
}

sub _get_files {
    my $dir = shift;

    my @files;
    my %contents;

    my $files_dir = $dir->subdir('files');

    while ( my $entry = $files_dir->next() ) {
        next unless -d $entry && $entry !~ /\.\./;

        while ( my $file = $entry->next() ) {
            next unless -f $file;

            if ( $file =~ /\.json$/ ) {
                push @files, Silki::JSON->Decode( scalar read_file($file) );
            }
            else {
                $contents{ file($file)->basename() } = read_file($file);
            }
        }
    }

    for my $file (@files) {
        if ( !exists $contents{ $file->{filename} } ) {
            fail("No contents for $file->{filename} in tarball");
        }
        else {
            $file->{contents} = delete $contents{ $file->{filename} };
        }
    }

    if ( keys %contents ) {
        fail(
            "Found contents for files without metadata: "
                . (
                join ', ',
                keys %contents
                )
        );
    }

    return [ sort { $a->{filename} cmp $b->{filename} } @files ];
}
