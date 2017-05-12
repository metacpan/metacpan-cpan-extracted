#!/usr/bin/perl 

use strict;
use warnings;

use POE;
use POE::Session::PlainCall;

use Test::More tests => 8;

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
    $self->{alias} = $self->{name};
    poe->kernel->alias_set( $self->{alias} );
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
                    states    => [ qw( _start done ) ],
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
}

#######################################
sub done
{
    my( $self, $something ) = @_;
    is( $something, "Bon matin", "Got something back" );
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

    return POE::Session::PlainCall->create(
                    package     => $package, 
                    ctor_args   => [name => 'session2', other=>'session3' ],
                    states      => [ qw( _start _default ) ],
                )->ID;  
}

sub _default
{
    my( $self, $state, $args ) = @_;
    return if $state =~ /^_/;
    is( $state, 'wake-up', "Right state" ) or die "NO";
    is( poe->event, '_default', "poe->event _default" );

    is( $args->[0], "Hello world", "Said something" );

    my $before = poe->sender;
    my $said = poe->kernel->call( poe->sender => 'done', "Bon matin" );
    is( $said, "Buenas tardes", "Something more" );

    is( poe->sender, $before, "Same sender" );
    my $nothing = poe->kernel->call( poe->sender => 'not-there' );
    is( $nothing, undef(), "No _default" );
}

