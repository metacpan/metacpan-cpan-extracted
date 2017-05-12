#!perl

my $n_tests = 0;
use Test::More;


{
    package T1;
    use Test::More;

    # auxiliary test functions. I've seen some like that somewhere...

    sub dies_like {
        my ($code, $expect, $name) = @_;
        eval { $code->() };
        like($@, $expect, $name);
    }

    sub warns_like {
        my ($code, $expect, $name) = @_;
        my $msg;
        local $SIG{__WARN__} = sub { $msg = shift };
        $code->();
        like($msg, $expect, $name);
    }

    BEGIN {
        print "$_\n" for @INC;
    }
    use Sub::Implant;

    sub lala { (caller 0)[3] }

    # basic functionality
    $n_tests += 7;

    implant 'T1::One::lala', \ &lala; # two-arg call
    ok(defined &T1::One::lala, "Sub lala defined");
    is(T1::One::lala(), 'T1::lala', "Non anon name unchanged");

    my $anon = sub { (caller 0)[3] };
    implant 'T1::One', 'lulu', $anon; # three-arg call

    ok(defined &T1::One::lulu, "Sub lulu defined");
    is(T1::One::lulu(), 'T1::One::lulu', "Anon name changed");
    is($anon->(), 'T1::One::lulu', "Change reflected in original");

    implant 'T1::One', 'lele', sub { (caller 0)[3] }, name => 0;
    is(T1::One::lele(), 'T1::__ANON__', 'Anon name change suppressed');

    implant 'lola', \ &lala;
    ok(defined &lola, "Default package is current package");

    # carping/croaking behavior
    $n_tests += 6;

    dies_like(
        sub { implant },
        qr/Name and subref/,
        'Dies without argument'
    );

    dies_like(
        sub { implant \ &lala },
        qr/Name and subref/,
        'Dies with one argument'
    );

    dies_like(
        sub { implant qw(hi ha ho) },
        qr/No subref given/,
        'Dies without subref'
    );

    dies_like(
        sub { implant 'T1::One', 'qual::name', \ &lala },
        qr/package and qualified name/,
        'Dies with double package specification'
    );

    sub T1::One::schonda {}
    warns_like(
        sub { implant 'T1::One::schonda', \ &lala },
        qr/redefined/,
        'redefine warning'
    );

    warns_like(
        sub { implant 'T1::One::schonda', \ &lala, redef => 1 },
        qr/^$/,
        'redefine warning suppressed'
    );
}

{
    $n_tests += 2;
    package T2;
    use Test::More;
    use Sub::Implant qw(infuse);

    my %exports = (
        hick => sub { 'hick' },
        hack => sub { 'hack' },
    );

    infuse 'T2::One', \ %exports;

    ok defined(&T2::One::hick), "infuse implants 'hick'";
    ok defined(&T2::One::hack), "infuse implants 'hack'";
}

done_testing $n_tests;

