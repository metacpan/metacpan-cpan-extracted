use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use Test::More;
use Mock::MonkeyPatch;

my $package;

BEGIN {
  $package = 'SVG::Barcode';
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
  margin     => 10,
);

for (sort keys %defaults) {
  is $object->param($_), $defaults{$_}, "$_ is $defaults{$_}";
}

my %non_defaults = (
  background => 'cyan',
  margin     => 2,
);
ok $object = $package->new(\%non_defaults), 'Create object with parameters';
for (sort keys %non_defaults) {
  is $object->param($_), $non_defaults{$_}, "$_ is $non_defaults{$_}";
}
for (sort keys %defaults) {
  next if $non_defaults{$_};
  is $object->param($_), $defaults{$_}, "$_ is $defaults{$_}";
}

is $object->param(foreground => 'red')->param('foreground'), 'red',
  'Set color to red';
is $object->param(foreground => '')->param('foreground'), $defaults{foreground},
  'Set color to default';

eval { $object->param(inexistant => 'illegal') };
like $@, qr/Unknown parameter inexistant!/,
  'Correct error for inexistant parameter';

note 'Plot';
ok $object = $package->new, 'Create object';
my $text = 'Tekki';

eval { $object->plot };
like $@, qr/Too few arguments for subroutine/, 'Correct error for missing text';

eval { $object->plot($text) };
like $@, qr/Method _plot not implemented by subclass!/,
  'Correct error for unimplemented method';

ok my $mock = Mock::MonkeyPatch->patch(
  'SVG::Barcode::_plot' => sub ($self, $text) {
    $self->_rect(0,  0,  50, 50);
    $self->_rect(50, 0,  50, 50, 'cyan');
    $self->_rect(0,  50, 50, 50, 'magenta');
    $self->_rect(50, 50, 50, 50, 'yellow');
  }
  ),
  'Mock _plot method';
ok my $svg = $object->param(margin => 25)->plot($text), 'Generate svg';

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
