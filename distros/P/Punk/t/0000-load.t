#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Punk') || print "Bail out!\n";
    use_ok('Punk::App');
    use_ok('Punk::Router');
    use_ok('Punk::Router::Scope');
    use_ok('Punk::Context');
    use_ok('Punk::Request');
    use_ok('Punk::Response');
    use_ok('Punk::Controller');
    use_ok('Punk::Static');
    use_ok('Punk::Plugin');
}

diag("Testing Punk $Punk::VERSION, Perl $], $^X");

done_testing();
