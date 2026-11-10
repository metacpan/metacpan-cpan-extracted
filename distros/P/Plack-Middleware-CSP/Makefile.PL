use strict;
use inc::Module::Install;

name "Plack-Middleware-CSP";
license "perl";
all_from "lib/Plack/Middleware/CSP.pm";

makemaker_args( dist => { PREOP => 'pod2text lib/Plack/Middleware/CSP.pm > README' } );

requires "HTTP::CSPHeader";
requires "Plack";
requires "Plack::Middleware";
requires "Path::Tiny";

build_requires "HTTP::CSPHeader"; # Redundant?
build_requires "Test::More";

test_requires "Plack::Builder";
test_requires "HTTP::Request::Common";
test_requires "Test::Fatal";

auto_install;
WriteAll;

__END__
