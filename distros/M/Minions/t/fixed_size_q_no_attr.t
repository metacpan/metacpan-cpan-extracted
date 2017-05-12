use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package FixedSizeQueueImpl;
    
    our %__meta__ = (
        has  => {
            q => { default => sub { [ ] } },
            max_size => {},
        }, 
    );

    sub BUILD {
        my (undef, $self, $arg) = @_;

        $self->{-max_size} = $arg->{max_size};
    }
    
    sub size {
        my ($self) = @_;
        scalar @{ $self->{-q} };
    }
    
    sub push {
        my ($self, $val) = @_;
    
        push @{ $self->{-q} }, $val;
    }
}

package FixedSizeQueue;

our %__meta__ = (
    interface => [qw( push size )],
    implementation => 'FixedSizeQueueImpl',
    construct_with => {
        max_size => { 
            assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
        },
    }, 
);
Minions->minionize;

package main;

my $q = FixedSizeQueue->new(max_size => 3);

is($q->{-max_size}, 3);

$q->push(1);
is($q->size, 1);

$q->push(2);
is($q->size, 2);

throws_ok { FixedSizeQueue->new() } qr/Param 'max_size' was not provided./;
throws_ok { FixedSizeQueue->new(max_size => 0) } 'Minions::Error::AssertionFailure';

done_testing();
exit 0;
