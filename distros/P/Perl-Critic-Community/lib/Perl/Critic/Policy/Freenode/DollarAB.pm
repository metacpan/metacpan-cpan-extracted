package Perl::Critic::Policy::Freenode::DollarAB;

use strict;
use warnings;

use parent 'Perl::Critic::Policy::Community::DollarAB';

our $VERSION = 'v1.0.1';

sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::DollarAB - Don't use $a or $b as variable names
outside sort

=head1 DESCRIPTION

Legacy C<freenode> theme policy alias.

=head1 POLICY MOVED

This policy has been moved to the C<community> theme and renamed to
L<Perl::Critic::Policy::Community::DollarAB>.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy can be configured to allow C<$a> and C<$b> in additional functions,
by putting an entry in a C<.perlcriticrc> file like this:

  [Freenode::DollarAB]
  extra_pair_functions = pairfoo pairbar

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Community>
