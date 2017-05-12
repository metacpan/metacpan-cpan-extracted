# -*- perl -*-

# t/safari_new.t - Net::Safari accessors 


use Test::More qw( no_plan );

BEGIN { use_ok( 'Net::Safari' ); }

my $my_token = "MY_TOKEN";
my $my_url = "http://www.example.com/foo";
my $my_ua = LWP::UserAgent->new();

my $ua = Net::Safari->new (token => "DUMMY");
isa_ok ($ua, 'Net::Safari');

ok( $ua->token($my_token) eq $my_token, "token() sets." );
ok( $ua->token() eq $my_token, "token() gets." );


ok( $ua->base_url($my_url) eq $my_url, "base_url() sets." );
ok( $ua->base_url() eq $my_url, "base_url() gets." );


ok( $ua->ua($my_ua) == $my_ua, "ua() sets." );
ok( $ua->ua() == $my_ua, "ua() gets." );
