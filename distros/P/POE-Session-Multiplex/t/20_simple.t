#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;
use POE;

sub DEBUG () { 0 }

my @list = One->spawn;
Two->spawn( @list );

$poe_kernel->run;


##############################################################################
package One;

use strict;
use warnings;

use POE;
use POE::Session::Multiplex;
use Test::More;

sub DEBUG () {::DEBUG}
our @LIST;

############################################
sub spawn
{
    my( $package ) = @_;
    local @LIST;
    POE::Session::Multiplex->create( 
                                package_states => [
                                        $package => 
                                            [ qw( _start _stop sing put )]
                                    ]
                            );
    return @LIST;
}

############################################
sub _start
{
    my( $package ) = @_;
    DEBUG and warn "$package _start";
    $poe_kernel->alias_set( $package );
    foreach my $name ( qw( I love rock n roll ) ) {
        my $obj = $package->new( $name, $_[HEAP] );
        $_[SESSION]->object( $name, $obj ); 
        push @LIST, $name;       
    }
}

############################################
sub _stop
{
    my( $package ) = @_;
    DEBUG and warn "_stop";
}

##############################################################
sub new
{
    my( $package, $word, $heap ) = @_;
    return bless { word => $word, heap => $heap }, $package;
}

sub sing
{
    my( $self, $word ) = @_[ OBJECT, ARG0 ];
    is( $_[HEAP], $self->{heap}, 'HEAP' );
    is( $_[STATE], 'sing', 'STATE' );
    is( $_[CALLER_FILE], __FILE__, 'CALLER_FILE' );
    is( $_[CALLER_STATE], 'next', 'CALLER_STATE' );
    is( $word, $self->{word}, "Sing: $word" );
    $_[KERNEL]->yield( ev"put", $word );
    return $self->{word}
}

sub put
{
    my( $self, $word ) = @_[ OBJECT, ARG0 ];
    is( $word, $self->{word}, "also" );
}

##############################################################################
package Two;

use strict;
use warnings;

use POE;
use POE::Session::Multiplex;
use Test::More;

sub DEBUG () {::DEBUG}

############################################
sub spawn
{
    my( $package, @list ) = @_;
    POE::Session::Multiplex->create( 
                                package_states => [
                                        $package => 
                                            [ qw( _start _stop next done )]
                                    ],
                                args => [ \@list ]
                            );
    return @LIST;
}

############################################
sub _start
{
    my( $package, $list ) = @_[ OBJECT, ARG0 ];
    DEBUG and warn "$package _start";
    $poe_kernel->alias_set( $package );
    ok( ref $list, "Got a list" );
    ok( @$list, " ... of words to sing" );
    $_[HEAP]->{todo} = [ @$list ];
    $_[KERNEL]->yield( 'next' );
}

############################################
sub _stop
{
    my( $package ) = @_;
    DEBUG and warn "_stop";
}

############################################
sub next
{
    my( $package, $heap ) = @_[ OBJECT, HEAP ];
    DEBUG and warn "next";
    my $word = shift @{ $heap->{todo} };
    my $next = 'done';
    if( $word ) {
        my $sing = $poe_kernel->call( One => "$word->sing", $word );
        is( $sing, $word, "Sung: $word" );
        $next = 'next';
    }
    $poe_kernel->yield( $next );
}

############################################
sub done
{
    my( $package, $heap ) = @_[ OBJECT, HEAP ];
    $poe_kernel->alias_remove( $package );
}

