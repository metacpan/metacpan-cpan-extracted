# -*- perl -*-
#	history.t --- Term::ReadLine:GNU History Library Test Script
#  Adapted from:
#
#	$Id: history.t,v 1.11 2009/02/27 12:15:01 hiroo Exp $
#
#	Copyright (c) 2009 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/history.t'
use strict; use warnings;
use lib '../lib' ;

use Test::More;

BEGIN {
    $ENV{LANG} = 'C';
    # force Term::ReadLine to use Term::ReadLine::Perl5
    $ENV{PERL_RL} = 'Perl5';
    $ENV{'COLUMNS'} = '80';
    $ENV{'LINES'}    = '25';
    # stop reading ~/.inputrc
    $ENV{'INPUTRC'} = '/dev/null';
}

use Term::ReadLine::Perl5;

my $t;  # Term::ReadLine::Perl5 object
my $attribs = {};
my $verbose = @ARGV && ($ARGV[0] eq 'verbose');

# debugging support
sub show_indices {
    return;
    printf("where_history: %d ",	$t->where_history);
#    printf("current_history(): %s ",	$t->current_history);
    printf("history_base: %d, ",	$attribs->{history_base});
    printf("history_length: %d, ",	$attribs->{history_length});
#    printf("max_input_history: %d ",	$attribs->{max_input_history});
#    printf("history_total_bytes: %d ",	$t->history_total_bytes);
    print "\n";
}

########################################################################
# Use "new" method to get $t used below

eval { $t  = Term::ReadLine::Perl5->new('ReadLineTest'); };
plan skip_all => "Need access to tty" unless $t;
ok($t, "new method, new's");

my $OUT;
if ($verbose) {
    $OUT = $t->OUT;
} else {
    open(NULL, '>/dev/null') or die "cannot open \`/dev/null\': $!\n";
    $OUT = \*NULL;
    $t->Attribs->{outstream} = \*NULL;
}

########################################################################
# test ReadLine method

is($t->ReadLine, 'Term::ReadLine::Perl5',
   "t->ReadLine should be \`Term::ReadLine::Perl5\'");

########################################################################
# test Attribs method

$attribs = $t->Attribs;
ok($attribs, "Should have \$t->Attribs");

########################################################################
# 2.3.2 History List Management

my @list_set;
# default value of `history_base' is 1
@list_set = qw(one two two three);
show_indices;

$t->SetHistory(@list_set);
is_deeply([$t->GetHistory], \@list_set,
	  "GetHistory gives what SetHistory initially set");
show_indices;

$t->add_history('four');
push(@list_set, 'four');
is_deeply([$t->GetHistory], \@list_set,
	  "add_history() can push an item");
show_indices;

$t->remove_history(2);
splice(@list_set, 2, 1);
is_deeply([$t->GetHistory], \@list_set,
	  "remove_history() can remove an item");
show_indices;

# use Enbugger 'trepan'; Enbugger->stop();
$t->replace_history_entry(3, 'daarn');
splice(@list_set, 3, 1, 'daarn');
is_deeply([$t->GetHistory], \@list_set,
	  'replace_history_entry can replace an item');
show_indices;

# stifle_history
is($t->history_is_stifled, 0,
   "History should not start out stifled");

$t->stifle_history(3);
is($t->history_is_stifled, 1,
   "stifle_history() stifles history");
is($attribs->{history_length}, 3,
   "history should be stifled at 3 items");
is($attribs->{max_input_history}, 3,
   "max_input_history value should be 3");
show_indices;

# use Enbugger 'trepan'; Enbugger->stop;
$t->add_history('five');
is($t->history_is_stifled, 1,
   "history is still stifled");
is($attribs->{history_length}, 3,
   "history length hasn't changed");

show_indices;

# unstifle_history()
$t->unstifle_history;
is($t->history_is_stifled, 0);
is($attribs->{history_length}, 3);
show_indices;

# history_is_stifled()
$t->addhistory('six');  # Use older compatible form of addhistory
is($t->history_is_stifled, 0);
show_indices;

########################################################################
# 2.3.3 Information About the History List

show_indices;
@list_set = qw(zero one two three four);
$t->stifle_history(4);
show_indices;
$t->SetHistory(@list_set);
show_indices;

# history_list()
#	history_list() routine emulates history_list() function in
#	GNU Readline Library.
splice(@list_set, 0, 1);
# is_deeply(\@list_set, [$t->history_list()],
# 	  "history_list() emulation");
show_indices;

# # at first where_history() returns 0
# is($t->where_history, 0,
#    "where_history() should start out at 0");

# # current_history()
# #   history_base + 0 = 1
# is($t->current_history, 'one',
#    "current_history() for first item");

# # history_total_bytes()
# is($t->history_total_bytes, 15,
#    "history_total_bytes()");

# ########################################################################
# # 2.3.4 Moving Around the History List

