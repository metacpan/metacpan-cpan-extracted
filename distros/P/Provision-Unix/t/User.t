
use strict;
use warnings;

use English qw( -no_match_vars );
use Test::More;

use lib "lib";
use Provision::Unix;
use Provision::Unix::User;

my $prov = Provision::Unix->new( debug => 0 );
my $user;

eval { $user = Provision::Unix::User->new( prov => $prov, fatal => 0 ); };
if ( ! $user ) {
    my $message = $EVAL_ERROR; chop $message;
    $message .= " on " . $OSNAME;
    plan skip_all => $message;
} 
else {
    plan 'no_plan';
};

ok( defined $user, 'get Provision::Unix::User object' );
ok( $user->isa('Provision::Unix::User'), 'check object class' );

# exists
my $user_that_exists_by_default
    = lc($OSNAME) eq 'darwin'  ? 'daemon'
    : lc($OSNAME) eq 'linux'   ? 'daemon'
    : lc($OSNAME) eq 'freebsd' ? 'daemon'
    :                            'daemon';

my $r = $user->exists($user_that_exists_by_default);
if ( $r ) {
    ok( $r, 'exists' );
}
else {
    warn "seriously? Your $OSNAME system doesn't have the user $user_that_exists_by_default?";
};

# _is_valid_username
ok( $user->_is_valid_username('provunix'), '_is_valid_username valid' )
    or diag $prov->{errors}[-1]{errmsg};
ok( !$user->_is_valid_username('unix_geek'), '_is_valid_username invalid' );
ok( !$user->_is_valid_username('unix,geek'), '_is_valid_username invalid' );
ok( $user->_is_valid_username('provunix'),   '_is_valid_username valid' );

my $gid      = 65530;
my $uid      = 65530;
my $group    = 'provunix';
my $username = 'provuser';

#   invalid request, no username
ok( !eval {
        $user->create(
            test_mode => 1,
            usrename  => $username,
            uid       => $uid,
            gid       => $gid,
            debug     => 0,
            fatal     => 0,
        );
    },
    'create user, missing username param'
);

#   invalid username, invalid chars
ok( !$user->create(
        username => 'bob_builder',
        uid      => $uid,
        gid      => $gid,
        debug    => 0,
    ),
    'create user, invalid chars'
);

#   invalid username, too short
ok( !$user->create(
        username => 'b',
        uid      => $uid,
        gid      => $gid,
        debug    => 0,
    ),
    'create user, too short'
);

#   invalid username, too long
ok( !$user->create(
        username => 'bobthebuilderiscool',
        uid      => $uid,
        gid      => $gid,
        debug    => 0,
    ),
    'create user, too long'
);


# get_salt
my $length = 8;
my $salt = $user->get_salt( $length );
# the salt may include a prefix if crypt supports encryption better than DES
ok( length($salt) >= $length, "get_salt, $salt" );


# get_crypted_password
$salt = 'ylhEgHiL';
my $crypt = 'ylkljnQCaRzYE';
$r = $user->get_crypted_password( 'password', 'ylhEgHiL' );
ok( $r eq $crypt, "get_crypted_password, $r") or warn $r;

if ( $OSNAME =~ /FreeBSD|Linux|Solaris/i ) {
    $crypt = '$1$ylhEgHiL$86s2tXl.1oj4J/cisUqN1/';
    $r = $user->get_crypted_password( 'password', '$1$ylhEgHiL' );
    ok( $r eq $crypt, "get_crypted_password, $r") or warn $r;
};


SKIP: {
    skip "you are not root", 7 if $EFFECTIVE_USER_ID != 0;

    # destroy user first, as group deletion may fail if a user exists with the
    # group as its primary gid.

    # destroy user if exists
    ok( $user->destroy(
            username => $username,
            debug    => 0,
        ),
        "destroy $username if exists"
    ) if $user->exists($username);

    # destroy group if exists
    ok( $user->destroy_group(
            group => $group,
            gid   => $gid,
            debug => 0,
        ),
        "destroy_group $group if exists"
    ) if $user->exists_group($group);

    # create the group first, for the same reason as above.

    # create group
    ok( $user->create_group(
            group => $group,
            gid   => $gid,
            debug => 0,
        ),
        "create group $group ($gid)"
    );

    # create user, valid request in test mode
    ok( $user->create(
            username  => $username,
            uid       => $uid,
            gid       => $gid,
            debug     => 0,
            test_mode => 1,
        ),
        "create user $username, test mode"
    );

    # destroy user, valid request in test mode
    ok( $user->destroy(
            username  => $username,
            debug     => 0,
            test_mode => 1,
        ),
        "destroy user $username, test mode"
    );

    #   valid request

    # only run if provuser does not exist
    if ( !`grep '^$username:' /etc/passwd` ) {
        ok( $user->create(
                username => $username,
                uid      => $uid,
                gid      => $gid,
                debug    => 0,
            ),
            "create $username"
        );


# quota_set
SKIP: {
    my $uid;
    eval { require Quota; $uid = getpwnam($username) };

    skip "Quota.pm is not installed", 1 if $@;

    ok( $user->quota_set( user => $username, debug => 0 ), 'quota_set' );
}


        ok( $user->destroy(
                username => $username,
                debug    => 0,
            ),
            "destroy $username"
        );
    }
}

# user
#ok ( $prov->user ( vals=>{action=>'create', user=>'matt2'} ), 'user');

# web
#ok ( $prov->web ( vals=>{action=>'create', vhost=>'foo.com'} ), 'web');

# what_am_i
#   invalid request, no username

# quota_set
#my $mod = "Quota";
#if (eval "require $mod")
#{
#    ok ( $prov->quota_set( user=>'matt', debug=>0 ), 'quota_set');
#};

# user
#ok ( $prov->user ( vals=>{action=>'create', user=>'matt2'} ), 'user');

# web
#ok ( $prov->web ( vals=>{action=>'create', vhost=>'foo.com'} ), 'web');

# what_am_i
#ok ( $prov->what_am_i(), 'what_am_i');

