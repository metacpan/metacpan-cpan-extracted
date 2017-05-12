#
# $Id: Build.PL,v 05d886dffb1a 2015/02/20 05:58:44 gomor $
#
use strict;
use warnings;

use Module::Build;

my %supported = (
   linux => 1,
   freebsd => 1,
   netbsd => 1,
   openbsd => 1,
   darwin => 1,
);

if (! $supported{$^O}) {
   die("Your operating system is not supported: $^O\n");
}

my $builder = Module::Build->new(
   module_name => 'Net::Routing',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Routing.pm',
   requires => {
      'perl' => '5.6.1',
      'Class::Gomor' => '1.00',
      'Net::CIDR' => '0',
      'Net::IPv4Addr' => '0',
      'Net::IPv6Addr' => '0',
      'IPC::Run3' => '0',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
