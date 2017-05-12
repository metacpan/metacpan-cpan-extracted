# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
#use lib '/testusers/luxnet/perl/ssl/ssl';
use Reuters::SSL;

$loaded = 1;
print "\t\t\t\t\t\t";
print "ok 1\n";

######################### End of black magic.

my $fs = "\x1C";
my $gs = "\x1D";
my $rs = "\x1E";
my $us = "\x1F";

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$SIG{INT} = 'CleanShutDown';

my $retval;
my $channel;
my $shutdown = 0;
my $updates = 0;

sub CleanShutDown()
{
  $SIG{INT} = 'CleanShutDown';
  $shutdown = 1;
}

#$EventInfo{'1'} = 'abc';

print "Events received from reuters are no longer shown.\n";
print "Instead of this, only one character is shown.\n";
print " # = Image \n";
print " . = Update \n";
print " I = Status Information \n";
print " ? = Unknown to perl-module message \n";
print " - = Item Status Information \n";
print " + = Contribution Status Information \n";
print " \n";

print "sslInit \t\t\t\t\t";
$retval = sslInit();
print $retval==0 ? "ok 2\n" : "not ok 2\n";

print "sslErrorLog ./mysslerrors.log\t\t\t";
$retval = sslErrorLog("./mysslerrors.log", 1024);
print $retval==0 ? "ok 3\n" : "not ok 3\n";

print "sslSnkMount \t\t\t\t\t";
$retval = sslSnkMount('');
print $retval>=0 ? "ok 4\n" : "not ok 4\n";

$channel = $retval;
print "Information: ssl Channel is: $channel\n";

$fd = -1;
$dist = 'abcdefghijk';
print "sslGetProperty Channel FileDescriptor \t\t";
($retval,$fd) = sslGetProperty($channel,1);
print $retval==0 ? "ok 5\n" : "not ok 5\n";

print "sslRegisterCallBack \t\t\t\t";
$retval = sslRegisterCallBack($channel,1,\&CallBack);
print $retval==0 ? "ok 6\n" : "not ok 6\n";

print "sslSnkOpen \t\t\t\t\t";
$retval = sslSnkOpen($channel, 'IDN_SELECTFEED', 'N2_UBMS');
print $retval==0 ? "ok 7\n" : "not ok 7\n";

#$error = sslGetErrorText($channel);
#print "Errortext is: $error\n";


print "sslDispatchEvent ... \n(until CTRL-C is pressed or 10 Updates are received by Callback) \n";
while (!$shutdown)
{
  $retval = sslDispatchEvent($channel, 1000);
}
print "\t\t\t";
print $retval==0 ? "ok 8\n" : "not ok 8\n";

print "sslSnkClose \t\t\t\t\t";
$retval = sslSnkClose($channel, 'IDN_SELECTFEED', 'N2_UBMS');
print $retval==0 ? "ok 9\n" : "not ok 9\n";

$updates = 0;
$shutdown = 0;

print "sslSnkOpen \t\t\t\t\t";
$retval = sslSnkOpen($channel, 'IDN_SELECTFEED', 'EUR=');
print $retval==0 ? "ok 10\n" : "not ok 10\n";

print "sslPostEvent \t\t\t\t\t";
$InsertInfo{'ServiceName'} = 'DCS_MARKETLINK';
$InsertInfo{'InsertName'} = 'ACTIVEST38';
$InsertInfo{'InsertTag'} = 0;
$FS = "\x1C";
$GS = "\x1D";
$RS = "\x1E";
$US = "\x1F";
#$InsertInfo{'Data'} = "\x1C316\x1DACTIVEST38\x1E338\x1F...\x1C";
$InsertInfo{'Data'} = "\x1C316\x1DACTIVEST38\x1E338\x1F...\x1C";
$InsertInfo{'DataLength'} = 24;
$refInsertInfo = \%InsertInfo;
$retval = sslPostEvent($channel, 25, $refInsertInfo);
print $retval==0 ? "ok 11\n" : "not ok 11\n";
print sslGetErrorText($channel) . "\n";


