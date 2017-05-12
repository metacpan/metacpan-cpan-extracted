#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 27;
use POE;

sub DEBUG () { 0 }

use POE;
use POE::Session::Multiplex;

$poe_kernel->run;

my $session = POE::Session::Multiplex->create( 
                                inline_states => {
                                        _start => sub { '_start' },
                                    },
                                package_states => [
                                        One => [ qw( yeah oh )]
                                    ]
                            );
ok( $session, "Got a session object" );

#####
my $o = bless {}, 'One';
eval {
    $session->object( 'foo',  $o );
};
is( $@, '', "Added an object" ) or die $@;

#####
my $o2 = $session->object_get( 'foo' );
is_deeply( $o2, $o, "Got it back" );

#####
my $o3 = bless {}, 'One';
eval {
    $session->object( 'bar',  $o );
};
is( $@, '', "Added another object" ) or die $@;

#####
$o2 = $session->object_get( 'bar' );
is_deeply( $o2, $o3, "Got it back" );

$o2 = $session->object_get( 'foo' );
is_deeply( $o2, $o, "And the original" );

isnt( $o3, $o2, ' ... different' );

#####
eval {
    $session->object( 'bar' );
};
is( $@, '', "Removed that object" ) or die $@;

#####
$o2 = $session->object_get( 'bar' );
is( $o2, undef(), " ... no more" );

my $before = length Dumper $session;



##### Get handlers via ISA
$o3 = bless {}, 'Three';
eval {
    $session->object( cold => $o3 ); 
};
is( $@, '', "Added an object that is a known subclass" );


##### Objects in new packages
$o3 = bless {}, 'Two';
eval {
    $session->object( cold => $o3 ); 
};
ok( ( $@ =~ /No package_states/ ), "Can't register an object without states" );

#####
eval {
    $session->object( cold => $o3, [ qw( biff ) ] ); 
};
is( $@, '', "Added an object of a different package" );


$session->object_unregister( 'cold' );
is( length( Dumper $session ), $before, " ... didn't change sizes" )
            or die Dumper $session;

#####
eval {
    $session->object( cold => $o3, { zip => 'biff' } ); 
};
is( $@, '', "Defined object with a hash" );

$before = length Dumper $session;

eval {
    $session->object( cold => $o3, { zip => 'biff' } ); 
};
is( $@, '', "Redefined object with a hash" );

is( length( Dumper $session ), $before, " ... didn't change size" )
            or die Dumper $session;

$session->object( 'cold' );


##### Get handlers via package_register
$o3 = bless {}, 'Two';
$session->package_register( Two => { hum => 'biff' } );

eval {
    $session->object( cold => $o3 );
};
is( $@, '', "Added an object of a registered package" );


##### MOP
$o3 = bless { name => "something" }, 'Three';
eval {
    $session->object_register( object => $o3 );
};
is( $@, '', "Added an object w/o a name" );

my $o4 = $session->object_get( 'something' );
is_deeply( $o4, $o3, "Fetched object with its name" );

eval {
    $session->object_unregister( $o3 );
};
is( $@, '', "Unregistered a named object" );

$o4 = $session->object_get( $o3 );
is( $o4, undef(),  "It's gone" );




##### 
$o3 = bless {}, 'Two';
eval {
    $session->object_register( $o3 );
};
is( $@, '', "Added a no-name object" );

$o4 = $session->object_get( $o3 );
is_deeply( $o4, $o3, "Fetched the object anyway" );

eval {
    $session->object_unregister( $o3 );
};
is( $@, '', "Unregistered a no-name object" );

$o4 = $session->object_get( $o3 );
is( $o4, undef(),  "It's gone" );

##### object_list

my @list = $session->object_list;
is_deeply( [sort @list ], [ sort qw( cold foo  ) ], "List of objects" );

foreach my $o ( @list ) {
    $session->object_unregister( $o );
}

@list = $session->object_list;
is_deeply( \@list, [], "No more objects" );


##############################################################
package One;

sub yeah { 'yeah' }
sub oh   { 'oh' }

##############################################################
package Two;

use strict;
use warnings;

sub biff { 'biff' }

##############################################################
package Three;

use strict;
use warnings;

use base qw( One );

sub __name { $_[0]->{name} }


















