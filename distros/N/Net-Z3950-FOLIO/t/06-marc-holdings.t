# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Net-Z3950-FOLIO.t'

use strict;
use warnings;
use IO::File;
use MARC::Record;
use Cpanel::JSON::XS qw(decode_json);
use Test::More tests => 3;
BEGIN { use_ok('Net::Z3950::FOLIO') };
use Net::Z3950::FOLIO::MARCHoldings qw(insertMARCHoldings);
use DummyRecord;

for (my $i = 1; $i <= 1; $i++) {
    for (my $j = 1; $j <= 2; $j++) {
	my $cfg = new Net::Z3950::FOLIO::Config('t/data/config/foo', 'marcHoldings',
						$j == 2 ? 'fieldPerItem' : undef);
	#use Data::Dumper; $Data::Dumper::INDENT = 2; warn "j=$j, config", Dumper($cfg);
	my $dummyMarc = makeDummyMarc();
	my $expected = readFile("t/data/records/expectedMarc$i" . ($j == 2 ? 'byItem' : '') . ".marc");
	my $folioJson = readFile("t/data/records/input$i.json");
	my $folioHoldings = decode_json(qq[{ "holdingsRecords2": $folioJson }]);
	my $rec = new DummyRecord($folioHoldings, $dummyMarc);
	insertMARCHoldings($rec, $dummyMarc, $cfg);
	my $marcString = $dummyMarc->as_formatted() . "\n";
	is($marcString, $expected, "generated holdings $i match expected MARC");
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
