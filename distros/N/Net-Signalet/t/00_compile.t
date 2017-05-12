use strict;
use lib 'lib';
use Test::More tests => 1;

BEGIN {
    use_ok qw(
        Net::Signalet
        Net::Signalet::Server
        Net::Signalet::Client
    )
}
