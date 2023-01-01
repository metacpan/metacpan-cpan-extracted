use strict;
use warnings;
package Perl::Critic::Lax 0.014;
# ABSTRACT: policies that let you slide on common exceptions

#pod =head1 DESCRIPTION
#pod
#pod The Perl-Critic-Lax distribution includes versions of core Perl::Critic modules
#pod with built-in exceptions.  If you really like a Perl::Critic policy, but find
#pod that you often violate it in a specific way that seems pretty darn reasonable,
#pod maybe there's a Lax policy.  If there isn't, send one in!
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Lax - policies that let you slide on common exceptions

=head1 VERSION

version 0.014

=head1 DESCRIPTION

The Perl-Critic-Lax distribution includes versions of core Perl::Critic modules
with built-in exceptions.  If you really like a Perl::Critic policy, but find
that you often violate it in a specific way that seems pretty darn reasonable,
maybe there's a Lax policy.  If there isn't, send one in!

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Andreas Schröter Ricardo SIGNES Signes

=over 4

=item *

Andreas Schröter <andreas.schroeter@autinity.de>

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes <cpan@semiotic.systems>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
