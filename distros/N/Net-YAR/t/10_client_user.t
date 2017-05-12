# -*- Mode: Perl; -*-

=head1 NAME

01_user.t - Test the basic functionality of Net::YAR users

=cut

use strict;
use Test::More tests => 15;
use Data::Dumper qw(Dumper);

if (! $ENV{'TEST_NET_YAR_CONNECT'}) {
    SKIP: {
        skip('Set TEST_NET_YAR_CONNECT to "user/pass/host" to run tests requiring connection', 15);
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
        skip("TEST_NET_YAR_CONNECT could not connect: ".(eval { $r->code } || 'unknown'), 19);
    };
    exit;
}

###----------------------------------------------------------------###

my $username = $user . '_api_user_10_client_user';
my $info = {
    username   => $username, # username is optional
    password   => '123qwe',
    email      => 'foo@fastdomain.com',
    phone      => '+1.8017659400',
    first_name => 'George',
    last_name  => 'Jones',
};

$r = $yar->user_create($info);
ok($r, "Correctly could setup user");
my $user_id = $r->data->{'user_id'};
ok($user_id, "Got a new user_id ($user_id)");

###----------------------------------------------------------------###

$r = $yar->user_info({username => $username});
ok($r, "Ran user_info");
is($r->data->{'password'}, '-', 'Password is deprecated');

$r = $yar->user_info({user_id => 1});
ok(! $r, "Ran user_info");
ok($r->code eq 'not_found', 'Got correct not_found');

###----------------------------------------------------------------###

$r = $yar->user_update({
    username => $username,
    password => '',
});
ok(!$r, "Ran user_update with only password (deprecated)") || diag Dumper($r);

###----------------------------------------------------------------###

$r = $yar->user_search({select => ['username'], where => [{field => 'username', value => $username}]});
ok($r, "Ran search");


###----------------------------------------------------------------###

$r = $yar->user_delete({username => $username});
ok($r, "Ran user_delete");
ok($r->data->{'n_rows'} == 1, "Got the correct n_rows");

$r = $yar->user_delete({username => $username});
ok($r, "Ran user_delete again");
ok($r->data->{'n_rows'} == 0, "Got the correct n_rows again");
