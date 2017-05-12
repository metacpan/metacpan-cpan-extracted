# $Id: ipc.pl,v 1.4 2003/05/04 04:05:52 tower Exp $


open IPCS, "  ipcs | ";
$uid = shift;
print "usage: $0 <user_id>\n" and exit if !$uid;
$type = "shm";

while(<IPCS>) {
  last if /Queue/;
  $type =  "sem" if /semid/;  

  /(0x[a-fA-F0-9]+)\s+(\d+)\s+(\w+)/;
  next if /^\n/;
  print "$type: ", $1, " $2 $3\n" if $1;
  $cmd = "ipcrm $type $2";
  system ($cmd) if $3 =~ /$uid/;
}


