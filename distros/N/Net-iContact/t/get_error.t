#!perl -T
use strict;

use Test::More tests => 3;
use Net::iContact;

### _get_error and _parse are internal subs.

my $root = Net::iContact::_parse(do {local $/;<DATA>});
ok(ref($root) eq 'HASH');

my $ret  = Net::iContact::_get_error($root);
ok($ret->{code}    == 401, 'error code');
ok($ret->{message} eq 'Authorization problem.  Access not allowed.', 'error message');
__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<response status="fail">
   <error_code>401</error_code>
   <error_message>Authorization problem.  Access not allowed.</error_message>
</response>
