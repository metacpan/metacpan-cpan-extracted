#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use List::Util qw(max min);
use Term::Ghostty;

my $cols       = 100;
my $rows       = 40;
my $standalone = 0;
my $title      = 'Terminal Output';
my $cmd;
my $trim       = 1;
my $unwrap     = 0;

GetOptions(
    'cols=i'     => \$cols,
    'rows=i'     => \$rows,
    'standalone' => \$standalone,
    'title=s'    => \$title,
    'cmd=s'      => \$cmd,
    'trim!'      => \$trim,
    'unwrap!'    => \$unwrap,
    'help'       => sub { usage(0) },
) or usage(1);

sub usage {
    my ($exit_code) = @_;
    print { $exit_code ? *STDERR : *STDOUT } <<"USAGE";
Usage: $0 [options] [file ...]

Render ANSI/VT output (files, stdin or a command) as HTML using Ghostty VT.

Options:
  --cols <N>          Terminal width in cells (default: 100)
  --rows <N>          Minimum terminal height; it grows to the number of
                      input lines, up to 65535 (default: 40)
  --standalone        Emit a complete HTML5 document
  --title <text>      Document title for --standalone (default: "Terminal Output")
  --cmd <command>     Run a shell command and render its output
  --no-trim           Keep trailing whitespace on lines
  --unwrap            Join soft-wrapped lines
  --help              Show this help message

Examples:
  git log -p --color=always | $0 --standalone > git_log.html
  $0 --cmd 'ls -la --color=always' --standalone > dir.html
  $0 log.txt > snippet.html
USAGE
    exit $exit_code;
}

utf8::decode($title);

sub slurp {
    my ($fh) = @_;
    binmode $fh;
    local $/;
    return scalar(<$fh>) // '';
}

my $input = '';
if (defined $cmd) {
    open my $fh, '-|', $cmd or die "Cannot run '$cmd': $!\n";
    $input = slurp($fh);
    close $fh;
} elsif (@ARGV) {
    for my $file (@ARGV) {
        open my $fh, '<', $file or die "Cannot open '$file': $!\n";
        $input .= slurp($fh);
    }
} else {
    $input = slurp(\*STDIN);
}
$input =~ s/\n/\r\n/g;

my $lines = ($input =~ tr/\n//) + 1;
my $term  = Term::Ghostty->new(cols => $cols, rows => min(65535, max($rows, $lines)),
                               max_scrollback => $lines);
$term->feed($input);

my $html = $term->get_html(scrollback => 1, trim => $trim, unwrap => $unwrap);

binmode STDOUT, ':encoding(UTF-8)';

unless ($standalone) {
    print $html, "\n";
    exit;
}

(my $esc_title = $title) =~ s/([&<>"])/'&#' . ord($1) . ';'/ge;

print <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$esc_title</title>
<style>
body { margin: 0; padding: 24px; background: #111; font-family: sans-serif; }
.window { background: #1d1f21; color: #c5c8c6; border-radius: 8px; overflow: hidden; }
.bar { background: #282a2e; color: #969896; padding: 8px 16px; font-size: 12px; }
.screen { padding: 16px; overflow-x: auto; font-size: 13px; line-height: 1.4; }
</style>
</head>
<body>
<div class="window">
<div class="bar">$esc_title</div>
<div class="screen">$html</div>
</div>
</body>
</html>
HTML
