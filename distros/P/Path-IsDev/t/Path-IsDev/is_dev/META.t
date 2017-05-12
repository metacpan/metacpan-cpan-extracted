use strict;
use warnings;

use Test::More tests => 4;
use Path::Tiny qw(path);
use Test::Fatal qw( exception );
use FindBin;

sub nofatal {
  my ( $message, $sub ) = @_;
  my $e = exception { $sub->() };
  return is( $e, undef, $message );
}

my $corpus_dir = path($FindBin::Bin)->parent->parent->parent->child('corpus')->child('META');

nofatal 'Can require without exception' => sub {
  require Path::IsDev;
};

nofatal 'Can import without exception' => sub {
  Path::IsDev->import(qw(is_dev));
};

my $path;

nofatal 'Can call without exception' => sub {
  $path = is_dev($corpus_dir);
};

isnt( $path, undef, 'path is a dev dir' );
