
use Test::More tests => 21;

# this script is for testing Term::Size default behavior

BEGIN { use_ok('Term::Size', qw( chars pixels )); }

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

{
    pipe my $rd, my $wr;
    my @chars = chars $rd;
    ok(!@chars, 'chars return () on error (list context)');
    my $chars = chars $rd;
    is($chars, undef, 'chars return undef on error (scalar context)');

    my @pixels = pixels $rd;
    ok(!@pixels, 'pixels return () on error (list context)');
    my $pixels = pixels $rd;
    is($pixels, undef, 'pixels return undef on error (scalar context)');
}

if (-t STDIN) {
    # this is not at test, only a show-off
    my @chars = chars;
    my @pixels = pixels;
    diag("This terminal is $chars[0]x$chars[1] characters,"
         . " and $pixels[0]x$pixels[1] pixels."
    );

}
