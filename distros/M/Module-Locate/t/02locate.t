use Test::More tests => 27;

use strict;
use warnings;

use lib 't/';
use IO::File;
use File::Spec;

require Module::Locate;

Module::Locate->import(qw/ locate acts_like_fh /);

# no. 1, 2
can_ok(__PACKAGE__, 'locate');
can_ok(__PACKAGE__, 'acts_like_fh');

my($test_mod, $test_fn) = (
  'MLtest::hereiam', File::Spec->catfile(qw/t MLtest hereiam.pm/)
);

{
  my $path = locate($test_mod);
  
  # no. 3, 4
  ok( defined $path, "\$path was assigned something");
  like( $path, qr{\Q$test_fn\E\z},
        "module found in predicted place: $path");

  {
    local @INC = @INC[1 .. $#INC];

    $path = locate($test_mod);

    # no. 5
    ok(!$path, "locate() couldn't find what wasn't there");
  }
}


{
  my $path = locate($test_mod);
  
  # no. 3, 4
  ok( defined $path, "\$path was assigned something");
  like( $path, qr{\Q$test_fn\E\z},
        "module found in predicted place: $path");

  {
    local @INC = @INC[1 .. $#INC];

    $path = locate($test_mod);

    # no. 5
    ok(!$path, "locate() couldn't find what wasn't there");
  }
}

{
  unshift @INC => sub {
    local *FH;
    open(FH => $test_fn) or die "ack: $! [$test_fn]\n";
    *FH;
  };

  # no. 6, 7
  my $f;
  ok( $f = locate($test_mod), 'simple FH coderef in INC' );
  ok( acts_like_fh($f), "$f is deigned to be a filehandle");
  
  close $f;

  $INC[0] = sub { IO::File->new($test_fn) };
  
  # no. 8, 9
  ok( $f = locate($test_mod), 'IO::File coderef in INC');
  ok( acts_like_fh($f), "$f is deigned to be a filehandle");

  close $f;

  $INC[0] = sub { bless [], 'MLtest::iohandle' };
  
  # no. 10, 11
  ok( $f = locate($test_mod), 'IO::Handle object coderef in INC');
  ok( acts_like_fh($f), "$f is deigned to be a filehandle");

  $INC[0] = sub { bless [], 'MLtest::overloaded' };
  
  # no. 12, 13
  ok( $f = locate($test_mod), 'overloaded object coderef in INC');
  ok( acts_like_fh($f), "$f is deigned to be a filehandle");

  $INC[0] = sub { bless [], 'MLtest::nought' };
  
  undef $f;
  # no. 14, 15
  eval { $f = locate($test_mod) };
  like( $@, qr/invalid \@INC/, 'b0rken object coderef in INC');
  ok( !acts_like_fh($f), "\$f is not a filehandle");
}

{
  $INC[0] = [ sub { IO::File->new($test_fn) } ];
  
  my $f;

  # no. 16, 17
  ok( $f = locate($test_mod), 'IO::File arrayrefin INC');
  ok( acts_like_fh($f), "$f is deigned to be a filehandle");

  close $f;
  $INC[0] = [ sub { "fooey" } ];
  undef $f;

  # no. 18, 19
  eval { $f = locate($test_mod) };
  like( $@, qr/invalid \@INC/, 'b0rken arrayref return in INC');
  ok( !acts_like_fh($f), "\$f is not a filehandle");
}

{
  $INC[0] = bless [], 'MLtest::object';
  
  my $f;

  # no. 20, 21
  ok( $f = locate($test_mod), 'IO::File object INC');
  ok( acts_like_fh($f), "$f is deigned to be a filehandle");

  close $f;
  $INC[0] = bless [], 'MLtest::b0rkobj';
  undef $f;

  # no. 22, 23
  eval { $f = locate($test_mod) };
  like( $@, qr/invalid \@INC/, 'b0rken arrayref return in INC');
  ok( !acts_like_fh($f), "\$f is not a filehandle");
}

{
  # no. 24
  local *0 = *0;
  open 0;
  ok( acts_like_fh(*0), '*0 deigned to be a filehandle');
}

{
  package MLtest::iohandle;

  use base 'IO::Handle';

  package MLtest::overloaded;

  use overload (
    '<>'     => sub { },
    fallback => 1,
  );

  package MLtest::object;

  sub MLtest::object::INC { IO::File->new($test_fn) }

  package MLtest::b0rkobj;

  sub MLtest::b0rkobj::INC { 'wah wah waaaah' }
  
  package MLtest::nought;
}
