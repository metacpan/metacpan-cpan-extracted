# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


package Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 97;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  my $parser = Perl::Critic::Pulp::PodParser::ProhibitBadAproposMarkup->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitBadAproposMarkup;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  ### command: $command
  ### $text
  $self->SUPER::command(@_);  # maintain 'in_begin'

  if ($command eq 'head1') {
    $self->{'in_NAME'} = ($text =~ /^NAME\s*$/ ? 1 : 0);
  }
  ### in_NAME now: $self->{'in_NAME'}
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock ...
  ### in_begin: $self->{'in_begin'}
  ### $text

  # Pod::Man accept_targets() are man, MAN, roff, ROFF.  Only those =begin
  # bits are put through to the man page and therefore only those are bad.
  unless ($self->{'in_begin'} eq '' || $self->{'in_begin'} =~ /^:(man|MAN|roff|ROFF)$/) {
    return '';
  }

  $self->interpolate ($text, $linenum);
  return '';
}

sub interior_sequence {
  my ($self, $command, $arg, $seq_obj) = @_;
  ### interior: $command
  ### $arg
  ### $seq_obj
  ### seq raw_text: $seq_obj->raw_text
  ### seq left_delimiter: $seq_obj->left_delimiter
  ### seq outer: do {my $outer=$seq_obj->nested; $outer&&$outer->cmd_name}

  if ($self->{'in_NAME'} && $command eq 'C') {
    my ($filename, $linenum) = $seq_obj->file_line;

    $self->violation_at_linenum
      ('C<> markup in NAME section is bad for "apropos".',
       $linenum);
  }
  return '';
}

1;
__END__

=for stopwords builtin Ryde nroff

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup - don't use CE<lt>E<gt> markup in a NAME section

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to write CE<lt>E<gt> markup in the NAME section of
the POD because it comes out badly in the man-db "apropos" database.  For
example,

=for ProhibitVerbatimMarkup allow next 2

    =head1 NAME

    foo - like the C<bar> program     # bad

C<pod2man> formats "CE<lt>E<gt>" using nroff macros which "man-db"'s
C<lexgrog> program doesn't expand, resulting in unattractive description
lines from C<apropos> like

    foo - like the *(C`bar*(C' program

=for ProhibitUnbalancedParens allow next

Man's actual formatted output is fine, and the desired text is in there,
just surrounded by C<*(C> bits.  On that basis this policy is low severity
and under the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

The NAME section is everything from C<=head1 NAME> to the next C<=head1>.
Other markup like "BE<lt>E<gt>", "IE<lt>E<gt>" and "FE<lt>E<gt>" is allowed
because C<pod2man> uses builtin C<\fB> etc directives for them, which
C<lexgrog> recognises.

C<=begin :man> and C<=begin :roff> blocks are checked since C<Pod::Man>
processes those.  Other C<=begin> blocks are ignored as they won't appear in
the roff output.

=head2 Disabling

If want markup in the NAME line, perhaps if printed output is more important
than C<apropos>, then you can always disable from your F<.perlcriticrc> in
the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitBadAproposMarkup]

Or in an individual file with the usual C<## no critic>

    ## no critic (ProhibitBadAproposMarkup)

though if the NAME part is after an C<__END__> token then C<Perl::Critic>
1.112 or higher is required (and the annotation must be before the
C<__END__>).

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Documentation::RequirePackageMatchesPodName>,
L<Perl::Critic::Policy::Documentation::RequirePodSections>,
L<Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup>

L<man(1)>, L<apropos(1)>, L<lexgrog(1)>

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
