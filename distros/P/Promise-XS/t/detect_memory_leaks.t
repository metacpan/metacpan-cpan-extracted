package t::detect_memory_leaks;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use File::Temp;

use Promise::XS;

SKIP: {
    skip 'Windows, XS, fork, and heap allocation don’t get along.', 1 if $^O eq 'MSWin32';

    local $Promise::XS::DETECT_MEMORY_LEAKS = 1;

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
}

#----------------------------------------------------------------------

{
    my @inc_args = map { ( '-I', $_ ) } @INC;

    use File::Spec;
    my ($dir) = File::Spec->splitdir( __FILE__ );
    my $script_path = File::Spec->join( $dir, 'assets', 'deferred_leak.pl' );

    my $got = `$^X @inc_args -Mstrict -Mwarnings -MPromise::XS $script_path`;

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
    my @inc_args = map { ( '-I', $_ ) } @INC;

    use File::Spec;
    my ($dir) = File::Spec->splitdir( __FILE__ );
    my $script_path = File::Spec->join( $dir, 'assets', 'promise_leak.pl' );

    my $got = `$^X @inc_args -Mstrict -Mwarnings -MPromise::XS $script_path`;

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
