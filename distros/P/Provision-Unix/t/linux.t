use strict;
use warnings;

use English qw( -no_match_vars );
use Test::More;

use lib 'lib';
use Provision::Unix;
use Provision::Unix::VirtualOS;
use Provision::Unix::VirtualOS::Linux;

my $prov = Provision::Unix->new( debug => 0 );

if ( $OSNAME ne 'linux' ) {
    plan skip_all => 'linux specific tests';
};

my $vos;
eval { $vos = Provision::Unix::VirtualOS->new( prov => $prov ); };

if ( ! $vos ) {
    plan skip_all => 'no hypervisors detected';
}
else {
    plan 'no_plan';
};

my $linux = Provision::Unix::VirtualOS::Linux->new( vos => $vos );
my $fs_root = $vos->get_fs_root('12345');

my $r = $linux->set_ips_debian( 
    fs_root   => $fs_root,
    ips       => [ '67.223.249.65', '1.1.1.1'  ],
    test_mode => 1,
);
ok( $r );

$r = $linux->set_ips( 
    fs_root   => $fs_root,
    ips       => [ '67.223.249.65', '1.1.1.1'  ],
    test_mode => 1,
    distro    => 'redhat',
);
ok( $r );

$r = $linux->install_kernel_modules(
    test_mode => 1,
    version   => 2.0,
    fs_root   => $fs_root,
);
ok( $r );
