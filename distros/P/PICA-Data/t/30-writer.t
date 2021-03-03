use strict;
use warnings;
use utf8;

use Test::More;
use Test::XML;

use PICA::Data qw(pica_writer pica_parser);
use PICA::Writer::Plain;
use PICA::Writer::Plus;
use PICA::Writer::XML;
use PICA::Writer::PPXML;
use PICA::Parser::PPXML;
use PICA::Writer::JSON;
use PICA::Writer::Generic;
use PICA::Schema;

use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);
use Scalar::Util qw(reftype);
use JSON::PP;

my @pica_records = (
    [['003@', '', '0', '1041318383'], ['021A', '', 'a', 'Hello $¥!'],],
    {record => [['028C', '01', d => 'Emma', a => 'Goldman']]}
);

note 'PICA::Writer::Plain';

{
    my ($fh, $filename) = tempfile();
    my $writer = pica_writer('plain', fh => $fh);
    foreach my $record (@pica_records) {
        $writer->write($record);
    }
    close $fh;

    my $PLAIN = <<'PLAIN';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

    my $out = do {local (@ARGV, $/) = $filename; <>};
    is $out, $PLAIN, 'Plain writer';

    (undef, $filename) = tempfile(OPEN => 0);
    pica_writer('plain', fh => $filename);
    ok -e $filename, 'write to file';
}

sub write_result {
    my ($type, $options, @records) = @_;

    my ($fh, $filename) = tempfile();
    my $writer = pica_writer($type, fh => $fh, %$options);

    foreach my $record (@records) {
        $writer->write($record);
    }
    $writer->end;
    close $fh;

    return do {local (@ARGV, $/) = $filename; <>};
}

note 'PICA::Writer::Plus';

{
    my $out = write_result('plus', {}, @pica_records);
    my $PLUS = <<'PLUS';
003@ 01041318383021A aHello $¥!
028C/01 dEmmaaGoldman
PLUS

    is $out, $PLUS, 'Plus Writer';
}

note 'PICA::Writer::XML';

{
    my $schema = {
        fields => {
            '003@' => {label => 'PPN', url => 'http://example.org/'},
            '028C/01' => {subfields => {d => {pica3 => ', '}}}
        }
    };
    my $out = write_result('xml', { schema => $schema }, @pica_records);
    my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>

<collection xmlns="info:srw/schema/5/picaXML-v1.0">
  <record>
    <datafield tag="003@" label="PPN" url="http://example.org/">
      <subfield code="0">1041318383</subfield>
    </datafield>
    <datafield tag="021A">
      <subfield code="a">Hello $¥!</subfield>
    </datafield>
  </record>
  <record>
    <datafield tag="028C" occurrence="01">
      <subfield code="d" pica3=", ">Emma</subfield>
      <subfield code="a">Goldman</subfield>
    </datafield>
  </record>
</collection>
XML

    is $out, $xml, 'XML writer';
}

{
    {

        package MyStringWriter;
        sub print {$_[0]->{out} .= $_[1]}
    }

    my $string = bless {}, 'MyStringWriter';

    my $writer = PICA::Writer::XML->new(fh => $string);
    $writer->write($_) for map {bless $_, 'PICA::Data'} @pica_records;
    $writer->end;
    like $string->{out}, qr{^<\?xml.+collection>$}sm,
        'XML writer (to object)';
}

note 'PICA::Writer::PPXML';

{
    my $parser = pica_parser('PPXML' => 't/files/slim_ppxml.xml');
    my $record;
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::PPXML->new(fh => $fh);
    while ($record = $parser->next) {
        $writer->write($record);
    }
    $writer->end;
    close $fh;

    my $out = do {local (@ARGV, $/) = $filename; <>};
    my $in = do {local (@ARGV, $/) = 't/files/slim_ppxml.xml'; <>};

    is_xml($out, $in, 'PPXML writer');
}

note 'PICA::Writer::Generic';

{
    my $out = write_result('generic', {
        us => "#",
        rs => "%",
        gs => "\n\n"
    }, @pica_records);
    my $PLUS = <<'PLUS';
003@ #01041318383%021A #aHello $¥!%

028C/01 #dEmma#aGoldman%

PLUS

    is $out, $PLUS, 'Generic Writer';
}

{
    my $out = write_result('generic', {}, @pica_records);
    is $out, '003@ 01041318383021A aHello $¥!028C/01 dEmmaaGoldman',
        'Generic Writer (default)';

    my $binary = write_result('binary', {}, @pica_records);
    is $binary, $out, 'Binary Writer (default=generic)';
}

note 'PICA::Writer::JSON';
{
    my $out    = "";
    my $writer = PICA::Writer::JSON->new(fh => \$out);
    my $record = $pica_records[0];
    $writer->write($record);
    $writer->end;
    is $out, encode_json([@$record]) . "\n", 'JSON (array)';

    $out    = "";
    $writer = PICA::Writer::JSON->new(fh => \$out);
    $record = $pica_records[1];
    $writer->write($record);
    $writer->end;
    is $out, encode_json($record->{record}) . "\n", 'JSON (hash)';

    $out = "";
    $writer = PICA::Writer::JSON->new(fh => \$out, pretty => 1);
    $writer->write($record);
    $writer->end;
    like $out, qr/^\[\n\s+\[/m, 'JSON (pretty)';
}

note 'PICA::Data';

{
    my $append = "";
    foreach my $record (@pica_records) {
        bless $record, 'PICA::Data';
        $record->write(plain => \$append);
    }

    my $PLAIN = <<'PLAIN';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

    is $append, $PLAIN, 'record->write (multiple records)';

    my $record = bless $pica_records[1], 'PICA::Data';
    my $json = JSON::PP->new->utf8->convert_blessed->encode($record);
    is "$json\n", $record->string('JSON'), 'encode as JSON via TO_JSON';
}

note 'Exeptions';

{
    eval {pica_writer('plain', fh => '')};
    ok $@, 'invalid filename';

    eval {pica_writer('plain', fh => {})};
    ok $@, 'invalid handle';
}

note 'undefined occurrence';

{
    my $pica_record = [['003@', undef, '0', '1041318383']];
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::Plus->new(fh => $fh);
    $writer->write($pica_record);
    close $fh;

    my $out = do {local (@ARGV, $/) = $filename; <>};
    my $PLUS = <<'PLUS';
003@ 01041318383
PLUS
    is $out, $PLUS, 'undef occ';
}

note 'PICA::Writer::Fields';
{
    my $schema = PICA::Schema->new({
        fields => {
            '001A/01' => { label => 'Foo' },
            '066X/03-09' => { label => 'Bar' },
        }
    });
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::Fields->new(fh => $fh, schema => $schema);
    $writer->write([['001A', '01', 'x', 'y'], ['123X','','a','b']]);
    $writer->write([['001A', '01', 'x', 'y'], ['066X','05','a','b']]);
    $writer->end;

    my $out = do {local (@ARGV, $/) = $filename; <>};
    my $FIELDS = <<"FIELDS";
001A/01\tFoo
123X\t?
066X/03-09\tBar
FIELDS
    is $out, $FIELDS;
}

{
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::Fields->new(fh => $fh);
    $writer->write([['001A', '01', 'x', 'y'], ['123A','','a','b']]);
    $writer->end;

    is do {local (@ARGV, $/) = $filename; <>}, "001A/01\n123A\n";
}

done_testing;
