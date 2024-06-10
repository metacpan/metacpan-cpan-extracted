# -*- cperl -*-
use Test::More;

use IO::File;
use File::Compare;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

$0 =~ qr{(?<path>.*)\.(?<ext>[^\.]+)$};
$path = $+{path};
$path =~ s/\.\///;

say STDERR $path;

my @testfiles = glob "$path/*.spelidx";

plan tests => scalar @testfiles;

foreach my $file ( @testfiles ) {
  $file =~ qr{(?<base>.*)\.(?<ext>[^\.]+)$};
  $base = $+{base};
  system( "bin/spel-wizard.pl -v -v --test $base > $base.brown 2> $base.stderr" );
  eval {
    if( compare( "$base.brown", "$base.golden" ) ) {
      fail( $file );
    }
    else {
      pass( "$file" );
    }
    1;
  } or do {
    fail( "$file: no golden file available" );
  };
}
