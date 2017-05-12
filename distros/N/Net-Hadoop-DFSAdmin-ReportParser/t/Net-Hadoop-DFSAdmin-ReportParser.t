use strict;
use warnings;
use utf8;
use Test::More;

use Net::Hadoop::DFSAdmin::ReportParser;

my @lines = <DATA>;

subtest 'parse' => sub {
    my $r = Net::Hadoop::DFSAdmin::ReportParser->parse(@lines);
    is ($r->{capacity_configured}, 35339596017664);
    is ($r->{capacity_present}, 33022305342866);
    is ($r->{capacity}, 33022305342866);
    is ($r->{remaining}, 14420841762816);
    is ($r->{used}, 18601463580050);
    is ($r->{used_percent}, 56.33);
    is ($r->{blocks_under_replicated}, 15);
    is ($r->{blocks_with_corrupt_replicas}, 6);
    is ($r->{blocks_missing}, 0);
};

subtest 'parse_datanodes' => sub {
    my $r = Net::Hadoop::DFSAdmin::ReportParser->parse(@lines);
    is ($r->{datanodes_num}, 9);
    is ($r->{datanodes_available}, 9);
    is ($r->{datanodes_dead}, 0);
    is (scalar(@{$r->{datanodes}}), 9);
    my $d1 = $r->{datanodes}->[0];
    is ($d1->{name}, '10.130.60.133:50010');
    is ($d1->{status}, 'normal');
    is ($d1->{capacity_configured}, 3905711992832);
    is ($d1->{used_dfs}, 2059255336448);
    is ($d1->{used_non_dfs}, 268170412544);
    is ($d1->{remaining}, 1578286243840);
    is ($d1->{used_percent}, 52.72);
    is ($d1->{remaining_percent}, 40.41);
    is ($d1->{last_connect}, 'Wed Feb 01 12:56:17 JST 2012');
};

subtest 'aggregated_data' => sub {
    my $r = Net::Hadoop::DFSAdmin::ReportParser->parse(@lines);
    is ($r->{used_non_dfs_total}, 2317290674798);
    is ($r->{used_non_dfs_total_percent}, 6.56);
    is ($r->{remaining_percent}, 40.81);
    is ($r->{datanode_remaining_min}, 1569816522752);
    is ($r->{datanode_remaining_max}, 1629772095488);
};

done_testing;

__DATA__
Configured Capacity: 35339596017664 (32.14 TB)
Present Capacity: 33022305342866 (30.03 TB)
DFS Remaining: 14420841762816 (13.12 TB)
DFS Used: 18601463580050 (16.92 TB)
DFS Used%: 56.33%
Under replicated blocks: 15
Blocks with corrupt replicas: 6
Missing blocks: 0

-------------------------------------------------
Datanodes available: 9 (9 total, 0 dead)

Name: 10.130.60.133:50010
Decommission Status : Normal
Configured Capacity: 3905711992832 (3.55 TB)
DFS Used: 2059255336448 (1.87 TB)
Non DFS Used: 268170412544 (249.75 GB)
DFS Remaining: 1578286243840(1.44 TB)
DFS Used%: 52.72%
DFS Remaining%: 40.41%
Last contact: Wed Feb 01 12:56:17 JST 2012


Name: 10.130.60.139:50010
Decommission Status : Normal
Configured Capacity: 3937075302400 (3.58 TB)
DFS Used: 2076082566620 (1.89 TB)
Non DFS Used: 250875202084 (233.65 GB)
DFS Remaining: 1610117533696(1.46 TB)
DFS Used%: 52.73%
DFS Remaining%: 40.9%
Last contact: Wed Feb 01 12:56:19 JST 2012


Name: 10.130.60.137:50010
Decommission Status : Normal
Configured Capacity: 3937075302400 (3.58 TB)
DFS Used: 2059076667694 (1.87 TB)
Non DFS Used: 248226539218 (231.18 GB)
DFS Remaining: 1629772095488(1.48 TB)
DFS Used%: 52.3%
DFS Remaining%: 41.4%
Last contact: Wed Feb 01 12:56:18 JST 2012


Name: 10.130.60.134:50010
Decommission Status : Normal
Configured Capacity: 3937075302400 (3.58 TB)
DFS Used: 2075824386427 (1.89 TB)
Non DFS Used: 248039292549 (231 GB)
DFS Remaining: 1613211623424(1.47 TB)
DFS Used%: 52.73%
DFS Remaining%: 40.97%
Last contact: Wed Feb 01 12:56:17 JST 2012


Name: 10.130.60.132:50010
Decommission Status : Normal
Configured Capacity: 3905711992832 (3.55 TB)
DFS Used: 2059208580427 (1.87 TB)
Non DFS Used: 271775842997 (253.11 GB)
DFS Remaining: 1574727569408(1.43 TB)
DFS Used%: 52.72%
DFS Remaining%: 40.32%
Last contact: Wed Feb 01 12:56:18 JST 2012


Name: 10.130.60.136:50010
Decommission Status : Normal
Configured Capacity: 3937075302400 (3.58 TB)
DFS Used: 2059923480902 (1.87 TB)
Non DFS Used: 252310290106 (234.98 GB)
DFS Remaining: 1624841531392(1.48 TB)
DFS Used%: 52.32%
DFS Remaining%: 41.27%
Last contact: Wed Feb 01 12:56:17 JST 2012


Name: 10.130.60.138:50010
Decommission Status : Normal
Configured Capacity: 3937075302400 (3.58 TB)
DFS Used: 2068757280266 (1.88 TB)
Non DFS Used: 251378563574 (234.11 GB)
DFS Remaining: 1616939458560(1.47 TB)
DFS Used%: 52.55%
DFS Remaining%: 41.07%
Last contact: Wed Feb 01 12:56:18 JST 2012


Name: 10.130.60.135:50010
Decommission Status : Normal
Configured Capacity: 3937075302400 (3.58 TB)
DFS Used: 2078225719892 (1.89 TB)
Non DFS Used: 255720398252 (238.16 GB)
DFS Remaining: 1603129184256(1.46 TB)
DFS Used%: 52.79%
DFS Remaining%: 40.72%
Last contact: Wed Feb 01 12:56:16 JST 2012


Name: 10.130.60.131:50010
Decommission Status : Normal
Configured Capacity: 3905720217600 (3.55 TB)
DFS Used: 2065109561374 (1.88 TB)
Non DFS Used: 270794133474 (252.2 GB)
DFS Remaining: 1569816522752(1.43 TB)
DFS Used%: 52.87%
DFS Remaining%: 40.19%
Last contact: Wed Feb 01 12:56:18 JST 2012
