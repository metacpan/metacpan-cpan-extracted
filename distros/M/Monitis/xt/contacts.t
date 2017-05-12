use lib 't/lib';
use Test::Monitis tests => 20, live => 1;

note 'Action addContact (contacts->add)';

my $response = api->contacts->add(
    group       => 'test group',
    firstName   => 'Jon',
    lastName    => 'Doe',
    account     => '3153473',
    contactType => '3',            # ICQ
    timezone    => '-300'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{contactId}, qr/^\d+$/, 'API returned contact id';
like $response->{data}{confirmationKey}, qr/^\d+$/,
  'API returned confirmation key';

my $contact_id       = $response->{data}{contactId};
my $confirmation_key = $response->{data}{confirmationKey};

note 'Action confirmContact (contacts->confirm)';

$response = api->contacts->edit(
    contactId => $contact_id,
    lastName  => 'Smith'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action editContact (contacts->edit)';

$response = api->contacts->edit(
    contactId => "$contact_id",
    firstName => 'John',
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action activateContact (contacts->activate)';

$response = api->contacts->activate(contactId => $contact_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action deactivateContact (contacts->deactivate)';

$response = api->contacts->deactivate(contactId => $contact_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action contactsList';

$response = api->contacts->get;

isa_ok $response, 'ARRAY', 'JSON response ok';
my ($exists) = grep { $_->{contactId} == $contact_id } @{$response};
ok $exists, 'Contact exists';

$contact_id ||= $response->[0]->{contactId};

note 'Action contactGroupList';

$response = api->contacts->get_groups;

isa_ok $response, 'ARRAY', 'JSON response ok';

note 'Action recentAlerts';

$response = api->contacts->get_recent_alerts;

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status},   'ok',    'status ok';
isa_ok $response->{data}, 'ARRAY', 'response data ok';

note 'Action deleteContact (contact->delete)';

$response = api->contacts->delete(contactId => $contact_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
