use Test::More;
use Net::Iperf::Parser;


my $num = 0;
my $line;

my $p = new Net::Iperf::Parser();

# not is_valid
$num++;
$p->parse($line);
isnt($p->is_valid, 1, "Parsing failed");
$num++;
$p->parsecsv($line);
isnt($p->is_valid, 1, "Parsing failed CSV");

$line = "[  6] local 195.32.69.195 port 47294 connected with 172.16.11.45 port 5001\n";
$num++;
$p->parse($line);
isnt($p->is_valid, 1, "Not a valid line");

$line = "[  3]  0.0- 2.0 sec   512 KBytes  2.10 Mbits/sec\n";
$num++;
$p->parse($line);
is($p->is_valid, 1, "Valid line");
$num++;
isnt($p->is_process_avg, 1, "Not process avg");
$num++;
isnt($p->is_global_avg, 1, "Not global avg");

$line = "[SUM]  0.0- 2.0 sec  2.00 MBytes  8.39 Mbits/sec\n";
$p->parse($line);
$num++;
is($p->is_process_avg, 1, "Is a process avg");
$num++;
isnt($p->is_global_avg, 1, "But Not global avg");

$line = "[SUM]  0.0-20.4 sec  16.1 MBytes  6.64 Mbits/sec\n";
$p->parse($line);
$num++;
is($p->is_process_avg, 1, "Is a process avg");
$num++;
is($p->is_global_avg, 1, "And a global avg");


# CSV


$num++;
$line = '';
$p->parsecsv($line);
isnt($p->is_valid, 1, "Parsing failed");

# valid
$line = "20190708110018,4.6.1.5,41369,1.2.9.5,5001,6,0.0-1.0,0,57344\n";
$p->parsecsv($line);
$num++;
is($p->is_valid, 1, "Valid parser");
$num++;
is($p->duration, 1, "Valid duration");
$num++;
is($p->speed, 57344, "Valid speed");
$num++;
isnt($p->is_process_avg, 1, "This is not an avg process item");
$num++;
isnt($p->is_global_avg, 1, "and is not an avg global item");

$line = "20190708110018,4.6.1.5,41369,1.2.9.5,5001,-1,0.0-1.0,0,1357344\n";
$p->parsecsv($line);
$num++;
is($p->is_process_avg, 1, "This is an avg process item");
$num++;
isnt($p->is_global_avg, 1, "and is not an avg global item");

$line = "20190708110018,4.6.1.5,41369,1.2.9.5,5001,-1,0.0-10.0,0,13573440\n";
$p->parsecsv($line);
$num++;
is($p->duration, 10, "Valid duration");
$num++;
is($p->is_process_avg, 1, "This is an avg process item");
$num++;
is($p->is_global_avg, 1, "and is an avg global item");


#print $p->dump . "\n";

done_testing($num);
