use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing;

my @arr = do_test('list', 0);
my $str = do_test('scalar', 0);
do_test('void', 1);

sub do_test {
	my $type = shift;
	my $expected = shift;
	my $r = void_context ? 1 : 0;
	is $r, $expected, $type;
}