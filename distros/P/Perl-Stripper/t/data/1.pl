#!/usr/bin/perl

use Log::Any qw($log);
use Log::ger;
use vars qw($global $global3);

# line comment
#
# second line

our $our = 1;
my $lexical = 2;
$global = 3;

sub foo { # inline comment
    my $lexical = 4;
    local $global;
    $global2 = 5;
    print "variables inside double quote: $lexical $global
    ";
    $log->info("Will not be stripped %s", $global);
    log_info("Will not be stripped");
    $log -> debugf("Will be stripped %s", $lexical);
    log_debug("Will be stripped");
    $log->trace("Will
be
stripped");
    if ($log->is_trace) {
        # this code will be removed under strip_log
        my $foo;
        $foo = 1;
        $log->warn("blah ...");
    }
    if (log_is_trace()) {
        # this code will be removed under strip_log
        my $bar;
    }
}

=head1 SYNOPSIS

 foo - bar

=head1 DESCRIPTION

blah...

=cut
