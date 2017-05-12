# -*- perl -*-
#	readline.t - Test script for Term::ReadLine:GNU
#
#	$Id: readline.t 555 2016-11-03 14:04:27Z hayashi $
#
#	Copyright (c) 1996-2016 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/readline.t'

use strict;
use warnings;
use Test::More tests => 147;
use Data::Dumper;

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
    $ENV{LC_ALL} = 'C';		# LC_ALL is stronger than LANG
}

# 'define @ARGV' is deprecated
my $verbose = scalar @ARGV && ($ARGV[0] eq 'verbose');

use Term::ReadLine;
BEGIN {
    import Term::ReadLine::Gnu qw(:keymap_type RL_STATE_INITIALIZED);
}
ok(1, 'load done');

note "Testing Term::ReadLine::Gnu version $Term::ReadLine::Gnu::VERSION";

########################################################################
# test new method

# stop reading ~/.inputrc not to change the default key-bindings.
$ENV{'INPUTRC'} = '/dev/null';
# These tty setting affects GNU Readline key-bindings.
# Set the standard bindings before rl_initialize() being called.
# comment out since check_default_keybind_and_fix() takes care.
# system('stty erase  ^?') == 0 or warn "stty erase failed: $?";
# system('stty kill   ^u') == 0 or warn "stty kill failed: $?";
# system('stty lnext  ^v') == 0 or warn "stty lnext failed: $?";
# system('stty werase ^w') == 0 or warn "stty werase failed: $?";

my $t = new Term::ReadLine 'ReadLineTest';
isa_ok($t, 'Term::ReadLine');

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
ok($t->ReadLine eq 'Term::ReadLine::Gnu', '$t->ReadLine');

########################################################################
# test Features method
ok(%{ $t->Features }, 'Features method');
#isa_ok($t->Features, 'Term::ReadLine', 'Features');

########################################################################
# test Attribs method
my $a = $t->Attribs;
isa_ok($a, 'Term::ReadLine', 'Attribs');

########################################################################
note "2.3 Readline Variables";

my ($maj, $min) = $a->{library_version} =~ /(\d+)\.(\d+)/;
my $version = $a->{readline_version};
SKIP: {
    # rl_readline_version returns 0x0600.  The bug is fixed GNU Readline 6.1-p2
    skip "GNU Readline Library 6.1 may return wrong value.", 1 if ($a->{library_version} eq '6.1');
    ok($version == 0x100 * $maj + $min, 'readline_version');
}

# Version 2.0 and before are NOT supported.
ok($version > 0x0200, 'readline_version');

# check the values of initialized variables
ok($a->{line_buffer} eq '', 'line_buffer');
ok($a->{point} == 0, 'point');
ok($a->{end} == 0, 'end');
ok($a->{mark} == 0, 'mark');
ok($a->{done} == 0, 'done');

ok($a->{num_chars_to_read} == 0, 'num_chars_to_read');
ok($a->{pending_input} == 0, 'pending_input');
ok($a->{dispatching} == 0, 'dispatching');

ok($a->{erase_empty_line} == 0, 'erase_empty_line');
ok(! defined($a->{prompt}), 'prompt');
ok($a->{display_prompt} eq "", 'display_prompt');
ok($a->{already_prompted} == 0, 'already_prompted');
# library_version and readline_version are tested above.
ok($a->{gnu_readline_p} == 1, 'gnu_readline_p');

if ($version < 0x0402) {
    # defined but left assgined as NULL
    ok(! defined($a->{terminal_name}), 'terminal_name');
} else {
    ok($a->{terminal_name} eq $ENV{TERM}, 'terminal_name');
}
ok($a->{readline_name} eq 'ReadLineTest', 'readline_name');

# rl_instream and rl_outstream are tested below.
ok($a->{prefer_env_winsize} == 0, 'prefer_envwin_size');
ok(! defined($a->{last_func}), 'last_func');

ok(! defined($a->{startup_hook}), 'startup_hook');
ok(! defined($a->{pre_input_hook}), 'pre_input_hook');
ok(! defined($a->{event_hook}), 'event_hook');
ok(! defined($a->{getc_function}), 'getc_function');
ok(! defined($a->{signal_event_hook}), 'signal_event_hook'); # not tested!!!
ok(! defined($a->{input_available_hook}), 'input_available_hook');
ok(! defined($a->{redisplay_function}), 'redisplay_function');
ok(! defined($a->{prep_term_function}), 'prep_term_function');   # not tested!!!
ok(! defined($a->{deprep_term_function}), 'deprep_term_function'); # not tested!!!

# not defined here yet
ok(! defined($a->{executing_keymap}), 'executing_keymap');
# anonymous keymap
ok(defined($a->{binding_keymap}), 'binding_keymap');

ok(! defined($a->{executing_macro}), 'executing_macro');
ok($a->{executing_key} == 0, 'executing_key');

if ($version < 0x0603) {
    ok(! defined($a->{executing_keyseq}), 'executing_keyseq');
} else {
    ok(defined($a->{executing_keyseq}), 'executing_keyseq');
}
ok($a->{key_sequence_length} == 0, 'key_sequence_length');

