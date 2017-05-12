use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use Test::Deep qw/cmp_deeply/;

use lib 't/lib';
use PCNTest;

use Path::Iterator::Rule;

#--------------------------------------------------------------------------#

my @tree = qw(
  lib/Foo.pm
  lib/Foo.pod
  t/test.t
);

my $td = make_tree(@tree);

{
    my $rule     = Path::Iterator::Rule->new->name('Foo');
    my $expected = [];
    my @files    = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "name('Foo') empty match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule     = Path::Iterator::Rule->new->name('Foo.*');
    my $expected = [
        qw(
          lib/Foo.pm
          lib/Foo.pod
          )
    ];
    my @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "name('Foo.*') match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule     = Path::Iterator::Rule->new->name(qr/Foo/);
    my $expected = [
        qw(
          lib/Foo.pm
          lib/Foo.pod
          )
    ];
    my @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "name(qr/Foo/) match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule     = Path::Iterator::Rule->new->name(qr/foo/i);
    my $expected = [
        qw(
          lib/Foo.pm
          lib/Foo.pod
          )
    ];
    my @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "name(qr/Foo/) match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule     = Path::Iterator::Rule->new->name(qr/ foo /ix);
    my $expected = [
        qw(
          lib/Foo.pm
          lib/Foo.pod
          )
    ];
    my @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "name(qr/Foo/) match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule = Path::Iterator::Rule->new->name( "*.pod", "*.pm" );
    my $expected = [
        qw(
          lib/Foo.pm
          lib/Foo.pod
          )
    ];
    my @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "name('*.pod', '*.pm') match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule     = Path::Iterator::Rule->new->iname(qr/foo/);
    my $expected = [
        qw(
          lib/Foo.pm
          lib/Foo.pod
          )
    ];
    my @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "iname(qr/foo/) match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule     = Path::Iterator::Rule->new->iname(qr/ foo /x);
    my $expected = [
        qw(
          lib/Foo.pm
          lib/Foo.pod
          )
    ];
    my @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "iname(qr/foo/) match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule     = Path::Iterator::Rule->new->iname('foo.*');
    my $expected = [
        qw(
          lib/Foo.pm
          lib/Foo.pod
          )
    ];
    my @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "iname('foo.*') match" )
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
