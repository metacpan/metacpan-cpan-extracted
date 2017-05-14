use strict;
use warnings;

use T2::B 'Extended';

my ($file, $line) = (__FILE__, __LINE__ + 2);
t2->like(
    t2->dies(sub { T2->foo }),
    qr{Can't locate object method "foo" via package "T2" at \Q$file\E line $line},
    "Autoload dies on unknown class method"
);

$line = __LINE__ + 2;
t2->like(
    t2->dies(sub { t2->foo }),
    qr{No such function 'foo' at \Q$file\E line $line},
    "Autoload dies on un-imported function"
);

t2->ok(t2->lives(sub{ t2->DESTROY }), "DESTROY is special cased");

my (@args, @caller) = @_;
sub trace {
    @args = @_;
    @caller = caller(0);
    return 'xxx';
}

# Warning, implementation details:
{
    my $stash = ${t2()};
    no strict 'refs';
    *{"$stash\::trace"} = \&trace;
}

$line = __LINE__ + 1;
t2->is(t2->trace(qw/a b c/), 'xxx', "got expected return value");
t2->is(\@args, [qw/a b c/], "got args (no self)");
t2->like(
    \@caller,
    [__PACKAGE__, __FILE__, $line, 'main::trace'],
    "Got proper caller details"
);

t2->done_testing;
