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

use File::Temp qw(tempfile);
use IO::File;
use Encode qw(encode);
use Scalar::Util qw(reftype);

my @pica_records = (
    [
      ['003@', '', '0', '1041318383'],
      ['021A', '', 'a', "Hello \$\N{U+00A5}!"],
    ],
    {
      record => [
        ['028C', '01', d => 'Emma', a => 'Goldman']
      ]
    }
);


note 'PICA::Writer::Plain';

{
    my ($fh, $filename) = tempfile();
    my $writer = pica_writer( 'plain', fh => $fh );
    foreach my $record (@pica_records) {
        $writer->write($record);
    }
    close $fh;

    my $PLAIN = <<'PLAIN';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

    my $out = do { local (@ARGV,$/)=$filename; <> };
    is $out, $PLAIN, 'Plain writer'; 

    (undef, $filename) = tempfile(OPEN => 0);
    pica_writer('plain', fh => $filename);
    ok -e $filename, 'write to file';
}

note 'PICA::Writer::Plus';

{
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::Plus->new( fh => $fh );

    foreach my $record (@pica_records) {
        $writer->write($record);
    }
    close $fh;

    my $out = do { local (@ARGV,$/)=$filename; <> };
    my $PLUS = <<'PLUS';
003@ 01041318383021A aHello $¥!
028C/01 dEmmaaGoldman
PLUS

    is $out, $PLUS, 'Plus Writer';
}

note 'PICA::Writer::XML';

{
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::XML->new( fh => $fh );

    foreach my $record (@pica_records) {
        $writer->write($record);
    }
    $writer->end;
    close $fh;

    my $out = do { local (@ARGV,$/)=$filename; <> };

    my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>

<collection xmlns="info:srw/schema/5/picaXML-v1.0">
  <record>
    <datafield tag="003@">
      <subfield code="0">1041318383</subfield>
    </datafield>
    <datafield tag="021A">
      <subfield code="a">Hello $¥!</subfield>
    </datafield>
  </record>
  <record>
    <datafield tag="028C" occurrence="01">
      <subfield code="d">Emma</subfield>
      <subfield code="a">Goldman</subfield>
    </datafield>
  </record>
</collection>
XML

    is $out, $xml, 'XML writer';
}

note 'PICA::Writer::XML to object';

{
    { 
      package MyStringWriter;
      sub print { $_[0]->{out} .= $_[1] } 
    }

    my $string = bless { }, 'MyStringWriter';

    my $writer = PICA::Writer::XML->new( fh => $string );
    $writer->write($_) for map { bless $_, 'PICA::Data' } @pica_records;
    $writer->end;
    like $string->{out}, qr{^<\?xml.+collection>$}sm, 'XML writer (to object)';
}

note 'PICA::Writer::PPXML';

{
    my $parser = pica_parser( 'PPXML' => 't/files/slim_ppxml.xml' );
    my $record;
    my ($fh, $filename) = tempfile();
    my $writer = PICA::Writer::PPXML->new( fh => $fh );
    while($record = $parser->next){
        $writer->write($record);
    }
    $writer->end;
    close $fh;

    my $out = do { local (@ARGV,$/)=$filename; <> };
    my $in = do { local (@ARGV,$/)='t/files/slim_ppxml.xml'; <> };

    is_xml($out, $in, 'PPXML writer');
}

note 'PICA::Data';

{
  my $append = "";
  foreach my $record (@pica_records) {
      bless $record, 'PICA::Data';
      $record->write( plain => \$append );

      my $str = encode('UTF-8', $record->string);
      my $r = pica_parser('plain', \$str)->next;

      $record = $record->{record} if reftype $record eq 'HASH';
      is_deeply $r->{record}, $record, 'record->string';
  }
    my $PLAIN = <<'PLAIN';
003@ $01041318383
021A $aHello $$¥!

028C/01 $dEmma$aGoldman

PLAIN

  is $append, $PLAIN, 'record->write';
}



note 'Exeptions';

{
    eval { pica_writer('plain', fh => '') };
    ok $@, 'invalid filename';

    eval { pica_writer('plain', fh => {} ) };
    ok $@, 'invalid handle';
}

done_testing;