ok(($a->{readline_state} == RL_STATE_INITIALIZED), 'readline_state');
ok($a->{explicit_arg} == 0, 'explicit_arg');
ok($a->{numeric_arg} == 1, 'numeric_arg');
ok($a->{editing_mode} == 1, 'editing_mode');


########################################################################
note "2.4 Readline Convenience Functions";

########################################################################
# define some custom functions

sub reverse_line {		# reverse a whole line
    my($count, $key) = @_;	# ignored in this sample function
    
    $t->modifying(0, $a->{end}); # save undo information
    $a->{line_buffer} = reverse $a->{line_buffer};
}

# From the GNU Readline Library Manual
# Invert the case of the COUNT following characters.
sub invert_case_line {
    my($count, $key) = @_;

    my $start = $a->{point};
    return 0 if ($start >= $a->{end});

    # Find the end of the range to modify.
    my $end = $start + $count;

    # Force it to be within range.
    if ($end > $a->{end}) {
	$end = $a->{end};
    } elsif ($end < 0) {
	$end = 0;
    }

    return 0 if $start == $end;

    if ($start > $end) {
	my $temp = $start;
	$start = $end;
	$end = $temp;
    }

    # Tell readline that we are modifying the line, so it will save
    # undo information.
    $t->modifying($start, $end);

    # I'm happy with Perl :-)
    substr($a->{line_buffer}, $start, $end-$start) =~ tr/a-zA-Z/A-Za-z/;

    # Move point to on top of the last character changed.
    $a->{point} = $count < 0 ? $start : $end - 1;
    return 0;
}

########################################################################
note "2.4.1 Naming a Function";

my ($func, $type);

# test add_defun
ok(! defined($t->named_function('reverse-line'))
   && ! defined($t->named_function('invert-case-line'))
   && defined($t->named_function('operate-and-get-next'))
   && defined($t->named_function('display-readline-version'))
   && defined($t->named_function('change-ornaments')), 'add_defun: before');

($func, $type) = $t->function_of_keyseq("\ct");
ok($type == ISFUNC && $t->get_function_name($func) eq 'transpose-chars', 'add_defun, function_of_keyseq');

$t->add_defun('reverse-line',		  \&reverse_line, ord "\ct");
$t->add_defun('invert-case-line',	  \&invert_case_line);

ok(defined($t->named_function('reverse-line'))
   && defined($t->named_function('invert-case-line'))
   && defined($t->named_function('operate-and-get-next'))
   && defined($t->named_function('display-readline-version'))
   && defined($t->named_function('change-ornaments')), 'add_defun: after');

($func, $type) = $t->function_of_keyseq("\ct");
ok($type == ISFUNC && $t->get_function_name($func) eq 'reverse-line', 'add_defun, function_of_keyseq');

########################################################################
note "2.4.2 Selecting a Keymap";

# test rl_make_bare_keymap, rl_copy_keymap, rl_make_keymap, rl_discard_keymap, rl_free_keymap
my $baremap = $t->make_bare_keymap;
$t->bind_key(ord "a", 'abort', $baremap);
my $copymap = $t->copy_keymap($baremap);
$t->bind_key(ord "b", 'abort', $baremap);
my $normmap = $t->make_keymap;

ok(($t->get_function_name(($t->function_of_keyseq('a', $baremap))[0]) eq 'abort')
   && ($t->get_function_name(($t->function_of_keyseq('b', $baremap))[0]) eq 'abort')
   && ($t->get_function_name(($t->function_of_keyseq('a', $copymap))[0]) eq 'abort')
   && ! defined($t->function_of_keyseq('b', $copymap))
   && ($t->get_function_name(($t->function_of_keyseq('a', $normmap))[0]) eq 'self-insert'),
   'make_bare_keymap, copy_keymap, make_keymap, bind_key');

$t->discard_keymap($baremap);
$t->discard_keymap($copymap);
$t->discard_keymap($normmap);
ok(1, 'discard_keymap');

$t->free_keymap($baremap);
$t->free_keymap($copymap);
$t->free_keymap($normmap);
ok(1, 'free_keymap');

# test rl_get_keymap, rl_set_keymap, rl_get_keymap_by_name, rl_get_keymap_name
ok($t->get_keymap_name($t->get_keymap) eq 'emacs', 'get_keymap_name, get_keymap');

$t->set_keymap('vi');
ok($t->get_keymap_name($t->get_keymap) eq 'vi', 'set_keymap');

# equivalent to $t->set_keymap('emacs');
$t->set_keymap($t->get_keymap_by_name('emacs'));
ok($t->get_keymap_name($t->get_keymap) eq 'emacs', 'set_keymap, get_keymap_by_name');

########################################################################
note "2.4.3 Binding Keys";

#print $t->get_keymap_name($a->{executing_keymap}), "\n";
#print $t->get_keymap_name($a->{binding_keymap}), "\n";

# test rl_bind_key[_in_map], rl_bind_key_if_unbound[_in_map]!!!,
# rl_unbind_key[_in_map] (below), rl_unbind_function_in_map (below), rl_unbind_command_in_map (below),
# rl_bind_keyseq[_in_map]!!!, rl_set_key, rl_bind_keyseq_if_unbound[_in_map]!!!, 
# rl_generic_bind, rl_parse_and_bind

