#!/usr/bin/env perl

use strict;

use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use HTTP::Request;
use Mock::Apache;

use_ok('Apache::Util', ':all');

ok(defined &escape_html,       'escape_html()       exported');
ok(defined &escape_uri,        'escape_uri()        exported');
ok(defined &ht_time,           'ht_time()           exported');
ok(defined &parsedate,         'parsedate()         exported');
ok(defined &size_string,       'size_string()       exported');
ok(defined &unescape_uri,      'unescape_uri()      exported');
ok(defined &unescape_uri_info, 'unescape_uri_info() exported');
ok(defined &validate_password, 'validate_password() exported');

done_testing();

