package Perl::Critic::Policy::Freenode::StrictWarnings;

use strict;
use warnings;

use parent 'Perl::Critic::Policy::Community::StrictWarnings';

our $VERSION = 'v1.0.1';

sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::StrictWarnings - Always use strict and
warnings, or a module that imports these

=head1 DESCRIPTION

Legacy C<freenode> theme policy alias.

=head1 POLICY MOVED

This policy has been moved to the C<community> theme and renamed to
L<Perl::Critic::Policy::Community::StrictWarnings>.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy can be configured to recognize additional modules as importers of
L<strict> and L<warnings>, by putting an entry in a C<.perlcriticrc> file like
this:

  [Freenode::StrictWarnings]
  extra_importers = MyApp::Class MyApp::Role

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Community>
