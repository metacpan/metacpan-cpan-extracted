#!/usr/bin/perl
use lib '../lib';
use SAP::BC::XMLRFC;
use Thread qw(async);
use Thread::Queue;

$| = 1;
$THREADS = 1;
$TOT = 0;
$BIG = 0;

my $userid = 'Administrator';
my $passwd = 'manage';
my $server="http://kogut.local.net:5555";
my $service = 'WAS:readTable';
my $service1 = 'WAS:readReport';
my $tab = 'TRDIR';
my $tab1 = 'T000';

#  Create the queue of SAP Reports to be processed
my $Q = new Thread::Queue;

# Create a new RFC Object
my $xmlrfc = new SAP::BC::XMLRFC( SERVER => $server,
				  USERID => $userid,
				  PASSWD => $passwd );

my $i = $xmlrfc->Iface( $service );
$i->Parm('QUERY_TABLE')->value($tab);
$i->Parm('ROWCOUNT')->value('100');
push (@row,'NAME LIKE \'RDDIT%\'');
$i->Tab('OPTIONS')->addrow(\@row);
$xmlrfc->xmlrfc( $i );

my %name = {};
while (my $row = $i->Tab('DATA')->nextrow){
    my ( $r ) = $row->{WA} =~ /^(.*?)\s+.*$/;
    $cnt++;
    print "Program on Queue: $cnt -  $r \n";
    $Q->enqueue( $r );
}

# push enough null values on queue so all threads will exit
for $i ( 1..$THREADS){
  $Q->enqueue( undef );
}


# start main report processing
$before = scalar localtime;

for my $i (1..$THREADS){
    push( @threads, async{ &read_report( $i ) } );
};

print "Number of Threads: ", scalar @threads, "\n";

# wait for them to end
for $i ( @threads ){
  print "Waiting threads.... \n";
  $i->join();
}

# print out the results
$after = scalar localtime;
print "Start Time: $before \n";
print "Finish Time: $after \n";

print "Total: $TOT \n";

exit 0;


sub read_report {

  my $thno = shift;

  while ( my $program = $Q->dequeue ){
  my $rows = 1;
    {
      my $xmlrfc = new SAP::BC::XMLRFC( SERVER => $server,
					USERID => $userid,
					PASSWD => $passwd );

      my $i = $xmlrfc->Iface( $service1 );
      $i->Parm('PROGRAM')->value($program);
      $xmlrfc->xmlrfc( $i );
      lock( $TOT );
      my $rows = $i->Tab('QTAB')->rowcount;
      print "Thread no. $thno - does $program - Rows $rows \n";
      $TOT += $rows;
      lock($BIG);
      $BIG = $rows if $rows > $BIG;
    }
  }

}















