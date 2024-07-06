# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Net-Z3950-FOLIO.t'

### From discussion with Wayne:
#
# Soon I will write tests for the FOLIO Z39.50 server, verifying that
# the pipeline (JSON records merged into one, converted to XML,
# transformed via XSLT to MARCXML, rendered as ISO2709 records)
# continues to give the expected results. The most convenient way to
# do this would be by fetching well-known records from a reliable
# FOLIO service. Does such a service exist, and what is the best way
# to find the well-known records?
#
# What about using records that are in the inventory-storage
# schema(s)? Like in
# https://github.com/folio-org/mod-inventory-storage/tree/master/sample-data/instances

use strict;
use warnings;
use IO::File;
use MARC::Record;
use Cpanel::JSON::XS qw(decode_json);
use Test::More tests => 5;
use Test::Differences;
oldstyle_diff;
BEGIN { use_ok('Net::Z3950::FOLIO') };
use Net::Z3950::FOLIO::OPACXMLRecord;
use DummyRecord;

# Values taken from some random USMARC record
my $dummyMarc = makeDummyMarc();

for (my $testNo = 1; $testNo <= 4; $testNo++) {
    my $i = $testNo eq 4 ? 3 : $testNo;
    my $dummyCfg = $testNo ne 4 ? undef : {
	fieldDefinitions => {
	    circulation => {
		availableThru => 'temporaryLocation.servicePoints[0].discoveryDisplayName',
	    }
	},
    };
    my $expected = readFile("t/data/records/expectedOutput$testNo.xml");
    my $folioJson = readFile("t/data/records/input$i.json");
    my $folioHoldings = decode_json(qq[{ "holdingsRecords2": $folioJson }]);
    my $rec = new DummyRecord($folioHoldings, $dummyMarc, $dummyCfg);
    # use Data::Dumper; $Data::Dumper::INDENT = 2; warn "Config =", Dumper($rec->rs()->session()->{cfg});
    my $holdingsXml = Net::Z3950::FOLIO::OPACXMLRecord::makeOPACXMLRecord($rec, $dummyMarc);
    eq_or_diff($holdingsXml, $expected, "generated holdings $i match expected XML");
}


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
