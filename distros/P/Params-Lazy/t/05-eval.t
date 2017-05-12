use strict;
use warnings;

use Test::More;

if ( $] < 5.010 && ($ENV{PERL_DESTRUCT_LEVEL} || 0) > 0 ) {
    plan skip_all => "Segfaults during global destruction on 5.8 if PERL_DESTRUCT_LEVEL is set";
}

plan tests => $] >= 5.016 ? 20 : 19;

use Params::Lazy; # import the custom-op force()

sub lazy_run { force $_[0] };

use Params::Lazy lazy_run => '^';

sub runs_eval {
    my $msg = "eval q{ die } inside a sub";
    eval qq{ die '$msg' };
    like($@, qr/\Q$msg/, $msg);

    $msg = "do { eval { die } } inside a sub";
    do { eval { die $msg } };
    like($@, qr/\Q$msg/, $msg);
    
    $msg = "eval { die } inside a sub";
    eval { die $msg };
    like($@, qr/\Q$msg/, $msg);
    
    is(
        eval "10",
        10,
        "eval q{lives} inside a sub"
    );
}

lazy_run runs_eval();
pass("Survived this far without crashing");

is(
    lazy_run(eval q{ 10 }),
    10,
    "lazy_run eval q{ lives } works"
);

my $msg = "eval q{die}";
lazy_run eval qq{ die "$msg" };
like($@, qr/\Q$msg/, $msg);

if ( $] >= 5.016 ) {
    BEGIN {
        eval {
            require feature;
            feature->import('evalbytes');
        } or eval q{sub evalbytes ($) {}};
    }
    no warnings 'ambiguous';
    $msg = "evalbytes q{die}";
    lazy_run evalbytes qq{ die "$msg" };
    like($@, qr/\Q$msg/, $msg);
}

$msg = "eval { eval q{die}; foo; die }";
lazy_run eval {
    eval 'die q{Inner}';
    like($@, qr/Inner/, "eval q{die} inside a delayed eval {}");
    die $msg;
};
TODO: {
    local $TODO = "Broken on 5.8" if $] < 5.010;
    like($@, qr/\Q$msg/, $msg);
}

$msg = "do { eval {die}; foo() }";
lazy_run do {
    eval { die $msg };
    pass("Code after an eval { die } inside a do.");
};
like($@, qr/\Q$msg/, $msg);

$msg = "eval {die}";
lazy_run eval {
    die $msg
};
like($@, qr/\Q$msg/, $msg);

TODO: {
    local $TODO = "Broken on 5.8" if $] < 5.010;
    local $_ = "doof";
    my $ret = lazy_run eval { eval 'die'; eval 'qq{_${_}_}' };
    is($@, "", "nested delayed evals work");
    is($ret, "_doof_", "...and gets the correct return value");
}

SKIP: {
    skip("Crashes on 5.8", 11) if $] < 5.010;
    
    $msg = "map eval { die }, 1..10";
    lazy_run map eval { die $msg }, 1..10;
    like($@, qr/\Q$msg/, $msg);

    $msg = "map { eval {die}; \$_ } 1..10";
    my @ret = lazy_run map { eval { die $msg }; $_ } 1..10;
    like($@, qr/\Q$msg/, $msg);
    is_deeply(\@ret, [1..10]);

    $msg = "map { eval 'die'; eval qq{_\${_}_} } 1..10";
    @ret = lazy_run map { eval { eval 'die'; eval 'qq{_${_}_}' }; } 1..10;
    is($@, '', $msg);
    is_deeply(\@ret, [map "_${_}_", 1..10]);
}
