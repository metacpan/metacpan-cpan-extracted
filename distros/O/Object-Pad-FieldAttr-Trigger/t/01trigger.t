#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad;
use Object::Pad::FieldAttr::Trigger;

my @triggered;

class Example
{
   field $value :reader :writer :Trigger(trig);

   method trig { push @triggered, $value; }
}

my $obj = Example->new;

$obj->set_value( 123 );
$obj->set_value( 456 );

is( \@triggered, [ 123, 456 ],
   'Trigger method invoked by ->set_value' );

done_testing;
