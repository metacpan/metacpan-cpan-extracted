package Test::Module::Install::Rust::FFI;
use strict;
use warnings;
use FFI::Platypus::Declare qw/uint32/;

attach double => [ uint32 ] => uint32;

1;
