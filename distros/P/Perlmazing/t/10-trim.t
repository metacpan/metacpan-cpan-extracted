use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;
use Perlmazing;

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