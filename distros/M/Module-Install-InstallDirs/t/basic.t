
use Test::More tests => 2;

my $got;

$got = 'default';
Foo->installdirs(qw(Foo:Bar));
is($got,'default');

$got = 'default';
Foo->installdirs(qw(Carp));
is($got,'perl');



package Foo;

use Module::Install::InstallDirs;
BEGIN {
  @Foo::ISA = qw(Module::Install::InstallDirs);
}

sub makemaker_args {
  $got = $_[2];
}

