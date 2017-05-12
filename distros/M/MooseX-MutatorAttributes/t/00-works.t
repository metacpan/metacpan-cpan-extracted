#!/usr/bin/perl;

use strict;
use warnings;

use Test::More qw{no_plan};
use Test::Exception;

#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------
BEGIN {

package My::Test;
use Moose;
with qw{MooseX::MutatorAttributes};

has [qw{one two}] => (
   is => 'rw',
   isa => 'Int',
   default => 0,
);

has three => (
   is => 'ro',
   isa => 'Int',
   default => 3,
);

sub add {
   my ($self) = @_;
   return $self->one + $self->two;
}

} # END BEGIN

#---------------------------------------------------------------------------
#  
#---------------------------------------------------------------------------
lives_ok { My::Test->new() };

my $t  = My::Test->new();

is ( $t->add, 0 );
is ( $t->set(one => 12)->add, 12);
is ( $t->one, 12 );
is ( $t->set(one => 1, two => 1)->add, 2 ); 
is ( $t->one, 1 );
is ( $t->two, 1 );

throws_ok {$t->set( moo => 10)} qr/not an attribute/;
throws_ok {$t->set( three => 0)} qr/(is not writable|read-only accessor)/ ;
