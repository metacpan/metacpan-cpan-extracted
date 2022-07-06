use Test::Simple tests => 3;
use Cwd;
use StandupGenerator;

my $BASE = getcwd;
my $proper_standup = StandupGenerator::create_standup("${BASE}/data");
my $initial_standup = StandupGenerator::create_standup("${BASE}");
open my $fh, '<', "${BASE}/s1d01.txt";
my $dummy_file_content = do { local $/; <$fh> };
my $dummy_today_index = index($dummy_file_content, 'TODAY') + 6;
my $dummy_blockers_index = index($dummy_file_content, 'BLOCKERS') + 9;
my $dummy_today_content = substr($dummy_file_content, $dummy_today_index, $dummy_blockers_index - $dummy_today_index - 11);
close($fh);
system("rm ${BASE}/data/s1d04.txt");
system("rm ${BASE}/s1d01.txt");

print("*** CREATE STANDUP:\n");
 
ok( $proper_standup eq 's1d04.txt', 'will increment standup when creating new file' );
ok( $initial_standup eq 's1d01.txt', 'will initiate dummy file if folder initially empty of text files' );
ok( $dummy_today_content eq '- ', 'dummy file contains empty bullets');

# Execute tests from directory root with:
# perl -Ilib t/create_standup.t

1;