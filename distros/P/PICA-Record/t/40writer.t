use strict;
use utf8;

use Test::More tests => 27;
use Encode;
use File::Temp qw(tempfile);
use XML::Writer;

use_ok("PICA::Writer");
use_ok("PICA::XMLParser");
use_ok("PICA::Parser");
use_ok("PICA::Field");
use_ok("PICA::Record");

# prepare
my ($record, $xmldata, $str);
my ($fh, $filename);

# simple writing
my $w = PICA::Writer->new();
$w->write( PICA::Record->new('123@','0'=>'foo') );
is( $w->counter, 1, "simple writing (record)" );
is( $w->fields, 1, "simple writing (field)" );

my $s="";
PICA::Writer->new( \$s )->write( 
   PICA::Record->new('042A', '1' => 'bar' ),
   PICA::Record->new('045B', 'X' => 'doz' ) 
)->end();
is ( $s, "042A \$1bar\n\n045B \$Xdoz\n", "multiple records" );


# parsefile and readpicarecord
($record) = PICA::Parser->parsefile("t/files/minimal.xml")->records();
isa_ok($record, "PICA::Record");
my $r2 = readpicarecord("t/files/minimal.pica");
is( $record->string, $r2->string, "parse XML == read PICA" );

# writefile
($fh, $filename) = tempfile(UNLINK => 1);
writepicarecord( $record, $fh );
$r2 = readpicarecord( $filename );
is( $record->string, $r2->string, "read/write pica record" );

# open XML file
my $fxml;
open $fxml, "t/files/minimal.xml";
binmode $fxml, ":utf8";
$xmldata = join("",grep { !($_ =~ /^<\?|^$/); } <$fxml>);
close $fxml;

# write manually with xml
my $writer = XML::Writer->new( 
  DATA_MODE => 1, DATA_INDENT => 2, 
  NAMESPACES => 1, PREFIX_MAP => {$PICA::Record::XMLNAMESPACE=>''},
  OUTPUT => \$str
);
$writer->startTag([$PICA::Record::XMLNAMESPACE,'collection']);
$record->xml( $writer );
$writer->endTag();
is( "$str\n", $xmldata, "xml" );

# open XML file
open $fxml, "t/files/minimal.xml";
binmode $fxml, ":utf8";
$xmldata = join("", <$fxml>);
close $fxml;


# write to file

($fh, $filename) = tempfile(UNLINK => 1);
binmode $fh, ":utf8";

my $prefixmap = {'info:srw/schema/5/picaXML-v1.0'=>''};
$w = PICA::Writer->new( $fh, format => 'xml', 
  DATA_MODE => 1, DATA_INDENT => 2, 
  NAMESPACES => 1, PREFIX_MAP => $prefixmap, 
  xslt => '../script/pica2html.xsl'
);
$w->write( $record )->end();
close $fh;

is( file2string($filename), $xmldata, "format => 'xml'" );

sub file2string {
    my $fname = shift;
    my $fh;
    open( $fh, "<:utf8", $fname ) or return "failed to open $fname";
    my $string = join('',<$fh>);
    close $fh;
    return $string;
}

# write to XML with pretty print
($fh, $filename) = tempfile( SUFFIX => '.xml', UNLINK => 1 );
close $fh;
$w = PICA::Writer->new( $filename, pretty => 1, xslt => '../script/pica2html.xsl' );
$w->write( $record )->end();

is( file2string($filename), $xmldata, "format => 'xml' (implicit, pretty)" );

SKIP: {
    skip "Umlauts in XML look funny ", 2;

    $s = "";
    $w = PICA::Writer->new( \$s, format => 'xml' );
    PICA::Parser->parsefile( "t/files/graveyard.pica", Record => $w );
    $w->end();
    is ("$s", file2string("t/files/graveyard.xml"), "default XML conversion");
    is ($w->records, 1, "records=1");
};

# statistics
$w = PICA::Writer->new( stats => 1 );
PICA::Parser->parsefile( "t/files/dumpformat", Record => $w );
is ($w->records, 3, "records=3");
is ($w->fields, 92, "fields=92");

my @stat = $w->statlines;
is ($stat[5], "003@     ","stat");
is ($stat[6], "006G    *","stat");
is ($stat[10], '008@    +',"stat");
is ($stat[17], '029F    ?',"stat");
is ($stat[27], '045Q/01 ?',"stat");

$w = PICA::Writer->new( stats => 2 );
PICA::Parser->parsefile( "t/files/dumpformat", Record => $w );
@stat = $w->statlines;
#print join("'\n'", @stat)."\n";


# error handling
#$w = writepicarecord( $record, "/" );
$w = PICA::Writer->new( "/" );
is( $w->status, 0, "Failed to open writer" );
eval { $w->write( $record ); };
ok( $@, "Failed to write to writer in error status" );

$w = writepicarecord( $record, "/" );
ok( !$w->status, "writepicarecord failed" );
ok( !$w, "writepicarecord failed (bool overload)" );


__END__

TODO: write to a stream in another encoding

if(0) {
$str = "";
$w = PICA::Writer->new( \$str, format => 'xml',
  DATA_MODE => 1, DATA_INDENT => 2, 
  NAMESPACES => 1, PREFIX_MAP => {$PICA::Record::XMLNAMESPACE=>''},
);
$w->start()->write( $record )->end();
$w->start(); #->write($record);
# TODO: write fields
is( $str, $xmldata, "write via PICA::Writer" );
}

# add <collection> and <?xsl-stylesheet
