use strict;
use warnings;

use Test::More;

use_ok('Radamsa', qw(mutate));

my $seed = 12345;
my $input = "hello world\n";

my $out1 = mutate($input, seed => $seed, max_len => 2048);

ok(defined $out1 && length($out1) >= 0, 'mutate returns a string');
ok(length($out1) <= 2048, 'output respects max_len');

my $rad = Radamsa->new(seed => 7, max_len => 2048);
my $seq1 = $rad->mutate($input);
my $seq2 = $rad->mutate($input);

ok(defined $seq1 && defined $seq2, 'object form returns mutated payloads');
ok(length($seq1) <= 2048 && length($seq2) <= 2048, 'object form respects max_len');

done_testing;
