#!/usr/bin/perl

use strict;
use warnings;

use POSIX qw(locale_h);

use SVN::Web::action;
use Test::More tests => 4;

# Force the 'C' locale, so that tests give consistent results even if the
# user running under a non-English locale.
setlocale(LC_TIME, 'C');

my %config = (timezone        => '',
	      timedate_format => '%Y/%m/%d %H:%M:%S',
	      );

my $a = SVN::Web::action->new(config => \%config);
isa_ok($a, 'SVN::Web::action');

my $cstring = '2006-05-08T19:30:20.265743Z';

my $s = $a->format_svn_timestamp($cstring);
is($s, '2006/05/08 19:30:20');

$config{timedate_format} = '%a. %b %d, %l:%M%p';
$s = $a->format_svn_timestamp($cstring);
is($s, 'Mon. May 08,  7:30PM');

$config{timezone} = 'BST';
$s = $a->format_svn_timestamp($cstring);
is($s, 'Mon. May 08,  8:30PM');

