use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;
use Perlmazing;

my $r = testing();
is $r, 1, 'scalar';
my @r = testing();
is @r, 1, 'list';
is $r[0], 1, 'list';
is do {
	eval {
		testing();
	};
	$@ =~ s/(in void context at).*?\n$/$1/ if $@;
	$@;
}, 'Useless call to '.__PACKAGE__.'::testing in void context at', 'void';

sub testing {
	no_void;
	return 1;
}