use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use File::Temp;
use File::pushd qw/tempd/;
use Path::Class;

{
  package Foo;
  use Moose;
  use MooseX::Types::Path::Class::MoreCoercions qw/Dir File/;

  has temp_file => ( is => 'ro', isa => File, coerce => 1 );
  has temp_dir  => ( is => 'ro', isa => Dir,  coerce => 1 );
}

{
  package AbsFoo;
  use Moose;
  use MooseX::Types::Path::Class::MoreCoercions qw/AbsDir AbsFile/;

  has temp_file => ( is => 'ro', isa => AbsFile, coerce => 1 );
  has temp_dir  => ( is => 'ro', isa => AbsDir,  coerce => 1 );
}
my $tf = File::Temp->new;
my $td = File::Temp->newdir;

subtest "coerce stringable objects" => sub {
  my $obj = eval {
    Foo->new(
      temp_file => $tf,
      temp_dir  => $td,
    )
  };

  is( $@, '', "object created without exception" );
  isa_ok( $obj->temp_file, "Path::Class::File", "temp_file" );
  isa_ok( $obj->temp_dir, "Path::Class::Dir", "temp_dir" );
  is( $obj->temp_file, $tf, "temp_file set correctly" );
  is( $obj->temp_dir,  $td, "temp_dir set correctly" );
};

subtest "coerce strings (from supertype coercions)" => sub {
  my $wd = tempd;
  my $obj = eval {
    Foo->new(
      temp_file => "./foo",
      temp_dir  => ".",
    )
  };
  is( $@, '', "object created using strings without exception" );
  isa_ok( $obj->temp_file, "Path::Class::File", "temp_file" );
  isa_ok( $obj->temp_dir, "Path::Class::Dir", "temp_dir" );
  is( $obj->temp_file, file("./foo"), "temp_file set correctly" );
  is( $obj->temp_dir,  dir("."), "temp_dir set correctly" );
};

subtest "coerce to absolute from strings" => sub {
  my $wd = tempd;
  my $obj = eval {
    AbsFoo->new(
      temp_file => "./foo",
      temp_dir  => ".",
    )
  };
  is( $@, '', "absolute path object created" );
  isa_ok( $obj->temp_file, "Path::Class::File", "temp_file" );
  isa_ok( $obj->temp_dir, "Path::Class::Dir", "temp_dir" );
  is( $obj->temp_file, file("./foo")->absolute, "temp_file set correctly as absolute" );
  is( $obj->temp_dir,  dir(".")->absolute, "temp_dir set correctly as absolute" );
};

subtest "coerce to absolute from stringables" => sub {
  my $obj = eval {
    AbsFoo->new(
      temp_file => $tf,
      temp_dir  => $td,
    )
  };
  is( $@, '', "absolute path object created" );
  isa_ok( $obj->temp_file, "Path::Class::File", "temp_file" );
  isa_ok( $obj->temp_dir, "Path::Class::Dir", "temp_dir" );
  is( $obj->temp_file, $tf, "temp_file set correctly" );
  is( $obj->temp_dir,  $td, "temp_dir set correctly" );
};

subtest "coerce to absolute from Path::Class::*" => sub {
  my $wd = tempd;
  my $obj = eval {
    AbsFoo->new(
      temp_file => file("./foo"),
      temp_dir  => dir("."),
    )
  };
  is( $@, '', "absolute path object created" );
  isa_ok( $obj->temp_file, "Path::Class::File", "temp_file" );
  isa_ok( $obj->temp_dir, "Path::Class::Dir", "temp_dir" );
  is( $obj->temp_file, file("./foo")->absolute, "temp_file set correctly as absolute" );
  is( $obj->temp_dir,  dir(".")->absolute, "temp_dir set correctly as absolute" );
};

done_testing;
#
# This file is part of MooseX-Types-Path-Class-MoreCoercions
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
