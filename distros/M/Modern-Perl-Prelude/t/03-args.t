use v5.30;
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

done_testing;
