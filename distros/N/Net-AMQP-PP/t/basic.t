use strict;
use warnings;

use Test::More;
use Test::Without::Module qw( XML::LibXML );

use_ok("Net::AMQP::PP");
eval { Net::AMQP::Protocol->load_xml_spec() };
ok !$@;
ok scalar keys %Net::AMQP::Protocol::spec;
ok Net::AMQP::Protocol::Access::Request->can('class_id');

done_testing;

