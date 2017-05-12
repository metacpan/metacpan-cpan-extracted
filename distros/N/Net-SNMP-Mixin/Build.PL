use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name       => 'Net::SNMP::Mixin',
  create_readme     => 1,
  license           => 'perl',
  dist_author       => 'Karl Gaissmaier <karl.gaissmaier (at) uni-ulm.de>',
  requires          => {
    'perl'               => '5.6.0',
    'Net::SNMP'          => '0',
    'Sub::Exporter'      => '0.978',
    'Package::Generator' => '0.102',
    'Package::Reaper'    => '0.102',
    'Scalar::Util'       => '1.18',
  },
  build_requires => {
    'Module::Build' => '0',
    'Net::SNMP'     => '0',
    'Test::More'    => '0',
  },
  configure_requires => { 'Module::Build' => 0, },
  create_makefile_pl => 'small',
  add_to_cleanup => [qw/Net-SNMP-Mixin-* Makefile* META.yml README/],
);

# -----------------------------------------------------------------------
# shall we perform live tests?

print "==> For running live test you need a network connection <==\n";
if (
  $builder->y_n(
    'Do you want to run live tests against an active SNMP agent?', 'n'
  )
  )
{
  my $snmp_agent =
    $builder->prompt('Enter a hostname/ip-address of snmp agent []:');
  $builder->notes( snmp_agent => $snmp_agent || '' );

  my $community = $builder->prompt('Enter read-only community [public]:');
  $builder->notes( snmp_community => $community || 'public' );

  my $version = $builder->prompt('Enter snmp version [2c]:');
  $builder->notes( snmp_version => $version || '2c' );
}
else {
  print "Skipping live tests.\n";
  $builder->notes( snmp_agent     => '' );
  $builder->notes( snmp_community => '' );
  $builder->notes( snmp_version   => '' );
}

# -----------------------------------------------------------------------

$builder->create_build_script();
