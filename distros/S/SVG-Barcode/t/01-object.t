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
  $package = 'SVG::Barcode';
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
  background => 'white',
  class      => '',
  foreground => 'black',
  height     => '',
  id         => '',
  margin     => 2,
  scale      => '',
  width      => '',
);

for (sort keys %defaults) {
  can_ok $object, $_;
  is $object->$_, $defaults{$_}, "$_ is $defaults{$_}";
}

my %non_defaults = (
  background => 'cyan',
  margin     => 2,
);
ok $object = $package->new(%non_defaults), 'Create object with parameters';
for (sort keys %non_defaults) {
  is $object->$_, $non_defaults{$_}, "$_ is $non_defaults{$_}";
}
for (sort keys %defaults) {
  next if $non_defaults{$_};
  is $object->$_, $defaults{$_}, "$_ is $defaults{$_}";
}

is $object->foreground('red')->foreground, 'red', 'Set foreground to red';
is $object->foreground('')->foreground, $defaults{foreground}, 'Set foreground back to default';

eval { $package->new(inexistant => 'illegal') };
like $@, qr/Can't locate object method "inexistant"/, 'Correct error for inexistant parameter';

note 'Plot';
ok $object = $package->new, 'Create object';
my $text = '<black>';

eval { $object->plot };
like $@, qr/Too few arguments for subroutine/, 'Correct error for missing text';

eval { $object->plot($text) };
like $@, qr/Method _plot not implemented by subclass!/, 'Correct error for unimplemented method';

{
  no strict 'refs';    ## no critic 'ProhibitNoStrict'
  no warnings 'redefine';
  *SVG::Barcode::_plot = sub ($self, $text) {
    $self->_rect(0, 0, 5, 5);
    $self->_rect(5, 0, 5, 5, 'cyan');
    $self->_rect(0, 5, 5, 5, 'magenta');
    $self->_rect(5, 5, 5, 5, 'yellow');
    $self->_text($text, .3, 4.7, 1, 'white');
  };
}

ok my $svg = $object->margin(2)->scale(10)->plot($text), 'Generate svg';
is $svg, slurp("$FindBin::Bin/resources/cmyk.svg"), 'Content is correct';

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
