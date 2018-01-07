#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 25;
BEGIN { use_ok('Slob') };

for my $path (<t/freedict-*.slob>) {
	note "Now using $path";
	my $slob = Slob->new($path);

	my $nr_of_entries = $slob->ref_count;

	my $second_ref = $slob->seek_and_read_ref(4);
	my $bin = $slob->seek_and_read_storage_bin($second_ref->{bin_index});

	is $second_ref->{key}, 'abacus';
	is $second_ref->{bin_index}, 0;
	is $second_ref->{item_index}, 161;
	my $count = scalar @{$bin->{positions}};
	is $count, 637;

	my $expected = <<'EOF';
<html><head><link href="~/css/default.css" rel="stylesheet" type="text/css"><link href="~/css/night.css" rel="alternate stylesheet" title="Night" type="text/css"></head><script src="~/js/styleswitcher.js"></script><body><div class="form">
          <div class="orth">abacus</div><div class="pron">æbəkəs</div></div><ol class="sense single"><li class="sense">
          <ol class="cit single"><li class="cit trans">
            <ol class="quote single"><li class="quote">Rechenbrett</li></ol><div class="gramGrp">
              <div class="gen">m</div></div></li></ol></li></ol></body></html>
EOF
	chomp $expected;
	is $slob->get_entry_of_storage_bin($bin, $second_ref->{item_index}), $expected;

	is $slob->seek_and_read_ref_and_data(4)->{data}, $expected;
}
