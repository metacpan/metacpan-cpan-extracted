
use Test::More;

# this script is for testing Term::Size::Any default behavior
use Module::Load::Conditional qw( can_load );
BEGIN {
  if ( can_load( modules => { 'Term::Size::Perl' => 0 } ) ) {
      plan( tests => 17 );
  } else {
      plan( skip_all => 'Term::Size::Perl not found' );
  }
}

BEGIN { use_ok('Term::Size::Any', qw( chars pixels )); }

my @handles = (
    # name args handle
    [ 'implicit STDIN', [], *STDIN ], # default: implicit STDIN
    [ 'STDIN', [*STDIN], *STDIN ],
    [ 'STDERR', [*STDERR], *STDERR ],
    [ 'STDOUT', [*STDOUT], *STDOUT ],
);

for (@handles) {
    my $h_name = $_->[0];
    my @args = @{$_->[1]};
    my $h = $_->[2];

    SKIP: {
    skip "$h_name is not tty", 4 unless -t $h;

    my @chars = chars @args;
    is(scalar @chars, 2, "$h_name: chars return (cols, rows) - $h_name");

    my $cols = chars @args;
    is($cols, $chars[0], "$h_name: chars return cols");

    my @pixels = pixels @args;
    is(scalar @pixels, 2, "$h_name: pixels return (x, y)");

    my $x = pixels @args;
    is($x, $pixels[0], "$h_name: pixels return x");

  }

}
