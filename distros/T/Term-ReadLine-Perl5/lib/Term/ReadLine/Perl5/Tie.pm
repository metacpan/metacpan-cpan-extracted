use strict; use warnings;
use version;

=head1 NAME

Term::ReadLine::Perl5::Tie

=head1 DESCRIPTION

Used by L<Term::ReadLine::Perl> to bind
I<%Term::ReadLine::Perl5::attribs> to their corresponding
I<%Term::ReadLine::readline> value in reading and setting those
attributes.

=head1 SEE ALSO

L<Term::ReadLine::Perl5>

=cut
package Term::ReadLine::Perl5::Tie;

# version might not be below other places in this routine
# no critic
our $VERSION = '1.43';

sub TIEHASH { bless {} }

sub STORE {
  my ($self, $name) = (shift, shift);
  no strict;
  no warnings 'once';
  $ {'Term::ReadLine::Perl5::readline::rl_' . $name} = shift;
}

sub FETCH {
  my ($self, $name) = (shift, shift);
  no strict;
  $ {'Term::ReadLine::Perl5::readline::rl_' . $name};
}

1;
