# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

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


# self:
# perlcritic -s ProhibitVerbatimMarkup ProhibitVerbatimMarkup.pm

package Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 99;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitVerbatimMarkup on: $elem->content

  my $parser = Perl::Critic::PodParser::ProhibitVerbatimMarkup->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::PodParser::ProhibitVerbatimMarkup;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  ### command: $command
  ### $text
  $self->SUPER::command(@_);  # maintain 'in_begin'

  if ($command eq 'for'
      && $text =~ /^ProhibitVerbatimMarkup\b\s*(.*)/) {
    my $directive = $1;
    ### $directive
    if ($directive =~ /^allow next( (\d+))?/) {
      # numbered "allow next 5" means up to that many following verbatims
      # unnumbered "allow next" means one following verbatim
      $self->{'allow_next'} = (defined $2 ? $2 : 1);
    }
  }
  return '';
}

sub verbatim {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### verbatim: $text

  if ($self->{'allow_next'}) {
    ### allow next: $self->{'allow_next'}
    $self->{'allow_next'}--;
    return '';
  }

  # process outside =begin, and inside =begin which is ":" markup
  unless ($self->{'in_begin'} eq '' || $self->{'in_begin'} =~ /^:/) {
    return '';
  }

  # I<> italic
  # B<> bold
  # C<> code
  # L<> link
  # E<> escape
  # F<> filename
  # S<> no break
  # X<> index
  # Z<> empty
  # J<> Pod::MultiLang
  #
  # DB<123> sample debugger output exempted
  #
  while ($text =~ /\bDB<\d+>|([IBCLEFSXZJ]<)/g) {
    next unless $1;
    my $markup = "$1>";

    $self->violation_at_linenum_and_textpos
      ("$markup markup in verbatim paragraph, is it meant to be so?",
       $linenum, $text, pos($text));
  }
  return '';
}

sub textblock {
  my ($self) = @_;
  $self->{'allow_next'} = 0;
  return '';
}

1;
__END__

=for stopwords Ryde fontification ascii unindented verbatimness ok unexpanded

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup - unexpanded CE<lt>E<gt> etc markup in POD verbatim paras

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It reports POD verbatim paragraphs which contain markup like
BE<lt>E<gt> or CE<lt>E<gt>.  That markup will appear literally in the
formatted output where you may have meant fontification.

=for ProhibitVerbatimMarkup allow next 3

    =head1 SOME THING

    Paragraph of text introducing an example,

        # call the C<foo> function      # bad
        &foo();

This is purely cosmetic so this policy is low severity and under the
"cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).  Normally it means one
of two things,

=over

=item *

You want markup -- it should be a plain paragraph not a verbatim indented
one.  An C<=over> can be used for indentation if desired.

=item *

You want verbatim -- replace the markup with an ascii approximation like
C<func()> or perhaps C<*bold*> or C<_underline_>.

=back

Don't forget that a verbatim paragraph extends to the next blank line and
includes unindented lines until then too (see L<perlpodspec/Pod
Definitions>).  If you forget the blank line then the verbatimness continues

=for ProhibitVerbatimMarkup allow next 2

    =pod

        $some->sample;
        code();
    And this was I<meant> to be plain text.    # bad

=head2 Markup Forms

The check for markup is unsophisticated.  Any of the POD specified "IE<lt>"
"CE<lt>" etc is taken to be markup, plus "JE<lt>" of C<Pod::MultiLang>.

=for ProhibitVerbatimMarkup allow next

    I<       # bad
    B<       # bad
    C<       # bad
    L<       # bad
    E<       # bad
    F<       # bad
    S<       # bad
    X<       # bad
    Z<       # bad
    J<       # bad, for Pod::MultiLang

It's possible a C<E<lt>> might be something mathematical like "XE<lt>Y", but
in practice spaces S<"X E<lt> Y"> or lower case letters are more common (and
are ok).

C<DBE<lt>1E<gt>> style sample Perl debugger output is exempted (see
L<perldebug>).  It's uncommon, but not likely to have intended
C<BE<lt>E<gt>> bold.

    DB<123> dump b        # ok

=head2 Disabling

If a verbatim paragraph is showing how to write POD markup then you can add
an C<=for> to tell C<ProhibitVerbatimMarkup> to allow it.  This happens most
often in documentation for modules which themselves operate on POD markup.

=for ProhibitVerbatimMarkup allow next 5

    =for ProhibitVerbatimMarkup allow next

        blah blah E<gt> etc

    =for ProhibitVerbatimMarkup allow next 2

        Two verbatims of C<code>

        or B<bold> etc

The usual no critic works too,

    ## no critic (ProhibitVerbatimMarkup)

But the annotation must be before any C<__END__> token, and if the POD is
after an C<__END__> token then C<Perl::Critic> 1.112 up is required.  An
C<=for> has the advantage of being together with the exception.

As always if you don't care at all about this at all then disable
C<ProhibitVerbatimMarkup> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitVerbatimMarkup]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup>,
L<Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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
