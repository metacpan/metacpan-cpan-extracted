
use ExtUtils::MakeMaker;
use 5.000;
use strict;
use warnings;
my %requires = (
                 'Carp'                     => '0',
                 'IO::File'                 => '0',
                 'Test::Inter'              => '0',
                 'Test::Pod'                => '0',
                 'Test::Pod::Coverage'      => '0',
               );


WriteMakefile(
        NAME             => 'Set::Files',
        VERSION          => '1.06',
        ($] >= 5.000
        ? (ABSTRACT=>'routines to work with files, each definining a single set',
           AUTHOR  =>'Sullivan Beck (sbeck@cpan.org)')
        : ()),
        'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
        PL_FILES  => {},
        PREREQ_PM => \%requires,
);
