use strict;
use warnings;
use Test::More;
use t::Util;

test('require pragma', <<'END', {strict => 0, warnings => 0});
require strict;
require warnings;
END

test('require Module', <<'END', {'Test' => 0, 'Test::More' => 0});
require Test;
require Test::More;
END

test('require v-string', <<'END', {perl => 'v5.10.1'});
require v5.10.1;
END

test('require version_number', <<'END', {perl => '5.010001'});
require 5.010001;
END

test('require file', <<'END', {});
my $file = "Test/More.pm";
require "Test/More.pm";
require $file;
END

done_testing;
