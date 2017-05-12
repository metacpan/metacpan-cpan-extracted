use strict;
use lib "t";
use SVNDiffTests;

plan tests => 8*blocks;

use Parse::SVNDiff;

use YAML;
while (my $block = next_block) {
    my $diff = Parse::SVNDiff->new;
    isa_ok($diff, 'Parse::SVNDiff');

    my ($rawdiff, $desc, $input, $output)
	= map { @$_} @{$block}{qw(diff description input output)};

    parse_ok($diff, $rawdiff, $desc);
    dump_is($diff, $rawdiff, $desc);
    apply_is($diff, $input, $output, $desc);

    $diff = Parse::SVNDiff->new( lazy => 1,
				 lazy_windows => 1,
			       );

    $desc .= " [lazy]";
    parse_ok($diff, $rawdiff, $desc);
    ok(!eof($diff->fh), "not at end of file after 1 window");
    cmp_ok($diff->windows_size, '<=', 1, "Parsed windows");
    apply_is($diff, $input, $output, $desc);
}


1;

__END__

=== Test one
--- input
aaaabbbbcccc
--- output
aaaaccccdddddddd
--- diff from_binary

01010011 01010110 01001110 00000000	Header ("SVN\0")

00000000				Source view offset 0
00001100				Source view length 12
00010000				Target view length 16
00000111				Instruction length 7
00000001				New data length 1

00000100 00000000			Source, len 4, offset 0
00000100 00001000			Source, len 4, offset 8
10000001				New, len 1
01000111 00001000			Target, len 7, offset 8

01100100				The new data: 'd'

=== Three windows
--- input
Today, young men on acid realised that we are all just one conciousness appearing to itself subjectively, there's no such thing as death, life is only a dream, and we're the imagination of ourselves.
--- output
Today, young men on acid realised that we are all just one conciousness appearing to itself subjectively, there's no such thing as bad taste, life is only a dream, and we're the imagination of ourselves.
--- diff from_binary

01010011 01010110 01001110 00000000	Header ("SVN\0")

00000000				Source view offset 0
10000001 00000011			Source view length 131
10000001 00000011			Target view length 131
00000100				Instruction length 4
00000001				New data length 1

00000000 10000001 00000011 00000000	Source, len 131, offset 0

00000000

00000000 				Source view offset 0
00000101				Source view length 5
00001001				Target view length 9
00000001				Instruction length 1
00001001				New data length 9

10001001				New, len 9

011000100110000101100100001000000111010001100001011100110111010001100101  New data

10000001 00001000 			Source view offset 136
01000000				Source view length 64
01000000				Target view length 64
00000011				Instruction length 1
00000001				New data length 1

00000000 01000000 00000000		Source, len 64, offset 0

00000000

