use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use Test::Deep qw/cmp_deeply/;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

use PIR;

#--------------------------------------------------------------------------#

my @tree = qw(
  aaaa.txt
  bbbb.txt
  cccc/dddd.txt
  cccc/eeee/ffff.txt
  gggg.txt
);

my $td = make_tree(@tree);

{
    my $rule = PIR->new;
    eval { $rule->and( bless {}, "Dummy" ) };
    like( $@, qr/rules must be/i, "catch invalid rules" );
}

{
    my $rule = PIR->new->and( sub { return "0 but true" } );
    eval { $rule->all($td) };
    like( $@, qr/0 but true/i, "catch 0 but true" );
}

{
    my @files;
    my $rule     = PIR->new->file->not_name("gggg.txt");
    my $expected = [
        qw(
          aaaa.txt
          bbbb.txt
          cccc/dddd.txt
          cccc/eeee/ffff.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "not() test" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule = PIR->new->file;
    $rule->or( $rule->new->name("gggg.txt"), $rule->new->name("bbbb.txt"), );
    my $expected = [qw/bbbb.txt gggg.txt/];

    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "or() test" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule = PIR->new;
    $rule->skip( $rule->new->name("gggg.txt"), $rule->new->name("cccc"), );
    $rule->file;
    my $expected = [
        qw(
          aaaa.txt
          bbbb.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "skip() test" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule = PIR->new;
    $rule->skip( sub { return \1 if /eeee$/ } );
    my $expected = [
        qw(
          .
          aaaa.txt
          bbbb.txt
          cccc
          gggg.txt
          cccc/dddd.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "skip() with custom rule" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule = PIR->new;
    $rule->skip( sub { return \0 if /eeee$/ } );
    my $expected = [
        qw(
          .
          aaaa.txt
          bbbb.txt
          cccc
          gggg.txt
          cccc/dddd.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "skip() with crazy custom rule" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule = PIR->new;
    $rule->skip( PIR->new->skip_dirs("eeee")->name("gggg*") );
    my $expected = [
        qw(
          .
          aaaa.txt
          bbbb.txt
          cccc
          cccc/dddd.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "skip() with skip" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule = PIR->new;
    $rule->and(
        PIR->new->not(
            PIR->new->or( PIR->new->name("lldskfkad"), sub { return \1 if /eeee$/ }, )
        )
    );
    my $expected = [
        qw(
          .
          aaaa.txt
          bbbb.txt
          cccc
          gggg.txt
          cccc/dddd.txt
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "nested not and or with references" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my @files;
    my $rule = PIR->new;
    $rule->and(
        PIR->new->or( sub { return \0 if /eeee/; return 0 }, sub { return 1 }, ),
        PIR->new->and( sub { /eeee/ } ),
    );
    my $expected = [
        qw(
          cccc/eeee
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "nested and + or with prunning" )
      or diag explain { got => \@files, expected => $expected };
}

done_testing;
#
# This file is part of Path-Iterator-Rule
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
