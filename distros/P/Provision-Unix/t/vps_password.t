use strict;
use warnings;

use Data::Dumper qw( Dumper );
use English qw( -no_match_vars );
use Test::More;

use lib "lib";
use Provision::Unix;
use Provision::Unix::VirtualOS;

my $prov = Provision::Unix->new( debug => 0 );
my $vos;

eval { $vos = Provision::Unix::VirtualOS->new( prov => $prov, fatal => 0, debug => 0 ) };
if ( $EVAL_ERROR ) {
    my $message = $EVAL_ERROR; chop $message;
    $message .= " on " . $OSNAME;
    plan skip_all => $message;
} 
else {
    plan 'no_plan';
};

# basic OO mechanism
ok( defined $vos, 'get Provision::Unix::VirtualOS object' );
ok( $vos->isa('Provision::Unix::VirtualOS'), 'check object class' );

my $virt_class = ref $vos->{vtype};
my @parts = split /::/, $virt_class;
my $virt_type = lc( $parts[-1] );
ok( $virt_type, "virtualization type: $virt_type");

my $ve_id_or_name
 = $virt_type eq 'openvz'    ? 72000
 : $virt_type eq 'ovz'       ? 72000
 : $virt_type eq 'virtuozzo' ? 72000
 : $virt_type eq 'xen'       ? 'test1'
 : $virt_type eq 'ezjail'    ? 'test1'
 : $virt_type eq 'jails'     ? 'test1'
 :                             undef;

exit if ! $ve_id_or_name;

my $r;

if ( $vos->is_present( name => $ve_id_or_name ) ) {
    $r = $vos->get_status( name => $ve_id_or_name );
    ok( $r, 'get_status' );
};

#warn Dumper($r);
#my $disk_image = '/dev/vol00/test1vm_rootimg';
#ok( $vos->get_disk_usage( $disk_image ), 'get_disk_usage');

exit;

ok( $vos->set_password( 
        name     => 'test1', 
        user     => 'root',
        password => 'devt3stLng',
        ssh_key  => 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAv6f4BW89Afnsx51BkxGvPbLeqDK+o6RXp+82KSIhoiWzCJp/dwhB7xNBR0W7Lt/n7KJUGYdlP7h5YlmgvpdJayzMkbsoBW2Hj9/7MkFraUlWYIU9QtAUCOARBPQWC3JIkslVvInGBxMxH5vcCO0/3TM/FFZylPTXjyqmsVDgnY4C1zFW3SdGDh7+1NCDh4Jsved+UVE5KwN/ZGyWKpWXLqMlEFTTxJ1aRk563p8wW3F7cPQ59tLP+a3iHdH9sE09ynbI/I/tnAHcbZncwmdLy0vMA6Jp3rWwjXoxHJQLOfrLJzit8wzG867+RYDfm6SZWg7iYZYUlps1LSXSnUxuTQ== matt@SpryBook-Pro.local',
    ), 
    'set_password'
);

