# -*- perl -*-
#	history.t --- Term::ReadLine:GNU History Library Test Script
#
#	$Id: history.t 524 2016-05-26 16:14:26Z hayashi $
#
#	Copyright (c) 1998-2016 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/history.t'

use strict;
use warnings;
use Test::More tests => 88;

# redefine Test::Mode::note due to it requires Perl 5.10.1.
no warnings 'redefine';
sub note {
    my $msg = join('', @_);
    $msg =~ s{\n(?!\z)}{\n# }sg;
    print "# $msg" . ($msg =~ /\n$/ ? '' : "\n");
}
use warnings 'redefine';

BEGIN {
    $ENV{PERL_RL} = 'Gnu';	# force to use Term::ReadLine::Gnu
    $ENV{LC_ALL} = 'C';
}
sub show_indices;		# for debugging

use Term::ReadLine;
ok(1, 'load done');

note "Testing Term::ReadLine::Gnu version $Term::ReadLine::Gnu::VERSION";

########################################################################
# test new method

my $t = new Term::ReadLine 'ReadLineTest';
isa_ok($t, 'Term::ReadLine');

my $OUT = $t->OUT || \*STDOUT;

########################################################################
# test ReadLine method
ok($t->ReadLine eq 'Term::ReadLine::Gnu', '$t->ReadLine');

########################################################################
# test Attribs method
use vars qw($attribs);

$attribs = $t->Attribs;
isa_ok($attribs, 'Term::ReadLine', 'Attribs');

my ($version) = $attribs->{library_version} =~ /(\d+\.\d+)/;

########################################################################
note "2.3.1 Initializing History and State Management";

# test using_history
# This is verbose since 'new' has already initialized the GNU history library.
$t->using_history;

# history_get_history_state, history_set_history_state
{
    ok($attribs->{history_length} == 0, 'history_get/set_history_state');
    my $state = $t->history_get_history_state();
    isa_ok($state, 'HISTORY_STATEPtr');
    $attribs->{history_length} = 10;
    ok($attribs->{history_length} == 10, 'history_get/set_history_state');
    $t->history_set_history_state($state);
    ok($attribs->{history_length} == 0, 'history_get/set_history_state');
}

# check the values of initialized variables
ok($attribs->{history_base} == 1, 'history_base');
ok($attribs->{history_length} == 0, 'history_length');
ok($attribs->{max_input_history} == 0, 'max_input_history');
ok($attribs->{history_max_entries} == 0, 'history_max_entries');
ok($attribs->{history_write_timestamps} == 0, 'history_write_timestamps');
ok($attribs->{history_expansion_char} eq '!', 'history_expansion_char');
ok($attribs->{history_subst_char} eq '^', 'history_subst_char');
ok($attribs->{history_comment_char} eq "\0", 'history_comment_char');
ok($attribs->{history_word_delimiters} eq " \t\n;&()|<>", 'history_word_delimiters');
ok($attribs->{history_no_expand_chars} eq " \t\n\r=", 'history_no_expand_chars');
ok(!defined $attribs->{history_search_delimiter_chars}, 'history_search_delimiter_chars');
ok($attribs->{history_quotes_inhibit_expansion} == 0, 'history_quotes_inhibit_expansion');
ok(!defined $attribs->{history_inhibit_expansion_function}, 'history_inhibit_expansion_function');


########################################################################
note "2.3.2 History List Management";

my @list_set;
# default value of `history_base' is 1
@list_set = qw(one two two three);
show_indices;

# test SetHistory(), GetHistory()
$t->SetHistory(@list_set);
is_deeply(\@list_set, [$t->GetHistory], 'SetHistory, GetHistory');
show_indices;

# test add_history(), add_history_time!!!
$t->add_history('four');
push(@list_set, 'four');
is_deeply(\@list_set, [$t->GetHistory], 'add_history');
show_indices;

# test remove_history()
$t->remove_history(2);
splice(@list_set, 2, 1);
is_deeply(\@list_set, [$t->GetHistory], 'remove_history');
show_indices;

# test replace_history_entry()
$t->replace_history_entry(3, 'daarn');
splice(@list_set, 3, 1, 'daarn');
is_deeply(\@list_set, [$t->GetHistory], 'replace_history_entry');
show_indices;

# clear_history() is tested below.

# stifle_history
ok($t->history_is_stifled == 0, 'history_is_stifled');
$t->stifle_history(3);
ok($t->history_is_stifled == 1
   && $attribs->{history_length} == 3 && $attribs->{max_input_history} == 3,
   'history_is_stifled');
#print "@{[$t->GetHistory]}\n";
show_indices;

# history_is_stifled()
$t->add_history('five');
ok($t->history_is_stifled == 1 && $attribs->{history_length} == 3, 'history_is_stifled');
show_indices;

# unstifle_history()
$t->unstifle_history;
ok($t->history_is_stifled == 0 && $attribs->{history_length} == 3, 'unstifle_history');
#print "@{[$t->GetHistory]}\n";
show_indices;

# history_is_stifled()
$t->add_history('six');
ok($t->history_is_stifled == 0 && $attribs->{history_length} == 4, 'history_is_stifled');
show_indices;

# clear_history()
$t->clear_history;
ok($attribs->{history_length} == 0, 'clear_history');
show_indices;

########################################################################
note "2.3.3 Information About the History List";

$attribs->{history_base} = 0;
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
is_deeply(\@list_set, [$t->history_list], 'history_list');
show_indices;

# at first where_history() returns 0
ok($t->where_history == 0, 'where_history');

# current_history()
#   history_base + 0 = 1
ok($t->current_history eq 'one', 'current_history');

# history_get()!!!, history_get_time()!!!

# history_total_bytes()
ok($t->history_total_bytes == 15, 'history_total_bytes');

########################################################################
note "2.3.4 Moving Around the History List";

# history_set_pos()
$t->history_set_pos(2);
ok($t->where_history == 2, 'history_set_pos');
#   history_base + 2 = 3
ok($t->current_history eq 'three');
show_indices;

$t->history_set_pos(10000);	# should be ingored
ok($t->where_history == 2);

# previous_history()
ok($t->previous_history eq 'two', 'previous_history');
ok($t->where_history == 1);
show_indices;
ok($t->previous_history eq 'one');
show_indices;
ok(! defined $t->previous_history);
show_indices;

# next_history()
ok($t->next_history eq 'two', 'next_history');
show_indices;
ok($t->next_history eq 'three');
show_indices; 
ok($t->next_history eq 'four');
show_indices;
ok(! defined $t->next_history);
ok($t->where_history == 4);
show_indices;

########################################################################
note "2.3.5 Searching the History List";

@list_set = ('red yellow', 'green red', 'yellow blue', 'green blue');
$t->SetHistory(@list_set);

$t->history_set_pos(1);
#show_indices;

# history_search()
ok($t->history_search('red',    -1) ==  6 && $t->where_history == 1, 'history_search');
ok($t->history_search('blue',   -1) == -1 && $t->where_history == 1);
ok($t->history_search('yellow', -1) ==  4 && $t->where_history == 0);

ok($t->history_search('red',     1) ==  0 && $t->where_history == 0);
ok($t->history_search('blue',    1) ==  7 && $t->where_history == 2);
ok($t->history_search('red',     1) == -1 && $t->where_history == 2);

ok($t->history_search('red')        ==  6 && $t->where_history == 1);

# history_search_prefix()
ok($t->history_search_prefix('red',  -1) ==  0 && $t->where_history == 0, 'history_search_prefix');
ok($t->history_search_prefix('green', 1) ==  0 && $t->where_history == 1);
ok($t->history_search_prefix('red',   1) == -1 && $t->where_history == 1);
ok($t->history_search_prefix('red')      ==  0 && $t->where_history == 0);

# history_search_pos()
$t->history_set_pos(3);
ok($t->history_search_pos('red',    -1, 1) ==  1, 'history_search_pos');
ok($t->history_search_pos('red',    -1, 3) ==  1);
ok($t->history_search_pos('black',  -1, 3) == -1);
ok($t->history_search_pos('yellow', -1)    ==  2);
ok($t->history_search_pos('green')         ==  3);
ok($t->history_search_pos('yellow',  1, 1) ==  2);
ok($t->history_search_pos('yellow',  1)    == -1);
ok($t->history_search_pos('red',     1, 2) == -1);

########################################################################
note "2.3.6 Managing the History File";

$t->stifle_history(undef);
my $hfile = '.history_test';
my @list_write = $t->GetHistory();
$t->WriteHistory($hfile) || warn "error at write_history: $!\n";

$t->SetHistory();		# clear history list
ok(! $t->GetHistory, 'SetHistory');

$t->ReadHistory($hfile) || warn "error at read_history: $!\n";
is_deeply(\@list_write, [$t->GetHistory], 'ReadHistory');

@list_write = qw(0 1 2 3 4);
$t->SetHistory(@list_write);
# write_history()
! $t->write_history($hfile) || warn "error at write_history: $!\n";
$t->SetHistory();		# clear history list
# read_history()
! $t->read_history($hfile) || warn "error at read_history: $!\n";
is_deeply(\@list_write, [$t->GetHistory], 'read_history');

# read_history() with range
! $t->read_history($hfile, 1, 3) || warn "error at read_history: $!\n";
is_deeply([0,1,2,3,4,1,2], [$t->GetHistory], 'read_history with range');
#print "@{[$t->GetHistory]}\n";
! $t->read_history($hfile, 2, -1) || warn "error at read_history: $!\n";
is_deeply([0,1,2,3,4,1,2,2,3,4], [$t->GetHistory]);
#print "@{[$t->GetHistory]}\n";

# append_history()
! $t->append_history(5, $hfile) || warn "error at append_history: $!\n";
$t->SetHistory();		# clear history list
! $t->read_history($hfile) || warn "error at read_history: $!\n";
is_deeply([0,1,2,3,4,1,2,2,3,4], [$t->GetHistory], 'append_history');
#print "@{[$t->GetHistory]}\n";

# history_truncate_file()
$t->history_truncate_file($hfile, 6); # always returns 0
$t->SetHistory();		# clear history list
! $t->read_history($hfile) || warn "error at read_history: $!\n";
is_deeply([4,1,2,2,3,4], [$t->GetHistory], 'history_truncate_file');
#print "@{[$t->GetHistory]}\n";

########################################################################
note "2.3.7 History Expansion";

my ($string, $ret, $exp, @exp);

@list_set = ('red yellow', 'blue red', 'yellow blue', 'green blue');
$t->SetHistory(@list_set);
$t->history_set_pos(2);

# history_expand()
#print "${\($t->history_expand('!!'))}";
# !! : last entry of the history list
ok($t->history_expand('!!') eq 'green blue', 'history_expand');
ok($t->history_expand('!yel') eq 'yellow blue');

($ret, $string) = $t->history_expand('!red');
ok($ret == 1 && $string eq 'red yellow');

# get_history_event()
my ($text, $cindex);
#		     1	       2
#	   012345678901234567890123
$string = '!-2 !?red? "!blu" white';

# !-2: 2 line before
($text, $cindex) = $t->get_history_event($string, 0);
ok($cindex == 3 && $text eq 'yellow blue', 'get_history_event');
#print "$cindex,$text\n";

# non-event designator
($text, $cindex) = $t->get_history_event($string, 3);
ok($cindex == 3 && ! defined $text);
#print "$cindex,$text\n";

# The following 2 test may fail with readline-4.3 with some locale
# setting. It comes from bug of the Readline Library.  I sent a patch
# to the maintainer.  `LANG=C make test' should work.
# !?red?: line including `red'
($text, $cindex) = $t->get_history_event($string, 4);
ok($cindex == 10 && $text eq 'blue red');
#print "$cindex,$text\n";

# "!?blu": line including `blu'
($text, $cindex) = $t->get_history_event($string, 12, '"');
ok($cindex == 16 && $text eq 'blue red');
#print "$cindex,$text\n";


# history_tokenize(), history_arg_extract()

$string = ' foo   "double quoted"& \'single quoted\' (paren)';
# for history_tokenize()
@exp = ('foo', '"double quoted"', '&', '\'single quoted\'', '(', 'paren', ')');
# for history_arg_extract()
$exp = "@exp";

is_deeply([$t->history_tokenize($string)], \@exp, 'history_tokenize');

ok($t->history_arg_extract($string, 0, '$') eq $exp, 'history_arg_extract');
ok($t->history_arg_extract($string, 0)      eq $exp);
ok($t->history_arg_extract($string)         eq $exp);
$_ = $string;
ok($t->history_arg_extract                  eq $exp);

########################################################################
note "2.4 History Variables";

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

ok($t->history_expand('!!') eq '!!', 'history_inhibit_expansion_function');
ok($t->history_expand(' !r') eq ' red yellow');
# strange behavior was fixed on version 6.0
if ($version < 6.0) {
    ok($t->history_expand('!! !y') eq 'green blue yellow blue');
} else {
    ok($t->history_expand('!! !y') eq '!! yellow blue');
}
#done_testing();
end_of_test:
exit 0;

########################################################################
# subroutines

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
