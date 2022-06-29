use strict;
use inc::Module::Install;

name "Plack-Middleware-CSP";
license "perl";
all_from "lib/Plack/Middleware/CSP.pm";

requires "Plack";
requires "Plack::Middleware";
requires "Path::Tiny";
requires "HTTP::CSPHeader";

build_requires "Test::More";

test_requires "HTTP::Request::Common";

auto_install;
WriteAll;

__END__
