use strict;
use Test::Lib;
use Test::Most;
use Minions ();

BEGIN {
our %Assert = (is_integer => sub { Scalar::Util::looks_like_number($_[0]) && $_[0] == int $_[0] });
}

{
    package CounterImpl;
    use Scalar::Util;

    use Minions::Implementation
        has  => {
            count => {
                default => 0,
                assert  => { %main::Assert },
            },
            step => {
                init_arg => 'step',
            }
        }, 
    ;
    
    our $Count = 0;

    sub BUILD {
        my (undef, $self, $arg) = @_;

        $self->{$__}->ASSERT('count', $arg->{start}) if $arg->{start};
        $self->{$__}->ASSERT('step',  $arg->{-step}) if $arg->{-step};
        $self->{$COUNT} = $arg->{start};
    }
    
    sub next {
        my ($self) = @_;

        $self->{$COUNT}++;
    }
}

{
    package Counter;

    our %__meta__ = (
        interface => [qw( next )],
        construct_with => {
            start => {
                optional => 1,
            },
            step => {
                optional => 1,
                assert  => { %main::Assert },
            },
            -step => {
                optional => 1,
                assert  => { %main::Assert },
            },
        },
        implementation => 'CounterImpl',
    );
    Minions->minionize;
}

package main;

lives_ok { my $counter = Counter->new() } 'Minions::Error::AssertionFailure';
throws_ok { my $counter = Counter->new(start => 'asd') } 'Minions::Error::AssertionFailure';
throws_ok { my $counter = Counter->new(starr => 'asd') } qr/Unknown args: \[starr\]/;
throws_ok { my $counter = Counter->new(start => 1, step => 'asd') } 'Minions::Error::AssertionFailure';
throws_ok { my $counter = Counter->new(start => 1, -step => 'asd') } 'Minions::Error::AssertionFailure';
lives_ok  { my $counter = Counter->new(start => 1) } 'Parameter is valid';

done_testing();
