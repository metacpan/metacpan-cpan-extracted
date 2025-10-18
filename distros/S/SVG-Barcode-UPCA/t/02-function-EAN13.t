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
  $package = 'SVG::Barcode::EAN13';
  use_ok $package or exit;
}

note 'Functions';
my @functions = qw|plot_ean13|;
can_ok $package, $_ for @functions;

is_deeply \@SVG::Barcode::EAN13::EXPORT_OK, \@functions, 'All functions exported';

note 'Plot';
my $plot = $package->can('plot_ean13');
my $text = '1234567890128';
ok my $svg = $plot->($text), 'Plot code';
is $svg, slurp("$FindBin::Bin/resources/1234567890128_black_text.svg"), 'Content is correct';

ok $svg = $plot->($text, foreground => 'red', lineheight => 20, textsize => 0),
  'Plot in red without text';
is $svg, slurp("$FindBin::Bin/resources/1234567890128_red_notext.svg"), 'Content is correct';

eval { $plot->() };
like $@, qr/Too few arguments for subroutine/, 'Correct error for missing text';

note 'Plot with uncalculated check digit';
my $text_no_check_digit = '123456789012';
ok $svg = $plot->($text_no_check_digit), 'Plot code, letting library calculate check digit';
is $svg, slurp("$FindBin::Bin/resources/1234567890128_black_text.svg"), 'Content is correct';

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
