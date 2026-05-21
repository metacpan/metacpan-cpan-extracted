#!/usr/bin/env perl
use strict;
use warnings;

#use lib './lib';  # Uncomment to run from the repo root without installing
use Term::ReadLine::Repl;

# In-memory note storage for this session.
my @notes;

my $repl = Term::ReadLine::Repl->new({
    name        => 'notes',
    prompt      => '[%s]>',
    passthrough => 1,
    hist_file   => "$ENV{HOME}/.notes_repl_history",
    cmd_schema  => {

        # Add a note.  All words after 'add' become the note text.
        add => {
            exec => sub {
                my @words = @_;
                unless (@words) {
                    print "Usage: add <text>\n";
                    return;
                }
                push @notes, join(' ', @words);
                printf "Note %d saved.\n", scalar @notes;
            },
        },

        # List all saved notes with index numbers.
        list => {
            exec => sub {
                unless (@notes) {
                    print "No notes yet. Use 'add <text>' to create one.\n";
                    return;
                }
                printf "%2d. %s\n", $_ + 1, $notes[$_] for 0 .. $#notes;
            },
        },

        # Remove a note by its index number.
        remove => {
            exec => sub {
                my ($id) = @_;
                unless (defined $id && $id =~ /^\d+$/ && $id >= 1 && $id <= @notes) {
                    printf "Usage: remove <1-%d>\n", scalar @notes || 1;
                    return;
                }
                my $removed = splice(@notes, $id - 1, 1);
                print "Removed: $removed\n";
            },
            # Tab completion hints for the first argument position.
            args => [{ '1' => undef, '2' => undef, '3' => undef,
                       '4' => undef, '5' => undef }],
        },

    },
});

$repl->run();
