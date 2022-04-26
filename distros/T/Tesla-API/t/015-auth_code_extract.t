use warnings;
use strict;
use feature 'say';

use lib 't/';

use Tesla::API;
use TestSuite;
use Test::More;

my $ts = TestSuite->new;
my $data = $ts->data;
my $known_code = '2B51b8031f2b4ad4db52873da125b729497593e6c15c4a2dd591e698777f';

my $t = Tesla::API->new(unauthenticated => 1);

my $url = $data->{auth_url_extract};

my $code = $t->_authentication_code_extract($url);
is $code, $known_code, "Extracted code is correct ok";

$url =~ s/code/asdf/;

my $ok = eval { $t->_authentication_code_extract($url); 1; };

is $ok, undef, "If the auth code can't be extracted, we croak ok";
like $@, qr/Could not extract the auth/, "...and error is sane";

done_testing();