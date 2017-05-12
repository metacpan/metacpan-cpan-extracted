# Copyright 2013, 2014, 2015, 2016 Kevin Ryde

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


# perlcritic -s ProhibitMarkupExtraOpen ProhibitMarkupExtraOpen.pm
# perlcritic -s ProhibitMarkupExtraOpen /usr/share/perl5/IPC/Run.pm

# smiley close:
#  perlcritic -s ProhibitMarkupExtraOpen /usr/share/perl5/accessors.pm


package Perl::Critic::Policy::Documentation::ProhibitMarkupExtraOpen;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 93;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitMarkupExtraOpen on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitMarkupExtraOpen->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitMarkupExtraOpen;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  if ($command eq 'for'
      && $text =~ /^ProhibitMarkupExtraOpen\b\s*(.*)/) {
    my $directive = $1;
    ### $directive
    if ($directive =~ /^allow next( (\d+))?/) {
      # numbered "allow next 5" means up to that many following
      # unnumbered "allow next" means one following
      $self->{'allow_next'} = (defined $2 ? $2 : 1);
    }
  }
  return $self->command_as_textblock(@_);
}

sub textblock {
  my ($self, $text, $linenum, $pod_para) = @_;
  ### textblock: "linenum=$linenum"

  if (($self->{'allow_next'}||0) > 0) {
    $self->{'allow_next'}--;
    return '';
  }

  my $interpolated = $self->interpolate($text, $linenum);
  # foreach my $p (@opens) {
  # }
  return '';
}

sub interior_sequence {
  my ($self, $cmd, $text, $pod_seq) = @_;
  ### interior_sequence(): $cmd
  ### $text
  ### raw_text: $pod_seq->raw_text
  ### left_delimiter: $pod_seq->left_delimiter

  if ($pod_seq->left_delimiter eq '<' && $text =~ /^(<+)/) {
    my $angles = $1;
    my ($filename, $linenum) = $pod_seq->file_line;
    $self->violation_at_linenum
      ("Multi-angle markup without space $cmd<$angles",
       $linenum);
  }
  return '';
}

1;
__END__

=for stopwords Ryde paren parens ie deref there'd backslashing Parens

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitMarkupExtraOpen - don't write CE<lt>E<lt>abc...

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to write single-angle POD markup with extra "<" at
the start,

=for ProhibitVerbatimMarkup allow next

    C<<foo>        # bad

The formatters are perfectly happy with this.  They apply code markup to
"E<lt>foo".  But the idea of this policy is that it's likely to be a
mistaken double-angle markup, or at least will make a human reader wonder.
On that basis this policy is under the "bugs" theme (see
L<Perl::Critic/POLICY THEMES>) but low severity.

If a "<" like this is wanted then it can be escaped with C<EE<lt>ltE<gt>> to
pass this policy and make it clear "<" is intended and not a double-angle.

=for ProhibitVerbatimMarkup allow next

    C<E<lt>foo>    # ok

If doing this for a readline or glob form like C<E<lt>FHE<gt>> then escape
both angles.  The "<" for this policy, and the ">" must be escaped so it
doesn't prematurely close the markup,

    C<E<lt>FHE<gt>>       # ok, code markup of <FH>

It also works to put a C<ZE<lt>E<gt>> so that "<" is not the start.  Whether
this looks better or worse than C<E<lt>FHE<gt>> is another matter.

    C<Z<><--foo>          # ok, Z<>code markup of <FH>

=head2 Disabling

If you always want to write C<CE<lt>E<lt>foo...> unescaped then you can
disable C<ProhibitMarkupExtraOpen> completely from your F<.perlcriticrc> in
the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitMarkupExtraOpen]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2013, 2014, 2015, 2016 Kevin Ryde

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

C<<foo>>

B<< <foo> >>

=cut
