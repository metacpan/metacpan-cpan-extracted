#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Term::Ghostty;

my $cols = 40;
my $rows = 20;
my ($cmd1, $cmd2);

GetOptions(
    'cols=i' => \$cols,
    'rows=i' => \$rows,
    'cmd1=s' => \$cmd1,
    'cmd2=s' => \$cmd2,
    'help'   => sub { usage(0) },
) or usage(1);

sub usage {
    my ($exit_code) = @_;
    print { $exit_code ? *STDERR : *STDOUT } <<"USAGE";
Usage: $0 [options] fileA fileB
   or: $0 --cmd1 'command 1' --cmd2 'command 2'

Render two outputs in headless terminals and show the resulting screens side
by side, marking rows whose text differs with '!'. Exits 1 if the screens
(text or cursor position) differ.

Options:
  --cols <N>     Width of each terminal (default: 40)
  --rows <N>     Height of each terminal (default: 20)
  --cmd1 <cmd>   Run this command for the left side instead of reading fileA
  --cmd2 <cmd>   Run this command for the right side instead of reading fileB
  --help         Show this help
USAGE
    exit $exit_code;
}

my @src = ([$cmd1 // shift @ARGV, defined $cmd1], [$cmd2 // shift @ARGV, defined $cmd2]);
usage(1) if @ARGV || grep { !defined $_->[0] } @src;

sub render {
    my ($src, $is_cmd) = @_;
    my $term = Term::Ghostty->new(cols => $cols, rows => $rows);
    open my $fh, $is_cmd ? '-|' : '<', $src or die "Cannot open '$src': $!\n";
    binmode $fh;
    local $/ = \65536;
    while (my $chunk = <$fh>) {
        $chunk =~ s/\n/\r\n/g;
        $term->feed($chunk);
    }
    return $term;
}

sub cells {
    my ($s) = @_;
    return length($s) + (() = $s =~ /[\p{EA=W}\p{EA=F}]/g) - (() = $s =~ /[\p{Mn}\p{Me}\p{Cf}]/g);
}

sub pad { my $n = $cols - cells($_[0]); $_[0] . ($n > 0 ? ' ' x $n : '') }

my @terms = map { render(@$_) } @src;
my @screens = map { [split /\n/, $_->get_text] } @terms;
my @cursors = map { [$_->cursor_pos] } @terms;
my @labels = map { my $l = $_->[0]; utf8::decode($l); substr($l, 0, $cols - 4) } @src;

binmode STDOUT, ':encoding(UTF-8)';

my $rule = '-' x $cols . '-+-' . '-' x $cols . "\n";
print pad("[A] $labels[0]"), ' | ', "[B] $labels[1]\n", $rule;

my $diffs = 0;
for my $r (0 .. $rows - 1) {
    my ($l, $rt) = map { $_->[$r] // '' } @screens;
    my $differs = $l ne $rt;
    $diffs++ if $differs;
    print pad($l), $differs ? ' ! ' : ' | ', "$rt\n";
}

my $cursor_differs = "@{ $cursors[0] }" ne "@{ $cursors[1] }";
print $rule;
print pad(sprintf 'cursor (%d, %d)', @{ $cursors[0] }), $cursor_differs ? ' ! ' : ' | ',
    sprintf("cursor (%d, %d)\n", @{ $cursors[1] });
print $diffs || $cursor_differs
    ? "$diffs row(s) differ" . ($cursor_differs ? ', cursor differs' : '') . "\n"
    : "Screens are identical\n";
exit($diffs || $cursor_differs ? 1 : 0);
