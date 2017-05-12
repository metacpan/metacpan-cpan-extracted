use 5.006;
use inc::Module::Install;

name "Module-Install-Rust";
author q{Vickenty Fesunov <kent@setattr.net>};
license "perl";

all_from "lib/Module/Install/Rust.pm";

perl_version 5.014; # for /r regexp flag.

resources homepage => "https://github.com/vickenty/mi-rust";
resources repository => "https://github.com/vickenty/mi-rust";
resources bugtracker => "https://github.com/vickenty/mi-rust/issues";

configure_requires "Module::Install" => 0;

build_requires "Test::More" => 0;

requires "TOML" => "0.97";

WriteAll;
