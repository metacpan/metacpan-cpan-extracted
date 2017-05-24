use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = Ryu::Source->new;
my @actual;
$src->switch_str(
    sub { $_ },
    first => sub { 'one' },
    second => sub { 'two' },
    sub { 'many' }
)->each(sub {
	push @actual, $_;
});
$src->emit($_) for qw(first second third);
cmp_deeply(\@actual, [ qw(one two many) ], 'switch_str operation was performed');
done_testing;

