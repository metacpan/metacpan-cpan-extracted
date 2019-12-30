package t::detect_memory_leaks;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use File::Temp;

use Promise::XS;

my $deferred = Promise::XS::deferred();

my $ar = [ $deferred ];
push @$ar, $ar;

my $fh = File::Temp::tempfile();

my $pid = fork or do {
    close STDERR;
    open *STDERR, '>>&=', $fh;

    exit;
};

waitpid $pid, 0;

is(
    (stat $fh)[7],
    0,
    'no warning on leak from subprocess',
) or do {
    sysseek $fh, 0, 0;

    my $buf = q<>;
    1 while sysread( $fh, $buf, 512, length $buf );

    diag $buf;
};

@$ar = ();

#----------------------------------------------------------------------

{
    my @inc_args = map { "-I$_" } @INC;

    my $got = `$^X @inc_args -Mstrict -Mwarnings -MPromise::XS -e'\$Promise::XS::DETECT_MEMORY_LEAKS = 1; open STDERR, ">>&=", *STDOUT; my \$deferred = Promise::XS::deferred(); my \$ar = [ \$deferred ]; push \@\$ar, \$ar;'`;

    warn "CHILD_ERROR: $?" if $?;

    cmp_deeply(
        $got,
        all(
            re( qr<Promise::XS::Deferred=> ),
            re( qr<destr>i ),
        ),
        'warning about deferred object that persists to global destruction',
    );
}

#----------------------------------------------------------------------

{
    my @inc_args = map { "-I$_" } @INC;

    my $got = `$^X @inc_args -Mstrict -Mwarnings -MPromise::XS -e'\$Promise::XS::DETECT_MEMORY_LEAKS = 1; open STDERR, ">>&=", *STDOUT; my \$deferred = Promise::XS::deferred(); my \$p = \$deferred->promise(); undef \$deferred; my \$ar = [ \$p ]; push \@\$ar, \$ar;'`;

    warn "CHILD_ERROR: $?" if $?;

    cmp_deeply(
        $got,
        all(
            re( qr<Promise::XS::Promise=> ),
            re( qr<destr>i ),
        ),
        'warning about promise object that persists to global destruction',
    );
}

done_testing;

1;
