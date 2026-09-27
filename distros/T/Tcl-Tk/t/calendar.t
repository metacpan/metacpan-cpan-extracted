use strict;
use Test::More tests => 5;
use Tcl::Tk;

# 1. Check that the module loads correctly
my $int = new Tcl::Tk;
if (!$int) {
    plan skip_all => "X11/Window server wrapper not available for testing UI";
}

ok($int, "Tcl::Tk interpreter successfully initialized");

## 2. Redefine MainLoop to prevent the test from hanging on user input
no warnings 'redefine';
local *Tcl::Tk::MainLoop = sub {
    $int->update; # Process geometry and rendering events
    sleep 2;
};
use warnings 'redefine';

# 3. Test perl/Tk syntax demo execution
my $perltk_demo = "./demos/calendar-perltk.pl";
ok(-f $perltk_demo, "Found $perltk_demo");
my $res_perltk = eval { do $perltk_demo };
ok(!$@, "Executed calendar-perltk.pl without runtime errors");

# 4. Test Tcl/Tk syntax demo execution
my $tcltk_demo = "./demos/calendar-tcltk.pl";
ok(-f $tcltk_demo, "Found $tcltk_demo");

# Note: If the second script requires a fresh environment, 
# 'do' will run it natively within the same process.
eval { do $tcltk_demo };

ok(!$@, "Executed calendar-tcltk.pl without runtime errors");

