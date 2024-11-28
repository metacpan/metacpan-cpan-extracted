use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 7;
use Perlmazing qw(trim);

my $string = '

	This is  an awesome string for 
	testing.
	
';
my $shouldbe = 'This is  an awesome string for 
	testing.';

my $r = trim $string;
isnt $r, $string, 'original untouched';
is $r, $shouldbe, 'right result';
my $backup = $string;
trim $string;
isnt $string, $backup, 'original changed';
is $string, $shouldbe, 'right change';

my $undefined;
my $trimmed = trim $undefined;
my @trimmed = trim $undefined;

is $trimmed, '', 'trim on undef becomes empty string';
is scalar(@trimmed), 1, 'trim on undef to array returns one element';
is $trimmed[0], '', 'trim on undef to array returns an empty string';