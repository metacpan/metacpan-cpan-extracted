# -*- Mode: Perl; -*-

=head1 NAME

20_client_contact.t - Test the basic functionality of Net::YAR contacts

=cut

use strict;
use Test::More tests => 25;
use Data::Dumper qw(Dumper);

if (! $ENV{'TEST_NET_YAR_CONNECT'}) {
    SKIP: {
        skip('Set TEST_NET_YAR_CONNECT to "user/pass/host" to run tests requiring connection', 25);
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
    SKIP: {
        require Data::Dumper;
        my $s = Data::Dumper::Dumper($r);
        $s =~ s/^/\#/gm;
        print $s;
        skip("TEST_NET_YAR_CONNECT could not connect: ".(eval { $r->code } || 'unknown'), 23);
    };
    exit;
}


my $username = $user . '_api_user_20_client_contact';
my $info = {
    username   => $username,
    password   => '123qwe',
    email      => 'foo@bar.com',
    phone      => '+1.8017659400',
    first_name => 'George',
    last_name  => 'Jones',
};

$r = $yar->user_create($info);
if ($r) {
    ok($r, "Correctly could setup user ($@)");
} else {
    my $n = 0;
    $r = $yar->user_info({username => $username});
    if ($r) {
        my $rows = $yar->contact_search({where => {field => 'user_id', value => $r->data->{'user_id'}}})->data->{'rows'};
        foreach my $row (@$rows) {
            $yar->contact_delete({contact_id => $row->{'contact_id'}});
            $n++;
        }
    }
    ok($r, "Found exising user - deleted $n existing contacts");
}

my $user_id = $r->data->{'user_id'};
ok($user_id, "Got a new user_id ($user_id)");

END {
    if ($user_id) {
        $r = $yar->user_delete({username => $username});
        ok($r, "Deleted the user") || diag Dumper $r;
    }
};

###----------------------------------------------------------------###
### add an contact

my $first_name = 'George';
$info = {
    tld          => 'com',
    user_id      => $user_id,
    first_name   => $first_name,
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

for (qw(tld user_id first_name last_name email street1 city province country phone)) {
    local $info->{$_};
    ok(! $yar->contact_create($info), "Correctly couldn't setup contact with missing $_");
}

###----------------------------------------------------------------###

ok($r = $yar->contact_create($info), "Correctly could setup contact");
my $contact_id = $r->data->{'contact_id'};
ok($contact_id, "Got a contact id ($contact_id)");

END {
    if ($user_id) {
        if ($contact_id) {
            ok($yar->contact_delete({contact_id => $contact_id}), "Deleted the id");
        } else {
            ok(1, "Contact already deleted");
        }
    }
}

###----------------------------------------------------------------###

ok(($r = $yar->contact_info({contact_id => $contact_id})), "Ran contact_info");
ok($r->data->{'first_name'} eq $first_name, "First name was set properly");

ok(($r = $yar->contact_update({contact_id => $contact_id, first_name => 'Joe'})), "Ran contact_update");
ok($r->data->{'n_rows'} == 1, "Updated a row");

ok(($r = $yar->contact_update({contact_id => $contact_id, first_name => 'Joe'})), "Ran contact_update");
ok($r->data->{'n_rows'} == 0, "Row already updated");
