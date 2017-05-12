use strict;
use Test::More tests => 1;

BEGIN { use_ok 'RPC::XML::Parser::LibXML' }
eval {
    diag "XML::LibXML: $XML::LibXML::VERSION";
    diag "libxml: " . XML::LibXML::LIBXML_VERSION;
};
