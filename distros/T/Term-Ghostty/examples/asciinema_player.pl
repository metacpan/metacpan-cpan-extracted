#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use JSON::PP qw(decode_json);
use Time::HiRes qw(sleep);
use Getopt::Long qw(GetOptions);
use Term::Ghostty;

my $speed      = 0;
my $format     = 'plain';
my $standalone = 0;
my $frame_at;

GetOptions(
    'speed=f'    => \$speed,
    'format=s'   => \$format,
    'standalone' => \$standalone,
    'frame-at=f' => \$frame_at,
    'help'       => sub { usage(0) },
) or usage(1);
usage(1) unless $format =~ /\A(?:plain|vt|html)\z/;

sub usage {
    my ($exit_code) = @_;
    print { $exit_code ? *STDERR : *STDOUT } <<"USAGE";
Usage: $0 [options] [recording.cast]

Play an asciinema v2 (.cast) recording through Term::Ghostty, or print the
screen it ends on (or the screen at --frame-at) as text, VT or HTML.

Options:
  --speed <float>     Play back in this terminal at this speed instead of
                      printing a snapshot (1 = real time)
  --format <type>     Snapshot format: plain, vt, html (default: plain)
  --standalone        Emit a complete HTML5 document (with --format html)
  --frame-at <secs>   Stop at this timestamp
  --help              Show this help

Examples:
  $0 demo.cast
  $0 --format html --standalone demo.cast > recording.html
  $0 --frame-at 5.5 demo.cast
  $0 --speed 2 demo.cast
USAGE
    exit $exit_code;
}

my $fh = \*STDIN;
if (@ARGV && $ARGV[0] ne '-') {
    open $fh, '<', $ARGV[0] or die "Cannot open '$ARGV[0]': $!\n";
}
binmode $fh;
binmode STDOUT, ':encoding(UTF-8)';

my $header = eval { decode_json(scalar <$fh>) };
die "Not an asciicast v2 recording\n"
    unless ref $header eq 'HASH' && ($header->{version} // 0) == 2;

sub size { my $n = int(shift // 0); $n < 1 ? 1 : $n > 1000 ? 1000 : $n }

my $term = Term::Ghostty->new(cols => size($header->{width} // 80), rows => size($header->{height} // 24));

sub draw { print "\e[H\e[2J", $term->get_vt(cursor => 1) }

my $last = 0;
while (my $line = <$fh>) {
    next unless $line =~ /\S/;
    my $event = eval { decode_json($line) };
    die "Line $.: not an asciicast event\n" unless ref $event eq 'ARRAY';
    my ($t, $type, $data) = @$event;
    last if defined $frame_at && $t > $frame_at;

    if ($speed > 0 && $t > $last) {
        draw();
        sleep(($t - $last) / $speed);
    }
    $last = $t;

    if ($type eq 'o') {
        $term->feed($data);
    } elsif ($type eq 'r' && $data =~ /\A(\d+)x(\d+)\z/) {
        $term->resize(size($1), size($2));
    }
}

if ($speed > 0) {
    draw();
    print "\r\n";
    exit;
}

my $out = $term->format(format => $format);

unless ($format eq 'html' && $standalone) {
    print $out, "\n";
    exit;
}

(my $title = $header->{title} // 'asciicast') =~ s/([&<>"])/'&#' . ord($1) . ';'/ge;

print <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>$title</title>
<style>
body { background: #111; padding: 20px; }
.screen { background: #1d1f21; color: #c5c8c6; border-radius: 6px; padding: 16px; display: inline-block; }
</style>
</head>
<body>
<div class="screen">$out</div>
</body>
</html>
HTML
