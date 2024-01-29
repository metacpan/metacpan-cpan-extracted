#!perl -T

use strict;
use warnings;
use Test::More;

if ( $ENV{API_KEY} ) {
    plan tests => 65;
} else {
    plan( skip_all => "API_KEY env var required for usage testing." );
}

use_ok('Mslm');

my $mslm;
$mslm = Mslm->new($ENV{API_KEY});
isa_ok( $mslm, "Mslm", '$mslm' );

my $real_resp = $mslm->email_verify->single_verify('support@mslm.io');
ok( $real_resp, "single_verify() return a hash when querying a valid email" );
is($real_resp->{username}, "support", "username must be `support`");
is($real_resp->{domain}, "mslm.io", "domain must be `mslm.io`");
is($real_resp->{accept_all}, "0", "accept_all must be `0`");
is($real_resp->{has_mailbox}, "1", "has_mailbox must be `1`");
is($real_resp->{status}, "real", "status must be `real`");
is($real_resp->{disposable}, "0", "disposable must be `0`");
is($real_resp->{malformed}, "0", "malformed must be `0`");
is($real_resp->{email}, 'support@mslm.io', 'email must be `support@mslm.io`');
is($real_resp->{suggestion}, '', 'suggestion must be empty string');
is($real_resp->{role}, '1', 'role must be `1`');
is($real_resp->{free}, '0', 'free must be `0`');
my $expected_real_mx = [
    { "host" => "ASPMX.L.GOOGLE.COM.", "pref" => 1 },
    { "host" => "ALT1.ASPMX.L.GOOGLE.COM.", "pref" => 5 },
    { "host" => "ALT2.ASPMX.L.GOOGLE.COM.", "pref" => 5 },
    { "host" => "ALT3.ASPMX.L.GOOGLE.COM.", "pref" => 10 },
    { "host" => "ALT4.ASPMX.L.GOOGLE.COM.", "pref" => 10 }
];
_compare_mx_arrays($real_resp->{mx}, $expected_real_mx);

my $fake_resp = $mslm->email_verify->single_verify('fakefakefake@mslm.io');
ok( $fake_resp, "single_verify() returned a hash when querying a valid email" );
is($fake_resp->{username}, "fakefakefake", "username must be `fakefakefake`");
is($fake_resp->{domain}, "mslm.io", "domain must be `mslm.io`");
is($fake_resp->{accept_all}, "0", "accept_all must be `0`");
is($fake_resp->{has_mailbox}, "0", "has_mailbox must be `0`");
is($fake_resp->{status}, "fake", "status must be `fake`");
is($fake_resp->{disposable}, "0", "disposable must be `0`");
is($fake_resp->{malformed}, "0", "malformed must be `0`");
is($fake_resp->{email}, 'fakefakefake@mslm.io', 'email must be `fakefakefake@mslm.io`');
is($fake_resp->{suggestion}, '', 'suggestion must be empty string');
is($fake_resp->{role}, '0', 'role must be `0`');
is($fake_resp->{free}, '0', 'free must be `0`');
my $expected_fake_mx = [
    { "host" => "ASPMX.L.GOOGLE.COM.", "pref" => 1 },
    { "host" => "ALT1.ASPMX.L.GOOGLE.COM.", "pref" => 5 },
    { "host" => "ALT2.ASPMX.L.GOOGLE.COM.", "pref" => 5 },
    { "host" => "ALT3.ASPMX.L.GOOGLE.COM.", "pref" => 10 },
    { "host" => "ALT4.ASPMX.L.GOOGLE.COM.", "pref" => 10 }
];
_compare_mx_arrays($fake_resp->{mx}, $expected_fake_mx);

my $disposable_resp = $mslm->email_verify->single_verify('asdfasdf@temp-mail.org');
ok( $disposable_resp, "single_verify() returned a hash when querying a valid email" );
is($disposable_resp->{username}, "asdfasdf", "username must be `asdfasdf`");
is($disposable_resp->{domain}, "temp-mail.org", "domain must be `temp-mail.org`");
is($disposable_resp->{accept_all}, "1", "accept_all must be `1`");
is($disposable_resp->{has_mailbox}, "1", "has_mailbox must be `1`");
is($disposable_resp->{status}, "disposable", "status must be `disposable`");
is($disposable_resp->{disposable}, "1", "disposable must be `1`");
is($disposable_resp->{malformed}, "0", "malformed must be `0`");
is($disposable_resp->{email}, 'asdfasdf@temp-mail.org', 'email must be `asdfasdf@temp-mail.org`');
is($disposable_resp->{suggestion}, '', 'suggestion must be empty string');
is($disposable_resp->{role}, '0', 'role must be `0`');
is($disposable_resp->{free}, '1', 'free must be `1`');
my $expected_disposable_mx = [
    { "host" => "mx.yandex.net.", "pref" => 10 }
];
_compare_mx_arrays($disposable_resp->{mx}, $expected_disposable_mx);

my $malformed_resp = $mslm->email_verify->single_verify('malformedemail');
ok( $malformed_resp, "single_verify() returned a hash when querying a valid email" );
is($malformed_resp->{username}, "", "username must be empty string");
is($malformed_resp->{domain}, "", "domain must be empty string");
is($malformed_resp->{accept_all}, "0", "accept_all must be `0`");
is($malformed_resp->{has_mailbox}, "0", "has_mailbox must be `0`");
is($malformed_resp->{status}, "fake", "status must be `disposable`");
is($malformed_resp->{disposable}, "0", "disposable must be `0`");
is($malformed_resp->{malformed}, "1", "malformed must be `1`");
is($malformed_resp->{email}, 'malformedemail', 'email must be `malformedemail`');
is($malformed_resp->{suggestion}, '', 'suggestion must be empty string');
is($malformed_resp->{role}, '0', 'role must be `0`');
is($malformed_resp->{free}, '0', 'free must be `0`');
my $expected_malformed_mx = [];
_compare_mx_arrays($malformed_resp->{mx}, $expected_malformed_mx);

sub _compare_mx_arrays {
    my ($real_mx, $expected_mx) = @_;

    # Ensure both arrays have the same length
    is(scalar @$real_mx, scalar @$expected_mx, "Same number of elements in both arrays");

    # Check if each element in the actual 'mx' array is present in the expected 'mx' array
    if (scalar @$real_mx == scalar @$expected_mx) {
        foreach my $actual_mx (@$real_mx) {
            my $found = 0;
            foreach my $expected_mx_record (@$expected_mx) {
                if ($actual_mx->{host} eq $expected_mx_record->{host} && $actual_mx->{pref} == $expected_mx_record->{pref}) {
                    $found = 1;
                    last;
                }
            }
            ok($found, "Found mx record with host: $actual_mx->{host} and pref: $actual_mx->{pref} in expected mx");
        }
    }
    
}
