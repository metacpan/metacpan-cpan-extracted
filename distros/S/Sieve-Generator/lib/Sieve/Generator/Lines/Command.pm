use v5.36.0;
package Sieve::Generator::Lines::Command 0.001;
# ABSTRACT: a single Sieve command statement

use Moo;
with 'Sieve::Generator::Lines';

use Params::Util qw(_ARRAY0);

#pod =head1 DESCRIPTION
#pod
#pod A command is a single semicolon-terminated Sieve statement, such as C<stop;>,
#pod C<keep;>, or C<fileinto "Spam";>.  It consists of an identifier followed by
#pod zero or more arguments.
#pod
#pod =attr identifier
#pod
#pod This attribute holds the name of the Sieve command, such as C<stop>,
#pod C<fileinto>, or C<require>.
#pod
#pod =cut

has identifier  => (is => 'ro', required => 1);

#pod =attr args
#pod
#pod This attribute holds the list of arguments to the command.  Each argument may
#pod be a plain string or an object doing L<Sieve::Generator::Text>.
#pod
#pod =cut

has _args => (is => 'ro', required => 1, init_arg => 'args');
sub args { $_[0]->_args->@* }

sub as_sieve ($self, $i = undef) {
  my $indent = q{  } x ($i // 0);

  my $str = $indent . $self->identifier;
  my $n = 0;

  $str .= ' ' . (ref $_ ? $_->as_sieve(0) : $_) for $self->args;
  $str .= ";\n";

  return $str;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Lines::Command - a single Sieve command statement

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A command is a single semicolon-terminated Sieve statement, such as C<stop;>,
C<keep;>, or C<fileinto "Spam";>.  It consists of an identifier followed by
zero or more arguments.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 identifier

This attribute holds the name of the Sieve command, such as C<stop>,
C<fileinto>, or C<require>.

=head2 args

This attribute holds the list of arguments to the command.  Each argument may
be a plain string or an object doing L<Sieve::Generator::Text>.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
