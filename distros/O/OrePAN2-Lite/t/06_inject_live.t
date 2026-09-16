use strict;
use warnings;
use utf8;

use lib 't/lib';

use Test::More;

plan skip_all => 'set AUTHOR_TESTING to run live MetaCPAN tests'
    unless $ENV{AUTHOR_TESTING};

use Test::RequiresInternet ( 'fastapi.metacpan.org' => 443 );
use File::Temp qw( tempdir );
use OrePAN2::Indexer  ();
use OrePAN2::Injector ();

# Ported from OrePAN2 0.54 t/06_inject_live.t, heavily adapted for
# OrePAN2::Lite. All subtests exercising the removed MetaCPAN::Client
# provides-optimization (metacpan => 1, _metacpan_lookup,
# do_metacpan_lookup, metacpan_lookup_size) are gone -- that capability
# was dropped in 2.0.0. What remains tests OUR live paths:
#
#   * inject_from_http + multi-version "latest wins" indexing
#   * coderef author resolved over http (_detect_author via http)
#   * inject-by-name, which is OrePAN2::Lite's HTTP::Tiny reimplementation
#     of the metacpan download_url lookup (the thing that replaced
#     MetaCPAN::Client in the injector)

sub inject_and_index {
    my ( $dir, $archive ) = @_;

    my $injector = OrePAN2::Injector->new( directory => $dir );
    $injector->inject($archive);

    my $orepan = OrePAN2::Indexer->new( directory => $dir );
    return $orepan->make_index;
}

subtest 'inject by module name (download_url reimplementation)' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    # Bare module name -> OrePAN2::Lite resolves via
    # fastapi.metacpan.org/v1/download_url/<name> using HTTP::Tiny,
    # then inject_from_http the resolved URL. This is the code path that
    # replaced MetaCPAN::Client in the injector.
    my $injector = OrePAN2::Injector->new( directory => $tmpdir );
    $injector->inject('OrePAN2');

    my @found = glob "$tmpdir/authors/id/*/*/*/OrePAN2-*.tar.gz";
    ok( @found, 'inject-by-name fetched and placed a OrePAN2 tarball' )
        or diag 'no OrePAN2 tarball under authors/id';
};

subtest 'upgrade undef versions (latest wins, injected out of order)' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    # Inject 0.32 then 0.31; newer archive must still win.
    inject_and_index( $tmpdir,
        'https://cpan.metacpan.org/authors/id/O/OA/OALDERS/OrePAN2-0.32.tar.gz'
    );
    my $index = inject_and_index( $tmpdir,
        'https://cpan.metacpan.org/authors/id/O/OA/OALDERS/OrePAN2-0.31.tar.gz'
    );

    my $latest = 'OrePAN2-0.32.tar.gz';
    for my $pkg ( 'OrePAN2', 'OrePAN2::Indexer' ) {
        my ( undef, $path ) = $index->lookup($pkg);
        like $path, qr{$latest}, "$pkg resolves to $latest";
    }
};

subtest 'coderef author with inject from http' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );

    my $author = sub {
        my $source = shift;
        return $source =~ m{authors/id/./../([^/]+)} ? $1 : die 'unexpected';
    };

    my $injector = OrePAN2::Injector->new( directory => $tmpdir );
    $injector->inject(
        'https://cpan.metacpan.org/authors/id/O/OA/OALDERS/OrePAN2-0.32.tar.gz',
        { author => $author },
    );

    ok -f "$tmpdir/authors/id/O/OA/OALDERS/OrePAN2-0.32.tar.gz",
        'author detected from url via coderef';
};

done_testing;
