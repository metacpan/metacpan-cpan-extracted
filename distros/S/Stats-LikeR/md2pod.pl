#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Markdown::To::POD 'markdown_to_pod';
use List::MoreUtils 'first_index';

sub file2string ($file) {
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}

my $md = file2string('README.md');
my @md = split /\n/, $md;

my $pod = markdown_to_pod($md);
say 'Writing README.pod from README.md, which must be copied into lib/Stats/LikeR.pm';
open my $tmp, '>', 'README.pod';
say $tmp $pod;
close $tmp;
$pod = file2string('README.pod');
my @pod = split /\n/, $pod;
# get table start and end indices
foreach my $i ( grep {$pod[$_] =~ /^<img\h/} reverse 0..$#pod) {
	next if $pod[$i-1] eq '<p>' eq $pod[$i+1]; # html paragraph
#	my @p = @pod[$i-3..$i+3];
#	p @p;
	splice @pod, $i+1, 0, '<p>', ''; # end
	splice @pod, $i, 0, '', '=for html', '<p>',; # start
#	@p = @pod[$i-3..$i+3];
#	p @p;
}
foreach my $i (grep {$pod[$_] eq '<table>'} reverse 0..$#pod) {
	splice @pod, $i, 0, '=for html';
}
unshift @pod, "=encoding utf8\n";
#p @pod;
open my $fh, '>', 'README.pod';
say $fh join ("\n", @pod);
close $fh;
my $lib = file2string('lib/Stats/LikeR.pm');
my @lib = split /\n/, $lib;
my $line = first_index {$_ eq '1;'} @lib;
if ($line == -1) {
	die 'Could not find correct line index';
}
splice @lib, 1-(scalar @lib - $line);
push @lib, @pod; # add properly formatted POD text
open $fh, '>', 'lib/Stats/LikeR.pm';
say $fh join ("\n", @lib);
close $fh;

