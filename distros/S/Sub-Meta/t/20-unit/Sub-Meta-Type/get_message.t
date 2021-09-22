use Test2::V0;

use Sub::Meta;
use Sub::Meta::Type;

my $submeta = Sub::Meta->new(args => ['Int', 'Int'], returns => 'Int');
my $other = Sub::Meta->new(args => ['Str', 'Int'], returns => 'Str');

my $SubMeta = Sub::Meta::Type->new(
    submeta => $submeta,
    submeta_strict_check => 0,
    find_submeta => sub { },
    display_name => 'SubMeta',
);

my $StrictSubMeta = Sub::Meta::Type->new(
    submeta => $submeta,
    submeta_strict_check => 1,
    find_submeta => sub { },
    display_name => 'StrictSubMeta',
);

## no critic (RegularExpressions::ProhibitComplexRegexes);
subtest 'SubMeta' => sub {
    my $message = $SubMeta->get_message($other);
    my @m = split /\n/, $message;

    is @m, 4;
    like $m[0], qr/did not pass type constraint "SubMeta"/;
    like $m[1], qr/Reason\s*:\s*invalid parameters\s*:\s*args\[0\] is invalid. got: Str, expected: Int/;
    like $m[2], qr/Expected\s*:\s*sub\(Int, Int\) => Int/;
    like $m[3], qr/Got\s*:\s*sub\(Str, Int\) => Str/;
};

subtest 'StrictSubMeta' => sub {
    my $message = $StrictSubMeta->get_message($other);
    my @m = split /\n/, $message;

    is @m, 4;
    like $m[0], qr/did not pass type constraint "StrictSubMeta"/;
    like $m[1], qr/Reason\s*:\s*invalid parameters\s*:\s*args\[0\] is invalid. got: Str, expected: Int/;
    like $m[2], qr/Expected\s*:\s*sub\(Int, Int\) => Int/;
    like $m[3], qr/Got\s*:\s*sub\(Str, Int\) => Str/;
};

subtest "empty other/SubMeta" => sub {
    my $message = $SubMeta->get_message(undef);
    my @m = split /\n/, $message;

    is @m, 4;
    like $m[0], qr/^Undef did not pass type constraint "SubMeta"/;
    like $m[1], qr/Reason\s*:\s*other must be Sub::Meta./;
    like $m[2], qr/Expected\s*:\s*sub\(Int, Int\) => Int/;
    like $m[3], qr/Got\s*:\s*/;
};

subtest "empty other/StrictSubMeta" => sub {
    my $message = $StrictSubMeta->get_message(undef);
    my @m = split /\n/, $message;

    is @m, 4;
    like $m[0], qr/^Undef did not pass type constraint "StrictSubMeta"/;
    like $m[1], qr/Reason\s*:\s*other must be Sub::Meta./;
    like $m[2], qr/Expected\s*:\s*sub\(Int, Int\) => Int/;
    like $m[3], qr/Got\s*:\s*/;
};

done_testing;
