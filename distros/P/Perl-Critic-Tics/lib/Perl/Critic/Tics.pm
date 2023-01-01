use strict;
use warnings;
package Perl::Critic::Tics 0.010;
# ABSTRACT: policies for things that make me wince

#pod =head1 DESCRIPTION
#pod
#pod The Perl-Critic-Tics distribution includes extra policies for Perl::Critic to
#pod address a fairly random assortment of things that make me (rjbs) wince.
#pod
#pod =head1 WHY TICS?
#pod
#pod Take your pick:
#pod
#pod =over
#pod
#pod =item B<T>hings B<I> B<C>an't B<S>tand
#pod
#pod =item They set off my nervous tic.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Perl::Critic>, the driving force behind it all.  L<Perl::Critic::Lax>, the
#pod other half of things I don't like: things I don't like about core Perl::Critic
#pod rules.
#pod
#pod Other people have released their own tics:
#pod
#pod =for :list
#pod * L<Perl::Critic::Bangs>
#pod * L<Perl::Critic::Itch>
#pod * L<Perl::Critic::Pulp>
#pod * L<Perl::Critic::Swift>
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Tics - policies for things that make me wince

=head1 VERSION

version 0.010

=head1 DESCRIPTION

The Perl-Critic-Tics distribution includes extra policies for Perl::Critic to
address a fairly random assortment of things that make me (rjbs) wince.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 WHY TICS?

Take your pick:

=over

=item B<T>hings B<I> B<C>an't B<S>tand

=item They set off my nervous tic.

=back

=head1 SEE ALSO

L<Perl::Critic>, the driving force behind it all.  L<Perl::Critic::Lax>, the
other half of things I don't like: things I don't like about core Perl::Critic
rules.

Other people have released their own tics:

=over 4

=item *

L<Perl::Critic::Bangs>

=item *

L<Perl::Critic::Itch>

=item *

L<Perl::Critic::Pulp>

=item *

L<Perl::Critic::Swift>

=back

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Kent Fredric Ricardo SIGNES Signes

=over 4

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
