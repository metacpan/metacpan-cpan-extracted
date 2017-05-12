# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RPC-XML-Parser-XS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 30;
use File::Spec;
BEGIN { use_ok('RPC::XML::Parser::LibXML') };

use RPC::XML;
use utf8;

#########################

# bloody hack to shut up Test::Builder being passed Unicode strings
sub _is_deeply {
    my($this, $that, $msg) = @_;
    utf8::encode($msg) if $msg;
    @_ = ($this, $that, $msg);
    goto &is_deeply;
}

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

_is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
    </methodCall>
  }), RPC::XML::request->new('foo.bar'),
  'methodCall w/ no params';

_is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params />
    </methodCall>
  }), RPC::XML::request->new('foo.bar'),
  'methodCall w/ empty <params />';

_is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params></params>
    </methodCall>
  }), RPC::XML::request->new('foo.bar'),
  'methodCall w/ empty <params></params>';

_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
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


_is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><dateTime.iso8601>20070501T12:06:56</dateTime.iso8601></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::datetime_iso8601->new('20070501T12:06:56'),
     ),
  'methodCall w/ [20070501T12:06:56::dateTime.iso8601]';

_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><struct>
                        <member>
                          <name>い</name>
                          <value><struct>
                            <member>
                              <name>foo</name>
                              <value><string>bar</string></value>
                            </member>
                          </struct></value>
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
          'い' => RPC::XML::struct->new({
            'foo' => RPC::XML::string->new('bar'),
          }),
          'は' => RPC::XML::string->new('に'),
      })),
  'methodCall w/ [struct]';

_is_deeply parse_rpc_xml(qq{
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


_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
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


_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
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

_is_deeply parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><struct>
                        <member><name>foo</name><value><string>bar</string></value></member>
                        <member><name>bar</name>
                          <value><string>baz</string></value></member>
                      </struct></value></param>
      </params>
    </methodCall>
  }), RPC::XML::request->new(
      'foo.bar',
      RPC::XML::struct->new({
          'foo' => RPC::XML::string->new('bar'),
          'bar' => RPC::XML::string->new('baz'),
      })),
  'methodCall w/ [struct], no newlines';

_is_deeply parse_rpc_xml(qq{<?xml version="1.0" encoding="utf-8"?>
<methodCall>
 <methodName>metaWeblog.newPost</methodName>
 <params>
  <param>
   <value>
    <string>3</string>
   </value>
  </param>
  <param>
   <value>
    <string>foo</string>
   </value>
  </param>
  <param>
   <value>
    <struct>
     <member>
      <name>title</name>
      <value>
       <string>testing excerpt</string>
      </value>
     </member>
     <member>
      <name>description</name>
      <value>
       <string>&lt;p&gt;testing xxx&lt;/p&gt;</string>
      </value>
     </member>
     <member>
      <name>dateCreated</name>
      <value>
       <dateTime.iso8601>20080403T22:11:33</dateTime.iso8601>
      </value>
     </member>
    </struct>
   </value>
  </param>
 </params>
</methodCall>
}), RPC::XML::request->new(
    'metaWeblog.newPost',
    RPC::XML::string->new('3'),
    RPC::XML::string->new('foo'),
    RPC::XML::struct->new({
        title => RPC::XML::string->new('testing excerpt'),
        description => RPC::XML::string->new('<p>testing xxx</p>'),
        dateCreated => RPC::XML::datetime_iso8601->new('20080403T22:11:33'),
    }),
  ),
  'Windows Live Write style newlines';

{
    my $r = eval { RPC::XML::Parser::LibXML::parse_rpc_xml(<<XML);
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
<methodName>metaWeblog.newPost</methodName><params>
<param><value><string>testf</string></value></param>
<param><value><string>USERNAME</string></value></param><param><value><string>PASSWORD</string></value></param>
<param><value><struct><member><name>title</name><value>tyuyur</value></member><member><name>description</name><value>&lt;a href=&quot;http://example.com/.a/6a00d83453919f69e200ddx53f5f4178833-pi&quot;&gt;&lt;img src = &quot;http://tsdavis.typepad.com/.a/6a00d83453919f69e200e553f5f4178833-pi&quot; align = &quot;left&quot; height=&quot;384&quot; width=&quot;212&quot; hspace = &quot;20&quot; /&gt;&lt;/a&gt;</value></member></struct></value></param>
<param><value><boolean>1</boolean></value></param></params>
</methodCall>
XML
    };

    ok !$@;
    is $r->{name}, 'metaWeblog.newPost';
    is @{ $r->{args} }, 5;
}

{
    my $r = eval { RPC::XML::Parser::LibXML::parse_rpc_xml(<<XML);
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
 <methodName>metaWeblog.newPost</methodName>
 <params>
  <param>
   <value>foobar</value>
  </param>
  <param>
   <value><string>**ACCOUNTNAME**</string></value>
  </param>
  <param>
   <value><string>**PASSWORD**</string></value>
  </param>
  <param>
   <value>
    <struct>
     <member><name>title</name><value>test</value></member>
     <member><name>description</name><value><string>desc</string></value></member>
    </struct>
   </value>
  </param>
  <param>
   <value>
    <array>
     <data>
      <value>foo</value>
      <value><string>bar</string></value>
     </data>
    </array>
   </value>
  </param>
 </params>
</methodCall>
XML
    };

    is $r->{args}->[0]->value, 'foobar';
    is $r->{args}->[3]->{title}->value, 'test';
    is $r->{args}->[3]->{description}->value, 'desc';
    is_deeply $r->{args}->[4], [ map RPC::XML::string->new($_), qw( foo bar ) ];
}

## Don't allow external entities
{
    my $path = File::Spec->rel2abs('t/passwd');
    my $r = eval { RPC::XML::Parser::LibXML::parse_rpc_xml(<<XML);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [
    <!ENTITY foo SYSTEM "file://$path">
]>
<methodCall>
 <methodName>metaWeblog.newPost</methodName>
 <params>
  <param>
   <value>entity:[&foo;]</value>
  </param>
  <param>
   <value><string>**ACCOUNTNAME**</string></value>
  </param>
  <param>
   <value><string>**PASSWORD**</string></value>
  </param>
  <param>
   <value>
    <struct>
     <member><name>title</name><value>test</value></member>
     <member><name>description</name><value><string>desc</string></value></member>
    </struct>
   </value>
  </param>
  <param>
   <value>
    <array>
     <data>
      <value>foo</value>
      <value><string>&lt;</string></value>
     </data>
    </array>
   </value>
  </param>
 </params>
</methodCall>
XML
    };

    ok !$@, "We didn't die...";
    is $r->{args}->[0]->value, 'entity:[]', "...but entities were ignored";
}
