#!/usr/bin/perl -w

use strict;
use warnings;

use POE;
use POE::Component::XUL;
use File::Path;

use Test::More ( tests=> 8 );

use POE::XUL::Logging;
use t::XUL;

#################
my $L = bless [], 't::Log4Perl';

my $xul = t::XUL->new( { root => 't/poe-xul', port=>8881, logging => $L } );
ok( $xul, "Created PoCo::XUL object" );

$xul->log_setup();

xwarn "Hello world!";
pass( "xwarn didn't die" );

xlog "It is snowing right now.";
pass( "xlog didn't die" );

xdebug "My pants are on fire!";
pass( "xdebug didn't die" );

do_carp();
pass( "xcarp didn't die" );

xlog( { type    => 'BONK', 
        message => 'This is a bonk' 
    } );
pass( "xlog w/ hashref didn't die" );

#################
is( 0+@$L, 5, "5 calls to log4perl" );

is_deeply( $L, [
        { level => 30000, message => "Hello world!" },
        { level => 20000, message => "It is snowing right now." },
        { level => 10000, message => "My pants are on fire!" },
        { level => 30000, message => "This is a carp message" },
        { level => 20000, message => "This is a bonk" },
    ], "That look like I expected" );
# use Data::Dumper;
# warn Dumper $L;

###########################################################
sub do_carp
{
    __do_carp();
}

sub __do_carp()
{
    xcarp "This is a carp message";
}

##########################################################################
package t::Log4Perl;
use strict;
use warnings;


sub log
{
    my( $self, $lvl, $message ) = @_;

    push @$self, { level => $lvl, message => $message };
}
