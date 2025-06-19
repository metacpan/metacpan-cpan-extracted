use strict;
use warnings;
use IO::File;
use MARC::Record;
use Cpanel::JSON::XS qw(decode_json);
use Net::Z3950::FOLIO::MARCHoldings qw(insertMARCHoldings);
use DummyRecord;

BEGIN {
    use vars qw(@tests);
    @tests = (
	# testName, configName1, configName2
	[ '[regular]', undef ],
	[ 'fieldPerItem', 'fieldPerItem' ],
	[ 'restrictToItem', 'restrictToItem' ],
	[ 'holdingsInEachItem', 'holdingsInEachItem' ],
	[ 'fieldPerItem with holdings', 'fieldPerItem', 'holdingsInEachItem' ],
    );
}

use Test::More tests => 1 + scalar(@tests);

BEGIN { use_ok('Net::Z3950::FOLIO') };

for (my $i = 1; $i <= 1; $i++) {
    foreach my $test (@tests) {
	my($testName, $configName1, $configName2) = @$test;

	my $cfg = new Net::Z3950::FOLIO::Config('t/data/config/foo', 'marcHoldings', $configName1, $configName2);
	#use Data::Dumper; $Data::Dumper::INDENT = 2; warn "config", Dumper($cfg);
	my $dummyMarc = makeDummyMarc();
	my $expected = readFile("t/data/records/expectedMarc$i" . ($configName1 || "") . ($configName2 || "") . ".marc");
	my $folioJson = readFile("t/data/records/input$i.json");
	my $folioHoldings = decode_json(qq[{ "holdingsRecords2": $folioJson }]);
	my $rec = new DummyRecord($folioHoldings, $dummyMarc);
	insertMARCHoldings($rec, $dummyMarc, $cfg, '9876543210');
	my $marcString = $dummyMarc->as_formatted() . "\n";
	is($marcString, $expected, "generated holdings $i: $testName match expected MARC");
    }
}


### Copied from test 03: maybe move these out to shared utils?

sub makeDummyMarc {
    my $marc = new MARC::Record();
    $marc->leader('03101cam a2200505Ii 4500');
    $marc->append_fields(
	new MARC::Field('007', 'cr cnu---unuuu'),
	new MARC::Field('008', '1234567890123456789012345678901'),
	new MARC::Field('845', '#', '#',
			'3' => 'Bituminous Coal Division and National Bituminous Coal Commission Records',
			'a' => '"No information obtained from a producer disclosing cost of production or sales realization shall be made public without the consent of the producer from whom the same shall have been obtained";',
			'c' => '50 Stat.88.',
	)
    );
    return $marc;
}


sub readFile {
    my($fileName) = @_;

    my $fh = IO::File->new();
    $fh->open("<$fileName") or die "can't read '$fileName': $!";
    my $data = join('', <$fh>);
    $fh->close();
    return $data;
}
