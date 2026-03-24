use v5.36.0;
package Sieve::Generator::Text::QstrList 0.001;
# ABSTRACT: a Sieve string list (a bracketed list of quoted strings)

use Moo;
with 'Sieve::Generator::Text';

#pod =head1 DESCRIPTION
#pod
#pod A C<QstrList> renders a list of Perl strings as a Sieve string list -- a
#pod comma-separated sequence of quoted strings enclosed in square brackets, as
#pod defined in RFC 5228 section 2.4.2.
#pod
#pod =attr strs
#pod
#pod This attribute holds the arrayref of strings to be encoded.
#pod
#pod =cut

has strs => (is => 'ro', init_arg => 'strs', required => 1);

sub as_sieve ($self, $i = undef) {
  state $JSON = JSON::MaybeXS->new->utf8(0)->allow_nonref;

  my $str = join q{, }, map {;
    defined || Carp::confess("can't encode undef"); # XXX
    $JSON->encode("$_")
  } $self->strs->@*;

  return (q{  } x ($i // 0)) . "[ $str ]";
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Text::QstrList - a Sieve string list (a bracketed list of quoted strings)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A C<QstrList> renders a list of Perl strings as a Sieve string list -- a
comma-separated sequence of quoted strings enclosed in square brackets, as
defined in RFC 5228 section 2.4.2.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 ATTRIBUTES

=head2 strs

This attribute holds the arrayref of strings to be encoded.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
