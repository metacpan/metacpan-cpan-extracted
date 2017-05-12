#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use Tangence::Compiler::Parser;

use Tangence::Constants;

use lib ".";

my $parser = Tangence::Compiler::Parser->new;

{
   my $meta = $parser->from_file( "t/Ball.tan" );
   is_deeply( [ sort keys %$meta ], [sort qw( t.Colourable t.Ball )], 'keys of t/Ball.tan' );

   my $methods;
   my $events;
   my $props;
   my @args;

   my $colourable = $meta->{'t.Colourable'};
   isa_ok( $colourable, "Tangence::Meta::Class", 't.Colourable meta' );
   is( $colourable->name, "t.Colourable", 't.Colourable name' );
   is( $colourable->perlname, "t::Colourable", 't.Colourable perlname' );

   $props = $colourable->direct_properties;

   is_deeply( [ sort keys %$props ], [qw( colour )], 't.Colourable direct props' );

   isa_ok( $props->{colour}, "Tangence::Meta::Property", 't.Colourable prop colour' );
   is( $props->{colour}->name, "colour", 't.Colourable prop colour name' );
   is( $props->{colour}->dimension, DIM_SCALAR, 't.Colourable prop colour dimension' );
   isa_ok( $props->{colour}->type, "Tangence::Meta::Type", 't.Colourable prop colour type' );
   is( $props->{colour}->type->sig, "str", 't.Colourable prop colour type sig' );
   ok( !$props->{colour}->smashed, 't.Colourable prop colour !smashed' );

   is_deeply( [ sort keys %{ $colourable->properties } ], [qw( colour )], 't.Colourable props' );

   identical( $colourable->property( "colour" ), $props->{colour}, 't.Colourable ->property' );

   my $ball = $meta->{'t.Ball'};
   isa_ok( $ball, "Tangence::Meta::Class", 't.Ball meta' );

   $methods = $ball->direct_methods;

   is_deeply( [ sort keys %$methods ], [qw( bounce )], 't.Ball direct methods' );

   isa_ok( $methods->{bounce}, "Tangence::Meta::Method", 't.Ball method bounce' );
   identical( $methods->{bounce}->class, $ball, 't.Ball method bounce class' );
   is( $methods->{bounce}->name, "bounce", 't.Ball method bounce name' );
   @args = $methods->{bounce}->arguments;
   is( scalar @args, 1, 't.Ball method bounce has 1 argument' );
   is( $args[0]->name, "howhigh", 't.Ball method bounce arg[0] name' );
   isa_ok( $args[0]->type, "Tangence::Meta::Type", 't.Ball method bounce arg[0] type' );
   is( $args[0]->type->sig, "str", 't.Ball method bounce arg[0] type sig' );
   is_deeply( [ map $_->sig, $methods->{bounce}->argtypes ], [qw( str )], 't.Ball method bounce argtypes sigs' );
   isa_ok( $methods->{bounce}->ret, "Tangence::Meta::Type", 't.Ball method bounce ret' );
   is( $methods->{bounce}->ret->sig, "str", 't.Ball method bounce ret sig' );

   is_deeply( [ sort keys %{ $ball->methods } ], [qw( bounce )], 't.Ball methods' );

   identical( $ball->method( "bounce" ), $methods->{bounce}, 't.Ball ->method' );

   $events = $ball->direct_events;

   is_deeply( [ sort keys %$events ], [qw( bounced )], 't.Ball direct events' );

   isa_ok( $events->{bounced}, "Tangence::Meta::Event", 't.Ball event bounced' );
   identical( $events->{bounced}->class, $ball, 't.Ball event bounced class' );
   is( $events->{bounced}->name, "bounced", 't.Ball event bounced name' );
   @args = $events->{bounced}->arguments;
   is( scalar @args, 1, 't.Ball event bounced has 1 argument' );
   is( $args[0]->name, "howhigh", 't.Ball event bounced arg[0] name' );
   isa_ok( $args[0]->type, "Tangence::Meta::Type", 't.Ball event bounced arg[0] type' );
   is( $args[0]->type->sig, "str", 't.Ball event bounced arg[0] type sig' );
   is_deeply( [ map $_->sig, $events->{bounced}->argtypes ], [qw( str )], 't.Ball event bounced argtypes sigs' );

   is_deeply( [ sort keys %{ $ball->events } ], [qw( bounced )], 't.Ball events' );

   identical( $ball->event( "bounced" ), $events->{bounced}, 't.Ball ->event' );

   $props = $ball->direct_properties;

   is_deeply( [ sort keys %$props ], [qw( size )], 't.Ball direct props' );

   identical( $props->{size}->class, $ball, 't.Ball prop size class' );
   is( $props->{size}->name, "size", 't.Ball prop size name' );
   is( $props->{size}->dimension, DIM_SCALAR, 't.Ball prop size dimension' );
   isa_ok( $props->{size}->type, "Tangence::Meta::Type", 't.Ball prop size type' );
   is( $props->{size}->type->sig, "int", 't.Ball prop size type sig' );
   ok( $props->{size}->smashed, 't.Ball prop size smashed' );

   is_deeply( [ sort keys %{ $ball->properties } ], [qw( colour size )], 't.Ball props' );

   identical( $ball->property( "size" ), $props->{size}, 't.Ball ->property' );

   is_deeply( [ map { $_->name } $ball->direct_superclasses ], [qw( t.Colourable )], 't.Ball direct superclasses' );
   is_deeply( [ map { $_->name } $ball->superclasses ], [qw( t.Colourable )], 't.Ball superclasses' );
}

