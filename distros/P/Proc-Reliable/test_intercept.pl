#!/usr/bin/perl

=head1 test User Intercept Methods

This performs very minimal testing and was written to test
some minor changes I made to Proc::Reliable so that STDERR
was properly routed to user methods AND any left over strings
were passed (those not terminated by an ending newline).

Written by Robb Canfield <robb at canfield dot com>

Date 2003-11-21

=end

=cut


use lib qw/../;

use Proc::Reliable;
use Test::More qw/no_plan/;
use strict;

# test that capturing works for STDERR and STDOUT
{
    my $proc = Proc::Reliable->new();

    my $buffer_out;
    my $buffer_err;

    # Default for single line is TRUE which routes ALL data to STDOUT leaving STDERR empty
    # Change to FALSE so I can test each separate stream.
    # 
    #   I feel that internally Proc::Reliable should keep three buffers and return
    #   the proper ones as requested. But that would make it backward incompatible.
    #       - STDERR
    #       - STDOUT
    #       - mingled as they occurred
    #
    # Of course it would be easy enough to create a module based on Proc::Reliable  that
    # did exactly that!
    $proc->want_single_list(0);

    # Not very efficeient but makes tests easier.
    #   - $_[0] is the type as a string 'STDERR', 'STDOUT' this is NOT documented and I do not need it.
    $proc->stdout_cb(sub {shift; $buffer_out .= join('', @_);});
    $proc->stderr_cb(sub {shift; $buffer_err .= join('', @_);});

    $proc->run(sub {
        print        "STDOUT Output\n";
        print STDERR "STDERR Output\n";
        print        "STDOUT Output: No Newline";
        print STDERR "STDERR Output: No Newline";
    });

    # Make sure each buffer is separate
    ok(
        $buffer_err =~ /STDERR Output\n/ && $buffer_err !~ /^STDOUT Output/,
        "STDERR captured"
    ) or die("Unexpected output: $buffer_err");

    ok(
        $buffer_out =~ /STDOUT Output\n/ && $buffer_out !~ /^STDERR Output/,
        "STDOUT captured"
    ) or die("Unexpected output: $buffer_out");

    # make sure ending data is in buffers
    ok(
        $buffer_err =~ /STDERR.*No Newline$/s,
        "STDOUT captured data without a newline"
    ) or die("Unexpected output: $buffer_err");

    ok(
        $buffer_out =~ /STDOUT.*No Newline$/,
        "STDOUT captured data without a newline"
    ) or die("Unexpected output: $buffer_out");
}


