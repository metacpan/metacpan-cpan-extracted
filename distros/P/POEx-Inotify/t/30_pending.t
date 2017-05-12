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
use Test::More ( tests => 20 );

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

#############################################
sub spawn
{
    my( $package, %init ) = @_;
    POE::Session::PlainCall->create(
                    package   => $package,
                    ctor_args => [ \%init ],
                    states    => [ qw( _start _stop 
                                    notify_create notify_delete
                                    notify_create2 notify_delete2
                                    next done ) ]
                );
}

sub new
{
    my( $package, $args ) = @_;
    my $self = bless { notify=>$args->{alias}, delay=>$args->{delay} }, $package;
    $self->{dir} = File::Spec->catdir( getcwd, "something" );
    remove_tree $self->{dir};
    make_path $self->{dir};

    $self->{sleep} = 2;

    $self->{want} = File::Spec->catfile( $self->{dir}, qw( one two three something.txt ) );
    $self->{want2} = File::Spec->catfile( $self->{dir}, qw( one two three other.txt ) );
    $self->{todo} = [ qw( one/ one/two/ one/two/not.txt -one/two/ 
                          one/two/three/ one/two/three/something.txt
                          -one/two/
                          one/two/three/ one/two/three/something.txt
                          one/two/three/other.txt
                          -one/ ) ];

    return $self;
}

sub my_sleep
{
    my( $self, $next, $N, @args ) = @_;
    $N ||= $self->{sleep};
    DEBUG and diag( "Sleep $N" );
    $self->{delay} = poe->kernel->delay_set( $next => $N, @args );
}

#############################################
sub _start
{
    my( $self ) = @_;
    DEBUG and diag( "_start $self" );



    my $M = { path  => $self->{want},
              mode  => 'cooked',
              events => { (IN_CREATE|IN_CLOSE_WRITE) => 'notify_create',
                          IN_DELETE_SELF() => [ 'notify_delete' ]
                        }
            };
    poe->kernel->call( $self->{notify},  monitor => $M );

    $M    = { path  => $self->{want2},
              mode  => 'cooked',
              events => { (IN_CREATE|IN_CLOSE_WRITE) => 'notify_create2',
                          IN_DELETE_SELF() => [ 'notify_delete2' ]
                        }
            };

    poe->kernel->call( $self->{notify},  monitor => $M );
    $self->my_sleep( 'next' );

}

#############################################
sub _stop
{
    my( $self ) = @_;
    DEBUG and diag( "_stop $self" );
    if( $self->{dir} ) {
        remove_tree $self->{dir};
    }
    poe->kernel->call( $self->{notify}, 'shutdown' );
}

#############################################
sub next
{
    my( $self ) = @_;
    my $todo = shift @{ $self->{todo} };

    delete $self->{delay};

    my $delete = 1 if $todo =~ s/^-//;

    if( $todo =~ s(/$)() ) {
        my $dest = File::Spec->catdir( $self->{dir}, $todo );
        if( $delete ) {
            DEBUG and diag "Remove $dest/";
            remove_tree( $dest );
        }
        else {
            DEBUG and diag "Make $dest/";
            make_path( $dest );
        }
    }
    else {
        my $dest = File::Spec->catfile( $self->{dir}, $todo );
        if( $delete ) {
            DEBUG and diag "Unlink $dest";
            unlink $dest or die "Unable to unlink $dest: $!";
        }
        else {
            DEBUG and diag "Create $dest";
            my $fh = IO::File->new( ">$dest" );
            $fh or die "Unable to create $self->{file1}: $!";
            $fh->print( "HONK" );
            $fh->close;
        }
    }

    if( @{ $self->{todo} } ) {
        $self->my_sleep( 'next' );
    }
    else {
        $self->my_sleep( 'done' );
    }

}

#############################################
sub done
{
    my( $self ) = @_;
    DEBUG and diag( "Done" );
    my $M = { path  => $self->{want},
              events => [ qw( notify_create notify_delete ) ]
            };
    poe->kernel->call( $self->{notify}, unmonitor => $M );

    $M    = { path  => $self->{want2},
              events => [ qw( notify_create2 notify_delete2 ) ]
            };
    poe->kernel->call( $self->{notify}, unmonitor => $M );
}

#############################################
sub notify_create
{
    my( $self, $e ) = @_;
    ok( $e->IN_CLOSE || $e->IN_CREATE, "Created" );
    like( $e->fullname, qr(something.txt$), " ... something.txt" );
    is( $e->name, '' );
}

#############################################
sub notify_delete
{
    my( $self, $e ) = @_;
    ok( $e->IN_DELETE_SELF, "Deleted" );
    like( $e->fullname, qr(something.txt$), " ... something.txt" );
    is( $e->name, '' );
    return;
}

#############################################
sub notify_create2
{
    my( $self, $e ) = @_;
    ok( $e->IN_CLOSE || $e->IN_CREATE, "Created" );
    like( $e->fullname, qr(other.txt$), " ... other.txt" );
    is( $e->name, '' );
}

#############################################
sub notify_delete2
{
    my( $self, $e ) = @_;
    ok( $e->IN_DELETE_SELF, "Deleted" );
    like( $e->fullname, qr(other.txt$), " ... other.txt" );
    is( $e->name, '' );
    return;
}

