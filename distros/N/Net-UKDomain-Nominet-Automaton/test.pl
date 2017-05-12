# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
my $verbose = 0; # Turn this to 1 to see verbose...

use Test;
my $d = undef;
my $details = undef;
my $domain = undef;
BEGIN { plan tests => 13, onfail => sub { print $d->errstr(); } };
use Net::UKDomain::Nominet::Automaton;
ok(1);
# If we made it this far, we're ok.
if ($verbose) { print 'issued use Net::UKDomain::Nominet::Automaton'."\n"; }

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use Crypt::OpenPGP;
ok(2);
if ($verbose) { print 'issued use Crypt::OpenPGP'."\n"; }

my $pgp = Crypt::OpenPGP->new(  -SecRing => './.pgp',
                                -PubRing => './.pgp',
                                -Compat => 'PGP2'
                                );
if ($pgp) { ok(3); }
if ($verbose) { print 'created $pgp'."\n"; }

my ($public, $secret) = $pgp->keygen(   Type => 'RSA',
                                        Size => 512,
                                        Identity => 'Test <test@my.isp>',
                                        Passphrase => 'TestOpenPGP',
                                        );
if ($public) { ok(4); }
if ($verbose) { print 'created $public and $secret'."\n"; }

my $psaved = $public->save;
my $ssaved = $secret->save;

open FH, '>', '.pgp/public.pgp' || die $!;
print FH $psaved;
close FH;

open FH, '>', '.pgp/secret.pgp' || die $!;
print FH $ssaved;
close FH;
ok(5);
if ($verbose) { print 'pgp files were written'."\n"; }

my $keyID = substr($secret->key->key_id_hex, -8, 8);

$secret = undef;
$public = undef;
$pgp = undef;

$d = Net::UKDomain::Nominet::Automaton->new( keyid     => $keyID,
                                        passphrase      => 'TestOpenPGP',
                                        tag             => 'IPSTAG',
                                        smtpserver      => 'smtp.example.com',
                                        emailfrom       => 'UK Domains <ukdomains@example.com>',
                                        secring         => './.pgp/secret.pgp',
                                        pubring         => './.pgp/public.pgp',
                                        compat          => 'PGP2',
                                        testemail       => 'testemail'
                                        ); 
if ($d) { ok(6); }
if ($verbose) { print '$d was populated using Net::UKDomain::Nominet::Automaton->new'."\n"; }

$domain = 'automaton-test-';
$domain .= join '', (0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64];
$domain .= '.co.uk';

my $valid;
if ($d->valid_domain($domain)) { $valid = "$domain was validated"; }
if ($valid) { ok(7); } # In test case, domain should always be valid
if ($verbose) { print '$domain was validated'."\n"; }

if (!$d->domain_available($domain) ) { print "Domain not available - ".$d->errstr."\n"; }
else { ok(8); } # In test case, domain should always be available
if ($verbose) { print '$domain was availablility was checked'."\n"; }

$details = {
		'for' 		=> 'Test Registrant',
		'reg-contact'	=> 'Test Contact',
		'reg-addr'	=> '1 High Street',
		'reg-city'	=> 'A Town',
		'reg-county'	=> 'County',
		'reg-postcode'	=> 'AN0 0NA',
		'reg-country'	=> 'GB',
		'reg-email'	=> 'test@example.com'
};
#use Data::Dumper; print Dumper(\$details);

if (!$d->register($domain, $details)) {
        print "Cannot register $domain ".$d->errstr()."\n";
}
else { ok(9); }

$domain = 'nominet.org.uk';
# This $details has no 'for' field
$details = {
		'reg-contact'	=> 'Test Contact',
		'reg-addr'	=> '1 High Street',
		'reg-city'	=> 'A Town',
		'reg-county'	=> 'County',
		'reg-postcode'	=> 'AN0 0NA',
		'reg-country'	=> 'GB',
		'reg-email'	=> 'test@example.com'
};
if (!$d->modify($domain, $details) ) {
	print "Cannot modify $domain " . $d->errstr() . "\n";
}
else { ok(10); }
if ($verbose) { print 'modify request issued'."\n"; }
if ( ! $d->renew($domain) ) {
	print "Cannot renew $domain " . $d->errstr() . "\n";
}
else { ok(11); }
if ($verbose) { print 'renew request issued'."\n"; }
if ( ! $d->release($domain, 'NOMINET') ) { 
	print "Cannot release $domain " . $d->errstr() . "\n";
}
else { ok(12); }
if ($verbose) { print 'released request issued'."\n"; }
if ( ! $d->delete($domain) ) { 
	print "Cannot delete $domain " . $d->errstr() . "\n";
}
else { ok(13); }
if ($verbose) { print 'delete request issued'."\n"; }
