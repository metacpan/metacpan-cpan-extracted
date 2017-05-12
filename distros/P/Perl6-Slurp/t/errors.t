use Test::More "no_plan";
BEGIN {use_ok(Perl6::Slurp)};

my $desc;
sub TEST { $desc = $_[0] };

TEST "can't slurp in void context";

eval{;slurp $0;1}
    ? ok 0, $desc
    : like $@,
           qr/void context/,
           $desc;

TEST "shouldn't be able to slurp non-existent file";

eval{slurp "non-existent file"}
    ? ok 0, $desc
    : like $@,
           qr/^Can't open 'non-existent file'/,
           $desc;

TEST "shouldn't be able to slurp failed pipe";

if ($^O ne 'MSWin32') {
    eval{slurp "-|", "non-existent_prog"}
        ? ok 0, $desc
        : like $@,
            qr/^Can't open '-|non-existent_prog'/,
            $desc;
}

TEST "shouldn't be able to read from unreadable filehandle";
open *FILE, ">-";

slurp(\*FILE)
    ? ok 0, $desc
    : ok 1, $desc;
