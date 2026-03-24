use v5.26;
use strict;
use warnings;
use utf8;

use Test::More;

my $ok_utf8 = eval <<'PERL';
    package Local::Prelude::Args::Utf8;

    use Modern::Perl::Prelude '-utf8';

    our $OK;

    my $ёж = "ёж";
    $OK = ($ёж eq "ёж") ? 1 : 0;

    1;
PERL

ok($ok_utf8, 'use Modern::Perl::Prelude -utf8 compiles')
    or diag $@;

{
    no warnings 'once';
    ok($Local::Prelude::Args::Utf8::OK, '-utf8 enables utf8 source semantics');
}

my $ok_no_utf8 = eval <<'PERL';
    package Local::Prelude::Args::NoUtf8;

    use Modern::Perl::Prelude '-utf8';
    no Modern::Perl::Prelude '-utf8';

    1;
PERL

ok($ok_no_utf8, 'no Modern::Perl::Prelude -utf8 accepts known option')
    or diag $@;

my $ok_hash_utf8 = eval <<'PERL';
    package Local::Prelude::Args::HashUtf8;

    use Modern::Perl::Prelude { utf8 => 1 };

    our $OK;

    my $ёж = "ёж";
    $OK = ($ёж eq "ёж") ? 1 : 0;

    1;
PERL

ok($ok_hash_utf8, 'hash-style utf8 option compiles')
    or diag $@;

{
    no warnings 'once';
    ok($Local::Prelude::Args::HashUtf8::OK, 'hash-style utf8 enables utf8 source semantics');
}

my $ok_hash_no_utf8 = eval <<'PERL';
    package Local::Prelude::Args::HashNoUtf8;

    use Modern::Perl::Prelude { utf8 => 1 };
    no Modern::Perl::Prelude { utf8 => 1 };

    1;
PERL

ok($ok_hash_no_utf8, 'hash-style no accepts known option')
    or diag $@;

my $ok_always_true_flag = eval <<'PERL';
    package Local::Prelude::Args::AlwaysTrueFlag;

    use Modern::Perl::Prelude '-always_true';

    1;
PERL

ok($ok_always_true_flag, 'flag-style always_true option compiles')
    or diag $@;

my $ok_always_true_hash = eval <<'PERL';
    package Local::Prelude::Args::AlwaysTrueHash;

    use Modern::Perl::Prelude { always_true => 1 };

    1;
PERL

ok($ok_always_true_hash, 'hash-style always_true option compiles')
    or diag $@;

my $ok_bad_use = eval <<'PERL';
    package Local::Prelude::Args::BadUse;

    use Modern::Perl::Prelude '-bogus';

    1;
PERL

ok(!$ok_bad_use, 'unknown option in use dies');
like(
    $@,
    qr/^Modern::Perl::Prelude: unknown import option "-bogus"/,
    'unknown option in use gives expected error',
);

my $ok_bad_no = eval <<'PERL';
    package Local::Prelude::Args::BadNo;

    use Modern::Perl::Prelude;
    no Modern::Perl::Prelude '-bogus';

    1;
PERL

ok(!$ok_bad_no, 'unknown option in no dies');
like(
    $@,
    qr/^Modern::Perl::Prelude: unknown import option "-bogus"/,
    'unknown option in no gives expected error',
);

my $ok_bad_hash_key = eval <<'PERL';
    package Local::Prelude::Args::BadHashKey;

    use Modern::Perl::Prelude { bogus => 1 };

    1;
PERL

ok(!$ok_bad_hash_key, 'unknown hash-style key dies');
like(
    $@,
    qr/^Modern::Perl::Prelude: unknown import key "bogus"/,
    'unknown hash-style key gives expected error',
);

my $ok_mixed = eval <<'PERL';
    package Local::Prelude::Args::Mixed;

    use Modern::Perl::Prelude(
        '-utf8',
        {},
    );

    1;
PERL

ok(!$ok_mixed, 'mixed flag-style and hash-style args die');
like(
    $@,
    qr/^Modern::Perl::Prelude: hash-style arguments must be passed as a single hash reference/,
    'mixed args give expected error',
);

my $ok_conflict_flags = eval <<'PERL';
    package Local::Prelude::Args::ConflictFlags;

    use Modern::Perl::Prelude qw(
        -class
        -corinna
    );

    1;
PERL

ok(!$ok_conflict_flags, 'conflicting -class and -corinna flags die');
like(
    $@,
    qr/^Modern::Perl::Prelude: options "-class" and "-corinna" are mutually exclusive/,
    'flag conflict gives expected error',
);

my $ok_conflict_hash = eval <<'PERL';
    package Local::Prelude::Args::ConflictHash;

    use Modern::Perl::Prelude {
        class   => 1,
        corinna => 1,
    };

    1;
PERL

ok(!$ok_conflict_hash, 'conflicting class/corinna hash-style args die');
like(
    $@,
    qr/^Modern::Perl::Prelude: options "-class" and "-corinna" are mutually exclusive/,
    'hash-style conflict gives expected error',
);

done_testing;