print "sslDispatchEvent ... \n(until CTRL-C is pressed or 10 Updates are received by Callback) \n";
while (!$shutdown)
{
  $retval = sslDispatchEvent($channel, 1000);
}
print "\t\t\t\t\t";
print $retval==0 ? "ok 12\n" : "not ok 12\n";

print "sslSnkClose \t\t\t\t\t";
$retval = sslSnkClose($channel, 'IDN_SELECTFEED', 'EUR=');
print $retval==0 ? "ok 13\n" : "not ok 13\n";

# No continued close to this open is necessary
print "sslSnkOpen (Snapshot) \t\t\t\t";
$retval = sslSnkOpen($channel, 'IDN_SELECTFEED', 'EUR=', SSL_RT_SNAPSHOT); 
print $retval==0 ? "ok 14\n" : "not ok 14\n";

$imageReceived = 0;
while (!$imageReceived and !$retval)
{
  $retval = sslDispatchEvent($channel, 1000);
}

print "sslDismount \t\t\t\t\t";
$retval = sslDismount($channel);
print $retval==0 ? "ok 15\n" : "not ok 15\n";

sub CallBack()
{
my %hData;

  $locChannel = shift;
  $Event = shift;
  $reflocEventInfo = shift;
  %locEventInfo = %{$reflocEventInfo};

  if ($Event == 0 or $Event == 1)
  {
    #print "CallBack for $Event";
    #foreach $key ( keys %locEventInfo )
    #{
      #if ($key ne 'Data' )
      #{
        #print "Callback:  $key  $locEventInfo{$key}\n";
      #}
    #}
  
    %hData = splitData($locEventInfo{"Data"});
    #foreach $key ( sort keys %hData )
    #{
      #print join (':',unpack("C*",$key));
      #print "Data:  <$key>  $hData{$key}\n";
    #}
    #print "$locEventInfo{'ServiceName'} ";
    #print "$locEventInfo{'ItemName'} ";
    #print "Name=<$hData{'3'}>, Bid=<$hData{'22'}>, Ask=<$hData{'25'}>\n"; 
    print "." if $Event == 1;
    print "#" if $Event == 0;
    $updates++ if $Event == 1;
    $shutdown = 1 if $updates >= 10;
    $imageReceived = 1 if $Event == 0;
  
  }
  elsif ( ($Event >= 7) and ($Event <= 11) )
  {
    #print "$locEventInfo{'ServiceName'} Status<$Event> $locEventInfo{'ItemName'} $locEventInfo{'Text'}\n";
    print "-";
  }
  elsif ( ($Event >= 12) and ($Event <= 13) )
  {
  #  print "Insert_" . ($Event == 12 ? "ACK" : "NAK") . " $locEventInfo{'Data'} for $locEventInfo{'ServiceName'}: $locEventInfo{'InsertName'}\n";
    print "+";
  }
  elsif ( $Event == 30 )
  {
  #  print "$locEventInfo{'ServiceName'} \t$locEventInfo{'ServiceStatus'}\n";
    print "I";
  }
  else
  {
  #  print "Event $Event\n";
    foreach $key ( keys %locEventInfo )
    {
  #    print "$key $locEventInfo{$key}\n";
    }
    print "?";
  }
}

sub splitData()
{

my %rHash;

  $data = shift;
  @chars = unpack("C*",$data);
  $tdata = join (':', @chars);
  #$tdata = ":" . $tdata . ":";
  @list = split(/:30:/,$tdata);
  
  foreach $item (@list)
  {
    @chars = split (/:/,$item);
    #print "Item: " . pack ("C*",@chars) . "\n";
    $line = pack("C*",@chars);
    @chars = unpack("C*",$line);
    $tdata = join (':',@chars);
    @list1 = split(/:31:/,$tdata);
    #print "Item: " . pack("C*",split(/:/,$list1[0])) . "\t\t" . 
		#pack("C*",split(/:/,$list1[1])) . "\n";
    $rHash{pack("C*",split(/:/,$list1[0]))} = pack("C*",split(/:/,$list1[1]));
  }
  foreach $key ( keys %rHash )
  {
    #print "Data:  $key  $rHash{$key}\n";
  }
  return %rHash;
}

