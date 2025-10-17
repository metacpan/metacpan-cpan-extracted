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
  $package = 'SVG::Barcode::UPCA';
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
  lineheight => 50,
  linewidth  => 1,
  textsize   => 10,
);

for (sort keys %defaults) {
  can_ok $object, $_;
  is $object->$_, $defaults{$_}, "$_ is $defaults{$_}";
}

ok $package->new(%defaults), 'Create again using defaults';

my %non_defaults = (
  lineheight => 22,
  textsize   => 0,
);
ok $object = $package->new(%non_defaults), 'Create object with non-default parameters';
for (sort keys %non_defaults) {
  is $object->$_, $non_defaults{$_}, "$_ is $non_defaults{$_}";
}
for (sort keys %defaults) {
  next if defined $non_defaults{$_};
  is $object->$_, $defaults{$_}, "$_ is $defaults{$_}";
}

is $object->linewidth(3)->linewidth, 3, 'Set linewidth to 3';
is $object->linewidth('')->linewidth, $defaults{linewidth}, 'Set linewidth back to default';

note 'Plot';
ok $object = $package->new, 'Create object';
my $text = '012345678905';
ok my $svg = $object->plot($text), 'Plot barcode';
is $svg, slurp("$FindBin::Bin/resources/012345678905_black_text.svg"), 'Content is correct';

is $object->foreground('red')->textsize(0)->lineheight(20), $object,
  'Change color and height, hide text';
ok $svg = $object->plot($text), 'Plot barcode';
is $svg, slurp("$FindBin::Bin/resources/012345678905_red_notext.svg"), 'Content is correct';

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
