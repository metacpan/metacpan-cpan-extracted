package My::Package;
use strict;
use base qw(Package::Base);

sub method {
  my $self = shift;
  warn "warning 1";
  $self->log->warn("warning 2");
  return 123;
}

sub slot1 {
  my($self,$val) = @_;
  $self->{slot1} = $val if defined($val);
  return $self->{slot1};
}

package main;

use strict;
use Test::More;

BEGIN {
  plan tests => 19;
  use_ok('Package::Base');

  print STDERR "\nWARNINGS ARE NORMAL HERE\n";
}

my $root = Package::Base->new();
ok(!$root);

my $package = My::Package->new();
ok($package);
ok($package->method == 123);

ok $package = My::Package->new(slot0 => 1);
ok $package = My::Package->new(slot1 => 1);
ok($package->slot1 == 1);
ok($package->slot1(2) == 2);
ok($package->slot1 == 2);

ok $package = My::Package->new(slot2 => [1,2,3]);

ok($package->loglevel('OFF'));
ok($package->loglevel('FATAL'));
ok($package->loglevel('ERROR'));
ok($package->loglevel('WARN'));
ok($package->loglevel('INFO'));
ok($package->loglevel('DEBUG'));
ok($package->loglevel('ALL'));

ok($Package::Base::Devel::log4perl_template =  "wibble %s %s");
ok($Package::Base::Devel::log4perl_template eq 'wibble %s %s');
