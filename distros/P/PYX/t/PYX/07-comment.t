# Pragmas.
use strict;
use warnings;

# Modules.
use PYX qw(comment);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $comment = 'comment';
my $ret = comment($comment);
is($ret, '_comment');

# Test.
$comment = "comment\ncomment";
$ret = comment($comment);
is($ret, '_comment\ncomment');