# define subroutine to use again later
my ($helpmap, $mymacro);
sub bind_my_function {
    $t->bind_key(ord "\ct", 'reverse-line');
    $t->bind_key(ord "\cv", 'display-readline-version', 'emacs-ctlx');
    $t->parse_and_bind('"\C-xv": display-readline-version');
    $t->bind_key(ord "c", 'invert-case-line', 'emacs-meta');
    if ($version >= 0x0402) {
	# rl_set_key in introduced by GRL 4.2
	$t->set_key("\eo", 'change-ornaments');
    } else {
	$t->bind_key(ord "o", 'change-ornaments', 'emacs-meta');
    }
    $t->bind_key(ord "^", 'history-expand-line', 'emacs-meta');
    
    # make an original map
    $helpmap = $t->make_bare_keymap();
    $t->bind_key(ord "f", 'dump-functions', $helpmap);
    $t->generic_bind(ISKMAP, "\e?", $helpmap);
    $t->bind_key(ord "v", 'dump-variables', $helpmap);
    # 'dump-macros' is documented but not defined by GNU Readline 2.1
    $t->generic_bind(ISFUNC, "\e?m", 'dump-macros') if $version > 0x0201;
    
    # bind a macro
    $mymacro = "\ca[insert text from the beginning of line]";
    $t->generic_bind(ISMACR, "\e?i", $mymacro);
}

bind_my_function;		# do bind

{
    my ($fn, $ty);
    # check keymap binding
    ($fn, $ty) = $t->function_of_keyseq("\cX");
    ok($t->get_keymap_name($fn) eq 'emacs-ctlx' && $ty == ISKMAP, 'keymap binding');

    # check macro binding
    ($fn, $ty) = $t->function_of_keyseq("\e?i");
    ok($fn eq $mymacro && $ty == ISMACR, 'macro binding');
}

# check some key binding used by following test
sub is_boundp {
    my ($seq, $fname) = @_;
    my ($fn, $type) = $t->function_of_keyseq($seq);
    if ($fn) {
	return ($t->get_function_name($fn) eq $fname
		&& $type == ISFUNC);
    } else {
	warn ("No function is bound for sequence \`", toprint($seq),
	      "\'.  \`$fname\' is expected,");
	return 0;
    }
}

# check function binding
ok(is_boundp("\cT", 'reverse-line')
   && is_boundp("\cX\cV", 'display-readline-version')
   && is_boundp("\cXv",   'display-readline-version')
   && is_boundp("\ec",    'invert-case-line')
   && is_boundp("\eo",    'change-ornaments')
   && is_boundp("\e^",    'history-expand-line')
   && is_boundp("\e?f",   'dump-functions')
   && is_boundp("\e?v",   'dump-variables')
   && ($version <= 0x0201 or is_boundp("\e?m",   'dump-macros')), 'function binding');

# test rl_read_init_file
ok($t->read_init_file('t/inputrc') == 0, 'read_init_file');

ok(is_boundp("a", 'abort')
   && is_boundp("b", 'abort')
   && is_boundp("c", 'self-insert'), 'read_init_file');

# resume
$t->bind_key(ord "a", 'self-insert');
$t->bind_key(ord "b", 'self-insert');
ok(is_boundp("a", 'self-insert') && is_boundp("b", 'self-insert'), 'bind_key');

# test rl_unbind_key (rl_unbind_key_in_map),
#      rl_unbind_command (rl_unbind_command_in_map),
#      rl_unbind_function (rl_unbind_function_in_map)
$t->unbind_key(ord "\ct");	# reverse-line
$t->unbind_key(ord "f", $helpmap); # dump-function
$t->unbind_key(ord "v", 'emacs-ctlx'); # display-readline-version
if ($version > 0x0201) {
    $t->unbind_command_in_map('display-readline-version', 'emacs-ctlx');
    $t->unbind_function_in_map($t->named_function('dump-variables'), $helpmap);
} else {
    $t->unbind_key(ord "\cV", 'emacs-ctlx');
    $t->unbind_key(ord "v", $helpmap);
}

my @keyseqs = ($t->invoking_keyseqs('reverse-line'),
	       $t->invoking_keyseqs('dump-functions'),
	       $t->invoking_keyseqs('display-readline-version'),
	       $t->invoking_keyseqs('dump-variables'));
ok(scalar @keyseqs == 0, "unbind_key\t[@keyseqs]");

SKIP: {
    skip "GNU Readline Library is older than 4.2.", 1 unless ($version >= 0x0402);
    $t->add_funmap_entry('foo_bar', 'reverse-line');
# This does not work.  We need something like `equal' in Lisp.
#    ok($t->named_function('reverse-line') == $t->named_function('foo_bar'));
    ok(defined $t->named_function('foo_bar'), 'add_funmap_entry');
}

########################################################################
note "2.4.4 Associating Function Names and Bindings";

bind_my_function;		# do bind

# rl_named_function, get_function_name, rl_function_of_keyseq,
# rl_invoking_keyseqs[_in_map]
# rl_function_dumper!!!, rl_list_funmap_names!!!, rl_funmap_names!!!
# rl_add_funmap_entry (above)
    
# test rl_invoking_keyseqs
@keyseqs = $t->invoking_keyseqs('abort', 'emacs-ctlx');
ok("\\C-g" eq "@keyseqs", 'invoking_keyseqs');

