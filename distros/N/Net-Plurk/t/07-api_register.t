#!perl -T

use Test::More skip_all => 'API 2 not support user register now';
use Env qw(PLURKAPIKEY);

BEGIN {
	use Net::Plurk;
        my $api_key = $PLURKAPIKEY // "dKkIdUCoHo7vUDPjd3zE0bRvdm5a9sQi";
        my $p = Net::Plurk->new(api_key => $api_key);
        my $json = $p->api( path => '/Users/register',
            nick_name => 'plurkpl', full_name => 'Plurk Perl',
            password => '1234fake', gender => 'male',
            date_of_birth => '2010-05-07');
        isa_ok ($json, HASH);
        is ($json->{error_text}, "User already found");
        is ($p->api_errormsg, "User already found");
}

diag( "Testing Net::Plurk Register API" );
