##############################################################################
package Session;

use strict;
use warnings;
our @ISA;
BEGIN {
    @ISA = qw( POE::Session::Multiplex POE::Session::PlainCall );
}

##############################################################################
package t::One;

use strict;
use warnings;

use POE;
use POE::Session::Multiplex;
use Test::More;

use POE::Session::PlainCall;

sub DEBUG () {::DEBUG}
our @LIST;

############################################
sub spawn
{
    my( $package ) = @_;
    local @LIST;
    Session->create( package_states => [
                            $package => [ qw( _start _stop sing put ) ]
                        ]
                    );
    return @LIST;
}

############################################
sub _start
{
    my( $package ) = @_;
    DEBUG and warn "$package _start";
    my $alias = $package;
    $alias =~ s/t:://;
    $poe_kernel->alias_set( $alias );
    foreach my $name ( qw( I love rock n roll ) ) {
        my $obj = $package->new( $name, poe->heap );
        poe->session->object( $name, $obj ); 
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
    my( $self, $word ) = @_;
    is( poe->heap, $self->{heap}, 'HEAP' );
    is( poe->state, 'sing', 'STATE' );
    is( poe->caller_file, __FILE__, 'CALLER_FILE' );
    is( poe->caller_state, 'next', 'CALLER_STATE' );
    is( $word, $self->{word}, "Sing: $word" );
    poe->kernel->yield( ev"put", $word );
    return $self->{word}
}

sub put
{
    my( $self, $word ) = @_;
    is( $word, $self->{word}, "also" );
}

##############################################################################
package t::Two;

use strict;
use warnings;

use POE;
use POE::Session::Multiplex;
use Test::More;
use POE::Session::PlainCall;

sub DEBUG () {::DEBUG}

############################################
sub spawn
{
    my( $package, @list ) = @_;
    Session->create( 
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
    my( $package, $list ) = @_;
    DEBUG and warn "$package _start";
    $poe_kernel->alias_set( $package );
    ok( ref $list, "Got a list" );
    ok( @$list, " ... of words to sing" );
    poe->heap->{todo} = [ @$list ];
    poe->kernel->yield( 'next' );
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
    my( $package ) = @_;
    my $heap = poe->heap;
    DEBUG and warn "next";
    my $word = shift @{ $heap->{todo} };
    my $next = 'done';
    if( $word ) {
        my $sing = $poe_kernel->call( One => evo($word, "sing" ), $word );
        is( $sing, $word, "Sung: $word" );
        $next = 'next';
    }
    $poe_kernel->yield( $next );
}

############################################
sub done
{
    my( $package ) = @_;
    $poe_kernel->alias_remove( $package );
}


1;
