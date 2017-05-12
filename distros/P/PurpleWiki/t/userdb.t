# userdb.t

use strict;
use Test;

BEGIN { plan tests => 5 };

use PurpleWiki::Database::User::UseMod;
use PurpleWiki::Config;

my $configdir = 't';
my $userName = '@blueoxen*eekim';

#########################

my $config = new PurpleWiki::Config($configdir);

# create new user database
my $userDb = PurpleWiki::Database::User::UseMod->new;

# create new user $userName
my $user = $userDb->createUser;
ok($user->id == 1001);
$user->username($userName);
$userDb->saveUser($user);
ok(-f "$configdir/user/1/1001.db");

# create another user
$user = undef;
$user = $userDb->createUser;
ok($user->id == 1002);

# now open user $userName again
$user = undef;
$user = $userDb->loadUser($userDb->idFromUsername($userName));
ok($user->id == 1001);
ok($user->username eq $userName);

sub END { 
    # delete user database
    unlink("$configdir/user/usernames.db");
    unlink("$configdir/user/1/1001.db");
    unlink("$configdir/user/2/1002.db");
    rmdir("$configdir/user/0");
    rmdir("$configdir/user/1");
    rmdir("$configdir/user/2");
    rmdir("$configdir/user/3");
    rmdir("$configdir/user/4");
    rmdir("$configdir/user/5");
    rmdir("$configdir/user/6");
    rmdir("$configdir/user/7");
    rmdir("$configdir/user/8");
    rmdir("$configdir/user/9");
    rmdir("$configdir/user");
}
