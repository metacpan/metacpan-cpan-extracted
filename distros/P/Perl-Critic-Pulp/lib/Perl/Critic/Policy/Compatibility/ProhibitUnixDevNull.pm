# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


package Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull;
use 5.006;
use strict;
use warnings;
use List::Util;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp;

our $VERSION = 97;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => qw(PPI::Token::Quote
                                        PPI::Token::QuoteLike::Words);

# See Perl_do_openn() for IsSPACE allowed leading, after mode and trailing.
# No layers in a two-arg open, only < > >> etc.
#
use constant _DEV_NULL_RE => qr{^\s*
                                (\+?(<|>>?)\s*)?
                                /dev/null
                                \s*$
                             }sxo;

my %equality_operators = (eq => 1, ne => 1);

sub violates {
  my ($self, $elem, $document) = @_;

  if ($elem->isa('PPI::Token::QuoteLike::Words')) {
    return unless List::Util::first {$_ eq '/dev/null'} $elem->literal;

  } else {  # PPI::Token::Quote
    my $str = $elem->string;
    return unless $str =~ _DEV_NULL_RE;

    # Allow ... eq 'dev/null' or 'dev/null' eq ...
    #
    # Could think about the filetest operators too.  -e '/dev/null' is
    # probably a portability check, but believe still better to have
    # File::Spec->devnull there.
    #
    foreach my $adj ($elem->sprevious_sibling, $elem->snext_sibling) {
      if ($adj
          && $adj->isa('PPI::Token::Operator')
          && $equality_operators{$adj}) {
        return;
      }
    }
  }

  return $self->violation
    ('For maximum portability use File::Spec->devnull instead of "/dev/null"',
     '',
     $elem);
}

1;
__END__

=for stopwords filename backticks Ryde

=head1 NAME

Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull - don't use explicit /dev/null

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It ask you to not to use filename

=over

F</dev/null>

=back

explicitly, but instead C<File::Spec-E<gt>devnull()> for maximum portability
across operating systems.

This policy is under the C<maintenance> theme (see
L<Perl::Critic/POLICY THEMES>) on the basis that even if you're on a Unix
system now you never know where your code might travel in the future.

C<devnull()> is new in C<File::Spec> version 0.8, so you should require that
version (it's included in Perl 5.6.0 and up).

The checks for F</dev/null> are unsophisticated.  A violation is reported
for any string C</dev/null>, possibly with an C<open> style mode part, and
any C<qw> containing C</dev/null>.

    open my $fh, '< /dev/null';                    # bad
    do_something ("/dev/null");                    # bad
    foreach my $file (qw(/dev/null /etc/passwd))   # bad

String comparisons are allowed because they're not uses of F</dev/null> as
such but likely some sort of cross-platform check.

    if ($f eq '/dev/null') { ... }                 # ok
    return ($f ne '>/dev/null');                   # ok

F</dev/null> as just part of a string is allowed, including things like
backticks and C<system>.

    print "Flames to /dev/null please\n"           # ok
    system ('rmdir /foo/bar >/dev/null 2>&1');     # ok
    $hi = `echo hi </dev/null`;                    # ok

Whether F</dev/null> is a good idea in such command strings depends what
sort of shell you reach with that command and how much of Unix it might
emulate on a non-Unix system.

=head2 Disabling

If you only ever use a system with F</dev/null> or if everything else you
write is hopelessly wedded to Unix anyway then you can disable
C<ProhibitUnixDevNull> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Compatibility::ProhibitUnixDevNull]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<File::Spec>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut
