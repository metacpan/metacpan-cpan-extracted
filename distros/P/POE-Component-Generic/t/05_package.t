#!/usr/bin/perl -w
# $Id: 05_package.t 1044 2012-11-28 16:35:54Z fil $

use strict;

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More tests => 7;
use POE;
use POE::Component::Generic;
use Symbol ();

my $generic1 = POE::Component::Generic->new( package=>'P1' );
my $generic = POE::Component::Generic->new( 'P1' );

is_deeply( $generic1, $generic, "Both calling styles work" );

########## Test package_load
eval { POE::Component::Generic::Child::package_load( 'P1' ) };
is( $@, '', "Didn't try to load P1.pm" );
$generic->{package} = 't::P4';
eval { POE::Component::Generic::Child::package_load( 't::P4' ) };
is( $@, '', "Didn't fail loading t/P4.pm" ) 
    or die "Failure=$@";
my $functions = [ sort Devel::Symdump->functions( "t::P4" ) ];
is_deeply( $functions, [ qw(t::P4::in4) ], "Loaded t/P4.pm" ) 
          or die "functions=", join ', ', @$functions;

######### Test package_map
$generic->__package_map( 'P1' );
is_deeply( $generic->{package_map}, {P1=>{ qw(
        new P2
        in3f P3
        in22f P22
        in2f P2
        in1f P1 ) }}, "Got the package map right");


######### Test object_build
my $obj = POE::Component::Generic::Child::object_build( 't::P4', [] );
is_deeply( $obj, (bless {}, 't::P4'), "Built object" );


######### Test methods
$generic->{package_map} = {};
$generic->__package_map( 'P1', [ qw( new in3f in1f ) ] );
is_deeply( $generic->{package_map}, {P1=>{ qw(
        new P2
        in3f P3
        in1f P1 ) }}, "Got the package map right using {methods}");




BEGIN {
#######################################################
package P3;
use strict;
use vars qw( @ISA );

BEGIN { 
    require Exporter;
    @ISA = qw( Exporter ) 
};

sub new { my $p=shift; return bless {@_}, $p }
sub in3f {}
sub _no_see_me {}

#######################################################
package P22;
use strict;

sub new { P3::new( @_ ) }
sub in22f {}
sub in2f {}
sub fiddle_carp {}

#######################################################
package P2;
use strict;
use vars qw( @ISA );
require Exporter;

BEGIN { @ISA = qw( P22 ) };

sub in2f {}
sub new { return shift->SUPER::new( @_ ) }
sub __private {}

#######################################################
package P1;
use strict;
use vars qw( @ISA );
require Exporter;

BEGIN { @ISA = qw( P2 P3 ) };


sub in1f {}

}



