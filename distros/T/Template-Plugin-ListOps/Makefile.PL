
use ExtUtils::MakeMaker;
use 5.004;
use strict;
use warnings;
my %requires = (
                 'Array::AsObject'          => '0',
                 'Template'                 => '0',
                 'Template::Plugin'         => '0',
                 'IO::File'                 => '0',
                 'Test::More'               => '0',
                 'Test::Pod'                => '0',
                 'Test::Pod::Coverage'      => '0',
               );


WriteMakefile(
        NAME             => 'Template::Plugin::ListOps',
        VERSION          => '2.01',
        ($] >= 5.004
        ? (ABSTRACT=>'Plugin interface to list operations',
           AUTHOR  =>'Sullivan Beck (sbeck@cpan.org)')
        : ()),
        'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
        PL_FILES  => {},
        PREREQ_PM => \%requires,
);
