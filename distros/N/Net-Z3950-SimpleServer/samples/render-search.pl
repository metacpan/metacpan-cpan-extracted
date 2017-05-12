#!/usr/bin/perl -w

# $Header: /home/cvsroot/simpleserver/samples/render-search.pl,v 1.2 2002-03-05 12:03:26 mike Exp $
#
# Trivial example of programming using the "augmented classes"
# paradigm.  This tiny SimpleServer-based Z39.50 server logs Type-1
# searches in human-readable form.  It works by augmenting existing
# classes (the RPN-node types) with additional methods -- something
# that most OO languages would definitely not allow, but Perl does.
# And it's sort of cute.

use Net::Z3950::SimpleServer;
use strict;

my $handler = Net::Z3950::SimpleServer->new(SEARCH => \&search_handler,
					    FETCH => \&fetch_handler);
$handler->launch_server("render-search.pl", @ARGV);

sub search_handler {
    my($args) = @_;
    print "got search: ", $args->{RPN}->{query}->render(), "\n";
}

sub fetch_handler {} # no-op


package Net::Z3950::RPN::Term;
sub render {
    my $self = shift;
    return '"' . $self->{term} . '"';
}

package Net::Z3950::RPN::And;
sub render {
    my $self = shift;
    return '(' . $self->[0]->render() . ' AND ' .
                 $self->[1]->render() . ')';
}

package Net::Z3950::RPN::Or;
sub render {
    my $self = shift;
    return '(' . $self->[0]->render() . ' OR ' .
                 $self->[1]->render() . ')';
}

package Net::Z3950::RPN::AndNot;
sub render {
    my $self = shift;
    return '(' . $self->[0]->render() . ' ANDNOT ' .
                 $self->[1]->render() . ')';
}