########################################################################
note "2.4.5 Allowing Undoing";
# rl_begin_undo_group!!!, rl_end_undo_group!!!, rl_add_undo!!!,
# rl_free_undo_list!!!, rl_do_undo!!!, rl_modifying

########################################################################
note "2.4.6 Redisplay";
# rl_redisplay!!!, rl_forced_update_display (below), rl_on_new_line!!!,
# rl_on_new_line_with_prompt!!!, rl_clear_visible_line()!!!,
# rl_reset_line_state!!!, rl_crlf!!!,
# rl_show_char!!!,
# rl_message, rl_clear_message, rl_save_prompt, rl_restore_prompt:
#   see Gnu/XS.pm:change_ornaments()
# rl_expand_prompt!!!, rl_set_prompt!!!

########################################################################
note "2.4.7 Modifying Text";
# rl_insert_text!!!, rl_delete_text!!!, rl_copy_text!!!, rl_kill_text!!!,
# rl_push_macro_input!!!

########################################################################
note "2.4.8 Character Input";
# rl_read_key!!!, rl_getc, rl_stuff_char!!!, rl_execute_next!!!,
# rl_clear_pending_input!!!, rl_set_keyboard_input_timeout!!!

########################################################################
note "2.4.9 Terminal Management";
# rl_prep_terminal!!!, rl_deprep_terminal!!!,
# rl_tty_set_default_bindings!!!, rl_tty_unset_default_bindings!!!,
# rl_tty_set_echoing!!!, rl_reset_terminal!!!

########################################################################
note "2.4.10 Utility Functions";
# rl_save_state, rl_restore_state, -rl_free-, rl_replace_line!!!,
# -rl_extend_line_buffer-,
# rl_initialize, rl_ding!!!, rl_alphabetic!!!,
# rl_display_match_list (below)
SKIP:
{
    skip "GNU Readline Library is older than 4.3.", 4 unless ($version >= 0x0403);
    ok($a->{point} == 0, 'save_state, restore_state');
    my $state = $t->save_state();
    isa_ok($state, 'readline_state_tPtr');
    $a->{point} = 10;
    ok($a->{point} == 10, 'save_state, restore_state');
    $t->restore_state($state);
    ok($a->{point} == 0, 'save_state, restore_state');
}

########################################################################
note "2.4.11 Miscellaneous Functions";
# rl_macro_bind!!!, rl_macro_dumpter!!!,
# rl_variable_bind!!!, rl_variable_value!!!, rl_variable_dumper!!!
# rl_set_paren_blink_timeout!!!, rl_get_termcap!!!, rl_clear_history!!!

########################################################################
note "2.4.12 Alternate Interface";
# tested in callback.t
# rl_callback_handler_install, rl_callback_read_char,
# rl_callback_sigcleanup!!!, rl_callback_handler_remove,

########################################################################
note "2.5 Readline Signal Handling";
ok($a->{catch_signals} == 1, 'catch_signals');
ok($a->{catch_sigwinch} == 1, 'catch_sigwinch');
ok($a->{persistent_signal_handlers} == 0, 'persistent_signal_handlers');
ok($a->{change_environment} == 1, 'change_environment');

# rl_pending_signal()!!!, rl_cleanup_after_signal!!!, rl_free_line_state!!!,
# rl_reset_after_signal!!!, rl_echo_signal_char!!!, rl_resize_terminal!!!,

# rl_set_screen_size, rl_get_screen_size
SKIP: {
    skip "GNU Readline Library is older than 4.2.", 1 unless ($version >= 0x0402);
    my ($rowsav, $colsav) =  $t->get_screen_size;
    $t->set_screen_size(60, 132);
    my ($row, $col) =  $t->get_screen_size;
    # col=131 on a terminal which does not support auto-wrap function
    ok($row == 60 && ($col == 132 || $col == 131), 'set/get_screen_size');
    $t->set_screen_size($rowsav, $colsav);
}

# rl_reset_screen_size!!!, rl_set_signals!!!, rl_clear_signals!!!

########################################################################
note "2.6 Custom Completers";
note "2.6.1 How Completing Works";
# rl_complete, rl_completion_entry_function (below)
note "2.6.2 Completion Functions";
# rl_complete_internal!!!, rl_complete, rl_possible_completions, rl_insert_completions,
# rl_completion_mode!!!, rl_completion_matches,
# rl_filename_completion_function, rl_username_completion_function,
# list_completion_function

note "2.6.3 Completion Variables";
ok(! defined $a->{completion_entry_function}, 'completion_entry_function');
ok(! defined $a->{attempted_completion_function}, 'attempted_completion_function');
ok(! defined $a->{filename_quoting_function}, 'filename_quoting_function');
ok(! defined $a->{filename_dequoting_function}, 'filename_dequoting_function');
ok(! defined $a->{char_is_quoted_p}, 'char_is_quoted_p');
ok(! defined $a->{ignore_some_completions_function}, 'ignore_some_completions_function');
ok(! defined $a->{directory_completions_hook}, 'directory_completions_hook');
ok(! defined $a->{directory_rewrite_hook}, 'directory_rewrite_hook');
ok(! defined $a->{filename_stat_hook}, 'filename_stat_hook');
ok(! defined $a->{filename_rewrite_hook}, 'filename_rewrite_hook');
ok(! defined $a->{completions_display_matches_hook}, 'completions_display_matches_hook');

