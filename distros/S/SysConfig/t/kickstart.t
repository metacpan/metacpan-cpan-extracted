use lib qw(. blib/lib t);
use strict;
use SysConfig;
use T;
use Carp;
$SIG{__WARN__} = \&Carp::cluck;
 
my $t = T->new();

eval "use SysConfig::Kickstart";

if( $@ ) {
  $t->skip('SysConfig::Kickstart not installed');
}

my $x = new SysConfig::Kickstart();

$x->inst_type( {
   inst_type	=> 'nfs',
   nfsserver	=> 'foo:/bar'
  } );

$t->eok( $x->{settings}->{inst_type}->{inst_type} eq 'nfs',
         "failed to set value" );

my( $k ) = ${ $x->kickstart( '700' ) };
my @k = split "\n", $k;

$t->eok( $#k, "didn't generate kickstart file" );

$t->done;



