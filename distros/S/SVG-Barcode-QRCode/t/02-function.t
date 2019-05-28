use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use Test::More;

my $package;

BEGIN {
  $package = 'SVG::Barcode::QRCode';
  use_ok $package or exit;
}

note 'Functions';
my @functions = qw|plot_qrcode|;
can_ok $package, $_ for @functions;

is_deeply \@SVG::Barcode::QRCode::EXPORT_OK, \@functions,
  'All functions exported';

note 'Plot';
my $plot   = $package->can('plot_qrcode');
my $text   = 'Tekki';
my %params = (width => 200, height => 200);
ok my $svg = $plot->($text, %params), 'Plot QR Code';
is $svg, slurp("$FindBin::Bin/resources/Tekki_200x200_black.svg"),
  'Content is correct';

$text               = 'Szőlőlé';
$params{level}      = 'H';
$params{foreground} = 'red';
ok $svg = $plot->($text, %params), 'Plot with red unicode text';
is $svg, slurp("$FindBin::Bin/resources/Grapejuice_200x200_H_red.svg"),
  'Content is correct';

eval { $plot->() };
like $@, qr/Too few arguments for subroutine/, 'Correct error for missing text';

done_testing();

# utils

sub slurp ($path) {
  CORE::open my $file, '<', $path or die qq{Can't open file "$path": $!};
  my $ret = my $content = '';
  while ($ret = $file->sysread(my $buffer, 131072, 0)) { $content .= $buffer }
  die qq{Can't read from file "$path": $!} unless defined $ret;

  return $content;
}

sub spurt ($path, $content) {
  CORE::open my $file, '>', $path or die qq{Can't open file "$path": $!};
  ($file->syswrite($content) // -1) == length $content
    or die qq{Can't write to file "$path": $!};

  return $path;
}
