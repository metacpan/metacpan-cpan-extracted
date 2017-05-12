use 5.006;
use strict;
use warnings;
use Test::More 0.96;

{
  package BlessedPath;
  use overload q{""} => sub { "${$_[0]}" };
  sub new { my ($class, $path) = @_; return bless \$path, $class; }
}

{
  package Foo;
  use Moose;
  use MooseX::Types::Stringlike qw/Stringable Stringlike/;
  
  has path => ( is => 'ro', isa => Stringlike, coerce => 1 );
  has path_obj => (is => 'ro', isa => Stringable );
}


my $obj = eval {
  Foo->new(
    path => BlessedPath->new("./t"),
    path_obj => BlessedPath->new("./lib"),
  )
};

is( $@, '', "object created without exception" );

is( ref($obj->path), '', "path attribute has been coerced to string" );
is( ref($obj->path_obj), 'BlessedPath', "path_obj is still an object" );

done_testing;
#
# This file is part of MooseX-Types-Stringlike
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
