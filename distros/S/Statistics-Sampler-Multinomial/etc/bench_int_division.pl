use 5.010;
use strict;
use warnings;


BEGIN {
    if ($^O eq 'MSWin32') {
        use Path::Tiny qw /path/;
        use Env qw /@PATH/;
        push @PATH, path($^X)->parent->parent->parent->child ('c/bin')->stringify;
    }
}


say norm();
say integer();
say bitshift();

use Benchmark qw {:all};

cmpthese (
    -3,
    {
        bitshift => \&bitshift,
        integer  => \&integer,
        norm     => \&norm,
        hash     => \&hash(),
    }
);

sub integer {
    use integer;
    my $x = 1500;
    $x /= 2;
    $x /= 2;
    $x /= 2;
    $x /= 2;
    $x /= 2;
}

sub bitshift {
    my $x = 1500;
    $x >>= 1;
    $x >>= 1;
    $x >>= 1;
    $x >>= 1;
    $x >>= 1;
}


sub norm {
    my $x = 1500;
    $x = int ($x / 2);
    $x = int ($x / 2);
    $x = int ($x / 2);
    $x = int ($x / 2);
    $x = int ($x / 2);
}

