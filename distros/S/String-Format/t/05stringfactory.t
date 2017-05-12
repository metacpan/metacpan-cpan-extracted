#!/usr/bin/env perl
# vim: set ft=perl ts=4 sw=4:

# ======================================================================
# 05stringfactory.t
#
# Test the subroutine generating facilities, supported by the
# stringfactory class method.
# ======================================================================

use strict;
use Test::More tests => 1;
use String::Format;
use POSIX qw(strftime);

my ($orig, $target, $result);

# ======================================================================
# Test 1
# Using instance methods
# ======================================================================
my $tpkg = TestPkg->new;
my %formats = (
    'i' => sub { $tpkg->id },
    'd' => sub { strftime($_[0], localtime($tpkg->date)) },
    'f' => sub { $tpkg->diff($_[0]) }
);
my $formatter = String::Format->stringfactory(\%formats);

$orig   = 'my lovely TestPkg instance has an id of %i.';
$target = 'my lovely TestPkg instance has an id of ' . $tpkg->id . '.';
$result = $formatter->($orig);

is $target => $result;

BEGIN {
    # (silly) embedded package
    package TestPkg;
    sub new  { bless \(my $o = int rand($$)) => $_[0] }
    sub id   { ${$_[0]} }
    sub date { time }
    sub diff { $_[0]->id - ($_[0] || 0) }
}
