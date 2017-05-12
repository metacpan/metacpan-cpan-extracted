use lib 't/lib';
use Test::Monitis tests => 15, live => 1;

note 'Action addSubAccount';

my $test_email = 'test@user.com';
my $response   = api->sub_accounts->add(
    firstName => 'foo',
    lastName  => 'bar',
    email     => $test_email,
    password  => 'test password',
    group     => 'test group'
);


isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{userId}, qr/^\d+$/, 'API returned user id';

my $user_id = $response->{data}{userId};

note 'Action subAccounts';

my $sub_accounts = api->sub_accounts->get;

isa_ok $sub_accounts, 'ARRAY', 'JSON response ok';

my $exists = scalar grep { $_->{account} eq $test_email } @$sub_accounts;
ok $exists, 'account created';

# If no user were created, I suppose user already exists
$user_id ||= $sub_accounts->[0]->{id};

$response =
  api->sub_accounts->add_pages(userId => $user_id, pageNames => 'Monitors');

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action subAccountPages (sub_accounts->pages)';

my $sub_account_pages = api->sub_accounts->pages;
isa_ok $sub_account_pages, 'ARRAY', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

my ($user) = grep { $_->{id} eq $user_id } @$sub_account_pages;
ok $user, 'user found';

$exists = scalar grep { $_ eq 'Monitors' } @{$user->{pages}};
ok $exists, 'page exists in user account';

note 'Action deletePagesFromSubAccount (sub_accounts->delete_pages)';

$response = api->sub_accounts->delete_pages(
    userId    => $user_id,
    pageNames => 'Monitors'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action deleteSubAccount (sub_accounts->delete)';

$response = api->sub_accounts->delete(userId => $user_id);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
