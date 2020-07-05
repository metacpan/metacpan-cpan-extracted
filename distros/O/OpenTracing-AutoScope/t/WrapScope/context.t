use Test::Most tests => 3;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope qw/context/;

my $was_void;

sub context {
    if (not defined wantarray) {
        $was_void = 1;
        return;
    }
    if (wantarray) {
        return (1, 2, 3);
    }
    return 'X';
}

context();
ok $was_void, 'void context';
is scalar context(), 'X', 'scalar context';
is_deeply [ context() ], [ 1, 2, 3 ], 'list context';
