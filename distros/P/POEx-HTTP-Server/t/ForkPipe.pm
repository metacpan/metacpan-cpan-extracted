t::ForkPipe;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( pipe_to_fork pipe_from_fork );

# Code ganked from http://perldoc.perl.org/perlfork.html

# simulate open(FOO, "|-")
sub pipe_to_fork ($) {
    my $parent = shift;
    pipe my $child, $parent or die;
    my $pid = fork();
    return unless defined $pid;
    if ($pid) {
        close $child;
    }
    else {
        close $parent;
        open(STDIN, "<&=" . fileno($child)) or die;
    }
    return $pid;
}

# simulate open(FOO, "-|")
sub pipe_from_fork ($) {
    my $parent = shift;
    pipe $parent, my $child or die;
    my $pid = fork();
    return unless defined $pid;
    if ($pid) {
        close $child;
    }
    else {
        close $parent;
        open(STDOUT, ">&=" . fileno($child)) or die;
    }
    return $pid;
}