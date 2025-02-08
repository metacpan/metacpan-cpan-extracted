#!/usr/bin/env perl
use 5.014;
use warnings;

my ($min_seq, $max_seq, $min_len, $max_len) = @ARGV;
die "Parameters: min_seqs max_seqs min_len max_len" unless ($max_len);

my $total_seqs = $min_seq + int(rand($max_seq - $min_seq));

say STDERR "# Seqs: $total_seqs";

for (my $seq_id = 1; $seq_id <= $total_seqs; $seq_id++) {
	my $len = $min_len + int(rand($max_len - $min_len));
	say ">Seq_${seq_id} len=${len}\n", 'N' x $len;
}
