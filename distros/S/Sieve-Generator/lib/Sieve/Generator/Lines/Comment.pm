use v5.36.0;
package Sieve::Generator::Lines::Comment 0.002;
# ABSTRACT: a Sieve comment line

use Moo;
with 'Sieve::Generator::Lines';

#pod =head1 DESCRIPTION
#pod
#pod A comment renders as one or more C<#>-prefixed lines of Sieve code.  The
#pod number of hash characters is configurable.
#pod
#pod =attr content
#pod
#pod This attribute holds the content of the comment.  It may be a plain string
#pod or an object doing L<Sieve::Generator::Text>.
#pod
#pod =cut

has content => (is => 'ro', required => 1);

#pod =attr hashes
#pod
#pod This attribute controls how many C<#> characters prefix each comment line.
#pod It defaults to C<1>.
#pod
#pod =cut

has hashes  => (is => 'ro', default  => 1);

sub as_sieve ($self, $i = undef) {
  $i //= 0;
  my $sieve = ref $self->content
            ? $self->content->as_sieve(0)
            : $self->content;

  my $indent = q{  } x $i;
  my $hashes = q{#} x $self->hashes;
  $sieve =~ s/^/$indent$hashes /gm;

  return $sieve;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Lines::Comment - a Sieve comment line

=head1 VERSION

version 0.002

=head1 DESCRIPTION

A comment renders as one or more C<#>-prefixed lines of Sieve code.  The
number of hash characters is configurable.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 content

This attribute holds the content of the comment.  It may be a plain string
or an object doing L<Sieve::Generator::Text>.

=head2 hashes

This attribute controls how many C<#> characters prefix each comment line.
It defaults to C<1>.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
