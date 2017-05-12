use strict;
use warnings;
use Test::More;

require_ok "Test::Module::Install::Rust::FFI";

is Test::Module::Install::Rust::FFI::double(4), 8, "simple ok";

done_testing;
