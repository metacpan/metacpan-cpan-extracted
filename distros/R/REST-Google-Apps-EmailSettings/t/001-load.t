#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'REST::Google::Apps::EmailSettings' );
}

diag( "Testing REST::Google::Apps::EmailSettings $REST::Google::Apps::EmailSettings::VERSION, Perl $], $^X" );

my $google = REST::Google::Apps::EmailSettings->new(
    domain => 'company.com'
);
isa_ok( $google, 'REST::Google::Apps::EmailSettings' );

