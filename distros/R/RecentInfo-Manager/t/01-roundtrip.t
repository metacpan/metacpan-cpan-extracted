#!perl
use 5.020;
use Test2::V0 -no_srand;
use XML::LibXML;
use RecentInfo::Manager::XBEL;
use experimental 'try', 'signatures';
use stable 'postderef';

# Do some roundtrip tests

my @tests;
{
    local $/;
    @tests = map {
        s/\A---(?: ([^\r\n]+))?\r?\n//;
        {
            xbel => $_,
            todo => $1,
        }
    } split /(?=---)/, <DATA>;
}

sub valid_xml( $xml, $msg ) {
    state $xmlschema = XML::LibXML::Schema->new( location => 'xsd/recently-used-xbel.xsd', no_network => 1 );
    my $doc = XML::LibXML->new->parse_string( $xml );

    try {
        $xmlschema->validate( $doc );
        pass($msg);
    } catch( $e ) {
        diag $e;
        fail($msg);
    }
}

for my $test (@tests) {
    my $xml = $test->{xbel};
    my $todo;
    if( $test->{todo}) {
        $todo = todo($test->{todo});
    };
    #valid_xml( $xml, "The input XML is valid" );

    my $xbel = RecentInfo::Manager::XBEL->new( filename => undef );
    my $bm = $xbel->fromString( $test->{xbel});
    $xbel->entries->@* = $bm->@*;

    $xml = $xbel->toString;
    #valid_xml( $xml, "The generated XML is valid" );

    # Fudge the whitespace a bit
    $test->{xbel} =~ s!\s+xmlns:! xmlns:!msg;
    $test->{xbel} =~ s!\s+>!>!msg;
    $test->{xbel} =~ s!\s+version=! version=!msg;
    $test->{xbel} =~ s!\s+\z!!msg;
    $xml =~ s!\s+\z!!msg;

    # Since Test2::V0 does not produce usable diffs, compare line-by-line
    # this works since we expect things to align
    my $x1 = [split /\r?\n/, $test->{xbel}];
    my $x2 = [split /\r?\n/, $xml];

    # Fudge the attributes in the "xbel" element
    for( $x1->[1], $x2->[1] ) {
        my ($version,$bookmark,$mime);
        s!\b(version=[^>\s]+)!! and $version = $1;
        s!\b(xmlns:bookmark=[^>\s]+)!! and $bookmark = $1;
        s!\b(xmlns:mime=[^>\s]+)!! and $mime = $1;

        $_ =~ s/xbel /xbel $version $bookmark $mime/;
    };

    is $x1, $x2, "The strings are identical";

    my $reconstructed = RecentInfo::Manager::XBEL->new( filename => undef );
    $bm = $reconstructed->fromString( $xml );
    $reconstructed->entries->@* = $bm->@*;

    is $xbel, $reconstructed, "The reconstructed data structure is identical to the first parse";
}

done_testing();

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
      xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info"
      version="1.0">
  <bookmark href="file:///home/corion/Projekte/MIME-Detect/Changes" added="2024-06-06T15:59:35.484580Z" modified="2024-06-06T15:59:35.484583Z" visited="2024-06-06T15:59:35.484580Z">
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="text/plain"/>
        <bookmark:groups>
          <bookmark:group>geany</bookmark:group>
        </bookmark:groups>
        <bookmark:applications>
          <bookmark:application name="geany" exec="&apos;geany %u&apos;" modified="2024-06-06T15:59:35.484582Z" count="1"/>
        </bookmark:applications>
      </metadata>
    </info>
  </bookmark>
</xbel>
---
<?xml version="1.0" encoding="UTF-8"?>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
      xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info"
      version="1.0"/>
---
<?xml version="1.0" encoding="UTF-8"?>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
      xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info"
      version="1.0">
  <bookmark href="file:///home/corion/Projekte/MIME-Detect/Changes" added="2024-06-06T15:59:35.484580Z" modified="2024-06-06T15:59:35.484583Z" visited="2024-06-06T15:59:35.484580Z">
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="text/plain"/>
        <bookmark:groups>
          <bookmark:group>geany</bookmark:group>
          <bookmark:group>Office</bookmark:group>
        </bookmark:groups>
        <bookmark:applications>
          <bookmark:application name="geany" exec="&apos;geany %u&apos;" modified="2024-06-06T15:59:35.484582Z" count="1"/>
          <bookmark:application name="geany2" exec="&apos;geany %u&apos;" modified="2024-06-06T15:59:35.484582Z" count="1"/>
        </bookmark:applications>
      </metadata>
    </info>
  </bookmark>
</xbel>

--- We (well, XSD) don't handle arbitrary metadata well
<?xml version="1.0" encoding="UTF-8"?>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
      xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info"
      version="1.0">
  <bookmark href="file:///home/corion/Projekte/MIME-Detect/Changes" added="2024-06-06T15:59:35.484580Z" modified="2024-06-06T15:59:35.484583Z" visited="2024-06-06T15:59:35.484580Z">
    <info>
      <metadata owner="http://freedesktop.org">
        <mime:mime-type type="text/plain"/>
        <bookmark:groups>
          <bookmark:group>geany</bookmark:group>
          <bookmark:group>Office</bookmark:group>
        </bookmark:groups>
        <bookmark:applications>
          <bookmark:application name="geany" exec="&apos;geany %u&apos;" modified="2024-06-06T15:59:35.484582Z" count="1"/>
          <bookmark:application name="geany2" exec="&apos;geany %u&apos;" modified="2024-06-06T15:59:35.484582Z" count="1"/>
        </bookmark:applications>
      </metadata>
      <metadata owner="http://example.com">
        <img href="https://example.com/welcome.png"/>
      </metadata>
    </info>
  </bookmark>
</xbel>
