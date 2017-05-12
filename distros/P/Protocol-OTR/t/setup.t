
use strict;
use warnings;
use Test::More;

BEGIN { $ENV{PROTOCOL_OTR_ENABLE_QUICK_RANDOM} = 1 }

use Protocol::OTR qw( :constants );
use File::Temp qw( tempdir );

my $tmpdir = tempdir( 'XXXXXXXX', DIR => "t/", CLEANUP => 1 );

my $otr = Protocol::OTR->new(
    {
        privkeys_file => "$tmpdir/otr.private_key",
        contacts_file => "$tmpdir/otr.fingerprints",
        instance_tags_file => "$tmpdir/otr.instance_tags",
    }
);
isa_ok($otr, 'Protocol::OTR');

my $act = $otr->account('user@domain', 'protocol');

isa_ok($act, 'Protocol::OTR::Account');

is($act->name, 'user@domain', '$act->name');
is($act->protocol, 'protocol', '$act->protocol');
like($act->fingerprint, qr/^(?:[A-F0-9]{8} ){4}[A-F0-9]{8}$/, '$act->fingerprint');

my $act2 = $act->ctx->find_account('user@domain', 'protocol');

isa_ok($act2, 'Protocol::OTR::Account');
is($act2->name, $act->name, 'and matches name');
is($act2->protocol, $act->protocol, 'and matches protocol');
is($act2->fingerprint, $act->fingerprint, 'and matches fingerprint');

my @accounts = $otr->accounts();
is(scalar @accounts, 1, "Context has one account");

is($accounts[0]->name, $act->name, 'and matches name');
is($accounts[0]->protocol, $act->protocol, 'and matches protocol');
is($accounts[0]->fingerprint, $act->fingerprint, 'and matches fingerprint');


my $cnt = $act->contact('contact@domain', '12345678 90ABCDEF 12345678 90ABCDEF 12345678', 0);

isa_ok($cnt, 'Protocol::OTR::Contact');

is(scalar $act->contacts(), 1, "Account has one contact");

is($cnt->name, 'contact@domain', '$cnt->name');
is($cnt->account->name, 'user@domain', '$cnt->account->name');

my @fingerprints = $cnt->fingerprints();

is(scalar @fingerprints, 1, "Contact has one fingerprint");

is($fingerprints[0]->hash, '12345678 90ABCDEF 12345678 90ABCDEF 12345678', '$fingerprint->hash');
is($fingerprints[0]->status, 'Unused', '$fingerprint->status');
ok(! $fingerprints[0]->is_verified, '$fingerprint->is_verified');
ok($fingerprints[0]->set_verified(1), '$fingerprint->set_verified');
ok($fingerprints[0]->is_verified, '...which works');
is($fingerprints[0]->contact->name, 'contact@domain', '$fingerprint->contact->name');
is($fingerprints[0]->contact->account->name, 'user@domain', '$fingerprint->contact->account->name');

my $cnt2 = $act->contact('contact@domain', '87654321 FEDCBA09 87654321 FEDCBA09 87654321', 1);

isa_ok($cnt2, 'Protocol::OTR::Contact');

is(scalar $act->contacts(), 1, "Account has still single contact");

is($cnt2->name, 'contact@domain', '$cnt->name');
is($cnt2->account->name, 'user@domain', '$cnt->account->name');

@fingerprints = sort { $a->hash cmp $b->hash } $cnt2->fingerprints();

is(scalar @fingerprints, 2, "Contact has two fingerprints");

is($fingerprints[0]->hash, '12345678 90ABCDEF 12345678 90ABCDEF 12345678', '$fingerprint->hash');
is($fingerprints[0]->status, 'Unused', '$fingerprint->status');
ok($fingerprints[0]->is_verified, '$fingerprint->is_verified');
is($fingerprints[0]->contact->name, 'contact@domain', '$fingerprint->contact->name');
is($fingerprints[0]->contact->account->name, 'user@domain', '$fingerprint->contact->account->name');

is($fingerprints[1]->hash, '87654321 FEDCBA09 87654321 FEDCBA09 87654321', '$fingerprint->hash');
is($fingerprints[1]->status, 'Unused', '$fingerprint->status');
ok($fingerprints[1]->is_verified, '$fingerprint->is_verified');
is($fingerprints[1]->contact->name, 'contact@domain', '$fingerprint->contact->name');
is($fingerprints[1]->contact->account->name, 'user@domain', '$fingerprint->contact->account->name');


my $cnt3 = $act->contact('contact3@domain', '00000000 00000000 00000000 00000000 00000000');

isa_ok($cnt3, 'Protocol::OTR::Contact');

is(scalar $act->contacts(), 2, "Account has now two contacts");

is($cnt3->name, 'contact3@domain', '$cnt->name');
is($cnt3->account->name, 'user@domain', '$cnt->account->name');

@fingerprints = $cnt3->fingerprints();

is(scalar @fingerprints, 1, "Contact has single fingerprints");

is($fingerprints[0]->hash, '00000000 00000000 00000000 00000000 00000000', '$fingerprint->hash');
is($fingerprints[0]->status, 'Unused', '$fingerprint->status');
ok(! $fingerprints[0]->is_verified, '$fingerprint->is_verified');
is($fingerprints[0]->contact->name, 'contact3@domain', '$fingerprint->contact->name');
is($fingerprints[0]->contact->account->name, 'user@domain', '$fingerprint->contact->account->name');


my $cnt4 = $act->contact('contact@domain');

isa_ok($cnt4, 'Protocol::OTR::Contact');

is(scalar $act->contacts(), 2, "Account has still two contacts");

is($cnt4->name, 'contact@domain', '$cnt->name');
is($cnt4->account->name, 'user@domain', '$cnt->account->name');

@fingerprints = sort { $a->hash cmp $b->hash } $cnt4->fingerprints();

is(scalar @fingerprints, 2, "Contact has two fingerprints");

is($fingerprints[0]->hash, '12345678 90ABCDEF 12345678 90ABCDEF 12345678', '$fingerprint->hash');
is($fingerprints[0]->status, 'Unused', '$fingerprint->status');
ok($fingerprints[0]->is_verified, '$fingerprint->is_verified');
is($fingerprints[0]->contact->name, 'contact@domain', '$fingerprint->contact->name');
is($fingerprints[0]->contact->account->name, 'user@domain', '$fingerprint->contact->account->name');

is($fingerprints[1]->hash, '87654321 FEDCBA09 87654321 FEDCBA09 87654321', '$fingerprint->hash');
is($fingerprints[1]->status, 'Unused', '$fingerprint->status');
ok($fingerprints[1]->is_verified, '$fingerprint->is_verified');
is($fingerprints[1]->contact->name, 'contact@domain', '$fingerprint->contact->name');
is($fingerprints[1]->contact->account->name, 'user@domain', '$fingerprint->contact->account->name');

is($cnt4->active_fingerprint, undef, "Contact has no active fingerprint");

done_testing;