ok($a->{basic_word_break_characters} eq " \t\n\"\\'`\@\$><=;|&{(", 'basic_word_break_characters');
ok($a->{basic_quote_characters} eq "\"'", 'basic_quote_characters');
ok($a->{completer_word_break_characters} eq " \t\n\"\\'`\@\$><=;|&{(", 'completer_word_break_characters');
ok(! defined $a->{completion_word_break_hook}, 'completion_word_break_hook');
ok(! defined $a->{completer_quote_characters}, 'completer_quote_characters');
ok(! defined $a->{filename_quote_characters}, 'filename_quote_characters');
ok(! defined $a->{special_prefixes}, 'special_prefixes');

ok($a->{completion_query_items} == 100, 'completion_query_items');
ok($a->{completion_append_character} eq " ", 'completion_append_character');

ok($a->{completion_suppress_append} == 0, 'completion_suppress_append');
ok($a->{completion_quote_character} eq "\0", 'completion_quote_character');
ok($a->{completion_suppress_quote} == 0, 'completion_suppress_quote');
ok($a->{completion_found_quote} == 0, 'completion_found_quote');
ok($a->{completion_mark_symlink_dirs} == 0, 'completion_mark_symlink_dirs');

ok($a->{ignore_completion_duplicates} == 1, 'ignore_completion_duplicates');
ok($a->{filename_completion_desired} == 0, 'filename_completion_desired');
ok($a->{filename_quoting_desired} == 1, 'filename_quoting_desired');
ok($a->{attempted_completion_over} == 0, 'attempted_completion_over');
ok($a->{sort_completion_matches} == 1, 'sort_completion_matches');

ok($a->{completion_type} == 0, 'completion_type');
ok($a->{completion_invoking_key} eq "\0", 'completion_invoking_key');
ok($a->{inhibit_completion} == 0, 'inhibit_completion');


########################################################################

$t->parse_and_bind('set bell-style none'); # make readline quiet
#$t->parse_and_bind('set enable-bracketed-paste on');
#$t->parse_and_bind('set blink-matching-paren on');
#$t->parse_and_bind('set colored-completion-prefix off');

my ($INSTR, $line);
# simulate key input by using a variable 'rl_getc_function'
$a->{getc_function} = sub {
    unless (length $INSTR) {
	print $OUT "Error: getc_function: insufficient string, \`\$INSTR\'.";
	undef $a->{getc_function};
	return 0;
    }
    my $c  = substr $INSTR, 0, 1; # the first char of $INSTR
    $INSTR = substr $INSTR, 1;	# rest of $INSTR
    return ord $c;
};

# This is required after GNU Readline Library 6.3.
$a->{input_available_hook} = sub {
    return 1;
};

# convert control charactors to printable charactors (ex. "\cx" -> '\C-x')
sub toprint {
    join('',
	 map{$_ eq "\e" ? '\M-': ord($_)<32 ? '\C-'.lc(chr(ord($_)+64)) : $_}
	 (split('', $_[0])));
}

sub check_default_keybind_and_fix {
    my ($seq, $fname) = @_;
    if (is_boundp($seq, $fname)) {
	ok(1, "  $fname was bound to " . toprint($seq));
    } else {
	# Try to fix the binding.  But tty setting seems have precedence.
	$t->set_key($seq, $fname);
	if (is_boundp($seq, $fname)) {
	    # The default keybinding for $fname was changed. Fixed.
	    ok(1, "  $fname is now bound to " . toprint($seq));
	} else {
	    ok(0, "  $fname cannot be bound to " . toprint($seq));
	}
    }
}
note "check_default_keybind_and_fix";
check_default_keybind_and_fix("\cM", 'accept-line');
check_default_keybind_and_fix("\cF", 'forward-char');
check_default_keybind_and_fix("\cB", 'backward-char');
check_default_keybind_and_fix("\ef", 'forward-word');
check_default_keybind_and_fix("\eb", 'backward-word');
check_default_keybind_and_fix("\cE", 'end-of-line');
check_default_keybind_and_fix("\cA", 'beginning-of-line');
check_default_keybind_and_fix("\cH", 'backward-delete-char');
check_default_keybind_and_fix("\cD", 'delete-char');
check_default_keybind_and_fix("\cI", 'complete');

$INSTR = "abcdefgh\cM";
$line = $t->readline("self insert> ");
ok($line eq 'abcdefgh', "self insert\t[$line]");

$INSTR = "\cAe\cFf\cBg\cEh\cH ij kl\eb\ebm\cDn\cM";
$line = $t->readline("cursor move> ", 'abcd'); # default string
SKIP: {
    # skip on CPAN Testers test. 
    skip "This 'cursor move' test fails on an active tester's environment, but we could not solve the issue.", 1 
	if $ENV{AUTOMATED_TESTING} || defined $ENV{PERL_CPAN_REPORTER_CONFIG};
    ok($line eq 'eagfbcd mnj kl', "cursor move\t[$line]");
}

# test reverse_line, display_readline_version, invert_case_line
$INSTR = "\cXvabcdefgh XYZ\e6\cB\e4\ec\cT\cM";
$line = $t->readline("custom commands> ");
ok($line eq 'ZYx HGfedcba', "custom commands\t[$line]");

