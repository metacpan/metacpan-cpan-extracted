use v5.36.0;
package Sieve::Generator::Lines 0.002;
# ABSTRACT: role for objects that render as lines of Sieve code

use Moo::Role;

#pod =head1 DESCRIPTION
#pod
#pod This role is consumed by all objects that render as one or more complete lines
#pod of Sieve code.  It requires a single method, C<as_sieve>.
#pod
#pod This role isn't really meant to be used directly, and should be considered an
#pod implementation detail that may go away.
#pod
#pod =method as_sieve
#pod
#pod   my $sieve_text = $lines_obj->as_sieve;
#pod   my $sieve_text = $lines_obj->as_sieve($indent_level);
#pod
#pod This method renders the object as a string of Sieve code.  The optional
#pod C<$indent_level> argument is a non-negative integer controlling the
#pod indentation depth; each level adds two spaces.  If not given, no indenting is
#pod added.
#pod
#pod =cut

requires 'as_sieve';

no Moo::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Lines - role for objects that render as lines of Sieve code

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This role is consumed by all objects that render as one or more complete lines
of Sieve code.  It requires a single method, C<as_sieve>.

This role isn't really meant to be used directly, and should be considered an
implementation detail that may go away.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 METHODS

=head2 as_sieve

  my $sieve_text = $lines_obj->as_sieve;
  my $sieve_text = $lines_obj->as_sieve($indent_level);

This method renders the object as a string of Sieve code.  The optional
C<$indent_level> argument is a non-negative integer controlling the
indentation depth; each level adds two spaces.  If not given, no indenting is
added.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
