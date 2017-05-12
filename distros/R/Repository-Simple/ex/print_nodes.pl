#!/usr/bin/perl
#
# This is the code in the synopsis of Repository::Simple::Node.
#
# Run:
#
#   perldoc print_nodes.pl
#
# for documentation.

use strict;
use warnings;

use Repository::Simple;

sub print_node;

my $repository = Repository::Simple->attach(
    FileSystem => root => $ARGV[0],
);

my $node = $repository->root_node;
print_node($node, 0);

sub print_node {
    my ($node, $depth) = @_;

    print "\t" x $depth, " * ", $node->name, "\n";

    for my $p ($node->properties) {
        print "\t" x $depth, "\t * ", 
            $p->name, " = ", $p->value->get_scalar, "\n";
    }

    for my $child ($node->nodes) {
        print_node($child, $depth + 1);
    }
}

__END__

=head1 NAME

print_nodes.pl - Example showing how to print nodes/properties

=head1 SYNOPSIS

  print_nodes.pl t/root

=head1 DESCRIPTION

This will print every node and property using the FileSystem storage engine using the given path as the root.

B<DO NOT> run this on anything with binary files or big files as this prints the contents of every file too!

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
