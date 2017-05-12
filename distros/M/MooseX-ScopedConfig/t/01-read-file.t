#!perl -T

package MooseX::ScopedConfig::ConfigTest;
use Moose;
with 'MooseX::ScopedConfig';
has 'module' => (
  is => 'ro',
  isa => 'HashRef',
);

package main;
use Test::More tests => 1;
use File::Temp qw/tempfile/;
my $test = {
  module => {
    foo => {
      global => 'variable',
      another => 'global',
      myfoo => 'set',
    },
    bar => {
      global => 'variable',
      another => 'global',
      mybar => 'settoo',
    },
  },
};
my ($fh, $filename) = tempfile();
print $fh <<ENDOFCONFIG;
global = variable
another = global
module foo {
  myfoo => set
}
module bar {
  mybar = settoo
}
ENDOFCONFIG
close($fh);
my $testobj = MooseX::ScopedConfig::ConfigTest->new_with_config(configfile => $filename);
unlink($filename);
is_deeply($test->{module}, $testobj->{module});
