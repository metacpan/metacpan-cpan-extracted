use Test::More tests => 2;

use strict;
use warnings;

my @hasnt = ();
my @test = (['Filter::Util::Call','Filter'],
	    ['Text::Balanced','Text::Balanced'],
	   );	
for my $mod (@test) {
  eval "use $mod->[0]";
  ok !$@;
  push @hasnt, $mod->[1] if $@;
}

if (@hasnt) {
        diag <<'EOP';

********************************************************
* IMPORTANT: Your installation will not work since it  *
* lacks critical modules.                              *
* ALL TESTS WILL FAIL UNLESS YOU IMMEDIATELY           *
* INSTALL THE FOLLOWING MODULES [available from CPAN]: *
*
EOP

    for (@hasnt) { diag "*\t$_\n" }


    diag <<'EOP';
*                                                      *
* Please install the missing module(s) and start the   *
* PDLA build process again (perl Makefile.PL; ....)     *
*                                                      *
********************************************************

EOP

}
