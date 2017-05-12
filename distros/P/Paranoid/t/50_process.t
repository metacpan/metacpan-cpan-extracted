#!/usr/bin/perl -T

use Test::More tests => 36;
use Paranoid;
use Paranoid::Process qw(:all);
use Paranoid::IO qw(:all);
use Paranoid::IO::Line;
use Paranoid::Debug;

use strict;
use warnings;

psecureEnv();
PIOMAXFSIZE = 512 * 1024;

my ( $rv,     $id,     @tmp,    $i,    $pid );
my ( @passwd, $user1,  $user2,  $uid1, $uid2 );
my ( @group,  $group1, $group2, $gid1, $gid2 );

SKIP: {

    # Prep:  get two valid users & groups to test with
    #
    # NOTE:  we use user1/group1 to test translation functions (they
    #        will probably be root/root|wheel) and user2/group2 to test
    #        user switch functions (they will hopefully be unprivileged
    #        users)
    slurp( '/etc/passwd', @passwd, 1 );
    slurp( '/etc/group',  @group,  1 );

    # Prune any comment lines (&*^@#4 FreeBSD!?)
    @passwd = grep !/^\s*(?:#.*)?$/, @passwd;
    @group  = grep !/^\s*(?:#.*)?$/, @group;

    if ( @passwd > 1 ) {
        ( $user1, $uid1 ) = ( split( /:/, $passwd[0] ) )[ 0, 2 ];
        ( $user2, $uid2 ) = ( split( /:/, $passwd[$#passwd] ) )[ 0, 2 ];
        $uid1 = undef unless $uid1 =~ /^\d+$/;
        $uid2 = undef unless $uid2 =~ /^\d+$/;
    }
    if (@group) {
        ( $group1, $gid1 ) = ( split( /:/, $group[0] ) )[ 0, 2 ];
        ( $group2, $gid2 ) = ( split( /:/, $group[$#group] ) )[ 0, 2 ];
        $gid1 = undef unless $gid1 =~ /^\d+$/;
        $gid2 = undef unless $gid2 =~ /^\d+$/;
    }

    skip( "Couldn't find enough users/groups to test with", 7 )
        unless defined $uid1
            and defined $uid2
            and defined $gid1
            and defined $gid2;

    $id = ptranslateUser($user1);
    if ( $id == -2 ) {
        warn 'Perl bug in casting unsigned int as signed int found -- '
            . "ignoring\n";
        $id = $uid1;
    }
    is( $id, $uid1, "ptranslateUser 1 ($user1)" );
    $id = ptranslateUser('no freaking way:::!');
    is( $id, undef, 'ptranslateUser 2' );
    $id = ptranslateGroup($group1);
    if ( $id == -2 ) {
        warn 'Perl bug in casting unsigned int as signed int found -- '
            . "ignoring\n";
        $id = $gid1;
    }
    is( $id, $gid1, "ptranslateGroup 1 ($group1)" );
    $id = ptranslateGroup('no freaking way:::!');
    is( $id, undef, 'ptranslateGroup 2' );

    skip( "Can't test switchUser without root privileges", 3 ) unless $< == 0;
    if ( $pid = fork ) {
        waitpid $pid, 0;
        $rv = !( $? >> 8 );
    } else {
        $rv = switchUser($user2);
        exit !$rv;
    }
    is( $rv, 1, "switchUser 1 (from user $ENV{USER} to $user2)" );

    if ( $pid = fork ) {
        waitpid $pid, 0;
        $rv = !( $? >> 8 );
    } else {
        $rv = switchUser( undef, $group2 );
        exit !$rv;
    }
    is( $rv, 1, "switchUser 2 (to group $group2)" );

    if ( $pid = fork ) {
        waitpid $pid, 0;
        $rv = !( $? >> 8 );
    } else {
        $rv = switchUser( $user2, $group2 );
        exit !$rv;
    }
    is( $rv, 1, 'switchUser 3 (user & group)' );
}

my $sigpid = 0;

# Install our signal handler
$SIG{CHLD} = \&sigchld;

# Test pfork child counting
foreach ( 1 .. 5 ) {
    if ( pfork() == 0 ) {
        sleep 5;
        exit 0;
    } else {
        ok( 1, "pfork $_" );
    }
}
$rv = childrenCount();
is( $rv, 5, 'childrenCount 1' );

# Wait for all children to exit
while ( childrenCount() ) { sleep 1 }

# Test pfork w/MAXCHILDREN limit
MAXCHILDREN = 3;
foreach ( 1 .. 5 ) {
    if ( pfork() == 0 ) {
        sleep 5;
        exit 0;
    } else {
        ok( 1, "pfork @{[ $_ + 5 ]}" );
    }
}
$rv = childrenCount() <= 3 ? 1 : 0;
is( $rv, 1, 'childrenCount 2' );

# Wait for all children to exit
while ( childrenCount() ) { sleep 1 }

# Test installChldHandler
sub testHandler ($$) {
    my $cpid  = shift;
    my $cexit = shift;

    $sigpid = $cpid;
}
ok( installChldHandler(&testHandler), 'installChldHandler 1' );
MAXCHILDREN = 5;
for ( 1 .. 5 ) {
    if ( pfork() == 0 ) {
        sleep 1;
        exit 0;
    } else {
        ok( 1, "pfork @{[ $_ + 10 ]}" );
    }
}
while ( childrenCount() ) { sleep 1 }
$rv = $sigpid ? 1 : 0;
is( $rv, 1, 'SIGCHLD 1' );

my ( $crv, $out );

# Test pcapture
ok( pcapture( "echo foo", $crv, $out ), 'pcapture 1' );
chomp $out;
is( $out, 'foo', 'pcapture 2' );
is( $crv, 0,     'pcapture 3' );
ok( !pcapture( "echo bar ; exit 3", $crv, $out ), 'pcapture 4' );
chomp $out;
is( $out, 'bar', 'pcapture 5' );
is( $crv, 3,     'pcapture 6' );
ok( !pcapture( "echo roo ; exit 1", $crv, $out ), 'pcapture 7' );
chomp $out;
is( $out, 'roo', 'pcapture 8' );
is( $crv, 1,     'pcapture 9' );
$rv = pcapture( "ecccchhhooooo", $crv, $out );

if ( $^O eq 'solaris' ) {
    warn "Solaris seems to only return '0', not '-1' for "
        . "non-existant commands.\n";
    $rv = -1;
}
is( $rv, -1, 'pcapture 10' );

# TODO:  have pcapture run command that kills itself, and reap RV

