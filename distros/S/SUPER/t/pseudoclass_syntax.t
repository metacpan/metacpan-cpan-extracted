#!perl
use strict;
use warnings;

# Test that the pseudo-class syntax still works despite having SUPER.pm loaded.

use SUPER;
use Test::More tests => 6;

package MyBase;

Test::More->import();

sub new { bless {}, shift }

sub foo
{
    my $self = shift;
    if (ref $self) {
        isa_ok( $self, "main" );
    }
    else {
        is( $self, "main" );    # isa_ok($str) doesn't work on older Test::More
    }
    is( $_[0], 123, "Arguments passed OK" );
}

package main;

Test::More->import();
@main::ISA = 'MyBase';

sub foo
{
    my $self = shift;
    $self->SUPER::foo(@_);
}

eval { main->foo(123) };
is( $@, '', 'Can use pseudo-class main->SUPER::method syntax' );

my $m = main->new();
eval { $m->foo(123) };
is( $@, '', 'Can use pseudo-class $isa_main->SUPER::method syntax' );
