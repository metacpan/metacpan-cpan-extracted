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

note 'Constructor';
can_ok $package, 'new';

note 'Object';
ok my $object = $package->new, 'Create object';
my @methods = qw|plot|;
can_ok $object, $_ for @methods;

note 'Parameters';
my %defaults = (
  SVG::Barcode::DEFAULTS->%*,
  level   => 'M',
  dotsize => 1,
  version => 0,
);

for (sort keys %defaults) {
  can_ok $object, $_;
  is $object->$_, $defaults{$_}, "$_ is $defaults{$_}";
}

ok $package->new(%defaults), 'Create again using defaults';

my %non_defaults = (
  level   => 'Q',
  dotsize => 2,
);
ok $object = $package->new(%non_defaults), 'Create object with non-default parameters';
for (sort keys %non_defaults) {
  is $object->$_, $non_defaults{$_}, "$_ is $non_defaults{$_}";
}
for (sort keys %defaults) {
  next if $non_defaults{$_};
  is $object->$_, $defaults{$_}, "$_ is $defaults{$_}";
}

is $object->level('Q')->level, 'Q', 'Set level to Q';
is $object->level('')->level, $defaults{level}, 'Set level back to default';

note 'Plot';
ok $object = $package->new, 'Create object';
my $text = 'Tekki';
ok my $svg = $object->width(200)->height(200)->plot($text), 'Plot QR Code';
is $svg, slurp("$FindBin::Bin/resources/Tekki_200x200_black.svg"), 'Content is correct';

is $object->foreground('red')->level('H'), $object, 'Change color and level';
$text = 'Szőlőlé';
ok $svg = $object->plot($text), 'Plot unicode text';
is $svg, slurp("$FindBin::Bin/resources/Grapejuice_200x200_H_red.svg"), 'Content is correct';

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
