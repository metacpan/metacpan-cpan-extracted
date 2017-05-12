use Test::More tests => 3;

BEGIN { use_ok('Net::BEEP::Lite::TLSProfile'); }


my $tls_profile = new Net::BEEP::Lite::TLSProfile(Server => 1);
ok(defined $tls_profile);
isa_ok($tls_profile, 'Net::BEEP::Lite::TLSProfile');
