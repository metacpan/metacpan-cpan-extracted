use inc::Module::Install;

name "Test-Module-Install-Rust-FFI";
version "1.00";
abstract "Test if Module::Install::Rust works with FFI::Platypus";
license "perl";

configure_requires "Module::Install::Rust" => 0;
requires "FFI::Platypus";

rust_write;
WriteAll;
