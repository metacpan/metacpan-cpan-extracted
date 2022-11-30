# Note that this test currently emits a harmless, though alarming, message:
#	Unknown argument "limit" on field "T_instance.holdingsRecords2".
# This is due to the Index Data FOLIO testing server being out of
# date. It should be cleared up in early 2022.

use strict;
use warnings;
use Test::More tests => 5;
use Test::Differences;
oldstyle_diff;

BEGIN { use_ok('Net::Z3950::FOLIO') };

SKIP: {
    skip('zoomsh not available', 4) if system('zoomsh quit') ne 0;

    # This test runs perfectly well as
    #	perl -I lib t/08-short-session.t
    # But for reasons that I can't begin to understand, it goes mad
    # when run under the test-harness library. The test runs to
    # successful completion, but then tries to run again -- which
    # times out and fails, because the forked server will only handle
    # one session. So we don't even try for now.
    skip('cannot run under Test::Harness', 4) if $ENV{PERL_DL_NONLAZY};

    my $pid = fork();
    exit 'Uh-oh! $!' if $pid < 0;

    if ($pid == 0) {
	# Child
	$ENV{OKAPI_INDEXDATA_PASSWORD} = 'swordfish';
	my $service = new Net::Z3950::FOLIO('etc/config');
	$service->launch_server('z2folio', '-1', '-f', 't/data/config/yazgfs-9996.xml');
    }

    # Parent
    sleep 1; # Allow time for server to start up
    ok(1, 'waited for service');
    my $res = `zoomsh -e "open \@:9996/indexdata|marcHoldings" "find \@attr 1=12 in00000000007" "set preferredRecordSyntax opac" "show 0" quit 2>&1`;
    ok(1, 'ran a session');
    my @lines = split("\n", $res);
    shift(@lines); # remove "@:9996/snapshot|marcHoldings: 1 hits"
    shift(@lines); # remove "0 database= syntax=OPAC schema=unknown"
    $res = join("\n", @lines) . "\n";
    ok(1, 'extracted OPAC XML');

    my $expectedFile = 'in00000000007-opac.xml';
    my $expected = readFile("t/data/fetch/$expectedFile");
    eq_or_diff($res, $expected, "OPAC record matches expected value ($expectedFile)");
    exit;
}


sub readFile {
    my($fileName) = @_;

    my $fh = IO::File->new();
    $fh->open("<$fileName") or die "can't read '$fileName': $!";
    my $data = join('', <$fh>);
    $fh->close();
    return $data;
}
