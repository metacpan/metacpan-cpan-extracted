#!perl

use strict;
use warnings;

use Test::More 0.88;
use FindBin 0.05;
use File::Spec::Functions;
use Devel::FindPerl qw(find_perl_interpreter);
use Cwd qw/ abs_path /;

my $PERL  = find_perl_interpreter() || die "can't find perl!\n";
my $MPATH = catfile( $FindBin::Bin, updir(), qw(bin mpath) );
my $path;
my $expected_path;

#
# The mpath script's hashbang line is:
#
#   #!/usr/bin/env perl
#
# This can result in it being run with a different perl than being used to run
# this test. So the path to strict may be different. So we use $^X to run
# mpath with the same perl binary being used to run this test.
# Instead of explicitly using $^X, we use Devel::FindPerl to get the
# path to perl
#
chomp($path = `"$PERL" "$MPATH" strict 2>&1`);

# This test does "use strict", so %INC should include the path where
# strict.pm was found, and module_path should find the same
$expected_path = abs_path($INC{'strict.pm'});
ok($? == 0 && defined($path) && $path eq $expected_path,
   "check 'mpath strict' matches \%INC") || do {
    warn "\n",
         "    \%INC          : $INC{'strict.pm'}\n",
         "    expected_path : $expected_path\n",
         "    module_path   : $path\n",
         "    \$^O           : $^O\n";
};

# module_path() returns undef if module not found in @INC
chomp($path = `"$PERL" "$MPATH" No::Such::Module 2>&1`);
ok($? != 0 && defined($path) && $path eq 'No::Such::Module not found',
   "non-existent module should result in failure");

chomp($path = `"$PERL" "$MPATH" strict warnings 2>&1`);

ok($? == 0, 'exit status is 0');
ok(defined($path), 'path for both strict.pm and warnings.pm are defined');
is($path, abs_path($INC{'strict.pm'}).$/.abs_path($INC{'warnings.pm'}), 'and they match %INC');

chomp($path = `"$PERL" "$MPATH" strict warnings No::Such::Module 2>&1`);

ok($? != 0,        'exit status is not zero');
ok(defined($path), 'path is defined');
is(
    $path,
    abs_path($INC{'strict.pm'}).$/.abs_path($INC{'warnings.pm'})."$/No::Such::Module not found",
    'got expected output'
);

chomp($path = `"$PERL" "$MPATH" --quiet strict warnings No::Such::Module 2>&1`);

ok($? != 0,        'exit status is not zero');
ok(defined($path), 'path is defined');
is(
    $path,
    abs_path($INC{'strict.pm'}).$/.abs_path($INC{'warnings.pm'}),
    "error message should not be printed when the option --quiet is specified"
);

chomp($path = `"$PERL" "$MPATH" --full strict warnings 2>&1`);

ok($? == 0,        'exit status is zero');
ok(defined($path), 'path is defined');
is(
    $path,
    "strict ".abs_path($INC{'strict.pm'})."$/warnings ".abs_path($INC{'warnings.pm'}),
    "module name should be printed right before its path if the option --full is specified"
);

done_testing;
