#!perl

use strict;
use warnings;

use Data::Dumper;
use FindBin;
use Path::Tiny;

use R::DescriptionFile;

use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;

my $data_path = "$FindBin::RealBin/data";

{
    my $descfile =
      R::DescriptionFile->parse_file( path( $data_path, "DESCRIPTION_Rcpp" ) );
    ok( $descfile, "parse_file()" );

    diag Dumper $descfile;
    ok( $descfile->get('Description') !~ /\n/,
        "Description field is merged from multiple lines" );

    is( $descfile->get('Package'), 'Rcpp', "Package field" );
    is( $descfile->get('Depends'), { 'R' => '>= 3.0.0' }, "Depends field" );
    is(
        $descfile->{'Suggests'},
        {
            'pkgKitten'  => '>= 0.1.2',
            'rbenchmark' => 0,
            'knitr'      => 0,
            'pinp'       => 0,
            'RUnit'      => 0,
            'inline'     => 0,
            'rmarkdown'  => 0
        },
        "Suggests field"
    );
    is( $descfile->get('Imports'), [ 'methods', 'utils' ], "Imports field" );

    is(
        $descfile->get('URL'),
        [
            'http://www.rcpp.org',
            'http://dirk.eddelbuettel.com/code/rcpp.html',
            'https://github.com/RcppCore/Rcpp'
        ],
        "URL field"
    );

    ok($descfile->{'Date/Publication'}, "last line is parsed");
}

{
    my $descfile = 
      R::DescriptionFile->parse_text( path( $data_path, "DESCRIPTION_Rcpp" )->slurp_utf8 );
    ok( $descfile, "parse_text()" );
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
