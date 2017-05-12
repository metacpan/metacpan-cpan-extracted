#!perl -T

use Test::More tests => 1;
use Net::TPP;

diag( "Testing Net::TPP $Net::TPP::VERSION, Perl $], $^X" );

my $tpp = Net::TPP->new( AccountNo => '00000', UserId => 'foo', Password => 'bar');
my $results = $tpp->login();

ok($tpp->{error_code} eq '102') or do {
    my $message = sprintf "Expected login failure, however the error is %s",$tpp->error;
    if ($tpp->error =~ /Protocol scheme 'https' is not supported/i) {
        diag($message."\nOn debian-based distros like ubuntu, you might need to sudo apt-get install libwww-perl liblwp-protocol-https-perl libnet-http-perl");
    } else {
        diag($message);
    }
}