# # history_set_pos()
# $t->history_set_pos(2);
# print $t->where_history == 2		? "ok $n\n" : "not ok $n\n"; $n++;
# #   history_base + 2 = 3
# print $t->current_history eq 'three'	? "ok $n\n" : "not ok $n\n"; $n++;
# show_indices;

# $t->history_set_pos(10000);	# should be ingored
# print $t->where_history == 2		? "ok $n\n" : "not ok $n\n"; $n++;

# # previous_history()
# print $t->previous_history eq 'two'	? "ok $n\n" : "not ok $n\n"; $n++;
# print $t->where_history == 1		? "ok $n\n" : "not ok $n\n"; $n++;
# show_indices;
# print $t->previous_history eq 'one'	? "ok $n\n" : "not ok $n\n"; $n++;
# show_indices;
# $^W = 0;			# returns NULL
# print $t->previous_history eq ''	? "ok $n\n" : "not ok $n\n"; $n++;
# $^W = 1;
# show_indices;

# # next_history()
# print $t->next_history eq 'two'		? "ok $n\n" : "not ok $n\n"; $n++;
# show_indices;
# print $t->next_history eq 'three'	? "ok $n\n" : "not ok $n\n"; $n++;
# show_indices;
# print $t->next_history eq 'four'	? "ok $n\n" : "not ok $n\n"; $n++;
# show_indices;
# $^W = 0;			# returns NULL
# print $t->next_history eq ''		? "ok $n\n" : "not ok $n\n"; $n++;
# $^W = 1;
# print $t->where_history == 4		? "ok $n\n" : "not ok $n\n"; $n++;
# show_indices;


# ########################################################################
# # 2.3.5 Searching the History List

# @list_set = ('red yellow', 'green red', 'yellow blue', 'green blue');
# $t->SetHistory(@list_set);

# $t->history_set_pos(1);
# #show_indices;

# # history_search()
# print($t->history_search('red',    -1) ==  6 && $t->where_history == 1
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search('blue',   -1) == -1 && $t->where_history == 1
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search('yellow', -1) ==  4 && $t->where_history == 0
#       ? "ok $n\n" : "not ok $n\n"); $n++;

# print($t->history_search('red',     1) ==  0 && $t->where_history == 0
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search('blue',    1) ==  7 && $t->where_history == 2
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search('red',     1) == -1 && $t->where_history == 2
#       ? "ok $n\n" : "not ok $n\n"); $n++;

# print($t->history_search('red')        ==  6 && $t->where_history == 1
#       ? "ok $n\n" : "not ok $n\n"); $n++;

# # history_search_prefix()
# print($t->history_search_prefix('red',  -1) ==  0
#       && $t->where_history == 0 ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_prefix('green', 1) ==  0
#       && $t->where_history == 1 ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_prefix('red',   1) == -1
#       && $t->where_history == 1 ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_prefix('red')      ==  0
#       && $t->where_history == 0 ? "ok $n\n" : "not ok $n\n"); $n++;

# # history_search_pos()
# $t->history_set_pos(3);
# print($t->history_search_pos('red',    -1, 1) ==  1
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_pos('red',    -1, 3) ==  1
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_pos('black',  -1, 3) == -1
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_pos('yellow', -1)    ==  2
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_pos('green')         ==  3
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_pos('yellow',  1, 1) ==  2
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_pos('yellow',  1)    == -1
#       ? "ok $n\n" : "not ok $n\n"); $n++;
# print($t->history_search_pos('red',     1, 2) == -1
#       ? "ok $n\n" : "not ok $n\n"); $n++;

########################################################################
# 2.3.6 Managing the History File

$t->stifle_history(undef);
my $hfile = '.history_test';
my @list_write = $t->GetHistory();
$t->WriteHistory($hfile) || warn "error at write_history: $!\n";

$t->SetHistory();		# clear history list
ok(!$t->GetHistory );

$t->ReadHistory($hfile) || warn "error at read_history: $!\n";
is_deeply([$t->GetHistory], \@list_write, 'ReadHistory alias');

@list_write = qw(0 1 2 3 4);
$t->SetHistory(@list_write);
# write_history()
! $t->write_history($hfile) || warn "error at write_history: $!\n";
$t->SetHistory();		# clear history list
# read_history()
! $t->read_history($hfile) || warn "error at read_history: $!\n";
is_deeply(\@list_write, [$t->GetHistory], 'GetHistory alias');

done_testing();

# This is as far as I've gotten.
__END__

# read_history() with range
! $t->read_history($hfile, 1, 3) || warn "error at read_history: $!\n";
print cmp_list([0,1,2,3,4,1,2], [$t->GetHistory])
    ? "ok $n\n" : "not ok $n\n"; $n++;
#print "@{[$t->GetHistory]}\n";
! $t->read_history($hfile, 2, -1) || warn "error at read_history: $!\n";
print cmp_list([0,1,2,3,4,1,2,2,3,4], [$t->GetHistory])
    ? "ok $n\n" : "not ok $n\n"; $n++;
