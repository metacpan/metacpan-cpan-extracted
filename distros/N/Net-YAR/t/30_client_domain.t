# -*- Mode: Perl; -*-

=head1 NAME

02_client_domain.t - Test the basic functionality of Net::YAR domains

=cut

use constant N_TESTS => 51;
use strict;
use Test::More tests => N_TESTS;
use Data::Dumper qw(Dumper);

if (! $ENV{'TEST_NET_YAR_CONNECT'}) {
    SKIP: {
        skip('Set TEST_NET_YAR_CONNECT to "user/pass/host" to run tests requiring connection', N_TESTS);
    };
    exit;
}
my ($user, $pass, $host) = split /\//, $ENV{'TEST_NET_YAR_CONNECT'};

###----------------------------------------------------------------###

use_ok('Net::YAR');

my $yar;
ok(($yar = Net::YAR->new), "Was able to create a Net::YAR object");

ok(($yar = Net::YAR->new({
    api_user => $user,
    api_pass => $pass,
    api_host => $host,
})), "Got new object");

my $r = eval { $yar->noop };
if (! $r) {
    $r = "$@" if ! defined $r;
    SKIP: {
        my $s = Dumper($r);
        $s =~ s/^/\#/gm;
        print $s;
        skip("TEST_NET_YAR_CONNECT could not connect: ".(eval { $r->code } || 'unknown'), N_TESTS - 3);
    };
    exit;
}


my $username = $user . '_api_user'.time;
my $info = {
    username   => $username,
    password   => '123qwe',
    email      => 'foo@bar.com',
    phone      => '+1.8017659400',
    first_name => 'George',
    last_name  => 'Jones',
};


$r = $yar->user_create($info) || $yar->user_info({username => $username});
ok($r, "Correctly could setup user ($@)");
my $user_id = $r->data->{'user_id'};
ok($user_id, "Got a new user_id ($user_id)");

my $domain_id;
END {
    if ($user_id) {
        if ($domain_id) {
            ok(! $yar->user_delete({username => $username}), "Can't delete user because order and invoice history exists");
        } else {
            ok($yar->user_delete({username => $username}), "Can delete the first user");
        }
    }
}

###----------------------------------------------------------------###
### add an contact

my $contact_info = {
    tld          => 'com',
    user_id      => $user_id,
    first_name   => 'George',
    last_name    => 'Jones',
    organization => 'FastDomain Test',
    email        => 'foo@fastdomain.com',
    street1      => 'Techway',
    street2      => '',
    city         => 'Orem',
    province     => 'UT',
    postal_code  => '84058',
    country      => 'US',
    phone        => '+1.8017659400',
    fax          => '',
};

###----------------------------------------------------------------###

ok($r = $yar->contact_create($contact_info), "Correctly could setup contact");
my $contact_id = $r->data->{'contact_id'};
ok($contact_id, "Got a contact id ($contact_id)");

END {
    if ($user_id) {
        if ($contact_id) {
            $r = $yar->contact_delete({contact_id => $contact_id});
            ok($r, "Can delete the first contact id because we only did domain->db_ methods");
        } else {
            ok(1, "Skipping contact delete");
        }
    }
}

###----------------------------------------------------------------###

my $nameservers  = ["ns1.fastdomain.com", "ns2.fastdomain.com"];
my $nameservers2 = ['ns1.fastdomain.org', 'ns2.fastdomain.org']; # use a different tld so they will go through more easily

my $domain = $user .'-test-20-client-domain.com';
$domain =~ tr/a-z0-9\-.//cd;

my $domain_info = {
    user_id    => $user_id,
    domain     => $domain,
    duration   => 3,
    registrant => {contact_id => $contact_id},  # use already created contact
    admin      => $contact_info,                # create another contact
    billing    => {contact_id => 'registrant'}, # use the same contact as the registrant
    tech       => {contact_id => 'admin'},      # use the same contact as the admin
    nameservers => $nameservers,
};

### we are going to use domain->db_ methods to do the testing because we can instantly delete the domains,
### and no money will be docked from the account, and the records of the domain should be permanently removed.

for (qw(user_id domain duration registrant admin billing tech)) {
    local $domain_info->{$_};
    ok(! $yar->domain->db_register($domain_info), "Correctly couldn't setup domain with missing $_");
}

### - dont test further if there aren't enough funds
if ($yar->balance->data->{'balance'} < 100) {
    SKIP: {
        skip("Agent doesn't have enought balance to test domain operations", N_TESTS - 16);
    };
    exit;
}

###----------------------------------------------------------------###

$r = $yar->domain->db_register($domain_info);
ok($r, "Registered the domain $domain");
my $contact_id2 = $r->data->{'contact_id_admin'};
ok($contact_id2, "Got another contact id during setup");
$domain_id = $r->data->{'domain_id'};

