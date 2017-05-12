use Test::More tests => 20;
use RPC::XML::Parser::XS;

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
    </methodCall>
  }), RPC::XML::request->new('foo.bar'),
  'methodCall w/ no params';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params />
    </methodCall>
  }), RPC::XML::request->new('foo.bar'),
  'methodCall w/ empty <params />';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params></params>
    </methodCall>
  }), RPC::XML::request->new('foo.bar'),
  'methodCall w/ empty <params></params>';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><int>3</int></value></param>
        <param><value><i4>6</i4></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::int->new(3),
      RPC::XML::int->new(6),
     ),
  'methodCall w/ [3::int, 6::int]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><boolean>1</boolean></value></param>
        <param><value><boolean>0</boolean></value></param>
        <param><value><boolean>1</boolean></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::boolean->new(1),
      RPC::XML::boolean->new(0),
      RPC::XML::boolean->new(1),
     ),
  'methodCall w/ [1::boolean, ...]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><string>る</string></value></param>
        <param><value><string>はい</string></value></param>
        <param><value><string></string></value></param>
        <param><value><string /></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::string->new('る'),
      RPC::XML::string->new('はい'),
      RPC::XML::string->new(''),
      RPC::XML::string->new(''),
     ),
  'methodCall w/ ["る"::string, ...]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><double>-3.1415926536</double></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::double->new(-3.1415926536),
     ),
  'methodCall w/ [-3.1415926536::double]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><dateTime.iso8601>20070501T120656+0900</dateTime.iso8601></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::datetime_iso8601->new('20070501T120656+0900'),
     ),
  'methodCall w/ [20070501T120656+0900::dateTime.iso8601]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><base64>TnlhcmxhdGhvdGVw</base64></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::base64->new('Nyarlathotep'),
     ),
  'methodCall w/ ["Nyarlathotep"::base64]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><struct /></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::struct->new({}),
     ),
  'methodCall w/ <struct />';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><struct></struct></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::struct->new({}),
     ),
  'methodCall w/ <struct></struct>';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><struct>
                        <member>
                          <name>い</name>
                          <value><string>ろ</string></value>
                        </member>
                        <member>
                          <name>は</name>
                          <value><string>に</string></value>
                        </member>
                      </struct></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::struct->new({
          'い' => RPC::XML::string->new('ろ'),
          'は' => RPC::XML::string->new('に'),
      })),
  'methodCall w/ [struct]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><array>
                        <data />
                      </array></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::array->new(),
     ),
  'methodCall w/ <array><data /></array>';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><array><data></data></array></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::array->new(),
     ),
  'methodCall w/ <array><data></data></array>';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><array>
                        <data>
                          <value><string>る</string></value>
                          <value><string>はい</string></value>
                        </data>
                      </array></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::array->new(
          RPC::XML::string->new('る'),
          RPC::XML::string->new('はい'),
         )),
  'methodCall w/ ["る"::string, ...]';

is_deeply parse_rpc_xml(qq{
    <methodResponse>
      <params>
        <param>
          <value><string>る</string></value>
        </param>
      </params>
    </methodResponse>
  }), RPC::XML::response->new(
      RPC::XML::string->new('る'),
     ),
  'methodResponse w/ ["る"::string]';

is_deeply parse_rpc_xml(qq{
    <methodResponse>
      <fault>
        <value>
          <struct>
            <member>
              <name>faultCode</name>
              <value><int>3</int></value>
            </member>
            <member>
              <name>faultString</name>
              <value><string>る</string></value>
            </member>
          </struct>
        </value>
      </fault>
    </methodResponse>
  }), RPC::XML::response->new(
      RPC::XML::fault->new(3, 'る'),
     ),
  'methodResponse w/ [(3, "る")::fault]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value>baz</value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::string->new('baz')),
  'bare string values are string values';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::string->new('')),
  'empty values are string values [1]';

is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value /></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::string->new('')),
  'empty values are string values [2]';
