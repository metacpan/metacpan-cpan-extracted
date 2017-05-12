# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Citadel.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('Net::Citadel') };

use Data::Dumper;
use Config::YAML;

my $config = Config::YAML->new( config => "t/test.yaml" );

my $c;

eval {
    $c = new Net::Citadel (host => $config->{host});
}; exit if $@;

eval {
    $c->login ($config->{account}->{username}, 'zzz');
}; ok ($@, 'login failed');

# login/out
$c->login ($config->{account}->{username}, $config->{account}->{password});
$c->logout and pass ('logout');

$c->login ($config->{account}->{username}, $config->{account}->{password});

$c->citadel_echo ('rrrrrr') and pass ('echo');
$c->citadel_time and pass ('time');

my $inforef = $c->citadel_info;
is_deeply( $#{$inforef}, q{24}, "Expected 0 thru 23 information lines." );


my (%mrtg_info, $key_count);

%mrtg_info = $c->citadel_mrtg ('users');
$key_count = grep { defined } values %mrtg_info;
TODO: {
    local $TODO ='Getting undefined when testing?';
    is( $keycount, q{4}, 'citadel_mrtg returns 4 keys for type users.' );
}
%mrtg_info = $c->citadel_mrtg ('messages');
$key_count = grep { defined } values %mrtg_info;
TODO: {
    local $TODO ='Getting undefined when testing?';
    is( $keycount, q{3}, 'citadel_mrtg returns 3 keys for type messages.' );
}

# try to get rid of any testing artefacts
eval {
    $c->retract_room ('ramsti');
    $c->retract_room ('rimsti');
};

eval {
    $c->retract_floor ('rumsti');
};


# testing flooring

my @floors = $c->floors;
#warn Dumper \@floors;

ok (grep ($_->{name} eq 'Main Floor', @floors), 'Main Floor found');

$c->assert_floor ('rumsti');

my @floors2 = $c->floors;
ok (scalar @floors2 == scalar @floors + 1 &&
    grep ($_->{name} eq 'rumsti', @floors2), 'create floor'); # close enough

$c->assert_floor ('rumsti') and pass ('recreation of same floor');
#warn Dumper \@floors2;

$c->retract_floor ('rumsti');
@floors2 = $c->floors;
ok (scalar @floors2 == scalar @floors &&
    grep ($_->{name} ne 'rumsti', @floors2), 'floor removed'); # close enough

my @rooms = $c->rooms ('Main Floor');
ok (scalar @rooms &&
    grep ($_->{name} eq 'Lobby', @rooms), 'some rooms in main floor');

$c->retract_floor ('rumsti') and pass ('floor re-removal');

$c->assert_floor ('remsti');

my @rooms2 = $c->rooms ('remsti');
#warn "before assert". Dumper \@rooms2;
$c->assert_room ('remsti', 'ramsti');
$c->assert_room ('remsti', 'rimsti');
my @rooms3 = $c->rooms ('remsti');
#warn "after assert". Dumper \@rooms3;
ok (scalar @rooms2 + 2 == scalar @rooms3 &&
    grep ($_->{name} eq 'ramsti', @rooms3), 'room created'); # close enough

$c->assert_room ('remsti', 'ramsti') and pass ('recreate room');

$c->retract_room ('ramsti');
my @rooms4 = $c->rooms ('remsti');
#warn "after retract". Dumper \@rooms4;
ok (scalar @rooms2 + 1 == scalar @rooms4 &&
    grep ($_->{name} ne 'ramsti', @rooms4), 'room removed'); # close enough

$c->retract_room ('rimsti');
eval {                                   ############# CITADEL BUG
    $c->retract_floor ('remsti');
};

# users

$c->create_user ('TestUser', 'xxx');

{
    my $c2 = new Net::Citadel (host => $config->{host});
    $c2->login ('TestUser', 'xxx') and pass ('login new user');
    $c2->logout and pass ('logout new user');

}

$c->change_user ('TestUser', password => 'yyy');
{
    my $c2 = new Net::Citadel (host => $config->{host});
    $c2->login ('TestUser', 'yyy') and pass ('login new password');
    $c2->logout and pass ('logout new password');
}

$c->remove_user ('TestUser');
{
    my $c2 = new Net::Citadel (host => $config->{host});
    eval {
	$c2->login ('TestUser', 'yyy');
    }; ok ($@, 'user does not exist any more');
}

$c->logout;


__END__

eval {
}; like  ($@, qr/already exists/, 'floor rumsti already existed');


