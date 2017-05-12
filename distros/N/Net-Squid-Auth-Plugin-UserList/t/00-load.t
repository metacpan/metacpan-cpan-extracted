#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Net::Squid::Auth::Plugin::UserList');
}

diag(
"Testing Net::Squid::Auth::Plugin::UserList $Net::Squid::Auth::Plugin::UserList::VERSION, Perl $], $^X"
);
