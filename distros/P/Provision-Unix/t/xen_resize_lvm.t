use strict;
use warnings;

use Data::Dumper qw( Dumper );
use English qw( -no_match_vars );
use Test::More;

use lib 'lib';
use Provision::Unix;
use Provision::Unix::VirtualOS;

my $prov = Provision::Unix->new( debug => 0 );
my $util = $prov->get_util;
my $vos;

eval { $vos = Provision::Unix::VirtualOS->new( prov => $prov, fatal => 0, debug => 0 ) };
if ( $EVAL_ERROR ) {
        my $message = $EVAL_ERROR; chop $message;
            plan skip_all => $message;
}
else {
        plan 'no_plan';
};

ok( defined $vos, 'get Provision::Unix::VirtualOS object' );
ok( $vos->isa('Provision::Unix::VirtualOS'), 'check object class' );

my $virt_class = ref $vos->{vtype};
my @parts = split /::/, $virt_class;
my $virt_type = lc( $parts[-1] );
ok( $virt_type, "virtualization type: $virt_type");

my $template_dir;
my $template_that_exists = undef;
exit if $virt_type ne 'xen';
print "go test!\n";

require Provision::Unix::VirtualOS::Linux::Xen;
my $xen = Provision::Unix::VirtualOS::Linux::Xen->new( vos => $vos );

$vos->{name} = 'test1';
$vos->{ram} = 1024;
$vos->{disk_size} = 5000;

$xen->resize_disk_image();
$prov->error('dump');

