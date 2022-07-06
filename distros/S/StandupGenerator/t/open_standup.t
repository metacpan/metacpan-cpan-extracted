use Test::Simple tests => 2;
use Cwd;
use StandupGenerator;

my $BASE = getcwd;
system("killall TextEdit");
my $before_success_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
StandupGenerator::open_standup("${BASE}/data", 1, '02');
my $after_success_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
system("killall TextEdit");
my $before_failure_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
StandupGenerator::open_standup("${BASE}/data", 1, 2);
my $after_failure_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
system("killall TextEdit");

print("*** OPEN STANDUP:\n");

ok( $before_success_running eq undef && $after_success_running ne undef, 'will open a closed TextEdit app if proper arguments passed' );
ok( $before_failure_running eq undef && $after_failure_running eq undef, 'will not open a closed TextEdit app if improper arguments passed' );

# Execute tests from directory root with:
# perl -Ilib t/open_standup.t

1;