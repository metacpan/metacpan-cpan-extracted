use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => '<tmpl_var distro>',
    VERSION_FROM        => '<tmpl_var main_pm_file>',
    ABSTRACT_FROM       => '<tmpl_var main_pm_file>',
    AUTHOR              => '<tmpl_var author> <<tmpl_var email>>',
    LICENSE             => '<tmpl_var license>',
    PL_FILES            => {},
    PREREQ_PM => {
        'CGI::Application'              => 4.04,
        'HTML::Template'                => 0,
        'Test::More'                    => 0,
        'Test::WWW::Mechanize::CGIApp'  => 0,
    },
    SIGN => 1,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => '<tmpl_var distro>-*' },
);
