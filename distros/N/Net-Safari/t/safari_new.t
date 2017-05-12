# -*- perl -*-

# t/safari_new.t - Net::Safari constructor 


use Test::More qw( no_plan );

BEGIN { use_ok( 'Net::Safari' ); }

my $my_token = "MY_TOKEN";

my $ua = Net::Safari->new (token => $my_token);
isa_ok ($ua, 'Net::Safari');

ok($ua->token eq $my_token, "constructor args: token matches");