{
   my $meta = $parser->from_file( "t/TestObj.tan" );
   my $testobj = $meta->{'t.TestObj'};

   my $props = $testobj->direct_properties;

   is( $props->{array}->dimension, DIM_ARRAY, 't.TestObj prop array dimension' );
   is( $props->{array}->type->sig, "int", 't.TestObj prop array type sig' );
   is( $props->{hash}->dimension, DIM_HASH, 't.TestObj prop hash dimension' );
   is( $props->{hash}->type->sig, "int", 't.TestObj prop hash type sig' );
   is( $props->{queue}->dimension, DIM_QUEUE, 't.TestObj prop queue dimension' );
   is( $props->{queue}->type->sig, "int", 't.TestObj prop queue type sig' );
   is( $props->{scalar}->dimension, DIM_SCALAR, 't.TestObj prop scalar dimension' );
   is( $props->{scalar}->type->sig, "int", 't.TestObj prop scalar type' );
   is( $props->{objset}->dimension, DIM_OBJSET, 't.TestObj prop objset dimension' );
   is( $props->{objset}->type->sig, "obj", 't.TestObj prop objset type' );
   is( $props->{items}->dimension, DIM_SCALAR, 't.TestObj prop items dimension' );
   is( $props->{items}->type->aggregate, "list", 't.TestObj prop items type' );
   is( $props->{items}->type->sig, "list(obj)", 't.TestObj prop items type sig' );

   my $teststruct = $meta->{"t.TestStruct"};

   my @fields = $teststruct->fields;

   is( $fields[0]->name, "b", 't.TestStruct field b' );
   is( $fields[0]->type->sig, "bool", 't.TestStruct field b type sig' );
   is( $fields[1]->name, "i", 't.TestStruct field i' );
   is( $fields[1]->type->sig, "int", 't.TestStruct field i type sig' );
   is( $fields[2]->name, "f", 't.TestStruct field f' );
   is( $fields[2]->type->sig, "float", 't.TestStruct field f type sig' );
   is( $fields[3]->name, "s", 't.TestStruct field s' );
   is( $fields[3]->type->sig, "str", 't.TestStruct field s type sig' );
   is( $fields[4]->name, "o", 't.TestStruct field o' );
   is( $fields[4]->type->sig, "obj", 't.TestStruct field o type sig' );
}

done_testing;
