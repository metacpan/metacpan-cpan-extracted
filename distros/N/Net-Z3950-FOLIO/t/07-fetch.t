use strict;
use warnings;
use utf8;
use IO::File;
use Cpanel::JSON::XS qw(decode_json);
use MARC::Record;

BEGIN {
    use vars qw(@tests);
    @tests = (
	# format, comp, expectedFile
	[ 'JSON', 'F', 'sorted1.json' ],
	[ 'XML', 'raw', 'inventory1.xml' ],
	[ 'XML', 'usmarc', 'marc1.xml' ],
	[ 'XML', 'opac', 'marc1.opac.xml' ],
	[ 'USMARC', 'F', 'marc1.usmarc' ],
	[ 'USMARC', 'b', 'marc1.usmarc' ],
    );
}

use Test::More tests => 5 + 2*scalar(@tests);
use Test::Differences;
oldstyle_diff;

BEGIN { use_ok('Net::Z3950::FOLIO') };

my $SETNAME = 'dummy';
my $session = mock_session();
ok(defined $session, 'mocked session');

my $args = {
    HANDLE => $session,
    SETNAME => $SETNAME,
    OFFSET => 1,
};

foreach my $test (@tests) {
    my($format, $comp, $expectedFile) = @$test;
    my $format2OID = {
	JSON => Net::Z3950::FOLIO::FORMAT_JSON,
	XML => Net::Z3950::FOLIO::FORMAT_XML,
	USMARC => Net::Z3950::FOLIO::FORMAT_USMARC,
    };
    my $req_form = $format2OID->{$format};

    my $argsCopy = {
	%$args,
	REQ_FORM => $req_form,
	COMP => $comp,
    };

    Net::Z3950::FOLIO::_fetch_handler($argsCopy);
    pass("called _fetch_handler with $format/$comp");

    my $res = $argsCopy->{RECORD};
    if ($req_form eq Net::Z3950::FOLIO::FORMAT_USMARC) {
	my $marc = new_from_usmarc MARC::Record($res);
	$res = $marc->as_formatted() . "\n";
    }

    my $expected = readFile("t/data/fetch/$expectedFile");
    eq_or_diff($res, $expected, "$format/$comp record matched expected value ($expectedFile)");
}


sub mock_session {
    my $server = new Net::Z3950::FOLIO('t/data/config/foo');
    ok(defined $server, 'created Net::Z3950::FOLIO server object');

    my $session = $server->getSession('marcHoldings|postProcess');
    ok(defined $session, 'created session object');

    my $rs = mock_resultSet($session);
    ok(defined $session, 'mocked result-set object');

    $session->{resultsets} = {};
    $session->{resultsets}->{$SETNAME} = $rs;

    return $session;
}


sub mock_resultSet {
    my ($session) = @_;

    my $rs = new Net::Z3950::FOLIO::ResultSet($session, $SETNAME, 'title=water');
    $rs->totalCount(1);
    my $inventoryRecord = decode_json(readFile('t/data/fetch/input-inventory1.json'));
    $rs->insertRecords(0, [ { id => '123', holdingsRecords2 => [ $inventoryRecord ] } ]);

    my $marc = mock_marcRecord();
    $rs->record(0)->{marc} = $marc;

    return $rs;
}


sub mock_marcRecord {
    my $json = readFile('t/data/fetch/input-marc1.json');
    my $sourceRecord = decode_json($json);
    return Net::Z3950::FOLIO::Session::_JSON2MARC($sourceRecord);
}


sub readFile {
    my($fileName) = @_;

    my $fh = IO::File->new();
    $fh->open("<$fileName") or die "can't read '$fileName': $!";
    my $data = join('', <$fh>);
    $fh->close();
    return $data;
}
