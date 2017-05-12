#!/usr/bin/perl

use strict;
use warnings;

sub POE::Kernel::ASSERT_USAGE () { 1 }
sub POE::Kernel::TRACE_REFCNT () { 0 }


use Data::Dumper;
use POE;
use POEx::Inotify;
use Test::More ( tests => 9 );

POEx::Inotify->spawn( alias=>'notify' );
pass( "built Inotify session" );
My::Test->spawn( alias=>'notify' );

$poe_kernel->run;

pass( 'Sane shutdown' );

###############################################################
package My::Test;

use strict;
use warnings;


use Test::More;
use Cwd;
use IO::File;
use File::Spec;
use Linux::Inotify2;
use POE::Session::PlainCall;

sub DEBUG () { 0 }

sub spawn
{
    my( $package, %init ) = @_;
    POE::Session::PlainCall->create(
                    package   => $package,
                    ctor_args => [ \%init ],
                    states    => [ qw( _start _stop start notify1 
                                                    next  notify2 ) ]
                );
}

sub new
{
    my( $package, $args ) = @_;
    my $self = bless { notify=>$args->{alias} }, $package;
    $self->{dir} = File::Spec->catdir( getcwd, "something" );
    mkdir $self->{dir};
    $self->{file1} = File::Spec->catfile( $self->{dir}, 0+$self );
    DEBUG and diag( $self->{file1} );
    unlink $self->{file1} if $self->{file1};
    return $self;
}
 
sub _start
{
    my( $self ) = @_;
    DEBUG and diag( '_start' );
    poe->kernel->post( $self->{notify},  monitor => { path  => $self->{dir},
                                                      event => 'notify1',   
                                                      mode => 'raw',
                                                      args  => $self->{dir}
                                                    } );
    $self->{delay} = poe->kernel->delay_set( start => 2 );
}
 
sub _stop {
    my( $self ) = @_;
    DEBUG and diag( '_stop' );
    if( $self->{file1} ) {
        unlink $self->{file1};
    }
    if( $self->{dir} ) {
        rmdir $self->{dir};
    }
}

sub start
{
    my( $self ) = @_;
    pass( "start" );
    DEBUG and diag( $self->{file1} );
    delete $self->{delay};
    IO::File->new( ">$self->{file1}" ) or die "Unable to create $self->{file1}: $!";
    return;
}

sub notify1
{
    my( $self, $e, $path ) = @_;
    return if $self->{delay};
    is( $path, $self->{dir}, "Change in $self->{dir}" );
    isa_ok( $e, "Linux::Inotify2::Event" );

    poe->kernel->call( $self->{notify}, monitor => { path => $self->{file1}, 
                                                     mask => IN_DELETE_SELF,
                                                     event => 'notify2',
                                                     mode => 'raw',
                                                     args => $self->{file1} } );
    poe->kernel->call( $self->{notify}, unmonitor => { path => $self->{dir} } );
    $self->{delay} = poe->kernel->delay_set( next => 2 );

}

sub next
{
    my( $self ) = @_;
    pass( "next" );
    delete $self->{delay};
    unlink $self->{file1};
}

sub notify2
{
    my( $self, $e, $file ) = @_;
    return if $self->{delay};
    isa_ok( $e, "Linux::Inotify2::Event" );
    is( $file, $self->{file1}, "Changed $self->{file1}" );
    is( $e->fullname, $file, " ... exactly" );

    poe->kernel->post( $self->{notify}, 'shutdown' );
}
