use Test::Simple tests => 2;
use Cwd;
use StandupGenerator::Helper;

my $BASE = getcwd();
my $real_file = StandupGenerator::Helper::find_last_file("${BASE}/data");
my $dummy_file = StandupGenerator::Helper::find_last_file("${BASE}");

print("*** FIND LAST FILE:\n");
 
ok( $real_file eq 's1d03.txt', 'can find last file in directory with standups' );
ok( $dummy_file eq 's0d0.txt', 'will designate dummy file as last file in directory without standups' );

# Execute tests from directory root with:
# perl -Ilib t/routines/find_last_file.t

1;