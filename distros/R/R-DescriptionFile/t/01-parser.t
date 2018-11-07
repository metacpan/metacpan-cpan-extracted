#!perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use Path::Tiny;

use List::Util 1.33;
use R::DescriptionFile;

use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;

my $data_path = "$FindBin::RealBin/data";

subtest Rcpp => sub {
    my $descfile =
      R::DescriptionFile->parse_file( path( $data_path, "DESCRIPTION_Rcpp" ) );
    ok( $descfile, "parse_file()" );

    diag Dumper $descfile;
    ok( $descfile->get('Description') !~ /\n/,
        "Description field is merged from multiple lines" );

    is( $descfile->get('Package'), 'Rcpp', "Package field" );
    is(
        $descfile->get('Depends'),
        { 'R' => '>= 3.0.0' },
        '$descfile->get($field)'
    );
    is(
        $descfile->get('Imports'),
        { 'methods' => '', 'utils' => '' },
        '$descfile->get($field)'
    );
    is(
        $descfile->{'Suggests'},
        {
            'pkgKitten'  => '>= 0.1.2',
            'rbenchmark' => '',
            'knitr'      => '',
            'pinp'       => '',
            'RUnit'      => '',
            'inline'     => '',
            'rmarkdown'  => ''
        },
        '$descfile->{$field}'
    );

    is(
        $descfile->get('URL'),
        [
            'http://www.rcpp.org',
            'http://dirk.eddelbuettel.com/code/rcpp.html',
            'https://github.com/RcppCore/Rcpp'
        ],
        "URL field"
    );

    ok( $descfile->{'Date/Publication'}, "last line is parsed" );
};

subtest dplyr => sub {
    my $descfile =
      R::DescriptionFile->parse_file( path( $data_path, "DESCRIPTION_dplyr" ) );
    ok( $descfile, "parse_file()" );

    ok(
        (
            List::Util::all { ref( $descfile->{$_} ) eq 'HASH' }
            qw(Depends Suggests Imports LinkingTo)
        ),
        'Depends, Suggests, Imports, LinkingTo shall all be hashref'
    );

    ok(
        (
            List::Util::all { ref( $descfile->{$_} ) eq 'ARRAY' }
            qw(URL VignetteBuilder)
        ),
        'URL, VignetteBuilder shall all be arrayref'
    );
};

{
    my $descfile =
      R::DescriptionFile->parse_text(
        path( $data_path, "DESCRIPTION_foo" )->slurp_utf8 );
    ok( $descfile, "parse_text()" );

    is(
        $descfile->{Description},
        'This is a multiline description.',
        'good for multiline Description field'
    );
}

{
    like(
        dies {
            R::DescriptionFile->parse_file(
                path( $data_path, "DESCRIPTION_bad1" ) );
        },
        qr/Missing mandatory fields: Description, Maintainer/,
        "Got exception on missing mandatory fields"
    );
    like(
        dies {
            R::DescriptionFile->parse_file(
                path( $data_path, "DESCRIPTION_bad2" ) );
        },
        qr/Field not seen at line 21: it should break here/,
        "Got exception on invalid line"
    );
}

done_testing;
