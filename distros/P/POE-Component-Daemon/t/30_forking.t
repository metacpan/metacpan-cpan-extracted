#!/usr/bin/perl -w
# $Id: 30_forking.t 704 2010-12-15 20:29:47Z fil $

use strict;

#########################

use Test::More ( tests => 14 );

use t::Test;
use POSIX qw( SIGTERM SIGHUP );
pass( 'loaded' );

#########################
my $PORT = spawn_server('eg/forking', 0);
my $P1=connect_server($PORT);

#########################
$/="\r\n";
$P1->print("DONGS!!\n");
my $rep=$P1->getline();
chomp($rep);

is( $rep, '???', "Got confused answer" );

#########################
$P1->print("PING\n");
$rep=$P1->getline();
chomp($rep);
is( $rep, 'PONG', "PING-PONG" );


#########################
$P1->print("PID\n");
my $PID1=$P1->getline();
chomp($PID1);

ok( ($PID1 =~ /^(\d+)$/), "Got PID" );
$PID1=$1;

$P1->print("PID\n");
my $PID2=$P1->getline();
chomp($PID2);
is( $PID1, $PID1, "Got the same PID");

$P1->print("KERNEL\n");
my $KID1=$P1->getline();
chomp($KID1);
ok( $KID1, "Got kernel ID from first server" );

#########################
my $P2=connect_server($PORT);

#########################
$P2->print("PING\n");
$rep=$P2->getline();
chomp($rep);
is( $rep, 'PONG', "PING-PONG" );

$P2->print("PID\n");
$PID2=$P2->getline();
chomp($PID2);

isnt( $PID2, $PID1, "Different PID" );


$P2->print("KERNEL\n");
my $KID2=$P2->getline();
chomp($KID2);
ok( $KID2, "Got kernel ID from second server" );

isnt( $KID2, $KID1, "Different Kernel IDs" );

#########################
$P1->print( "LOGFILE\n" );
my $file = $P1->getline();
chomp( $file );

ok( ($file and -f $file), "Created a logfile" ) or warn $file;
END { unlink $file if $file }



#########################
$P1->print("DONE\n");

$P1=connect_server($PORT);
$P1->print("PID\n");
my $PID3=$P1->getline();
chomp($PID3);

ok( !( $PID3 == $PID2 or $PID3 == $PID1 ), "All different PIDs");

$P1->print("PARENT\n");
my  $PID4 = $P1->getline();
chomp( $PID4 );
# warn "Parent is $PID4";



#########################
my $P3 = connect_server( $PORT, 1 );
my_sleep( 3 );

my $alarm;
my $P4;
eval {
    local $SIG{ALRM} = sub { $alarm=1; die "ALARM"; };
    alarm( 5 );
    $P1 = connect_server( $PORT, 1 );
    alarm( 0 );
};
warn $@ if $@;
ok( (! $P4), "Max 3 children" );

#########################
$P1->print("DONE\n");
my_sleep( 3 );

$alarm = 0;
eval {
    local $SIG{ALRM} = sub { $alarm=1; die "ALARM"; };
    alarm( 5 );
    $P1 = connect_server( $PORT, 1 );
    alarm( 0 );
};
warn $@ if $@;
ok( $P1, "Max 3 children" );


#########################
$P2->print("DONE\n");

diag "Parent is $PID4";
kill SIGTERM, $PID4 if $PID4;
# system("killall forking");

