package Perl::Critic::Policy::Freenode::ArrayAssignAref;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref';

our $VERSION = '0.027';

sub default_severity { $SEVERITY_MEDIUM }
sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::ArrayAssignAref - Don't assign an anonymous
arrayref to an array

=head1 DESCRIPTION

A common mistake is to assign values to an array but use arrayref brackets
C<[]> rather than parentheses C<()>. This results in the array containing one
element, an arrayref, which is usually unintended. If intended, the arrayref
brackets can be wrapped in parentheses for clarity.

 @array = [];          # not ok
 @array = [1, 2, 3];   # not ok
 @array = ([1, 2, 3]); # ok

This policy is a subclass of the L<Perl::Critic::Pulp> policy
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref>, and
performs the same function but in the C<freenode> theme.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Pulp>