###----------------------------------------------------------------###

$r = $yar->domain->info({domain => $domain});
ok($r, "Got the domain info");
ok($r->data->{'contact_id_registrant'} eq $contact_id,  "Got the right contact id for registrant");
ok($r->data->{'contact_id_admin'}      eq $contact_id2, "Got the right contact id for admin");
ok($r->data->{'nameservers'}->[0] eq $nameservers->[0], "Got the right nameserver");

###----------------------------------------------------------------###

$r = $yar->domain->db_update({
    domain             => $domain,
    contact_id_admin   => $contact_id,
    nameservers_add    => $nameservers2,
    nameservers_remove => $nameservers,
});
ok($r, "Ran update");
if (! $r) {
    print Dumper $r;
}

$r = $yar->domain->info({domain => $domain});
ok($r, "Got the domain info");
ok($r->data->{'contact_id_admin'} eq $contact_id, "Got the right contact id for admin");
ok($r->data->{'nameservers'}->[0] eq $nameservers2->[0], "Got the right nameserver");

###----------------------------------------------------------------###
### try and delete and then setup using only one command

$r = $yar->domain->db_delete({domain => $domain});
ok($r, "Ran db_delete");
ok($r->data->{'n_rows'} == 1, "One row gone");

$r = $yar->domain->db_delete({domain => $domain});
ok($r, "Ran db_delete");
ok($r->data->{'n_rows'} == 0, "No more rows");

my $domain_info2 = {
    user    => {
        username   => "$username-2", # new user
        password   => '123qwe',
        email      => 'foo@bar.com',
        phone      => '+1.8017659400',
        first_name => 'George',
        last_name  => 'Jones',
    },
    domain     => $domain, # same domain
    duration   => 2,
    registrant => {contact_id => 'admin'},
    admin      => {
        first_name   => 'George',
        last_name    => 'Jones',
        organization => 'FastDomain Test',
        email        => 'foo@fastdomain.com',
        street1      => 'Techway',
        street2      => '',
        city         => 'Orem',
        province     => 'UT',
        postal_code  => '84058',
        country      => 'US',
        phone        => '+1.8017659400',
        fax          => '',
    },
    billing    => {contact_id => 'admin'},
    tech       => {contact_id => 'admin'},
    nameservers => [
        "ns1.fastdomain.com",
        "ns2.fastdomain.com",
    ],
};

ok(($r = $yar->domain->db_register($domain_info2)), "Ran db_register with all info");
$info = eval { $r->data } || {};
ok($info->{'contact_id_admin'}, "Got an admin contact");
ok($info->{'contact_id_admin'} eq $info->{'contact_id_registrant'}, "Regisrant matched admin");
ok($info->{'contact_id_admin'} eq $info->{'contact_id_billing'},    "Billing matched admin");
ok($info->{'contact_id_admin'} eq $info->{'contact_id_tech'},       "Tech matched admin");
ok($info->{'domain_id'},  "Got a domain_id");
ok($info->{'user_id'},    "Got a user_id");
ok($info->{'offer_id'},   "Got an offer_id");
ok($info->{'invoice_id'}, "Got an invoice_id");
ok($info->{'order_id'},   "Got an order_id");
ok($info->{'pending'},    "Got a pending status");

$r = $yar->invoice->info({invoice_id => $info->{'invoice_id'}});
ok($r, "Got invoice info");

$r = $yar->order->info({order_id => $info->{'order_id'}});
ok($r, "Got order info");

$r = $yar->order->search({
    select => ['order_id', 'date_completed'],
    where  => [{
        field => "date_completed",
        op => '>',
        value => '2007-03-01',
    }],
    rows_per_page => 10,
    order_by => ['date_completed'],
});
ok($r, "Ran order search");

$r = $yar->offer->info({offer_id => $info->{'offer_id'}});
ok($r, "Got offer info");

$r = $yar->offer->search({
    select => [qw(duration offer_id agent_price)],
    where  => [
        {field => 'tld', value => 'com'},
        {field => 'service_code', value => 'domain_reg'}
    ],
});
ok($r, "Ran offer search");

# print Dumper $r->data;


ok($r = $yar->domain->db_delete({ domain     => $domain}), "Deleted the domain");
ok($r = $yar->contact->db_delete({contact_id => $info->{'contact_id_admin'}}), "Deleted the contact - we can because we used db_methods");
ok($r = $yar->order->delete({  order_id   => $info->{'order_id'}}),         "Deleted the order   - we can because we used db_methods");
ok($r = $yar->invoice->delete({invoice_id => $info->{'invoice_id'}}),       "Deleted the invoice - we can because we used db_methods");
ok($r = $yar->user->delete({user_id => $info->{'user_id'}}),                "Deleted the user    - we can because we used db_methods");

###----------------------------------------------------------------###
