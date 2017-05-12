use strict;
use warnings;

use Test::More tests => 13;
use MIME::Base64;

use_ok('Net::Lighthouse::Base');
can_ok( 'Net::Lighthouse::Base', 'new' );
my $base = Net::Lighthouse::Base->new( account => 'sunnavy' );
isa_ok( $base, 'Net::Lighthouse::Base' );
for (qw/account auth base_url ua/) {
    can_ok( $base, $_ );
}

is( $base->base_url, 'http://sunnavy.lighthouseapp.com', 'base_url' );
isa_ok( $base->ua, 'LWP::UserAgent' );
is(
    $base->ua->default_header('User-Agent'),
    "net-lighthouse/$Net::Lighthouse::VERSION",
    'agent of ua'
);

is( $base->ua->default_header('Content-Type'),
    'application/xml', 'content-type of ua' );

my $token = 'a' x 40;
$base->auth->{token} = $token;
is( $base->ua->default_header('X-LighthouseToken'),
    $token, 'X-LighthouseToken of ua' );
$base->auth->{email} = 'mark@twain.org';
$base->auth->{password} = 'huckleberry';
my $auth_base64 = encode_base64( $base->auth->{email} . ':' . $base->auth->{password} );
chomp $auth_base64;
is(
    $base->ua->default_header('Authorization'),
    'Basic ' . $auth_base64,
    'Authorization of ua'
);