# test undo of reverse_line
$INSTR = "abcdefgh\cTi\c_\c_\cM";
$line = $t->readline("test undo> ");
ok($line eq 'abcdefgh', "undo\t[$line]");

# test macro, change_ornaments
$INSTR = "1234\e?i\eoB\cM\cM";
$line = $t->readline("keyboard macro> ");
ok($line eq "[insert text from the beginning of line]1234", "macro\t[$line]");
$INSTR = "\cM";
$line = $t->readline("bold face prompt> ");
ok($line eq '', "ornaments\t[$line]");

# test operate_and_get_next
$INSTR = "one\cMtwo\cMthree\cM\cP\cP\cP\cO\cO\cO\cM";
$line = $t->readline("> ");	# one
$line = $t->readline("> ");	# two
$line = $t->readline("> ");	# three
$line = $t->readline("> ");
ok($line eq 'one', "operate_and_get_next 1\t[$line]");
$line = $t->readline("> ");
ok($line eq 'two', "operate_and_get_next 2\t[$line]");
$line = $t->readline("> ");
ok($line eq 'three', "operate_and_get_next 3\t[$line]");
$line = $t->readline("> ");
ok($line eq 'one', "operate_and_get_next 4\t[$line]");

########################################################################
note "test history expansion";

$t->ornaments(0);		# ornaments off

#print $OUT "\n# history expansion test\n# quit by EOF (\\C-d)\n";
$a->{do_expand} = 1;
$t->MinLine(4);

sub prompt {
    # equivalent with "$nline = $t->where_history + 1"
    my $nline = $a->{history_base} + $a->{history_length};
    "$nline> ";
}

$INSTR = "!1\cM";
$line = $t->readline(prompt);
ok($line eq 'abcdefgh', "history 1\t[$line]");

$INSTR = "123\cM";		# too short
$line = $t->readline(prompt);
$INSTR = "!!\cM";
$line = $t->readline(prompt);
ok($line eq 'abcdefgh', "history 2\t[$line]");

$INSTR = "1234\cM";
$line = $t->readline(prompt);
$INSTR = "!!\cM";
$line = $t->readline(prompt);
ok($line eq '1234', "history 3\t[$line]");

########################################################################
note "test custom completion function";

$t->parse_and_bind('set bell-style none'); # make readline quiet

$INSTR = "t/comp\cI\e*\cM";
$line = $t->readline("insert completion>");
# "a_b" < "README" on some kind of locale since strcoll() is used in
# the GNU Readline Library.
# Not all perl support setlocale.  My perl supports locale and I tried
#   use POSIX qw(locale_h); setlocale(LC_COLLATE, 'C');
# But it seems that it does not affect strcoll() linked to GNU
# Readline Library.
ok($line eq 't/comptest/0123 t/comptest/012345 t/comptest/023456 t/comptest/README t/comptest/a_b '
   || $line eq 't/comptest/0123 t/comptest/012345 t/comptest/023456 t/comptest/a_b t/comptest/README '
   || $line eq 't/comptest/.svn t/comptest/0123 t/comptest/012345 t/comptest/023456 t/comptest/README t/comptest/a_b '
   || $line eq 't/comptest/.svn t/comptest/0123 t/comptest/012345 t/comptest/023456 t/comptest/a_b t/comptest/README ', "insert completion\t[$line]");

$INSTR = "t/comp\cIR\cI\cM";
$line = $t->readline("filename completion (default)>");
ok($line eq 't/comptest/README ', "default completion\t[$line]");

$a->{completion_entry_function} = $a->{'username_completion_function'};
my $user = getlogin || 'root';
$INSTR = "${user}\cI\cM";
$line = $t->readline("username completion>");
if ($line eq "${user} ") {
    ok(1, 'username completion');
} elsif ($line eq ${user}) {
    ok(1, 'username completion');
    diag "It seems that there is no user whose name is '${user}' or there is a user whose name starts with '${user}'";
} else { 
    ok(0, "username completion\t[$line]"); # something wrong...
}

$a->{completion_word} = [qw(a list of words for completion and another word)];
$a->{completion_entry_function} = $a->{'list_completion_function'};
print $OUT "given list is: a list of words for completion and another word\n";
$INSTR = "a\cI\cIn\cI\cIo\cI\cM";
$line = $t->readline("list completion>");
ok($line eq 'another ', "list completion\t[$line]");

$a->{completion_entry_function} = $a->{'filename_completion_function'};
$INSTR = "t/comp\cI\cI\cI0\cI\cI1\cI\cI\cM";
$line = $t->readline("filename completion>");
ok($line eq 't/comptest/0123', "filename completion\t[$line]");
undef $a->{completion_entry_function};

# attempted_completion_function

$a->{attempted_completion_function} = sub { undef; };
$a->{completion_entry_function} = sub {};
$INSTR = "t/comp\cI\cM";
$line = $t->readline("null completion 1>");
ok($line eq 't/comp', "null completion 1\t[$line]");

$a->{attempted_completion_function} = sub { (undef, undef); };
undef $a->{completion_entry_function};
$INSTR = "t/comp\cI\cM";
$line = $t->readline("null completion 2>");
ok($line eq 't/comptest/', "null completion 2\t[$line]");

