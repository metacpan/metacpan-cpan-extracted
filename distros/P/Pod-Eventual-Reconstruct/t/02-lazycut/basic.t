use strict;
use warnings;

use Test::More tests => 2;
use FindBin;
use Path::Tiny qw( path );
use Test::Differences qw( eq_or_diff_text );
use Test::Fatal;

my $corpus = path($FindBin::Bin)->parent->parent->child('corpus')->child('reconstruct');

use lib path($FindBin::Bin)->parent->child('lib')->stringify;

use EventPipe;

for my $file ( $corpus->children() ) {
  my $content = $file->slurp;
  my $output;
  my $fn = $file->relative($corpus)->stringify;
  is(
    exception {
      $output = EventPipe->transform_string($content);
    },
    undef,
    'can parse and reconstruct ' . $fn
  );

  eq_or_diff_text( $output, $content, "$fn reconstructed faithfully" );
}
