use v5.36.0;
package Sieve::Generator::Lines::Block 0.001;
# ABSTRACT: a Sieve block (a brace-delimited sequence of statements)

use Moo;
with 'Sieve::Generator::Lines';

#pod =head1 DESCRIPTION
#pod
#pod A block is the brace-delimited body of a Sieve C<if>, C<elsif>, or C<else>
#pod clause.  It contains an ordered list of things -- commands, nested
#pod conditionals, comments, or plain strings -- each rendered on its own indented
#pod line.
#pod
#pod =attr things
#pod
#pod This attribute holds the list of things that make up the block body.  Each
#pod may be an object doing either L<Sieve::Generator::Lines> or
#pod L<Sieve::Generator::Text>.
#pod
#pod =cut

has _things => (is => 'ro', init_arg => 'things', required => 1);
sub things ($self) { $self->_things->@* }

sub as_sieve ($self, $i = 0) {
  my $class = ref $self;

  my $str = q{};
  my $indent = q{  } x $i;
  for my $thing ($self->things) {
    my $text = ref $thing ? $thing->as_sieve($i+1)
             :              "$indent  $thing";

    $text .= "\n" unless $text =~ /\n\z/;

    $str .= $text;
  }

  return "{\n$str$indent}\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Lines::Block - a Sieve block (a brace-delimited sequence of statements)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A block is the brace-delimited body of a Sieve C<if>, C<elsif>, or C<else>
clause.  It contains an ordered list of things -- commands, nested
conditionals, comments, or plain strings -- each rendered on its own indented
line.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 things

This attribute holds the list of things that make up the block body.  Each
may be an object doing either L<Sieve::Generator::Lines> or
L<Sieve::Generator::Text>.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
