use strict;
use Module::Build;
use 5.005;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name => 'Net::CIDR::Set',
  license     => 'perl',
  dist_author => 'Andy Armstrong <andy.armstrong@messagesystems.com>',
  dist_version_from => 'lib/Net/CIDR/Set.pm',
  requires          => { 'Test::More' => 0 },
  add_to_cleanup    => ['Net-CIDR-Set-*'],
);

$builder->create_build_script();
