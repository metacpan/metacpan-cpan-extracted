use strict;
use warnings;

use Test::More;
use Test::Deep;

use Net::Async::HTTP::DAV;
use Net::Async::HTTP::DAV::XML;
use XML::SAX;
use XML::LibXML::SAX::ChunkParser;

my $propfind_result = <<'EOF';
<D:multistatus>
<D:response>
  <D:href>/file.txt</D:href>
  <D:propstat>
    <D:prop>
      <D:resourcetype/>
      <D:getcontentlength>1314</D:getcontentlength>
      <D:creationdate>Fri, 25 Mar 2011 20:46:31 GMT</D:creationdate>
      <D:getlastmodified>Fri, 25 Mar 2011 20:46:31 GMT</D:getlastmodified>
      <D:getetag>"ac2ba736dfea8e6aef829938a5efdeac"</D:getetag>
      <D:displayname>file.txt</D:displayname>
      <D:getcontenttype>text/plain</D:getcontenttype>
      <D:immutable/>
      <D:lastmodifieddate>Fri, 25 Oct 2011 20:26:31 GMT</D:lastmodifieddate>
      <D:resourceid>XYZ</D:resourceid>
      <D:read-only/>
    </D:prop>
    <D:status>HTTP/1.1 200 OK</D:status>
  </D:propstat>
</D:response>
<D:response>
  <D:href>/somepath</D:href>
  <D:propstat>
    <D:prop>
      <D:resourcetype>
       <D:collection/>
      </D:resourcetype>
      <D:creationdate>Fri, 25 Mar 2011 20:46:31 GMT</D:creationdate>
      <D:getlastmodified>Fri, 25 Mar 2011 20:46:31 GMT</D:getlastmodified>
      <D:getetag>"ac2ba736dfea8e6aef829938a5efdeac"</D:getetag>
      <D:displayname>somepath</D:displayname>
      <D:getcontenttype>text/plain</D:getcontenttype>
      <D:immutable/>
      <D:lastmodifieddate>Fri, 25 Oct 2011 20:26:31 GMT</D:lastmodifieddate>
      <D:resourceid>XYZ</D:resourceid>
      <D:read-only/>
    </D:prop>
    <D:status>HTTP/1.1 200 OK</D:status>
  </D:propstat>
</D:response>
<D:response>
  <D:href>/otherpath</D:href>
  <D:propstat>
    <D:prop>
      <D:resourcetype>
        <D:collection/>
      </D:resourcetype>
      <D:creationdate>Thu, 09 Dec 2010 11:03:08 GMT</D:creationdate>
      <D:getlastmodified>Thu, 09 Dec 2010 11:03:08 GMT</D:getlastmodified>
      <D:getetag>"ca32261b08a98cac399ac27f3f4faf2f"</D:getetag>
      <D:displayname>otherpath</D:displayname>
      <D:getcontenttype>httpd/unix-directory</D:getcontenttype>
      <D:immutable/>
      <D:lastmodifieddate>Thu, 09 Dec 2010 11:03:08 GMT</D:lastmodifieddate>
      <D:resourceid>NNTYX</D:resourceid>
      <D:read-only/>
    </D:prop>
    <D:status>HTTP/1.1 200 OK</D:status>
  </D:propstat>
</D:response>
</D:multistatus>
EOF

my @item;
my $xml = Net::Async::HTTP::DAV::XML->new(
	on_item	=> sub {
		my $item = shift;
		note sprintf("%-64.64s %12.12s %s\n", $item->{displayname}, ($item->{type} eq 'directory') ? '    <DIR>   ' : ($item->{size} // 0), $item->{getcontenttype});
		push @item, $item;
	}
);
my $sax = do {
	local $XML::SAX::ParserPackage = 'XML::LibXML::SAX::ChunkParser';
	XML::SAX::ParserFactory->parser({Handler => $xml}) or die "No SAX parser could be found";
};
$sax->parse_chunk($propfind_result);
is(@item, 3, 'have 3 items');
is($item[0]->{displayname}, 'file.txt', 'name is correct');
cmp_deeply(\@item, bag(
	superhashof({ displayname => 'file.txt' }),
	superhashof({ displayname => 'somepath' }),
	superhashof({ displayname => 'otherpath' }),
), 'items match');

done_testing;
