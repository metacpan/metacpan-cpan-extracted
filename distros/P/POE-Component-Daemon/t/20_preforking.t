#!/usr/bin/perl -w
# $Id: 20_preforking.t 761 2011-05-18 18:37:53Z fil $

use strict;

#########################

use Test::More ( tests=>16 );

use t::Test;
use POSIX qw( SIGHUP SIGTERM );

pass( "loaded" );

#########################
my $PORT = spawn_server('eg/preforking', 0);

my $P1 = connect_server($PORT);
my $P2 = connect_server($PORT);


#########################
$/="\r\n";
$P1->print("PID\n");
my $PID1=$P1->getline();

chomp($PID1);
ok( ($PID1 =~ /^(\d+)$/), "Got the PID ($PID1)");
$PID1=$1;

$P1->print("PID\n");
my $PID2=$P1->getline();
chomp($PID2);
is( $PID2, $PID1, "Same PID");




#########################
$P1->print( "LOGFILE\n" );
my $file = $P1->getline();
chomp( $file );

ok( ($file and -f $file), "Created a logfile ($file)" );

my $file2 = "$file.OLD";

rename $file, $file2;

ok( (-f $file2), "Moved the log file" ) 
    or diag( "Unable to move $file to $file2: $!" );

kill SIGHUP, $PID1;
my_sleep( 3 );
ok( ($file and -f $file), "Created a new logfile" );

END { unlink $file if $file }
END { unlink $file2 if $file2 }



#########################
$P2->print("PID\n");
$PID2=$P2->getline();
chomp($PID2);

isnt( $PID2, $PID1, "Different PID ($PID2)" );

#########################
$P1->print("DONE\n");
$P2->print("DONE\n");

# Allow new processes to spawn
my_sleep( 2 );


#########################
$P1 = connect_server($PORT);
$P2 = connect_server($PORT);

foreach my $p ( $P1, $P2 ) {
    $p->print( "PID\n" );
    my $PID3 = $p->getline();
    chomp( $PID3 );
    ok( $PID3, "Got PID ($PID3)" );
    isnt( $PID3, $PID1, "Not PID1" );
    isnt( $PID3, $PID2, "Not PID2" );
}

#########################
$P1->print( "STATUS\n" );
my @status;
my $line;
while( defined( $line = $P1->getline() ) ) {
    chomp $line;
    last if $line eq 'DONE';
    push @status, $line;
}

is( $status[1], "    Pre-forking server, we are a child", "Preforking" )
    or warn "Line 2 = $status[1]";

ok( $status[4] =~ /Slots \[.*r.*r.*\]/, "2 slots in 'r'" );

# warn join "\n", @status;



#########################
$P1->print( "PEEK\n" );
my @peek;
while( defined( $line = $P1->getline() ) ) {
    chomp $line;
    last if $line eq 'DONE';
    push @peek, $line;
}

my $peek = join "\n", @peek;
ok( (( 4 < @peek and $peek =~ /session \d+ \(Daemon\)/ ) || 
                $peek=~/Can't locate POE/ ), 
        "Peeked into kernel" ) or warn join "\n", @peek;


#########################
$P2->print("PARENT\n");
my $PID3 = $P2->getline();
chomp( $PID3 );

diag "Parent is $PID3";
kill SIGTERM, $PID3 if $PID3;
