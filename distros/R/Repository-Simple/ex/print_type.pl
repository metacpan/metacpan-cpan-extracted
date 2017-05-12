#!/usr/bin/perl
#
# This is the code in the synopsis of Repository::Simple::Type::Node.
#
# Run:
#
#   perldoc print_types.pl
#
# for documentation.

use strict;
use warnings;

use Repository::Simple;

sub print_node_type;

my $repository = Repository::Simple->attach(
    FileSystem => root => $ARGV[0],
);

my $node = $repository->get_item($ARGV[1]);
print_node_type($node);

sub print_node_type {
    my $node = shift;

    my $type = $node->type;

    print $node->name, ' : ', $type->name;
    print ' [AC]' if $type->auto_created;
    print ' [UP]' if $type->updatable;
    print ' [RM]' if $type->removable;
    print "\n";

    my %property_types = $type->property_types;
    while (my ($name, $ptype_name) = each %property_types) {
        my $ptype = $node->repository->property_type($ptype_name);

        printf ' * %-10s : %-16s', $name, $ptype->name;

        print ' [AC]' if $ptype->auto_created;
        print ' [UP]' if $ptype->updatable;
        print ' [RM]' if $ptype->removable;
        print "\n";
    }
}

__END__

=head1 NAME

print_type.pl - Repository example showing some type information

=head1 SYNOPSIS

  ./print_type.pl t/root /bar/baz

=head1 DESCRIPTION

A demo showing how to print out some of the type information associated with a node.

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
