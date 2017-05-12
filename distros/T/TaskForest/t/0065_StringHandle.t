# -*- perl -*-

use Test::More tests => 16;

BEGIN {
    use_ok( 'TaskForest::StringHandle',         "Can use StringHandle" );
    use_ok( 'TaskForest::StringHandleTier',     "Can use StringHandleTier" );
}

use strict;
use warnings;

my $obj = tie(*STDOUT, 'TaskForest::StringHandleTier');
isa_ok($obj, "TaskForest::StringHandleTier", "Created TaskForest::StringHandlerTier");
print "Booyah!";           
is($obj->[0], 'Booyah!', 'Saved text is correct');
my $data = $obj->getData;     # $data eq 'Booyah!'
is($data, 'Booyah!', 'getData works');
undef $obj;                # get rid of reference to STDOUT
untie(*STDOUT);            # STDOUT is 'back to normal'
print "Ignore this line: Hello, world!\n";   # printed to stdout


$obj = tie(*STDERR, 'TaskForest::StringHandleTier');
isa_ok($obj, "TaskForest::StringHandleTier", "Created TaskForest::StringHandlerTier");
print STDERR "Booyah!";           
is($obj->[0], 'Booyah!', 'Saved text is correct');
$data = $obj->getData;     # $data eq 'Booyah!'
is($data, 'Booyah!', 'getData works');
undef $obj;                # get rid of reference to STDERR
untie(*STDERR);            # STDERR is 'back to normal'
print STDERR "\nIgnore this line: Hello, world!\n";   # printed to stderr


my $text1 = "This is the first line\n";;
my $text2 = "This is the second line\n";
my ($stdout1, $stdout2, $stdout3, $stderr1, $stderr2, $stderr3);

my $sh = TaskForest::StringHandle->start(*STDOUT);
isa_ok($sh, "TaskForest::StringHandle", "Created TaskForest::StringHandler");
print $text1;
$stdout1 = $sh->read();
$stdout2 = $sh->read();
print $text2;
$stdout3 = $sh->stop();

# test now, after stop
is($stdout1, $text1, "Retrieved first line properly");
is($stdout2, '', "read() cleared the buffer");
is($stdout3, $text2, "Retrieved second line properly");

print "\nBack to stdout\n\n\n";
print $text1;
print $text2;


$sh = TaskForest::StringHandle->start(*STDERR);
isa_ok($sh, "TaskForest::StringHandle", "Created TaskForest::StringHandler");
print STDERR $text1;
$stderr1 = $sh->read();
$stderr2 = $sh->read();
print STDERR $text2;
$stderr3 = $sh->stop();

# test now, after stop
is($stderr1, $text1, "Retrieved first line properly");
is($stderr2, '', "read() cleared the buffer");
is($stderr3, $text2, "Retrieved second line properly");

print STDERR "\nBack to stderr - Ignore this line\n";
print STDERR "Ignore this line: $text1";
print STDERR "Ignore this line: $text2";

