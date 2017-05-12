#!/usr/bin/perl 

use strict;
use warnings;

use POE;
use POE::Session::PlainCall;

use Test::More;

# $poe_kernel->[POE::Session::CALLER_FILE] changed slightly (during ->yield)
plan tests => $POE::VERSION >= 1.356 ? 56 : 55;


#####
my $id = My::Session->spawn();

ok( $id && !ref $id, "Got a session ID" );

POE::Kernel->run;

pass( "Sane shutdown" );

##############################################################################
package My::Session;

use strict;
use warnings;

use Test::More;
use POE::Session::PlainCall;

my $SESSION;
our $SELF;

#######################################
sub spawn
{
    my( $package ) = @_;

    my $other = Other::Worker->new( prefix => 'Rolling', 
                                    suffix => 'Stones'
                                  );

    return $SESSION = POE::Session::PlainCall->create(
                    'package' => $package,
                    events  => [ qw( _start _stop next done ) ],
                    args    => [ 1, 8, 17, 42 ],
                    ctor_args => [ 'working', $other ],
                    package_states => [
                            $package => { sum => 'something' }
                        ],
                    object_states => [
                            $other   => { append => 'append',
                                          prepend => 'prepend_str'
                                        }
                        ]
                )->ID;  
}

#######################################
sub new
{
    my( $package, $name, $other ) = @_;
    is( $name, 'working', "ctor_args" );
    return $SELF = bless { name=>$package, other=>$other }, $package
}

#######################################
sub _start
{
    my( $self, @todo ) = @_;
    $self->check_poe( '_start' );
    $self->sender_is( _start => $poe_kernel->ID );
    is_deeply( \@todo, [ 1, 8, 17, 42 ], " ... args" );

    $self->{todo} = \@todo;
    $self->{alias} = $self->{name};
    poe->kernel->alias_set( $self->{alias} );

    poe->kernel->yield( 'next' );
}


#######################################
sub _stop
{
    my( $self ) = @_;
    $self->check_poe( "_stop" );
    $self->sender_is( _stop => $poe_kernel->ID );
}

#######################################
sub sender_is
{
    my( $self, $state, $want ) = @_;

    is( poe->sender, $want, "Correct ->sender for $state" );
    is( poe->SENDER->ID, $want, "Correct ->SENDER for $state" );

    if( $SESSION and $want eq $SESSION ) {
        is( poe->caller_file, __FILE__, " ... ->caller_file (".poe->caller_file.")" )
                    unless poe->caller_file eq $INC{'POE/Kernel.pm'};
        if( $self->{state} ) {
            is( poe->caller_state, delete $self->{state}, " ... ->caller_state" );
        }
    }
    else {
        ok( poe->caller_file, " ... ->caller_file" );
        ok( poe->caller_state, " ... ->caller_state" ) unless $state =~ /^_/;
    }
    ok( poe->caller_line, " ... ->caller_line" );
}

#######################################
sub check_poe
{
    my( $self, $method ) = @_;
    is( $self, $SELF, "$method passed the object" );
    is( poe->session->ID, $SESSION, " ... ->session" ) 
                    unless $method eq '_start';
    is( poe->kernel->ID, $poe_kernel->ID, " ... ->kernel" );
    is( poe->state, $method, " ... ->state" );
    is( poe->method, $method, " ... ->method" );
}


#######################################
sub next
{
    my( $self, $arg ) = @_;
    is( $self, $SELF, "next got an object" );
    $self->sender_is( next => $SESSION );

    my $todo = shift @{ $self->{todo} };
    unless( $todo ) {
        poe->kernel->yield( 'done' );
        return;
    }

    pass( "step $todo" );
    my $m = "step_$todo";
    $self->$m( $arg );
}

sub step_1 
{
    my( $self ) = @_;

    my $sum = poe->kernel->call( $SESSION => sum => 40, 2 );

    is( $sum, 42, "Indirect method invocation" );

    poe->kernel->yield( 'next' );
}

sub step_8
{
    my( $self ) = @_;

    my $str = poe->kernel->call( $SESSION => append => "TEST" );
    is( $str, "TESTStones", "Other object method invocation" );

    $str = poe->kernel->call( $SESSION => prepend => "TEST" );
    is( $str, "RollingTEST", "Other indirect object method invocation" );

    poe->kernel->yield( 'next' );
}

sub step_17 
{
    my( $self ) = @_;
    diag( "sleep 0.25" );
    poe->kernel->delay_add( next => 0.25, 'hello world' );
}

sub step_42
{
    my( $self, $arg ) = @_;
    is( $arg, 'hello world', "Got the argument" );
}

#######################################
sub something
{
    my( $package, $one, $two ) = @_;

    is( $package, __PACKAGE__, "package state" );

    return $one + $two;
}

#######################################
sub done
{
    my( $self ) = @_;
    is( $self, $SELF, "done passed the object" );
    poe->kernel->alias_remove( delete $self->{alias} ) if $self->{alias};
    return;
}

##############################################################################
package Other::Worker;

use strict;
use warnings;

use Test::More;
use POE::Session::PlainCall;

our $SELF;

sub new
{
    my( $package, @args ) = @_;
    return $SELF = bless {@args}, $package;
}

sub append
{
    my( $self, $string ) = @_;

    is( $self, $SELF, "Called on self" );
    is( poe->caller_file, __FILE__, " ... ->caller_file" );
    return "$string$self->{suffix}";
}

sub prepend_str
{
    my( $self, $string ) = @_;
    is( $self, $SELF, "Called on self" );
    is( poe->caller_file, __FILE__, " ... ->caller_file" );
    is( poe->state, 'prepend', " ... ->state" );
    is( poe->method, 'prepend_str', " ... ->method" );
    return "$self->{prefix}$string";
}
