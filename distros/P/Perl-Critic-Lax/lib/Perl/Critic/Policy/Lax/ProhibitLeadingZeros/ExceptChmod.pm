use strict;
use warnings;
package Perl::Critic::Policy::Lax::ProhibitLeadingZeros::ExceptChmod 0.014;
# ABSTRACT: leading zeroes are okay as the first arg to chmod

#pod =head1 DESCRIPTION
#pod
#pod This is subclass of
#pod L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros> with no
#pod changes.  It once allowed leading zeroes on numbers used as args to C<chmod>,
#pod but in 2008 the default Perl::Critic policy became to allow leading zeroes
#pod there and in a few other places.
#pod
#pod =cut

use Perl::Critic::Utils;
use parent qw(Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Lax::ProhibitLeadingZeros::ExceptChmod - leading zeroes are okay as the first arg to chmod

=head1 VERSION

version 0.014

=head1 DESCRIPTION

This is subclass of
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros> with no
changes.  It once allowed leading zeroes on numbers used as args to C<chmod>,
but in 2008 the default Perl::Critic policy became to allow leading zeroes
there and in a few other places.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes <cpan@semiotic.systems>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
