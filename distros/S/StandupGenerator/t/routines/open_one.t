use Test::Simple tests => 3;
use Cwd;
use StandupGenerator::Accessor;

my $BASE = getcwd;
system("killall TextEdit");
my $before_success_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
StandupGenerator::Accessor::open_one("${BASE}/data", 1, '02');
my $after_success_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
system("killall TextEdit");
my $before_failure_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
StandupGenerator::Accessor::open_one("${BASE}/data", 1, 2);
my $after_failure_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
system("killall TextEdit");
my $before_spaces_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
StandupGenerator::Accessor::open_one("${BASE}/data/Folder with Spaces", 1, '01');
my $after_spaces_running = `ps aux | grep "TextEdit" | grep -v "grep"`;
system("killall TextEdit");

print("*** OPEN ONE:\n");

ok( $before_success_running eq undef && $after_success_running ne undef, 'will open a closed TextEdit app if proper arguments passed' );
ok( $before_failure_running eq undef && $after_failure_running eq undef, 'will not open a closed TextEdit app if improper arguments passed' );
ok( $before_spaces_running eq undef && $after_spaces_running ne undef, 'will open a closed TextEdit app even if file path contains spaces' );

# Execute tests from directory root with:
# perl -Ilib t/routines/open_one.t

1;