#
# Makefile.PL
#
# $Author: grazz $
# $Date: 2003/11/03 22:51:29 $
#

use ExtUtils::MakeMaker;
use Config;
use 5.006;

my $define  = '-DRE_FIELDS';
my $tests   = 't/*.t';
my $dirs    = ['tie'];
my @NO_META;

if ($] >= 5.008001) {
    @NO_META = ( NO_META => 1 );
}
if ($] >= 5.008) {
    $define .= ' -DRE_FIELDS_MAGIC -DRE_FIELDS_LEXICAL';
    $tests  .= ' t/lexical/*.t';
    $dirs    = [];
}
if ($] >= 5.007001) {
    $define .= ' -DRE_FIELDS_REXC';
}

do './sources/patch.pl';
my $o = '$(OBJ_EXT)';

WriteMakefile(
    NAME            => 'Regexp::Fields',
    VERSION_FROM    => 'Fields.pm',
    ABSTRACT_FROM   => 'Fields.pm',
    AUTHOR          => 'Steve Grazzini <grazz@pobox.com>',
    OBJECT          => "rx_regcomp${o} rx_regexec${o} Fields${o}",
    INC             => '-I./include',
    DEFINE          => $define,
    DIR             => $dirs,

    clean  => { FILES => "rx_reg{comp,exec}.c" },
    test   => { TESTS => join " ", glob $tests },

    @NO_META
);
