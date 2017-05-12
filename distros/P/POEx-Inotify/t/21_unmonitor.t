#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    sub POE::Kernel::ASSERT_USAGE () { 1 }
    sub POE::Kernel::TRACE_SIGNALS () { 0 }
}

use Data::Dumper;
use POE;
use POEx::Inotify;
use POE::Session::PlainCall;
use Test::More ( tests => 6 );

POEx::Inotify->spawn();
pass( "built Inotify session" );
My::Test->spawn( alias=>'inotify' );

poe->kernel->run;

pass( 'Sane shutdown' );

###############################################################
package My::Test;

use strict;
use warnings;


use Test::More;
use Linux::Inotify2;
use Cwd;
use IO::File;
use File::Spec;
use POE::Session::PlainCall;
use File::Path qw( make_path remove_tree );

sub DEBUG () { 0 }

sub spawn
{
    my( $package, %init ) = @_;
    POE::Session::PlainCall->create(
                    package   => $package,
                    ctor_args => [ \%init ],
                    states    => [ qw( _start _stop start done
                                       notify_all notify_create notify_change ) ]
                );
}

sub new
{
    my( $package, $args ) = @_;
    my $self = bless { notify=>$args->{alias}, delay=>$args->{delay} }, $package;
    $self->{dir} = File::Spec->catdir( getcwd, "something" );
    remove_tree $self->{dir};
    make_path $self->{dir};

    $self->{file1} = File::Spec->catfile( $self->{dir}, 0+$self );
    DEBUG and diag( $self->{file1} );
    return $self;
}

sub _start
{
    my( $self ) = @_;
    DEBUG and diag( "_start $self" );
    my $M = { path  => $self->{dir},
              mode  => 'cooked',
              events => { IN_ALL_EVENTS, 'notify_all',
                          IN_CLOSE, 'notify_create',
                          IN_CLOSE_WRITE, 'notify_change'
                        }
            };
    poe->kernel->post( $self->{notify},  monitor => $M );
    $self->{delay} = poe->kernel->delay_set( start => 2 );

}

sub _stop
{
    my( $self ) = @_;
    DEBUG and diag( "_stop $self" );

    poe->kernel->call( $self->{notify}, 'shutdown' );
    if( $self->{file1} ) {
        remove_tree $self->{dir};
    }
}

sub start
{
    my( $self ) = @_;
    pass( "start" );
    DEBUG and diag( $self->{file1} );

    poe->kernel->call( $self->{notify}, unmonitor => { path=>$self->{dir}, 
                                                       event => 'notify_create' } );

    delete $self->{delay};
    my $fh = IO::File->new( ">$self->{file1}" );
    $fh or die "Unable to create $self->{file1}: $!";
    $fh->print( "HONK" );
    $fh->close;
    return;
}

sub notify_create
{
    my( $self, $e ) = @_;
    fail( "Never supposed to be called" );
}

sub notify_change
{
    my( $self, $e ) = @_;
    pass( "You called me!" );
}

sub notify_all
{
    my( $self, $e ) = @_;
    if( $e->IN_CLOSE_WRITE ) {
        pass( "notify_all" );
        $self->{delay} = poe->kernel->delay_set( done => 2 );
    }
}

sub done
{
    my( $self ) = @_;
    pass( "done" );
    poe->kernel->call( $self->{notify}, unmonitor => { path=>$self->{dir}, event => '*' } );
}
