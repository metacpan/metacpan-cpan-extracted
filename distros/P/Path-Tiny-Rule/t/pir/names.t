use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use Test::Deep qw/cmp_deeply/;

use lib 't/pir/lib';
use PCNTest;

use Path::Tiny::Rule;

#--------------------------------------------------------------------------#

my @tree = qw(
  lib/Foo.pm
  lib/Foo.pod
  t/test.t
);

my $td = make_tree(@tree);

{
    my $rule     = Path::Tiny::Rule->new->name('Foo');
    my $expected = [];
    my @files    = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "name('Foo') empty match" )
      or diag explain { got => \@files, expected => $expected };
}

{
    my $rule     = Path::Tiny::Rule->new->name('Foo.*');
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
    my $rule     = Path::Tiny::Rule->new->name(qr/Foo/);
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
    my $rule     = Path::Tiny::Rule->new->name(qr/foo/i);
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
    my $rule     = Path::Tiny::Rule->new->name(qr/ foo /ix);
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
    my $rule = Path::Tiny::Rule->new->name( "*.pod", "*.pm" );
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
    my $rule     = Path::Tiny::Rule->new->iname(qr/foo/);
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
    my $rule     = Path::Tiny::Rule->new->iname(qr/ foo /x);
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
    my $rule     = Path::Tiny::Rule->new->iname('foo.*');
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
# COPYRIGHT
