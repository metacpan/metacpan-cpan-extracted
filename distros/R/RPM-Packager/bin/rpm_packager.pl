#!/usr/bin/perl

use strict;
use warnings;
use YAML;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use RPM::Packager;

my $arg = shift;
usage() unless ( $arg && -f $arg );

my $config = YAML::LoadFile($arg);
my @rpms   = glob "*.rpm";
unlink @rpms;

my $packager = RPM::Packager->new( %{$config} );
$packager->create_rpm();

sub usage {
    print <<USAGE;
Create RPM from YAML manifest

    $0 <path_to_YAML>
USAGE
    exit(-1);
}
