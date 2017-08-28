use Mojo::Base -strict;

use Test::More;

use Mojo::XMLRPC 'from_xmlrpc';
use Scalar::Util 'blessed';

my $msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodCall>
   <methodName>examples.getStateName</methodName>
   <params>
      <param>
         <value><i4>41</i4></value>
         </param>
      </params>
   </methodCall>
MESSAGE

isa_ok $msg, 'Mojo::XMLRPC::Message::Call', 'correct message type';
is $msg->method_name, 'examples.getStateName', 'correct method';
is_deeply $msg->parameters, [41], 'correct parameters';

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodCall>
   <methodName>examples.getStateName</methodName>
   <params>
      <param>
         <value><int>3.14</int></value>
         </param>
      </params>
   </methodCall>
MESSAGE

isa_ok $msg, 'Mojo::XMLRPC::Message::Call', 'correct message type';
is $msg->method_name, 'examples.getStateName', 'correct method';
is_deeply $msg->parameters, [3.14], 'correct parameters';

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value><string>South Dakota</string></value>
         </param>
      </params>
   </methodResponse>
MESSAGE

isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
ok !$msg->is_fault, 'not a fault';
is_deeply $msg->parameters, ['South Dakota'], 'correct parameters';

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value><nil/></value>
         </param>
      </params>
   </methodResponse>
MESSAGE

isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
ok !$msg->is_fault, 'not a fault';
is_deeply $msg->parameters, [undef], 'correct parameters';

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value><boolean>1</boolean></value>
         </param>
      </params>
   </methodResponse>
MESSAGE

isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
ok !$msg->is_fault, 'not a fault';
is_deeply $msg->parameters, [Mojo::JSON::true], 'correct parameters';

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value><boolean>0</boolean></value>
         </param>
      </params>
   </methodResponse>
MESSAGE

isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
ok !$msg->is_fault, 'not a fault';
is_deeply $msg->parameters, [Mojo::JSON::false], 'correct parameters';

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value><dateTime.iso8601>1998-07-17T14:08:55Z</dateTime.iso8601></value>
         </param>
      </params>
   </methodResponse>
MESSAGE

{
  isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
  ok !$msg->is_fault, 'not a fault';
  my $date = $msg->parameters->[0];
  isa_ok $date, 'Mojo::Date', 'got a Mojo::Date';
  is $date->epoch, 900684535, 'got the correct date';
}

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value><dateTime.iso8601>19980717T14:08:55</dateTime.iso8601></value>
         </param>
      </params>
   </methodResponse>
MESSAGE

{
  isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
  ok !$msg->is_fault, 'not a fault';
  my $date = $msg->parameters->[0];
  isa_ok $date, 'Mojo::Date', 'got a Mojo::Date';
  is $date->epoch, 900684535, 'got the correct date';
}

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
         <value><base64>eW91IGNhbid0IHJlYWQgdGhpcyE=</base64></value>
         </param>
      </params>
   </methodResponse>
MESSAGE

{
  isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
  ok !$msg->is_fault, 'not a fault';
  my $base64 = $msg->parameters->[0];
  isa_ok $base64, 'Mojo::XMLRPC::Base64', 'got a Mojo::XMLRPC::Base64 object';
  is $base64->encoded, 'eW91IGNhbid0IHJlYWQgdGhpcyE=', 'got the encoded data';
  is $base64->decoded, q[you can't read this!], 'got the decoded data';
}

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <params>
      <param>
        <value>
          <array>
            <data>
              <value><i4>12</i4></value>
              <value><string>Egypt</string></value>
              <value><boolean>0</boolean></value>
              <value><i4>-31</i4></value>
            </data>
          </array>
        </value>
      </param>
    </params>
  </methodResponse>
MESSAGE

isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
ok !$msg->is_fault, 'not a fault';
is_deeply $msg->parameters, [[12, 'Egypt', Mojo::JSON::false, -31]], 'correct parameters';

$msg = from_xmlrpc(<<'MESSAGE');
<?xml version="1.0"?>
<methodResponse>
   <fault>
      <value>
         <struct>
            <member>
               <name>faultCode</name>
               <value><int>4</int></value>
               </member>
            <member>
               <name>faultString</name>
               <value><string>Too many parameters.</string></value>
               </member>
            </struct>
         </value>
      </fault>
   </methodResponse>
MESSAGE

isa_ok $msg, 'Mojo::XMLRPC::Message::Response', 'correct message type';
ok $msg->is_fault, 'not a fault';
is_deeply $msg->fault, {
  faultCode => 4,
  faultString => 'Too many parameters.',
}, 'correct parameters';

done_testing;

