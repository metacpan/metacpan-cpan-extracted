#
# $Id: Build.PL 359 2015-01-04 16:49:32Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Device',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Device.pm',
   requires => {
      'perl' => '5.6.1',
      'Class::Gomor' => '1.00',
      'Net::Libdnet' => 0,
      'Net::Libdnet6' => 0,
      'Net::IPv4Addr' => 0,
      'Net::IPv6Addr' => 0,
      'Net::Pcap' => '0.12',
      'Net::Write' => '1.00',
      'Net::Frame' => 0,
      'Net::Frame::Dump' => '1.08',  # For Dump::Online2
      'Net::Frame::Layer::IPv6' => 0,
      'Net::Frame::Layer::ICMPv6' => 0,
      'Net::Frame::Simple' => '1.05',  # Cause of a bug in ICMPv6 unpacking
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
