package nmsgtest;

use FindBin;

BEGIN {
  eval { require Test::More };
  $@ && push(@INC, "$FindBin::Bin/../compat");
}

use Test::More;

use strict;
use warnings;
use Carp;

use vars qw( @EXPORT );
use base qw( Exporter );

@EXPORT = qw(
  UTIL_CLASS
  IO_CLASS
  OUTPUT_CLASS
  INPUT_CLASS
  MSG_CLASS

  dat_files
  txt_files
  not_files
  are_files
  nmsg_files
  pcap_files
  not_nmsg_files
  not_pcap_files
);

use constant UTIL_CLASS   => 'Net::Nmsg::Util';
use constant IO_CLASS     => 'Net::Nmsg::IO';
use constant OUTPUT_CLASS => 'Net::Nmsg::Output';
use constant INPUT_CLASS  => 'Net::Nmsg::Input';
use constant MSG_CLASS    => 'Net::Nmsg::Msg';

my %paths;

BEGIN {
  my $tdir = $paths{dat_dir} = "$FindBin::RealBin/dat";
  $paths{nmsg_file}  = "$tdir/test.nmsg";
  $paths{pcap_file}  = "$tdir/test.pcap";
  $paths{bogus_file} = "$tdir/bogus.txt";
  $paths{empty_file} = "$tdir/empty.txt";
  $paths{gone_file}  = "$tdir/fnord";
}

sub dat_files {(@paths{qw(
  nmsg_file
  pcap_file
)})}

sub txt_files {(@paths{qw(
  bogus_file
  empty_file
)})}

sub not_files {(@paths{qw(
  dat_dir
  gone_file
)})}

sub are_files { (dat_files(), txt_files()) }

sub nmsg_files { $paths{nmsg_file} }

sub pcap_files { $paths{pcap_file} }

sub not_nmsg_files { grep { $_ ne $paths{nmsg_file} } values %paths }

sub not_pcap_files { grep { $_ ne $paths{pcap_file} } values %paths }

1;
