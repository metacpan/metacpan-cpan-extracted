#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Net::Whois::RIPE');
}

diag q{Testing Net::Whois::RIPE }
    . $Net::Whois::RIPE::VERSION
    . q{, Perl }
    . $] . q{, }
    . $^X;
