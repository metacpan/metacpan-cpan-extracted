use strict;
use warnings;

use Test::More tests => 11;
use Mojolicious::Plugin::DigestAuth::Util 'checksum';

BEGIN { use_ok('Mojolicious::Plugin::DigestAuth::DB'); }

sub each_user
{
    my ($users, $callback) = @_;
    for my $realm (keys %$users) {
	while(my ($u, $p) = each %{$users->{$realm}}) {
	    my $hash = checksum($u, $realm, $p);
	    $callback->($realm, $u, $hash);
	}
    }
}

eval { Mojolicious::Plugin::DigestAuth::DB::Hash->new };
like($@, qr/usage:/);

eval { Mojolicious::Plugin::DigestAuth::DB::File->new('does_not_exist') };
like($@, qr/error opening/i);

eval { Mojolicious::Plugin::DigestAuth::DB::File->new('t/bad_htdigest') };
like($@, qr/invalid entry: sshaw/);

my $users = {
    realm1 => {
	sshaw => 'B1gpAss',
	bob   => 'bob', 
	''    => ''
    },	    
    realm2 => {
	monkey => '_DeathMarch_'
    }
};	

my $store = Mojolicious::Plugin::DigestAuth::DB::Hash->new($users);
each_user($users, sub { 
    my ($realm, $user, $hash) = @_;
    is($store->get($realm, $user), $hash);
});

$users = {
    my_realm => {
	sshaw => 'my_password',
    },	    
    fofinha => {
	aa => ''
    },
    X => {
        '' => ''
    }
};	

my $file = 't/good_htdigest';
$store = Mojolicious::Plugin::DigestAuth::DB::File->new($file);
each_user($users, sub {
    my ($realm, $user, $hash) = @_;
    is($store->get($realm, $user), $hash);
});
