use v5.36.0;
package Sieve::Generator::Lines::Document 0.002;
# ABSTRACT: a sequence of Sieve lines forming a complete script or blank line

use Moo;
with 'Sieve::Generator::Lines';

#pod =head1 DESCRIPTION
#pod
#pod A document is an ordered sequence of things, and renders as a flat sequence of
#pod Sieve lines.  It serves as the top-level container for a complete Sieve script
#pod (when constructed by L<Sieve::Generator::Sugar/sieve>) or as an empty separator
#pod line (when constructed by L<Sieve::Generator::Sugar/blank>).
#pod
#pod =attr things
#pod
#pod This attribute holds the list of things that make up the document.  Each may
#pod be a string or an object doing L<Sieve::Generator::Lines> or
#pod L<Sieve::Generator::Text>.
#pod
#pod =cut

has _things => (is => 'ro', init_arg => 'things', required => 1);
sub things ($self) { $self->_things->@* }

#pod =method append
#pod
#pod   $doc->append(@things);
#pod
#pod This method adds the given C<@things> to the end of the document's list.
#pod
#pod =cut

sub append ($self, @things) {
  push $self->_things->@*, @things;
  return;
}

sub as_sieve ($self, $i = 0) {
  my $class = ref $self;

  my $str = q{};
  my $indent = q{  } x $i;
  for my $thing ($self->things) {
    my $text = ref $thing ? $thing->as_sieve($i)
             :              "$indent$thing";

    $text .= "\n" unless $text =~ /\n\z/;

    $str .= $text;
  }

  return $str;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Lines::Document - a sequence of Sieve lines forming a complete script or blank line

=head1 VERSION

version 0.002

=head1 DESCRIPTION

A document is an ordered sequence of things, and renders as a flat sequence of
Sieve lines.  It serves as the top-level container for a complete Sieve script
(when constructed by L<Sieve::Generator::Sugar/sieve>) or as an empty separator
line (when constructed by L<Sieve::Generator::Sugar/blank>).

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 things

This attribute holds the list of things that make up the document.  Each may
be a string or an object doing L<Sieve::Generator::Lines> or
L<Sieve::Generator::Text>.

=head1 METHODS

=head2 append

  $doc->append(@things);

This method adds the given C<@things> to the end of the document's list.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
