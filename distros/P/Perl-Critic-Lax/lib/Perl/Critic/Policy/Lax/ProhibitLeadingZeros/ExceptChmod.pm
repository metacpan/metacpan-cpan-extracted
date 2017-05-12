use strict;
use warnings;
package Perl::Critic::Policy::Lax::ProhibitLeadingZeros::ExceptChmod;
# ABSTRACT: leading zeroes are okay as the first arg to chmod
$Perl::Critic::Policy::Lax::ProhibitLeadingZeros::ExceptChmod::VERSION = '0.013';
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

version 0.013

=head1 DESCRIPTION

This is subclass of
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros> with no
changes.  It once allowed leading zeroes on numbers used as args to C<chmod>,
but in 2008 the default Perl::Critic policy became to allow leading zeroes
there and in a few other places.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo Signes <rjbs@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
