#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::SlotAttr::Trigger;

my @triggered;

class Example
{
   has $value :reader :writer :Trigger(trig);

   method trig { push @triggered, $value; }
}

my $obj = Example->new;

$obj->set_value( 123 );
$obj->set_value( 456 );

is_deeply( \@triggered, [ 123, 456 ],
   'Trigger method invoked by ->set_value' );

done_testing;
