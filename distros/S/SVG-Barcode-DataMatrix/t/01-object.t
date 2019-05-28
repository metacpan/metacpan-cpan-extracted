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
  $package = 'SVG::Barcode::DataMatrix';
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
  dotsize       => 1,
  encoding_mode => 'AUTO',
  process_tilde => 0,
  size          => 'AUTO',
);

for (sort keys %defaults) {
  can_ok $object, $_;
  is $object->$_, $defaults{$_}, "$_ is $defaults{$_}";
}

ok $package->new(%defaults), 'Create again using defaults';

my %non_defaults = (
  encoding_mode => 'ASCII',
  size          => '16x48',
);
ok $object = $package->new(%non_defaults),
  'Create object with non-default parameters';
for (sort keys %non_defaults) {
  is $object->$_, $non_defaults{$_}, "$_ is $non_defaults{$_}";
}
for (sort keys %defaults) {
  next if $non_defaults{$_};
  is $object->$_, $defaults{$_}, "$_ is $defaults{$_}";
}

is $object->encoding_mode('BASE256')->encoding_mode, 'BASE256',
  'Set encoding_mode to BASE256';
is $object->encoding_mode('')->encoding_mode, $defaults{encoding_mode},
  'Set encoding_mode back to default';

note 'Plot';
ok $object = $package->new, 'Create object';
my $text = 'Tekki';
ok my $svg = $object->width(200)->height(200)->plot($text), 'Plot Data Matrix';
is $svg, slurp("$FindBin::Bin/resources/Tekki_200x200_black.svg"),
  'Content is correct';

is $object->foreground('red')->size('16x48')->width(300)->height(100), $object,
  'Change color and level';
ok $svg = $object->plot($text), 'Plot unicode text';
is $svg, slurp("$FindBin::Bin/resources/Tekki_300x100_red.svg"),
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
