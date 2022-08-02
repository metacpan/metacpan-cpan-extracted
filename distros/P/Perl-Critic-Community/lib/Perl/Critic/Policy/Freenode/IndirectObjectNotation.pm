package Perl::Critic::Policy::Freenode::IndirectObjectNotation;

use strict;
use warnings;

use parent 'Perl::Critic::Policy::Community::IndirectObjectNotation';

our $VERSION = 'v1.0.3';

sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::IndirectObjectNotation - Don't call methods
indirectly

=head1 DESCRIPTION

Legacy C<freenode> theme policy alias.

=head1 POLICY MOVED

This policy has been moved to L<Perl::Critic::Community>.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy can be configured, in the same way as its parent policy
L<Perl::Critic::Policy::Objects::ProhibitIndirectSyntax>, to attempt to forbid
additional method names from being called indirectly. Be aware this may lead to
false positives as it is difficult to detect indirect object notation by static
analysis. The C<new> subroutine is always forbidden in addition to these.

 [Freenode::IndirectObjectNotation]
 forbid = create destroy

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Community>
