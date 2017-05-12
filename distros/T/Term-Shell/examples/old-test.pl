#!perl -w

package App;

use strict;
use base qw(Term::Shell);
use Data::Dumper;

sub init {
    my $o = shift;
    $o->remove_handlers("run_squiggle");
    $o->{API}{match_uniq} = 0;	# allow only exact matches
    $o->{API}{check_idle} = 1;	# run on_idle() every 1 second
}

sub idle {
    my $o = shift;
    $o->{SHELL}{num}++;
}

# The default method (when you enter a blank line). This command is not shown
# in the help or in completion lists.
sub run_ {
    print "Default command...\n";
}

# A standard command. It has a summary (smry_), help topic (help_), and an
# action. But it doesn't provide custom command completion (comp_).
sub smry_fuzz { "A test for bears at play" }
sub help_fuzz {
    <<'END';
Fuzzy bears are harsh quacked, man.
END
}
sub run_fuzz {
    my $o = shift;
    print "Please enter the name of your mother.\n";
    my $l = $o->prompt('Name: ', undef, [qw(Jill Mary Blanche)]);
    print "Say hi to $l for me!\n";
}

# This command ('proxy') runs 'foo' and prints its return value (42).
sub run_proxy {
    my $o = shift;
    my $c = shift;
    my $r = $o->run($c || "foo", @_);
    print "Foo returned: ", $r, "\n";
    print Dumper $o->{API}{command};
}

sub catch_run {
    my $o = shift;
    my $cmd = shift;
    print "NOTE: catch_run() called. Emulating $cmd()\n";
    print Dumper \@_;
}

# This command ('squiggle') has two aliases ('foo', 'bar'). It doesn't have a
# summary or a help topic. It does provide custom command completion, though.
# If you try to complete the line after typing 'squiggle' (or 'foo' or 'bar'),
# you will be able to complete to any of the words qw(all work and no play is
# no fun at). Just for fun.
sub run_squiggle {
    print "Squiggle!\n";
    return 42;
}
sub comp_squiggle {
    my $o = shift;
    my $word = shift;
    $o->{SHELL}{num}++;
    $o->completions($word, [qw(all work and no play is no fun at)]);
}
sub alias_squiggle { qw(foo bar) }

# You can override the prompt
sub prompt_str {
    my $o = shift;
    $o->{SHELL}{num}++;
    "test:$o->{SHELL}{num}> ";
}

sub run_attribs {
    my $o = shift;
    my $term = $o->term;
    print Dumper $term->Features;

    my @keys = qw(
	readline_name
	basic_word_break_characters
    );
    print Dumper $term->Attribs->{$_} for @keys;
}

package main;

if ($ENV{TEST_INTERACTIVE} or not (exists $ENV{MAKELEVEL} or exists $ENV{__MKLVL__}))
{
    print <<END;
==============================================================================
Type 'help' to see a list of commands or help topics. If your terminal
supports tab-completion (and Term::ReadLine supports it too), then you should
be able to hit tab to complete the command-line.

Have fun!
==============================================================================
END
    my $app = App->new('default');
    my $term = $app->term;
    warn "Using term $term\n";
    $app->cmdloop;
}
else {
    print <<END;
==============================================================================
To test the actual command-line client, please set TEST_INTERACTIVE in your
environment and rerun 'make test'.

Alternatively, you can run 'perl -Mblib test.pl'.

Have fun!
==============================================================================
END
}