#print "@{[$t->GetHistory]}\n";

# append_history()
! $t->append_history(5, $hfile) || warn "error at append_history: $!\n";
$t->SetHistory();		# clear history list
! $t->read_history($hfile) || warn "error at read_history: $!\n";
print cmp_list([0,1,2,3,4,1,2,2,3,4], [$t->GetHistory])
    ? "ok $n\n" : "not ok $n\n"; $n++;
#print "@{[$t->GetHistory]}\n";

# history_truncate_file()
$t->history_truncate_file($hfile, 6); # always returns 0
$t->SetHistory();		# clear history list
! $t->read_history($hfile) || warn "error at read_history: $!\n";
print cmp_list([4,1,2,2,3,4], [$t->GetHistory])
    ? "ok $n\n" : "not ok $n\n"; $n++;
#print "@{[$t->GetHistory]}\n";

########################################################################
# 2.3.7 History Expansion

my ($string, $ret, @ret, $exp, @exp);

@list_set = ('red yellow', 'blue red', 'yellow blue', 'green blue');
$t->SetHistory(@list_set);
$t->history_set_pos(2);

# history_expand()
#print "${\($t->history_expand('!!'))}";
# !! : last entry of the history list
print $t->history_expand('!!') eq 'green blue'
    ? "ok $n\n" : "not ok $n\n"; $n++;
print $t->history_expand('!yel') eq 'yellow blue'
    ? "ok $n\n" : "not ok $n\n"; $n++;

($ret, $string) = $t->history_expand('!red');
print $ret == 1 && $string eq 'red yellow' ? "ok $n\n" : "not ok $n\n"; $n++;

# get_history_event()
my ($text, $cindex);
#		     1	       2
#	   012345678901234567890123
$string = '!-2 !?red? "!blu" white';

# !-2: 2 line before
($text, $cindex) = $t->get_history_event($string, 0);
$res = $cindex == 3 && $text eq 'yellow blue'; ok('get_history_event');
#print "$cindex,$text\n";

# non-event designator
($text, $cindex) = $t->get_history_event($string, 3);
$res = $cindex == 3 && ! defined $text; ok;
#print "$cindex,$text\n";

# The following 2 test may fail with readline-4.3 with some locale
# setting. It comes from bug of the Readline Library.  I sent a patch
# to the maintainer.  `LANG=C make test' should work.
# !?red?: line including `red'
($text, $cindex) = $t->get_history_event($string, 4);
$res = $cindex == 10 && $text eq 'blue red'; ok;
#print "$cindex,$text\n";

# "!?blu": line including `blu'
($text, $cindex) = $t->get_history_event($string, 12, '"');
$res = $cindex == 16 && $text eq 'blue red'; ok;
#print "$cindex,$text\n";


# history_tokenize(), history_arg_extract()

$string = ' foo   "double quoted"& \'single quoted\' (paren)';
# for history_tokenize()
@exp = ('foo', '"double quoted"', '&', '\'single quoted\'', '(', 'paren', ')');
# for history_arg_extract()
$exp = "@exp";

@ret = $t->history_tokenize($string);
print cmp_list(\@ret, \@exp) ? "ok $n\n" : "not ok $n\n"; $n++;

$ret = $t->history_arg_extract($string, 0, '$'); #') comments for font-lock;
print $ret eq $exp ? "ok $n\n" : "not ok $n\n"; $n++;
$ret = $t->history_arg_extract($string, 0);
print $ret eq $exp ? "ok $n\n" : "not ok $n\n"; $n++;
$ret = $t->history_arg_extract($string);
print $ret eq $exp ? "ok $n\n" : "not ok $n\n"; $n++;
$_ = $string;
$ret = $t->history_arg_extract;
print $ret eq $exp ? "ok $n\n" : "not ok $n\n"; $n++;

########################################################################
# 2.4 History Variables

# history_base, history_length, max_input_history are tested above

# history_expansion_char!!!, history_subst_char!!!, history_comment_char!!!,
# history_word_delimiters!!!, history_no_expand_chars!!!

# history_inhibit_expansion_function
@list_set = ('red yellow', 'blue red', 'yellow blue', 'green blue');
$t->SetHistory(@list_set);
$t->history_set_pos(2);
# equivalent with 'history_no_expand_chars = "...!..."'
$attribs->{history_inhibit_expansion_function} = sub {
    my ($string, $index) = @_;
    substr($string, $index + 1, 1) eq '!'; # inhibit expanding '!!'
};

print $t->history_expand('!!') eq '!!'
    ? "ok $n\n" : "not ok $n\n"; $n++;
print $t->history_expand(' !r') eq ' red yellow'
    ? "ok $n\n" : "not ok $n\n"; $n++;

# strange behavior was fixed on version 6.0
print $t->history_expand('!! !y') eq '!! yellow blue'
    ? "ok $n\n" : "not ok $n\n"; $n++;
end_of_test:
