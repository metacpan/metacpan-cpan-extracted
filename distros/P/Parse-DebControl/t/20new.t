#!/usr/bin/perl -w

use Test::More tests => 7;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..';
}

my $pdc;
my $mod = "Parse::DebControl";

use_ok($mod);

ok($pdc = new Parse::DebControl, "Create object with 'new \$class' method"); 
ok($pdc = Parse::DebControl->new(), "Create object with '\$class->new()' method");

ok($pdc = new Parse::DebControl(1), "Create object with 'new \$class' method with debugging");
ok($pdc->{_verbose} == 1, "...and check to see if it actually got turned on");

ok($pdc = Parse::DebControl->new(1), "Create object with '\$class->new' method with debugging");
ok($pdc->{_verbose} == 1, "...and check to see if it actually got turned on");
