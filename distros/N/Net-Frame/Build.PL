#
# $Id: Build.PL,v 50c674721baf 2015/01/28 19:04:14 gomor $
#
use strict;
use warnings;

use Module::Build;

my @conditions_modules = ();
eval {
   require Socket;
   Socket->import(
      qw(AF_INET6 getaddrinfo getnameinfo inet_pton inet_ntop)
   );
};
if ($@) {
   @conditions_modules = ( Socket6 => 0 );
}

my $builder = Module::Build->new(
   module_name => 'Net::Frame',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame.pm',
   requires => {
      'perl' => '5.6.1',
      'Class::Gomor' => '1.00',
      'Net::IPv6Addr' => '0',
      'Bit::Vector' => '0',
      'Socket' => '0',
      @conditions_modules,
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
