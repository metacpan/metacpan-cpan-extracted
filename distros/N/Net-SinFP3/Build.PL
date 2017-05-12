#
# $Id: Build.PL,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::SinFP3',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_metabrik.org>',
   dist_version_from => 'lib/Net/SinFP3.pm',
   requires => {
      'perl' => '5.6.1',
      'Class::Gomor' => 0,
      'Data::Dumper' => 0,
      'DBD::SQLite' => 0,
      'DBI' => 0,
      'Digest::MD5' => 0,
      'File::Glob' => 0,
      'FindBin' => 0,
      'Frontier::Client' => 0,
      'IO::Socket::INET' => 0,
      'IO::Socket::INET6' => 0,
      'IO::Select' => 0,
      'LWP::UserAgent' => 0,
      'Net::Frame' => '1.07',
      'Net::Frame::Device' => 0,
      'Net::Frame::Dump' => '1.12',
      'Net::Frame::Layer::IPv6' => 0,
      'Net::Frame::Layer::SinFP3' => 0,
      'Net::Frame::Simple' => 0,
      'Net::Libdnet' => '0.90',
      'Net::Netmask' => 0,
      'Net::Write' => 0,
      'Parallel::ForkManager' => 0,
      'POSIX' => 0,
      'Socket' => 0,
      'Socket6' => 0,
      'Time::Interval' => 0,
      'Net::Write::Fast' => 0,
   },
   script_files => [ qw(bin/sinfp3.pl bin/sinfp3.db) ],
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
