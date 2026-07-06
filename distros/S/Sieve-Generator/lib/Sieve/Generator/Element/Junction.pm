use v5.36.0;
package Sieve::Generator::Element::Junction 0.003;
# ABSTRACT: a Sieve allof/anyof/noneof test

use Moo;
with 'Sieve::Generator::Element';

#pod =head1 DESCRIPTION
#pod
#pod A junction renders a Sieve multi-test expression: C<allof(...)>,
#pod C<anyof(...)>, or C<not anyof(...)> (for C<noneof>).  Each contained test is
#pod rendered on its own indented line.
#pod
#pod =attr type
#pod
#pod This attribute holds the junction type.  It must be one of C<allof>,
#pod C<anyof>, or C<noneof>.
#pod
#pod =cut

#pod =attr things
#pod
#pod This attribute holds the list of tests in the junction.  Each may be a plain
#pod string or an object doing L<Sieve::Generator::Element>.
#pod
#pod =cut

has type => (is => 'ro', required => 1);

has _things => (is => 'ro', init_arg => 'things', required => 1);
sub things ($self) { $self->_things->@* }
sub children ($self) { $self->things }

sub as_sieve ($self, $i = undef) {
  $i //= 0;
  my $indent = q{  } x $i;

  my $type  = $self->type;
  my $func  = $type eq 'anyof'  ? 'anyof'
            : $type eq 'allof'  ? 'allof'
            : $type eq 'noneof' ? 'not anyof'
            : die "unknown junction type";

  my $str = "${indent}$func(\n";

  my @strs;
  for my $thing ($self->things) {
    my $substr = $thing->as_sieve($i+1);
    push @strs, $substr;
  }

  $str .= join qq{,\n}, @strs;
  $str .= "\n${indent})";

  return $str;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Element::Junction - a Sieve allof/anyof/noneof test

=head1 VERSION

version 0.003

=head1 DESCRIPTION

A junction renders a Sieve multi-test expression: C<allof(...)>,
C<anyof(...)>, or C<not anyof(...)> (for C<noneof>).  Each contained test is
rendered on its own indented line.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 type

This attribute holds the junction type.  It must be one of C<allof>,
C<anyof>, or C<noneof>.

=head2 things

This attribute holds the list of tests in the junction.  Each may be a plain
string or an object doing L<Sieve::Generator::Element>.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
