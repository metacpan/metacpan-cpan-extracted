#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'REST::Google::Apps::Provisioning' );
}

diag( "Testing REST::Google::Apps::Provisioning $REST::Google::Apps::Provisioning::VERSION, Perl $], $^X" );

my $google = REST::Google::Apps::Provisioning->new(
    domain => 'company.com'
);
isa_ok( $google, 'REST::Google::Apps::Provisioning' );

