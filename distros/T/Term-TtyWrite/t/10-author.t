#!perl
#
# To use this test, open a terminal and obtain tty of such, then run
# something along the lines of:
#
#   sudo env AUTHOR_TEST_JMATES=/dev/ttyp4 PERL5LIB=$PERL5LIB prove -b t/10-author.t
#
# or as appropriate to obtain your local modules (if any) as well as
# this module; details will vary depending on perlbrew or other
# complications.

use Test::Most;
use Term::TtyWrite;

my $testcount = 2;

SKIP: {
    skip "not author", $testcount unless exists $ENV{AUTHOR_TEST_JMATES};
    my $tty;

    ok( $tty = Term::TtyWrite->new( $ENV{AUTHOR_TEST_JMATES} ),
        "user-supplied tty" );

    diag "PID $$\n";
    sleep 1;

    $tty->write("echo hi $$\n");

    $tty->write_delay( "echo slowly\n", 203 );
    # floats (now) supported, get whacked with the equivalent of int()
    $tty->write_delay( "echo floats\n", 640 / 3.1415926535897932385 );

    use IO::Pty;
    my $faketerm = IO::Pty->new;
    $tty = Term::TtyWrite->new( $faketerm->ttyname );
    my $slave = $faketerm->slave;

    # timeout to prevent IO blocking should this code not be run as root
    # or with appropriate permissions to inject data
    eval {
        local $SIG{ALRM} = sub { die "timeout on readline\n" };
        alarm 7;
        my $send_str = "test test $$\n";
        $tty->write($send_str);
        is( scalar readline $slave, $send_str, "in is the new out" );
        alarm 0;
    };
    if ($@) {
        diag "unexpected failure to read from fake pty: $@";
        print "Bail out!\n";
    }

    # TODO test write_delay via select/poll something something,
    # possibly raw terminal so not line buffered?
}

if ( $ENV{RELEASE_TESTING} and !exists $ENV{AUTHOR_TEST_JMATES} ) {
    diag "reminder: manually run the author tests!!\n";
}

plan tests => $testcount;
