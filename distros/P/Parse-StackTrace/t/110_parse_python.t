#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 71;

use Support qw(test_trace);

use constant TRACES => {
    'bugbot' => {
        threads => 1,
        thread  => 1,
        frames  => 6,
        crash_frame => 0,
        description => 'Error: timed out',
        trace_lines => 13,
        stack => [qw(
            getUrlFd
            getUrl
            _getBugXml
            getAttachmentsOnBug
            _handleBugmailForChannel
            handleBugmail
        )],
    },
    # Frames split across lines
    'deskbar-bug-467629' => {
        threads => 1,
        thread  => 1,
        frames  => 2,
        crash_frame => 0,
        description => 'TypeError: could not parse URI',
        trace_lines => 7,
        stack => [qw(
            install
            on_drag_data_received_data
        )],
    },
    # SyntaxError
    'gnome-bug-582762' => {
        threads => 1,
        thread  => 1,
        frames  => 5,
        crash_frame => 0,
        description => 'SyntaxError: invalid syntax',
        trace_lines => 15,
        error_location => 5,
        stack => ['', qw(
            <module>
            <module>
            start_game
            <module>
        )],
    },
    # Django Format
    'gnome-bug-587214' => {
        threads => 1,
        thread  => 1,
        frames  => 3,
        crash_frame => 0,
        description => 'Exception Type: UnicodeEncodeError at',
        trace_lines => 11,
        stack => [qw(
            parseDoc
            note_detail
            get_response
        )],
    },
};

foreach my $file (sort keys %{ TRACES() }) {
    test_trace('Python', $file, TRACES->{$file});
}

# This is a file that has the "bugbot" trace and then another
# trace later down. This makes sure that we only parse the first trace.
test_trace('Python', 'bugbot-multiple', TRACES->{'bugbot'});

