use strict;
use warnings;

use Data::Dumper qw( Dumper );
use English qw( -no_match_vars );
use Test::More;

use lib "lib";
use Provision::Unix;
use Provision::Unix::VirtualOS;

my $prov = Provision::Unix->new( debug => 0 );
#warn Dumper($prov);
my $vos;

eval { $vos = Provision::Unix::VirtualOS->new( prov => $prov, fatal => 0, debug => 0 ) };
#warn Dumper( $vos );
if ( $EVAL_ERROR ) {
    my $message = $EVAL_ERROR; chop $message;
    $message .= " on " . $OSNAME;
    plan skip_all => $message;
} 
else {
    plan 'no_plan';
};

use_ok('Provision::Unix::VirtualOS');
require_ok('Provision::Unix::VirtualOS');

# basic OO mechanism
ok( defined $vos, 'get Provision::Unix::VirtualOS object' );
ok( $vos->isa('Provision::Unix::VirtualOS'), 'check object class' );

my $r; 

if ( ref $vos->{vtype} eq 'Provision::Unix::VirtualOS::Linux::OpenVZ' ) {
    $r = $vos->gen_config( ram=>512, disk_size=>2, template=>'centos-5-i386', disk_root=>'/home', ip=>'127.0.0.1 127.0.0.2', name=>2000005, hostname=>'example.com', config => 'brand.512');
    ok( $r, 'get_config, openvz' );
print "$r\n";
};

$r = $vos->is_mounted( name => 2000005 );
if ( $r ) {
    ok( $r, 'is_mounted' );
    $r = $vos->unmount( name => 2000005 );
    ok( $r, 'unmount' );
};