sub sample_completion {
    my ($text, $line, $start, $end) = @_;
    # If first word then username completion, else filename completion
    if (substr($line, 0, $start) =~ /^\s*$/) {
	return $t->completion_matches($text, $a->{'list_completion_function'});
    } else {
	return ();
    }
}

$a->{attempted_completion_function} = \&sample_completion;
print $OUT "given list is: a list of words for completion and another word\n";
$INSTR = "li\cIt/comp\cI\cI\cI0\cI\cI2\cI\cM";
$line = $t->readline("list & filename completion>");
ok($line eq 'list t/comptest/023456 ', "list & file completion\t[$line]");
undef $a->{attempted_completion_function};

# ignore_some_completions_function
$a->{ignore_some_completions_function} = sub {
    return (grep m|/$| || ! m|^(.*/)?[0-9]*$|, @_);
};
$INSTR = "t/co\cIRE\cI\cM";
$line = $t->readline("ignore_some_completion>");
ok($line eq 't/comptest/README ', "ingore_some_completion\t[$line]");
undef $a->{ignore_some_completions_function};

# char_is_quoted, filename_quoting_function, filename_dequoting_function

sub char_is_quoted ($$) {	# borrowed from bash-2.03:subst.c
    my ($string, $eindex) = @_;
    my ($i, $pass_next);

    for ($i = $pass_next = 0; $i <= $eindex; $i++) {
	my $c = substr($string, $i, 1);
	if ($pass_next) {
	    $pass_next = 0;
	    return 1 if ($i >= $eindex); # XXX was if (i >= eindex - 1)
	} elsif ($c eq '\'') {
	    $i = index($string, '\'', ++$i);
	    return 1 if ($i == -1 || $i >= $eindex);
#	} elsif ($c eq '"') {	# ignore double quote
	} elsif ($c eq '\\') {
	    $pass_next = 1;
	}
    }
    return 0;
}
$a->{char_is_quoted_p} = \&char_is_quoted;
$a->{filename_quoting_function} = sub {
    my ($text, $match_type, $quote_pointer) = @_;
    my $qc = $a->{filename_quote_characters};
    return $text if $quote_pointer;
    $text =~ s/[\Q${qc}\E]/\\$&/;
    return $text;
};
$a->{filename_dequoting_function} = sub {
    my ($text, $quote_char) = @_;
    $quote_char = chr $quote_char;
    $text =~ s/\\//g;
    return $text;
};

$a->{completer_quote_characters} = '\'';
$a->{filename_quote_characters} = ' _\'\\';

$INSTR = "t/comp\cIa\cI 't/comp\cIa\cI\cM";
$line = $t->readline("filename_quoting_function>");
ok($line eq 't/comptest/a\\_b  \'t/comptest/a_b\' ', "filename_quoting_function\t[$line]");

$INSTR = "\'t/comp\cIa\\_\cI\cM";
$line = $t->readline("filename_dequoting_function>");
ok($line eq '\'t/comptest/a_b\' ', "filename_dequoting_function\t[$line]");

undef $a->{char_is_quoted_p};
undef $a->{filename_quoting_function};
undef $a->{filename_dequoting_function};

# directory_completion_hook
$a->{directory_completion_hook} = sub {
    if ($_[0] eq 'comp/') {	# simple alias function
	$_[0] = 't/comptest/';
	return 1;
    } else {
	return 0;
    }
};

$INSTR = "comp/\cI\cM";
$line = $t->readline("directory_completion_hook>");
ok($line eq 't/comptest/', "directory_completion_hook\t[$line]");
undef $a->{directory_completion_hook};

