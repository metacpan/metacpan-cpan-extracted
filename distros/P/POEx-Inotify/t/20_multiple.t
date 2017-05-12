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
use Test::More ( tests => 10 );

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
                    states    => [ qw( _start _stop start notify_create notify_del ) ]
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
              events => { IN_CLOSE()  => [ 'notify_create', $self->{dir} ],
                          IN_DELETE() => { event=>'notify_del', 
                                           args => [ 42, $self->{dir} ]
                                         }
             } };

    poe->kernel->post( $self->{notify},  monitor => $M );
    $self->{delay} = poe->kernel->delay_set( start => 2 );

}

sub _stop
{
    my( $self ) = @_;
    DEBUG and diag( "_stop $self" );
    if( $self->{file1} ) {
        remove_tree $self->{dir};
    }
}

sub start
{
    my( $self ) = @_;
    pass( "start" );
    DEBUG and diag( $self->{file1} );
    delete $self->{delay};
    my $fh = IO::File->new( ">$self->{file1}" );
    $fh or die "Unable to create $self->{file1}: $!";
    $fh->print( "HONK" );
    $fh->close;
    return;
}

sub notify_create
{
    my( $self, $e, $path ) = @_;
    is( $path, $self->{dir}, "Change in $self->{dir}" );
    is( $e->fullname, $self->{file1}, "Created $self->{file1}" );
    ok( $e->IN_CLOSE, " ... after closing" );
    unlink $self->{file1};
}

sub notify_del
{
    my( $self, $e, $N, $path ) = @_;
    is( $N, 42, "Args passed" );
    is( $path, $self->{dir}, "Change in $self->{dir}" );
    ok( $e->IN_DELETE, " ... deleted" );
    is( $e->fullname, $self->{file1}, " ... $self->{file1}" );
    poe->kernel->call( $self->{notify}, 'shutdown' );
    return;
}

