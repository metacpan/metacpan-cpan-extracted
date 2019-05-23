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
  $package = 'SVG::Barcode::Code128';
  use_ok $package or exit;
}

note 'Constructor';
can_ok $package, 'new';

note 'Object';
ok my $object = $package->new, 'Create object';
my @methods = qw|param plot|;
can_ok $object, $_ for @methods;

note 'Parameters';
my %defaults = (
  background => 'white',
  foreground => 'black',
  lineheight => 30,
  linewidth  => 1,
  margin     => 10,
  textsize   => 10,
);

for (sort keys %defaults) {
  is $object->param($_), $defaults{$_}, "$_ is $defaults{$_}";
}

my %non_defaults = (
  lineheight => 22,
  textsize   => 0,
);
ok $object = $package->new(\%non_defaults),
  'Create object with non-default parameters';
for (sort keys %non_defaults) {
  is $object->param($_), $non_defaults{$_}, "$_ is $non_defaults{$_}";
}
for (sort keys %defaults) {
  next if defined $non_defaults{$_};
  is $object->param($_), $defaults{$_}, "$_ is $defaults{$_}";
}

is $object->param(foreground => 'red')->param('foreground'), 'red',
  'Set color to red';
is $object->param(foreground => '')->param('foreground'), $defaults{foreground},
  'Set color to default';

note 'Plot';
ok $object = $package->new, 'Create object';
my $text = 'Tekki';
ok my $svg = $object->plot($text), 'Plot barcode';
spurt("$FindBin::Bin/resources/Tekki_black_text.svg",$svg);
is $svg, slurp("$FindBin::Bin/resources/Tekki_black_text.svg"),
  'Content is correct';

is $object->param(foreground => 'red')->param(textsize => 0)
  ->param(lineheight => 20), $object,
  'Change color and height, hide text';
ok $svg = $object->plot($text), 'Plot barcode';
spurt("$FindBin::Bin/resources/Tekki_red_notext.svg",$svg);
is $svg, slurp("$FindBin::Bin/resources/Tekki_red_notext.svg"),
  'Content is correct';

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
