#!/usr/bin/env perl

use strict;
use warnings;

sub main {
    my (@argv) = @_;
    my $cmd = shift @argv || 'version';

    if ($cmd eq 'version') {
        print "0.2.0\n";
        return 0;
    }

    print STDERR "unknown command: $cmd\n";
    return 2;
}

exit main(@ARGV) unless caller;

1;

=pod

=head1 NAME

t/fixtures/main_wrapped_app.pl - fixture for fixture where the main entrypoint is wrapped before execution

=head1 DESCRIPTION

This fixture exists to provide fixture where the main entrypoint is wrapped before execution. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
