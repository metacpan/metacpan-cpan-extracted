use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = Ryu::Source->new;
my @actual;
$src->extract_all(qr{(?<word>\w+)})->each(sub {
    push @actual, $_;
});
$src->emit($_) for 'this is a list of words', 'in several', 'parts';
cmp_deeply(\@actual, [
    map +{ word => $_ }, qw(this is a list of words in several parts)
], 'extract_all operation was performed');
done_testing;

