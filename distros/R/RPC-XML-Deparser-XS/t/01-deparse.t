use Test::More tests => 15;
use strict;
use warnings;
use RPC::XML::Deparser::XS;
use RPC::XML;

sub trim ($) {
    my $src = shift;
    
    $src =~ s/^\s*//mg;
    $src =~ s/\s*$//mg;
    $src =~ tr/\n//d;
    
    return $src;
}

my $req;

$req = RPC::XML::int->new(-12345);
is trim deparse_rpc_xml($req), trim "<int>-12345</int>";

$req = RPC::XML::i4->new(12345);
is trim deparse_rpc_xml($req), trim "<i4>12345</i4>";

$req = RPC::XML::double->new(3.14159);
is trim deparse_rpc_xml($req), trim "<double>3.14159</double>";

$req = RPC::XML::string->new("Get me out here!");
is trim deparse_rpc_xml($req), trim "<string>Get me out here!</string>";

$req = RPC::XML::string->new("\">>&&<<\"");
is trim deparse_rpc_xml($req), trim "<string>&quot;&gt;&gt;&amp;&amp;&lt;&lt;&quot;</string>";

$req = RPC::XML::string->new("る");
is trim deparse_rpc_xml($req), trim "<string>る</string>";

$req = RPC::XML::boolean->new(undef);
is trim deparse_rpc_xml($req), trim "<boolean>0</boolean>";

$req = RPC::XML::datetime_iso8601->new("2000-01-01T00:00:00+09:00");
is trim deparse_rpc_xml($req), trim "<dateTime.iso8601>2000-01-01T00:00:00+09:00</dateTime.iso8601>";

$req = RPC::XML::array->new(RPC::XML::int->new(300),
			    RPC::XML::string->new("Foo"));
is trim deparse_rpc_xml($req), trim q{
    <array>
      <data>
         <value><int>300</int></value>
         <value><string>Foo</string></value>
      </data>
    </array>};

$req = RPC::XML::struct->new({foo => RPC::XML::int->new(300)});
is trim deparse_rpc_xml($req), trim q{
    <struct>
      <member>
        <name>foo</name>
        <value><int>300</int></value>
      </member>
    </struct>};

$req = RPC::XML::base64->new("\x00\x01\x02");
is trim deparse_rpc_xml($req), trim "<base64>AAEC</base64>";

$req = RPC::XML::fault->new(404, 'Not Found');
do {
    # member の順序は不定。
    my $pat_1 = trim q{
      <fault>
        <value>
          <struct>
            <member>
              <name>faultCode</name>
              <value><int>404</int></value>
            </member>
            <member>
              <name>faultString</name>
              <value><string>Not Found</string></value>
            </member>
          </struct>
        </value>
      </fault>};

    my $pat_2 = trim q{
      <fault>
        <value>
          <struct>
            <member>
              <name>faultString</name>
              <value><string>Not Found</string></value>
            </member>
            <member>
              <name>faultCode</name>
              <value><int>404</int></value>
            </member>
          </struct>
        </value>
      </fault>};

    my $deparsed = trim deparse_rpc_xml($req);
    ok($deparsed eq $pat_1 or $deparsed eq $pat_2)
      or diag $deparsed;
};

$req = RPC::XML::request->new("はい", RPC::XML::int->new(-12345));
is trim deparse_rpc_xml($req), trim(q{
      <?xml version="1.0"?>
      <methodCall>
        <methodName>はい</methodName>
        <params>
          <param><value><int>-12345</int></value></param>
        </params>
      </methodCall>
  });


$req = RPC::XML::response->new(RPC::XML::string->new(""));
is trim deparse_rpc_xml($req), trim(q{
      <?xml version="1.0"?>
      <methodResponse>
        <params>
          <param><value><string></string></value></param>
        </params>
      </methodResponse>
  });


$req = RPC::XML::response->new(RPC::XML::fault->new(404, 'Not Found'));
do {
    # member の順序は不定。
    my $pat_1 = trim(q{
    <?xml version="1.0"?>
    <methodResponse>
      <fault>
        <value>
          <struct>
            <member>
              <name>faultCode</name>
              <value><int>404</int></value>
            </member>
            <member>
              <name>faultString</name>
              <value><string>Not Found</string></value>
            </member>
          </struct>
        </value>
      </fault>
    </methodResponse>});

    my $pat_2 = trim(q{
    <?xml version="1.0"?>
    <methodResponse>
      <fault>
        <value>
          <struct>
            <member>
              <name>faultString</name>
              <value><string>Not Found</string></value>
            </member>
            <member>
              <name>faultCode</name>
              <value><int>404</int></value>
            </member>
          </struct>
        </value>
      </fault>
    </methodResponse>});

    my $deparsed = trim deparse_rpc_xml($req);
    ok($deparsed eq $pat_1 or $deparsed eq $pat_2)
      or diag $deparsed;
};
