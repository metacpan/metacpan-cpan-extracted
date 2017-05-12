#!/usr/bin/perl
# $Id: 31_log_poe.t 509 2007-09-12 07:20:01Z fil $

use strict;
use warnings;

use POE;
use POE::Component::XUL;
use File::Path;

use constant DEBUG=>0;

use Test::More ( tests=> 60 );

use POE::XUL::Logging;
use t::XUL;

######################################################
our $logdir = "t/poe-xul/log";
our $logfile = "t/poe-xul/log/poco-xul.log";

######################################################
# alias + event
my $xul = t::XUL->spawn( { root  => 't/poe-xul', 
                           port  => 8881, 
                           alias => 'XUL-test',
                           logging => [ 'my-test', 'logging' ]
                       } );
ok( $xul, "Created PoCo::XUL session" );


My::Runner->spawn( xul_alias => 'XUL-test', alias => 'my-test' );
pass( "Created runner session" );

$poe_kernel->run;

pass( "Exited" );

######################################################
# Just alias
$xul = t::XUL->spawn( { root  => 't/poe-xul', 
                           port  => 8881, 
                           alias => 'XUL-test',
                           logging => '2nd-test',
                       } );
ok( $xul, "Created PoCo::XUL session" );


My::Runner->spawn( xul_alias => 'XUL-test', alias => '2nd-test' );
pass( "Created runner session" );

$poe_kernel->run;

pass( "Exited" );



############################################################################
package My::Runner;

use strict;
use warnings;
use POE;

use POE::XUL::Logging;


BEGIN {
    *DEBUG = \&::DEBUG;
    *ok    = \&::ok;
    *is    = \&::is;
    *diag  = \&::diag;
    *pass  = \&::pass;
}

sub spawn
{
    my( $package, @args ) = @_;
    my $self = bless { @args }, $package;
    POE::Session->create(
            object_states => [
                $self => [ qw( _start do_next done logging log ) ]
            ]
        )
}

sub _start
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    $self->{todo} = [ qw( __xwarn __xlog __xdebug __xcarp ) ];

    $kernel->alias_set( $self->{alias} );
    $kernel->yield( 'do_next' );

    $self->{expect} = { directory => $logdir, type=>'SETUP' };

    ok( !-d $::logdir, "Didn't create a log dir" );
    ok( !-f $::logfile, "Didn't create the log file" ) 
        or die "I need $logfile";

}

sub logging 
{
    my( $self, $kernel, $exception ) = @_[ OBJECT, KERNEL, ARG0 ];

    $self->__log( $exception );
}

sub log
{
    my( $self, $kernel, $exception ) = @_[ OBJECT, KERNEL, ARG0 ];

    $self->__log( $exception );
}

sub __log
{
    my( $self, $exception ) = @_;

    ok( $self->{expect}, "I was expecting something" );

    foreach my $f ( keys %{ $self->{expect} } ) {
        my $expect = $self->{expect}{$f};
        my $got    = $exception->{$f};
        unless( $f eq 'caller' ) {
            is( $got, $expect, " ... $f" );
        }
        else {
            for( my $e=0; $e < @$expect; $e++ ) {
                is( $got->[$e], $expect->[$e], " ... $f/$e" );
            }
        }
    }
    delete $self->{expect};
}

sub do_next
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];

    unless( @{ $self->{todo} } ) {
        $kernel->yield( 'done' );
        return;
    }

    my $func = shift @{ $self->{todo} };
    DEBUG and diag( $func );
    $self->$func();
    $poe_kernel->yield( 'do_next' );
}

sub done
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    DEBUG and diag( 'done' );
    $kernel->alias_remove( $self->{alias} );
    $kernel->post( $self->{xul_alias}, 'shutdown' );
}

sub __xwarn 
{
    my( $self ) = @_;
    $self->{expect} = { caller => [ qw( My::Runner t/31_log_poe.t ) ], 
                       message => 'Hello world!', type => 'WARN' };

    xwarn "Hello world!";
    pass( "xwarn didn't die" );
}

sub __xlog 
{
    my( $self ) = @_;
    $self->{expect} = { caller => [ qw( My::Runner t/31_log_poe.t ) ], 
                      message => 'It is snowing right now.', type => 'LOG' };
    xlog "It is snowing right now.";
    pass( "xlog didn't die" );
}

sub __xdebug
{
    my( $self ) = @_;
    $self->{expect} = { caller => [ qw( My::Runner t/31_log_poe.t ) ], 
                       message => 'My pants are on fire!', type => 'DEBUG' };

    xdebug "My pants are on fire!";
    pass( "xdebug didn't die" );
}


sub __xcarp
{
    my( $self ) = @_;

    $self->{expect} = { caller => [ qw( My::Runner t/31_log_poe.t ), __LINE__ + 2 ], 
                       message => 'This is a carp message', type => 'WARN' };
    do_carp();
    pass( "xcarp didn't die" );

}

###########################################################
sub do_carp
{
    xcarp "This is a carp message";
}
