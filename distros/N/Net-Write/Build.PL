#
# $Id: Build.PL 2014 2015-03-04 06:16:57Z gomor $
#
use strict;
use warnings;

use Module::Build;

# If Socket module does not support INET6 and getaddrinfo,
# we will have to use Socket6 module.
my @conditions_modules = ();
eval {
   require Socket;
   Socket->import(qw(AF_INET6 getaddrinfo inet_pton));
};
if ($@) {
   @conditions_modules = ( Socket6 => 0 );
}

my $builder = Module::Build->new(
   module_name => 'Net::Write',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Write.pm',
   requires => {
      'perl' => '5.6.1',
      'Class::Gomor' => 0,
      'Net::Pcap' => '0.12',
      'Socket' => 0,
      'Socket::GetAddrInfo' => 0,
      @conditions_modules,
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
