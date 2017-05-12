use strict;
use warnings;

use Carp qw(carp croak confess);
use Test::More tests => 35;

use Params::Lazy lazy_death => '^;$';
sub lazy_death {
    eval { force($_[0]) };
    return $@ unless $_[1];
    force($_[0]);
};

my $w = '';
local $SIG{__WARN__} = sub { $w .= shift };

sub dies      { die "die in sub"           }
# test carp() even though it's not really a death, since it 
# tends to give "Attempt to free unreferenced scalar" warnings
sub carps     { carp("carp in sub")       }
sub croaks    { croak("croak in sub")     }
sub confesses { confess("confess in sub") }
sub xs_croaks { force(1) }

like lazy_death(die("bare die")), qr/bare die/, "lazy_death die()";

$w = "";
is(
    lazy_death(carp("bare carp")),
    '',
    "a bare carp can be delayed"
);
like(
    $w, 
    qr/bare carp/,
    "...and it throws the correct warning"
);
unlike(
    $w,
    qr/Attempt to /,
    "...and no attempt to do anything with unreferenced/freed scalars"
);

like
    lazy_death(croak("bare croak")),
    qr/bare croak/,
    "lazy_death croak()";
like
    lazy_death(confess("bare confess")),
    qr/bare confess/,
    "lazy_death confess()";

my $xs_croak_re = qr/\Qforce() requires a delayed argument/;
like
    lazy_death(force(1)),
    $xs_croak_re,
    "lazy_death force()";

like
    lazy_death(dies()),
    qr/die in sub/,
    "lazy_death(dies())";
$w = "";
is(
    lazy_death(carps()),
    '',
    "a sub that carps can be delayed"
);
like(
    $w, 
    qr/carp in sub/,
    "...and it throws the correct warning"
);
unlike(
    $w,
    qr/Attempt to /,
    "...and no attempt to do anything with unreferenced/freed scalars"
);


like
    lazy_death(croaks()),
    qr/croak in sub/,
    "lazy_death(croaks())";
like
    lazy_death(confesses()),
    qr/confess in sub/,
    "lazy_death(confesses())";

like
    lazy_death(xs_croaks()),
    $xs_croak_re,
    "xs_croaks()";

use Params::Lazy lazy_run => '^';
sub lazy_run { force shift }

sub call_lazy_death {
    eval { lazy_death die("bare death"), 1 };
    like $@,
         qr/bare death/s,
         "eval { lazy_death(die()) }";

    eval { lazy_death dies(),            1 };
    like $@,
         qr/die in sub/s,
         "eval { lazy_death(dies()) }";

    $w = "";
    eval { lazy_death carps(), 1 };
    is($@, "", "eval { lazy_death carps() }");
    like($w, qr/carp in sub.*call_lazy_death/s);

    eval { lazy_death croaks(),          1 };
    like $@,
         qr/croak in sub.*call_lazy_death/s,
         "eval { lazy_death(croak()) }";

    eval { lazy_death confesses(),       1 };
    like $@,
         qr/confess in sub.*call_lazy_death/s,
         "eval { lazy_death(confess()) }";
         
    eval { lazy_death xs_croaks(),       1 };
    like $@,
         $xs_croak_re,
         "eval { lazy_death xs_croaks() }";

    eval { lazy_run(lazy_run(lazy_run force(1))) };
    like $@,
        $xs_croak_re,
        "lazy_run(lazy_run(lazy_run force(1))) gives the proper exception";         
         
    SKIP: {
        skip("Exception handling doesn't quite work on 5.8", 2);
    my $lex = 10;
    my $ret = lazy_run(lazy_run(lazy_run do {
        eval { force(1) };
        like $@,
         qr/\Qforce() requires a delayed argument/,
         "lazy_run(lazy_run(lazy_run do { eval {...} })) gives the proper exception";
         
        sub { "lex: $lex" }->();
    }));
    is($ret, "lex: 10", "..and got the right return value");
    }
}

# Do this twice; in some dev versions this caused segfaults,
# e.g. when cx->blk_sub.argarray was missing the REFCNT++
call_lazy_death();
call_lazy_death();

pass("Survived this far");
