use 5.010;
use warnings;

use Test::More;

use Data::Dumper;

use constant STRICT => !!grep { exists $ENV{$_} && $ENV{$_} } qw(
  PERL_STRICT
  EXTENDED_TESTING
  AUTHOR_TESTING
  RELEASE_TESTING
);

BEGIN {
  use_ok 'Termbox::PP';
}

sub lives_ok (&$) {
  my ($code, $name) = @_;
  my $error;
  my $ok = eval { $code->(); 1 };
  $error = $@;
  ok($ok, $name);
  diag("Died with: $error") unless $ok;
  return $ok;
}

my $buf;
subtest 'cellbuf->new()' => sub {
  plan tests => 2;
  $buf = new_ok( 'cellbuf' );
  isa_ok($buf, 'cellbuf');
  diag Dumper $buf if STRICT;
};

subtest 'cellbuf->init()' => sub {
  plan tests => 5;
  lives_ok(
    sub {
      $buf->init(3, 3);
    },
    'init'
  );
  is( $buf->{width},  3, 'width' );
  is( $buf->{height}, 3, 'height' );
  is (
    scalar(@{ $buf->{cells} }),
    $buf->{width} * $buf->{height}, 
    'size'
  );
  is_deeply(
    $buf->{cells},
    [ map { Termbox::Cell->new() } 1..$buf->{width}*$buf->{height} ],
    'exists'
  );
  diag Dumper $buf if STRICT;
};

subtest 'cellbuf->clear()' => sub {
  plan tests => 5;
  lives_ok(
    sub {
      my $i;
      $_->[1] = ++$i foreach @{ $buf->{cells} };
      $buf->clear() and die;
    },
    'clear'
  );
  is( $buf->{width},  3, 'width' );
  is( $buf->{height}, 3, 'height' );
  is (
    scalar(@{ $buf->{cells} }),
    $buf->{width} * $buf->{height}, 
    'size'
  );
  is_deeply(
    $buf->{cells},
    [ map { [ ' ', 0, 0 ] }
        1..$buf->{width}*$buf->{height} 
    ],
    'empty'
  );
  diag Dumper $buf if STRICT;
};

subtest 'cellbuf->resize()' => sub {
  plan tests => 12;
  lives_ok(
    sub {
      my $i;
      $_->[1] = ++$i foreach @{ $buf->{cells} };
      $buf->resize(2, 3);
    },
    'resize 2x3'
  );
  diag Dumper $buf if STRICT;
  is (
    scalar(@{ $buf->{cells} }),
    $buf->{width} * $buf->{height}, 
    'size'
  );
  is_deeply(
    $buf->{cells},
    [
      [ ' ', 1, 0 ],
      [ ' ', 2, 0 ],
      [ ' ', 4, 0 ],
      [ ' ', 5, 0 ],
      [ ' ', 7, 0 ],
      [ ' ', 8, 0 ],
    ],
    'equal'
  );

  lives_ok(
    sub {
      $buf->resize(1, 4);
    },
    'resize 1x4'
  );
  diag Dumper $buf if STRICT;
  is (
    scalar(@{ $buf->{cells} }),
    $buf->{width} * $buf->{height}, 
    'size'
  );
  is_deeply(
    $buf->{cells},
    [
      [ ' ', 1, 0 ],
      [ ' ', 4, 0 ],
      [ ' ', 7, 0 ],
      [ ' ', 0, 0 ],
    ],
    'equal'
  );

  lives_ok(
    sub {
      $buf->resize(2, 2);
    },
    'resize 2x2'
  );
  diag Dumper $buf if STRICT;
  is (
    scalar(@{ $buf->{cells} }),
    $buf->{width} * $buf->{height}, 
    'size'
  );
  is_deeply(
    $buf->{cells},
    [
      [ ' ', 1, 0 ],
      [ ' ', 0, 0 ],
      [ ' ', 4, 0 ],
      [ ' ', 0, 0 ],
    ],
    'equal'
  );

  lives_ok(
    sub {
      my $i;
      $_->[1] = ++$i foreach @{ $buf->{cells} };
      $buf->resize(3, 2);
    },
    'resize 3x2'
  );
  diag Dumper $buf if STRICT;
  is (
    scalar(@{ $buf->{cells} }),
    $buf->{width} * $buf->{height}, 
    'size'
  );
  is_deeply(
    $buf->{cells},
    [
      [ ' ', 1, 0 ],
      [ ' ', 2, 0 ],
      [ ' ', 0, 0 ],
      [ ' ', 3, 0 ],
      [ ' ', 4, 0 ],
      [ ' ', 0, 0 ],
    ],
    'equal'
  );
};

done_testing;
