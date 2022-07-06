use Test::Simple tests => 2;
use Cwd;
use StandupGenerator::Accessor;

my $BASE = getcwd;
system("killall TextEdit");
my $before_success_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
StandupGenerator::Accessor::open_many("${BASE}/data");
my $after_success_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
system("killall TextEdit");
my $before_failure_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
StandupGenerator::Accessor::open_many("${BASE}");
my $after_failure_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
system("killall TextEdit");

print("*** OPEN MANY:\n");

ok( $before_success_running eq undef && $after_success_running ne undef, 'will open a closed TextEdit app if given path to directory with standups' );
ok( $before_failure_running eq undef && $after_failure_running eq undef, 'will not open a closed TextEdit app if given path to directory without standups' );

# Execute tests from directory root with:
# perl -Ilib t/routines/open_many.t

1;