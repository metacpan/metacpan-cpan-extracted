package Perl::Critic::Freenode;

use strict;
use warnings;

our $VERSION = 'v1.0.2';

1;

=head1 NAME

Perl::Critic::Freenode - Community-inspired Perl::Critic policies

=head1 SYNOPSIS

  $ perlcritic --theme freenode script.pl
  $ perlcritic --theme freenode lib/
  
  # .perlcriticrc
  theme = freenode
  severity = 1

=head1 DESCRIPTION

Legacy alias for the L<Perl::Critic::Community> policy set. Contains all of the
same policies but under the C<Freenode::> policy namespace and C<freenode>
theme.

=head1 AFFILIATION

This module has no functionality, but instead contains documentation for this
distribution and acts as a means of pulling other modules into a bundle. All of
the Policy modules contained herein will have an "AFFILIATION" section
announcing their participation in this grouping.

=head1 CONFIGURATION AND ENVIRONMENT

All policies included are in the "freenode" theme. See the L<Perl::Critic>
documentation for how to make use of this.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 CONTRIBUTORS

=over

=item Graham Knop (haarg)

=item H.Merijn Brand (Tux)

=item John SJ Anderson (genehack)

=item Matt S Trout (mst)

=item William Taylor (willt)

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Community>
