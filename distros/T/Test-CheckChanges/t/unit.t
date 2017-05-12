use strict;
use warnings;

use Test::More;
use Test::CheckChanges;
  
BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 2;

throws_ok { ok_changes('bob' => 'bill'); } qr/ok_changes takes no arguments .*/, 'arguments';
throws_ok { ok_changes('bob'); } qr/ok_changes takes no arguments .*/, 'arguments';

