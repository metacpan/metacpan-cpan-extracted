#!/usr/bin/perl 

use strict;
use warnings;

use POE;
use POE::Session::PlainCall;

use Test::More tests => 41;

#####
My::Session2->spawn();
My::Session1->spawn();

POE::Kernel->run;

pass( "Sane shutdown" );

##############################################################################
package Base::Session;

use strict;
use warnings;

use POE;
use Test::More;
use POE::Session::PlainCall;

sub new
{
    my( $package, @args ) = @_;
    return bless {@args}, $package;
}

#######################################
sub _start
{
    my( $self, @todo ) = @_;
    $self->check_poe( '_start' );
    $self->sender_is( _start => $poe_kernel->ID );

    $self->{alias} = $self->{name};
    poe->kernel->alias_set( $self->{alias} );
}



#######################################
sub sender_is
{
    my( $self, $state, $want ) = @_;

    is( poe->sender, $want, "Correct ->sender for $state" );
    is( poe->SENDER->ID, $want, "Correct ->SENDER for $state" );

    ok( poe->caller_file, " ... ->caller_file" );
    ok( poe->caller_state, " ... ->caller_state" ) unless $state =~ /^_/;
    ok( poe->caller_line, " ... ->caller_line" );
}

#######################################
sub check_poe
{
    my( $self, $method ) = @_;
    is( poe->kernel->ID, $poe_kernel->ID, " ... ->kernel" );
    is( poe->state, $method, " ... ->state" );
    is( poe->method, $method, " ... ->method" );
}

#######################################
sub _stop
{
    my( $self ) = @_;
    $self->check_poe( "_stop" );
    $self->sender_is( _stop => $poe_kernel->ID );
}





##############################################################################
package My::Session1;

use strict;
use warnings;

use Test::More;
use POE::Session::PlainCall;

use base qw( Base::Session );

#######################################
sub spawn
{
    my( $package ) = @_;

    return POE::Session::PlainCall->create(
                    'package' => $package,
                    states    => [ qw( _start _stop done ) ],
                )->ID;  
}

#######################################
sub new
{
    my( $package ) = @_;
    return bless { name=>$package, other=>"session2" }, $package
}

#######################################
sub _start
{
    my( $self, @todo ) = @_;
    $self->SUPER::_start;
    poe->kernel->post( $self->{other} => 'wake-up', "Hello world" );
    poe->kernel->post( $self->{other} => 'inline', "Hello world" );
}

#######################################
sub done
{
    my( $self, $something ) = @_;
    is( $something, "Bon matin", "Got something back" );
    poe->session->state( done2 => $self => 'done' );
    return "Buenas tardes";
}

##############################################################################
package My::Session2;

use strict;
use warnings;

use Test::More;
use POE::Session::PlainCall;

use base qw( Base::Session );

#######################################
sub spawn
{
    my( $package ) = @_;

    my $self = $package->new( name => 'session2', other=>'session3' );

    return POE::Session::PlainCall->create(
                    object_states => [
                        $self => { _start => '_start', 
                                   _stop  => '_stop',
                                   'wake-up' => 'wake_up', 
                                  }
                    ],
                    inline_states => {
                        inline => \&inline_handler
                    }

                )->ID;  
}

sub wake_up
{
    my( $self, $text ) = @_;
    is( $text, "Hello world", "Said something" );
    my $said = poe->kernel->call( poe->sender => 'done', "Bon matin" );
    is( $said, "Buenas tardes", "Something more" );
}

sub inline_handler
{
    my( $text ) = @_;
    is( poe->object, undef(), "No poe->object" );
    is( poe->package, undef(), "No poe->package" );
    is( poe->event, 'inline', "poe->event" );
    is( poe->caller_state, '_start', "poe->caller_state" );
    is( $text, "Hello world", "Said something" );
    is( poe->args->[0], $text, "poe->args" );
    my @foo = poe->args;
    is_deeply( \@foo, [ $text ], "poe->args" );
 
    my $said = poe->kernel->call( poe->sender => 'done2', "Bon matin" );
    is( $said, "Buenas tardes", "Something more" );
}
