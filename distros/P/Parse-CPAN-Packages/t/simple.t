#!/usr/bin/perl
use strict;
use Test::InDistDir;
use Test::More;
use File::Slurp 'read_file';

run();
done_testing;

sub run {
    use_ok( "Parse::CPAN::Packages" );

    default_features();

    my $raw_data = read_file( "t/02packages.details.txt" );
    my $gz_data = read_file( "t/02packages.details.txt.gz", binmode => ':raw' );

    creation_check( "t/02packages.details.txt.gz", "gzip file is parsed" );
    creation_check( $raw_data,                     "text contents are parsed" );
    creation_check( $gz_data,                      "gzip contents are parsed" );

    dist_contents( "t/mirror/modules/02packages.details.txt.gz", "mirror file with implicit mirror directory" );
    dist_contents( filename => "t/02packages.details.txt", mirror_dir => "t/mirror", "mirror file with explicit mirror dir" );

    return;
}

sub default_features {
    my ( $p, @packages ) = creation_check( "t/02packages.details.txt", "text file is parsed" );

    is( $p->file,         '02packages.details.txt',                                  'file' );
    is( $p->url,          'http://www.perl.com/CPAN/modules/02packages.details.txt', 'url' );
    is( $p->description,  'Package names found in directory $CPAN/authors/id/',      'description' );
    is( $p->columns,      'package name, version, path',                             'columns' );
    is( $p->intended_for, 'Automated fetch routines, namespace documentation.',      'intended for' );
    is( $p->written_by,   'Id: mldistwatch 479 2004-01-04 13:29:05Z k ',             'written by' );
    is( $p->line_count,   23609,                                                     'line count' );
    is( $p->last_updated, 'Fri, 13 Feb 2004 13:50:21 GMT',                           'last updated' );

    my $m = $p->package( "Acme::Colour" );
    is( $m->package, "Acme::Colour" );
    is( $m->version, "1.00" );

    my $d = $m->distribution;
    is( $d->prefix,    "L/LB/LBROCARD/Acme-Colour-1.00.tar.gz" );
    is( $d->dist,      "Acme-Colour" );
    is( $d->version,   "1.00" );
    is( $d->maturity,  "released" );
    is( $d->filename,  "Acme-Colour-1.00.tar.gz" );
    is( $d->cpanid,    "LBROCARD" );
    is( $d->distvname, "Acme-Colour-1.00" );

    is( $p->package( "accessors::chained" )->distribution->dist, "accessors", "accessors::chained lives in accessors" );

    is( $p->package( "accessors::classic" )->distribution->dist, "accessors", "as does accessors::classic" );

    is( $p->package( "accessors::chained" )->distribution, $p->package( "accessors::classic" )->distribution, "and they're using the same distribution object" );

    my $dist = $p->distribution( 'S/SP/SPURKIS/accessors-0.02.tar.gz' );
    is( $dist->dist, 'accessors' );
    is( $dist, $p->package( "accessors::chained" )->distribution, "by path match by name" );

    is_deeply( [ map { $_->package } $dist->contains ], [qw( accessors accessors::chained accessors::classic )], "dist contains packages" );

    $d = $p->latest_distribution( "Acme-Colour" );
    is( $d->prefix,  "L/LB/LBROCARD/Acme-Colour-1.00.tar.gz" );
    is( $d->version, "1.00" );

    is_deeply(
        [ sort map { $_->prefix } $p->latest_distributions ],
        [
            'A/AU/AUTRIJUS/Acme-ComeFrom-0.07.tar.gz', 'K/KA/KANE/Acme-Comment-1.02.tar.gz', 'L/LB/LBROCARD/Acme-Colour-1.00.tar.gz', 'S/SM/SMUELLER/Acme-Currency-0.01.tar.gz',
            'S/SP/SPURKIS/accessors-0.02.tar.gz',      'X/XE/XERN/Acme-CramCode-0.01.tar.gz',
        ]
    );

    # counts
    is( $p->package_count,             scalar @packages, "package count" );
    is( $p->distribution_count,        7,                "dist count" );
    is( $p->latest_distribution_count, 6,                "latest dist count" );

    return;
}

sub dist_contents {
    my ( $p ) = creation_check( @_ );

    my $test_dist = $p->dists->{"K/KA/KANE/Acme-Comment-1.02.tar.gz"};
    my $file      = "Acme-Comment-1.02/lib/Acme/Comment.pm";
    is( ( $test_dist->list_files )[0], $file, "listing files in dists works" );

    my $test_pkg = $p->data->{"Acme::Comment"};
    is( $test_pkg->filename,                        $file, "a package can generate a good guess file name" );
    is( $test_dist->get_file_from_tarball( $file ), "moo", "getting the content of a file in a dist works" );
    is( $test_pkg->file_content,                    "moo", "a package can provide the content of its file" );

    return;
}

sub creation_check {
    my $reason = pop;
    my $p = eval { Parse::CPAN::Packages->new( @_ ) };
    is( $@, "", "no errors from the eval" );
    isa_ok( $p, "Parse::CPAN::Packages" );

    my @packages = sort map { $_->package } $p->packages;
    is_deeply( \@packages, default_packages(), $reason );

    return ( $p, @packages );
}

sub default_packages {
    return [qw(Acme::Colour Acme::Colour::Old Acme::ComeFrom Acme::Comment Acme::CramCode Acme::Currency accessors accessors::chained accessors::classic )];
}
