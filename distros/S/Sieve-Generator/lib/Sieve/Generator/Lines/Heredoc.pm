use v5.36.0;
package Sieve::Generator::Lines::Heredoc 0.001;
# ABSTRACT: a Sieve multiline string (heredoc)

use Moo;
with 'Sieve::Generator::Lines';

#pod =head1 DESCRIPTION
#pod
#pod A heredoc renders a block of text as a Sieve multiline string using the
#pod C<text:>/C<.> syntax defined in RFC 5228.  It is typically used as an
#pod argument to a command when the content is too large or complex for a simple
#pod quoted string.
#pod
#pod =attr text
#pod
#pod This attribute holds the text content of the multiline string.  A trailing
#pod newline is added automatically if absent, and any line beginning with C<.>
#pod is escaped to C<..>.
#pod
#pod =cut

has text => (is => 'ro', required => 1);

sub as_sieve ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);
  my $str = "${indent}text:\n" . $self->text;
  $str .= "\n" unless $str =~ /\n\z/;
  $str =~ s/^\./../mg;
  return "$str.\n";
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Lines::Heredoc - a Sieve multiline string (heredoc)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A heredoc renders a block of text as a Sieve multiline string using the
C<text:>/C<.> syntax defined in RFC 5228.  It is typically used as an
argument to a command when the content is too large or complex for a simple
quoted string.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 text

This attribute holds the text content of the multiline string.  A trailing
newline is added automatically if absent, and any line beginning with C<.>
is escaped to C<..>.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
