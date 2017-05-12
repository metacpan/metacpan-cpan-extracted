#!perl -T

#use Test::More qw(no_plan);
use Test::More tests => 23;

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Proc::Async::Config;
use File::Temp;

diag( "Configuration" );

{
    # mandatory argument
    eval {
        my $cfg = Proc::Async::Config->new();
    };
    ok ($@, "Missing config file undetected");
    ok ($@ =~ m{Missing config file name}i, "Unexpected error message: $@");

    my $tmpfile = File::Temp->new (UNLINK => 1, SUFFIX => '.cfg');
    my $cfg = Proc::Async::Config->new ($tmpfile);
    ok ($cfg, "Config object not created");
    is ($cfg->{cfgfile}, $tmpfile, "Config file name does not match");
}

{
    # other arguments
    my $tmpfile = File::Temp->new (UNLINK => 1, SUFFIX => '.cfg');
    my $cfg = Proc::Async::Config->new ($tmpfile, one => 1, two => 'a');
    is ($cfg->{one}, 1,   "Optional argument 1 value does not match");
    is ($cfg->{two}, 'a', "Optional argument 2 value does not match");
    is (my @f = $cfg->param(), 0, "Problem with properties storage");
}

# fill the configuration
my $cfgfile = File::Temp->new (UNLINK => 1, SUFFIX => '.cfg');
my $cfg = Proc::Async::Config->new ($cfgfile);
is ($cfg->param (name => 'tulak'), 'tulak', "Set property failed");
is ($cfg->param ('name'), 'tulak', "Get property failed");
$cfg->param (hobby => 'geocaching');
is_deeply ([ $cfg->param (hobby => 'gadgets' ) ],
           ['geocaching', 'gadgets'],
           "Set multivalue property failed");
is ($cfg->param ('hobby'), 'geocaching', "Get multivalue property as scalar failed");
my @hobbies = $cfg->param ('hobby');
is_deeply (\@hobbies,
           ['geocaching', 'gadgets'],
           "Get multivalue property as array failed");

# save and read it again
$cfg->save();
$cfg = Proc::Async::Config->new ($cfgfile);
is ($cfg->param ('name'), 'tulak', "Re-read property failed");
is ($cfg->param ('hobby'), 'geocaching', "Re-read multivalue property as scalar failed");
@hobbies = $cfg->param ('hobby');
is_deeply (\@hobbies,
           ['geocaching', 'gadgets'],
           "Re-Read multivalue property as array failed");

# getting a list of names and removing properties
{
    my $cfgfile = File::Temp->new (UNLINK => 1, SUFFIX => '.cfg');
    my $cfg = Proc::Async::Config->new ($cfgfile);
    my @array = $cfg->param();
    is (scalar @array, 0, "Empty configuration as an array failed");
    is (scalar $cfg->param(), undef, "Empty configuration as a scalar failed");

    $cfg->param ('greeting', 'ahoj');
    $cfg->param ('greeting', 'hi');
    $cfg->param ('bluting', 'bye');
    is_deeply ([$cfg->param()], [qw{bluting greeting}], "param lst does not comply");

    is_deeply ($cfg->remove ('greeting'), ['ahoj', 'hi'], "Remove of an array failed");
    is_deeply ($cfg->remove ('bluting'), ['bye'], "Remove of a single value failed");
    is ($cfg->param(), undef, "Empty by removing failed");
}

# clean (in memory)
{
    my $cfgfile = File::Temp->new (UNLINK => 1, SUFFIX => '.cfg');
    my $cfg = Proc::Async::Config->new ($cfgfile);
    $cfg->param ('hello', 'world');
    $cfg->clean();
    is ($cfg->param(), undef, "Empty by clean failed");
}

__END__
