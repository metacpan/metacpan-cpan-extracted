use strict;
use inc::Module::Install;

all_from 'lib/RPC/Any.pm';
repository 'bzr://bzr.everythingsolved.com/rpc-any/trunk';

requires 'Scalar::Util';
requires 'Taint::Util';
# Generally a good idea to require 0.65 for stability and features.
requires 'Moose' => '0.65';

# For $message->content_type_charset support
requires 'LWP' => '5.827';
# This makes us require RPC::XML 0.69 at least.
requires 'RPC::XML::ParserFactory';
# For JSON-RPC 1.0 and Content-Length support.
requires 'JSON::RPC::Common' => '0.07';
requires 'JSON';
requires 'MIME::Base64';

# 0.82 adds "explain", which we use.
test_requires 'Test::More' => 0.82;
test_requires 'Test::Exception';

makemaker_args(
    dist => { PREOP => 'pod2text lib/RPC/Any.pm > README' },
);

WriteAll;
