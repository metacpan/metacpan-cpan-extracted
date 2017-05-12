#!./perl -w

use strict;
use ExtUtils::MakeMaker;
use ObjStore::MakeMaker qw(add_os_args os_schema_rule);
use PDL::Version 1.99987; # plus needs patches
use PDL::Core::Dev;

my $v = '01';
my %args = (
	    PREREQ_PM	 => { ObjStore => '1.52' },
	    NAME         => 'ObjStore::Lib::PDL',
	    VERSION_FROM => './lib/ObjStore/Lib/PDL.pm',
	    OBJECT       => join(' ', 'PDL.o', "Lib-PDL-$v.o"),
	    INC		 => join(' ', &PDL_INCLUDE(), '-Ilib/ObjStore/Lib/PDL'),
	    OPTIMIZE => '-g',
);

WriteMakefile(add_os_args(%args));

sub MY::postamble { os_schema_rule("Lib-PDL-$v.sch") }

package MY;
sub constants {
    my $str = shift->SUPER::constants;
    $str =~ s/^(BASEEXT) =.*$/
	"$1 = libPDL" /me;
    $str;
}
