use Test::More tests => 1;
use Test::Exception;
use RPC::XML::Parser::XS;

my $libxml_version = RPC::XML::Parser::XS::libxml_version();
my $errmsg = 'encoder error';
if( $libxml_version <= 20620 )
{
  $errmsg = 'Extra content at the end of the document';
}

throws_ok {
    parse_rpc_xml(qq{<?xml version="1.0" encoding="us-ascii"?>
        <methodResponse>
          <params>
            <param>
              <value>
                <string>あああ</string>
              </value>
            </param>
          </params>
        </methodResponse>
      });
} qr/$errmsg/, "illegal charset raises '$errmsg'";
print "$@";

