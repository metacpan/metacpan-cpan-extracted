
use strict;
use lib 'inc';
use ExtUtils::MakeMaker;
use Devel::CheckLib;

check_lib_or_exit( lib => 'c', header => "regex.h" );

WriteMakefile(
    NAME              => 'POSIX::Regex',
    VERSION_FROM      => 'Regex.pm',
    AUTHOR            => 'Paul Miller <jettero@cpan.org>',
    'PREREQ_PM'    => {
        'ExtUtils::Constant' => 0.16,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.008,
            META_MERGE => {
                keywords => ['posix', 'regex'],
                resources=> {
                    repository => 'http://github.com/jettero/posix--regex/tree',
                },
            },

        LICENSE	=> 'lgpl2',
    ) : ()),
);

my @names = (qw(
    REG_EXTENDED
    REG_ICASE REG_NEWLINE
    REG_NOTBOL REG_NOTEOL
));

eval 'use ExtUtils::Constant';
if( not $@ ) {
    ExtUtils::Constant::WriteConstants(
        NAME         => 'POSIX::Regex',
        NAMES        => \@names,
        DEFAULT_TYPE => 'IV',
        C_FILE       => 'const-c.inc',
        XS_FILE      => 'const-xs.inc',
    );
}
