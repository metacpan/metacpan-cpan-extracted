#! -- perl --
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 2 + 6;
BEGIN { use_ok('RPM::Query') };

my $rpm  = RPM::Query->new;
isa_ok($rpm, 'RPM::Query');

my $skip = 1;
foreach (1) {
  last unless $^O eq 'linux';
  last unless qx{rpm -q perl};
  last if $?;
  $skip = 0;
}

SKIP: {
  skip 'rpm command not found or perl not installed by rpm', 6 if $skip;
  my $list = $rpm->provides('perl');
  isa_ok($list, 'ARRAY');

  my $cap = $list->[0];
  isa_ok($cap, 'RPM::Query::Capability');
  is($cap->name, 'perl');
  my @version = grep {m/\Aperl *= */} qx{rpm --query --provides perl}; #e.g. perl = 4:5.32.1-481.1.el9_6
  chomp @version;
  $version[0] =~ s/\Aperl *= *//;
  is($cap->version, $version[0]);

  my $pkg = $cap->package;
  isa_ok($pkg, 'RPM::Query::Package');
  #diag(Dumper $cap);
  is($pkg->name, 'perl');
}
