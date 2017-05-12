#!/usr/bin/perl -w

use strict;
use Net::Z3950::AsyncZ qw(:header :record :errors asyncZOptions);
use Net::Z3950::AsyncZ::Errors qw(suppressErrors);

my $actual_total = 0;
my $server_num = 0;
my $DB = "DB.txt";
open (DB,$DB);
my $start = time();
my @dbases = <DB>;
close(DB);

my $zl = check(1, scalar(@dbases-1));              
print "Time: ", (time() - $start)/60, " minutes ";
print "Total: $actual_total\n";


#-------------	END MAIN --------

my @servers =();

sub check {
my ($start, $max) = @_;
my $server_count = 0;

print "$start  $max\n";
for(my $i = $start; $i < $max; $i++) {
    chomp $dbases[$i];
    my ($inst, $server,$port, $db, $rest) = split /;/, $dbases[$i];
    $actual_total++;
    next if !$server && !$port && !$db;
    $servers[$server_count] = [$server,$port, $db];
    $server_count++;
}
  print "servers queried -- check()-- $server_count\n";
  return doQuery(\@servers);

}

sub doQuery {
my $servers = shift;
my $query = '  @attr 1=1003  "Henry James" ';
my $log = suppressErrors();
my $zl = Net::Z3950::AsyncZ->new(
                               servers=>$servers, monitor=>1200,
                               query=>$query, timeout=>25, num_to_fetch=>1,
		   	       log=>$log, swap_check => 25,
                               cb=>\&output2
 			);
return $zl;
}




#-----------  END MAIN ------------

sub output2 {  
my($index, $array) = @_;


my $pat = Net::Z3950::AsyncZ::Report::get_pats();

 foreach my $line(@$array) {
    return if noZ_Response($line);
    next if isZ_Header($line);     
   (print  "[", ++$server_num, "] ", Z_serverName($line), ":$servers[$index]->[1]/$servers[$index]->[2]\n"), next if isZ_ServerName($line);
   print $line,"\n\n"; 
   last;
 }
  
}

__END__

