#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Digest::SHA 'sha512_base64';

sub file2string {
	my $file = shift;
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}
my $f = '/tmp/undef.val.tsv';
my $str = file2string($f);
say sha512_base64($str);
