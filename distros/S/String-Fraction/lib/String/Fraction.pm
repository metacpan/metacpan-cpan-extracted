package String::Fraction;
use base qw(HTML::Fraction);

use strict;
use warnings;

our $VERSION = "0.30";

# Our superclass sometimes uses named
my %name2char = (
  '1/4'  => "\x{00BC}",
  '1/2'  => "\x{00BD}",
  '3/4'  => "\x{00BE}",
);

sub _name2char {
  my $self = shift;
  my $str = shift;

  my $entity = $self->SUPER::_name2char($str);
  if ($entity =~ /\A &\#(\d+); \z/x) {
    return chr($1);
  }

  return $name2char{ $str }
}

=head1 NAME

String::Fraction - convert fractions into unicode chars

=head1 SYNOPSIS

  use String::Fraction;
  print String::Fraction->tweak( <<ENDOFTEXT );
    When this is run through tweak things like 1/4 and 0.25 and 6.33
    will be converted to unicode chars that represent the fractional parts
  ENDOFTEXT

=head1 DESCRIPTION

This module functions identically to its superclass B<HTML::Fraction>,
but rather than converting fractions into HTML entities they are replaced
by the unicode characters for those fractions.

=head1 AUTHOR

Copyright Mark Fowler <mark@twoshortplanks.com> and Fotango 2005.

Copyright Mark Fowler <mark@twoshortplanks.com> 2012.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 BUGS 

None Known

=head1 SEE ALSO

L<HTML::Fraction>

=cut

1;