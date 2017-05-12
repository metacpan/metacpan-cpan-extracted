
use ExtUtils::MakeMaker;
use 5.000;
use strict;
use warnings;
my %requires = (
                 'Date::Manip'              => '0',
                 'Exporter'                 => '0',
                 'Storable'                 => '0',
                 'Test::Inter'              => '0',
               );


WriteMakefile(
        NAME             => 'Sort::DataTypes',
        VERSION          => '3.01',
        ($] >= 5.000
        ? (ABSTRACT=>'Sort a list of data using methods relevant to the type of data',
           AUTHOR  =>'Sullivan Beck (sbeck@cpan.org)')
        : ()),
        'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
        PL_FILES  => {},
        PREREQ_PM => \%requires,
);
