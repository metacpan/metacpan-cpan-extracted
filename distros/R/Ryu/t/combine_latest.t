use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $first = Ryu::Source->new;
my $second = Ryu::Source->new;
my @actual;
$first->combine_latest(
	$second,
	sub { join ':', @_ }
)->each(sub {
	push @actual, @$_;
});
$first->emit(1);
$second->emit('x');
$first->emit(2);
$first->emit(3);
$second->emit('y');
cmp_deeply(\@actual, [
	'1:x',
	'2:x',
	'3:x',
	'3:y'
], 'combine_latest operation was performed');
done_testing;

