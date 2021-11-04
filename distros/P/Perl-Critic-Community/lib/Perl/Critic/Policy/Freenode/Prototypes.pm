package Perl::Critic::Policy::Freenode::Prototypes;

use strict;
use warnings;

use parent 'Perl::Critic::Policy::Community::Prototypes';

our $VERSION = 'v1.0.1';

sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::Prototypes - Don't use function prototypes

=head1 DESCRIPTION

Legacy C<freenode> theme policy alias.

=head1 POLICY MOVED

This policy has been moved to the C<community> theme and renamed to
L<Perl::Critic::Policy::Community::Prototypes>.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy can be configured to recognize additional modules as enabling the
C<signatures> feature, by putting an entry in a C<.perlcriticrc> file like
this:

  [Freenode::Prototypes]
  signature_enablers = MyApp::Base

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Community>
