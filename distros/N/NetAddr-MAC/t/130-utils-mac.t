use strict;
use warnings;

use Symbol qw( delete_package );
use Test::More tests => 6;

require_ok('NetAddr::MAC')
    or die "# NetAddr::MAC not available\n";

my @properties = qw(
          mac_is_eui48     mac_is_eui64
          mac_is_unicast   mac_is_multicast
          mac_is_broadcast mac_is_vrrp
          mac_is_hsrp      mac_is_hsrp2
          mac_is_msnlb
          mac_is_local     mac_is_universal
);

my @normals = qw(
          mac_as_basic     mac_as_sun
          mac_as_microsoft mac_as_cisco
          mac_as_bpr       mac_as_ieee
          mac_as_ipv6_suffix
          mac_as_tokenring mac_as_singledash
          mac_as_pgsql
);

my @all = ( @properties, @normals );

can_ok('NetAddr::MAC', @all, @properties, @normals);

sub is_exported_by {
    my ($imports, $expect, $msg) = @_;
    delete_package 'Clean';
    eval '
        package Clean;
        NetAddr::MAC->import(@$imports);
        ::is_deeply([sort keys %Clean::], [sort @$expect], $msg);
    ' or die "# $@";
}

is_exported_by([], [], 'nothing is exported by default');
is_exported_by([qw( :all )], \@all, ':all exports all stand alone functions');
is_exported_by([qw( :properties )], \@properties, ':properties exports correct stand alone functions');
is_exported_by([qw( :normals )], \@normals, ':normals exports correct stand alone functions');
