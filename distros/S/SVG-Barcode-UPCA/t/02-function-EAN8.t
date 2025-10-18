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
  $package = 'SVG::Barcode::EAN8';
  use_ok $package or exit;
}

note 'Functions';
my @functions = qw|plot_ean8|;
can_ok $package, $_ for @functions;

is_deeply \@SVG::Barcode::EAN8::EXPORT_OK, \@functions, 'All functions exported';

note 'Plot';
my $plot = $package->can('plot_ean8');
my $text = '12345670';
ok my $svg = $plot->($text), 'Plot code';
is $svg, slurp("$FindBin::Bin/resources/12345670_black_text.svg"), 'Content is correct';

ok $svg = $plot->($text, foreground => 'red', lineheight => 20, textsize => 0),
  'Plot in red without text';
is $svg, slurp("$FindBin::Bin/resources/12345670_red_notext.svg"), 'Content is correct';

note 'Plot with uncalculated check digit';
my $text_no_check_digit = '1234567';
ok $svg = $plot->($text_no_check_digit), 'Plot code, letting library calculate check digit';
is $svg, slurp("$FindBin::Bin/resources/12345670_black_text.svg"), 'Content is correct';

done_testing();

# utils
sub slurp ($path) {
  CORE::open my $file, '<', $path or die qq{Can't open file "$path": $!};
  local $/;
  return <$file>;
}