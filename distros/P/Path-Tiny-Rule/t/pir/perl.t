use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use Path::Tiny;
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

my @bin = qw(
  bin/foo.pl
  bin/foo
  bin/bar
);

my $td = make_tree( @tree, @bin );

for my $f ( map { path( $td, $_ ) } @bin ) {
    next if $f =~ /foo\.pl/;
    my $fh = $f->openw;
    print {$fh} ( $f =~ 'bin/bar' ? "#!/usr/bin/env perl\n" : "#!/usr/bin/perl\n" );
    $fh->close;
}

{
    my @files;
    my $rule     = Path::Tiny::Rule->new->perl_file;
    my $expected = [
        qw(
          bin/bar
          bin/foo
          bin/foo.pl
          lib/Foo.pm
          lib/Foo.pod
          t/test.t
          )
    ];
    @files = map { unixify( $_, $td ) } $rule->all($td);
    cmp_deeply( \@files, $expected, "all perl files" )
      or diag explain { got => \@files, expected => $expected };
}

done_testing;
# COPYRIGHT