# filename_list
my @m = $t->filename_list('t/comptest/01');
ok($#m == 1, "filename_list\t[" . join(':', @m) . ']');

$t->parse_and_bind('set bell-style audible'); # resume to default style

########################################################################
note "test rl_startup_hook, rl_pre_input_hook";

$a->{startup_hook} = sub { $a->{point} = 10; };
$INSTR = "insert\cM";
$line = $t->readline("rl_startup_hook test>", "cursor is, <- here");
ok($line eq 'cursor is,insert <- here', "startup_hook\t[$line]");
$a->{startup_hook} = undef;

$a->{pre_input_hook} = sub { $a->{point} = 10; };
$INSTR = "insert\cM";
$line = $t->readline("rl_pre_input_hook test>", "cursor is, <- here");
SKIP: {
    skip "GNU Readline Library is older than 4.0.", 1 unless ($version >= 0x0400);
    ok($line eq 'cursor is,insert <- here', "pre_input_hook\t[$line]");
}
$a->{pre_input_hook} = undef;

#########################################################################
note "test redisplay_function";
$a->{redisplay_function} = $a->{shadow_redisplay};
$INSTR = "\cX\cVThis is a password.\cM";
$line = $t->readline("password> ");
ok($line eq 'This is a password.', "redisplay_function\t[$line]");
undef $a->{redisplay_function};
ok(1, 'redisplay_function');

#########################################################################
note "test rl_display_match_list";

SKIP: {
    skip "GNU Readline Library is older than 4.0.", 1 unless ($version >= 0x0400);
#    my @match_list = @{$a->{completion_word}};
    my @match_list = qw(possible_completion one two three four five six);
    $t->display_match_list(\@match_list);
    $t->parse_and_bind('set print-completions-horizontally on');
    $t->display_match_list(\@match_list);
    $t->parse_and_bind('set print-completions-horizontally off');
    @match_list = qw(foo/ foo/bar1 foo/bar2 foo/bar3);
    $t->display_match_list(\@match_list);
    @match_list = qw(foo/bar foo/bar1 foo/bar2 foo/bar3);
    $t->display_match_list(\@match_list);
    ok(1, 'display_match_list');
}

#########################################################################
note "test rl_completion_display_matches_hook";

SKIP: {
    skip "GNU Readline Library is older than 4.0.", 1 unless ($version >= 0x0400);
    # See 'eg/perlsh' for better example
    $a->{completion_display_matches_hook} = sub  {
	my($matches, $num_matches, $max_length) = @_;
	map { $_ = uc $_; }(@{$matches});
	$t->display_match_list($matches);
	$t->forced_update_display;
    };
    $t->parse_and_bind('set bell-style none'); # make readline quiet
    $INSTR = "Gnu.\cI\cI\cM";
    $t->readline("completion_display_matches_hook>");
    undef $a->{completion_display_matches_hook};
    ok(1, 'completion_display_matches_hook');
    $t->parse_and_bind('set bell-style audible'); # resume to default style
}

########################################################################
note "test ornaments";

$INSTR = "\cM\cM\cM\cM\cM\cM\cM";
print $OUT "# ornaments test\n";
print $OUT "# Note: Some function may not work on your terminal.\n";
# Kterm seems to have a bug with 'ue' (End underlining) does not work\n";
$t->ornaments(1);	# equivalent to 'us,ue,md,me'
print $OUT "\n" unless defined $t->readline("default ornaments (underline)>");
# cf. man termcap(5)
$t->ornaments('so,me,,');
print $OUT "\n" unless defined $t->readline("standout>");
$t->ornaments('us,me,,');
print $OUT "\n" unless defined $t->readline("underlining>");
$t->ornaments('mb,me,,');
print $OUT "\n" unless defined $t->readline("blinking>");
$t->ornaments('md,me,,');
print $OUT "\n" unless defined $t->readline("bold>");
$t->ornaments('mr,me,,');
print $OUT "\n" unless defined $t->readline("reverse>");
# It seems that on some systems a visible bell cannot be redirected
# to /dev/null and confuses ExtUtils::Command:MM::test_harness().
$t->ornaments('vb,,,') if $verbose;
print $OUT "\n" unless defined $t->readline("visible bell>");
$t->ornaments(0);
print $OUT "# end of ornaments test\n";

ok(1, 'ornaments');

########################################################################
note "end of non-interactive test";
unless ($verbose) {
    # Be quiet during CPAN Testers testing.
    diag "Try \`$^X -Mblib t/readline.t verbose\', if you will.\n"
	if (!$ENV{AUTOMATED_TESTING});
    exit 0;
}
undef $a->{getc_function};
undef $a->{input_available_hook};

########################################################################
note "interactive testn";

########################################################################
# test redisplay_function
$a->{redisplay_function} = $a->{shadow_redisplay};
$line = $t->readline("password> ");
print "<$line>\n";
undef $a->{redisplay_function};

########################################################################
# test rl_getc_function and rl_getc()

sub uppercase {
#    my $FILE = $a->{instream};
#    return ord uc chr $t->getc($FILE);
    return ord uc chr $t->getc($a->{instream});
}

$a->{getc_function} = \&uppercase;
print $OUT "\n" unless defined $t->readline("convert to uppercase>");
undef $a->{getc_function};
undef $a->{input_available_hook};

########################################################################
# test event_hook

my $timer = 20;			# 20 x 0.1 = 2.0 sec timer
$a->{event_hook} = sub {
    if ($timer-- < 0) {
	$a->{done} = 1;
	undef $a->{event_hook};
    }
};
$line = $t->readline("input in 2 seconds> ");
undef $a->{event_hook};
print "<$line>\n";

########################################################################
my %TYPE = (0 => 'Function', 1 => 'Keymap', 2 => 'Macro');

print $OUT "\n# Try the following commands.\n";
foreach ("\co", "\ct", "\cx",
	 "\cx\cv", "\cxv", "\ec", "\e^",
	 "\e?f", "\e?v", "\e?m", "\e?i", "\eo") {
    my ($p, $type) = $t->function_of_keyseq($_);
    printf $OUT "%-9s: ", toprint($_);
    (print "\n", next) unless defined $type;
    printf $OUT "%-8s : ", $TYPE{$type};
    if    ($type == ISFUNC) { print $OUT ($t->get_function_name($p)); }
    elsif ($type == ISKMAP) { print $OUT ($t->get_keymap_name($p)); }
    elsif ($type == ISMACR) { print $OUT (toprint($p)); }
    else { print $OUT "Error: Illegal type value"; }
    print $OUT "\n";
}

print $OUT "\n# history expansion test\n# quit by EOF (\\C-d)\n";
$a->{do_expand} = 1;
while (defined($line = $t->readline(prompt))) {
    print $OUT "<<$line>>\n";
}
print $OUT "\n";
