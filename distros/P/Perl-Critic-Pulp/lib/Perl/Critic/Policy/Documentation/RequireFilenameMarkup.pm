# Copyright 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# perlcritic -s RequireFilenameMarkup RequireFilenameMarkup.pm

# unmarked /usr/local
# perlcritic -s RequireFilenameMarkup /usr/share/perl5/XML/Twig.pm


package Perl::Critic::Policy::Documentation::RequireFilenameMarkup;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Pod::Escapes;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 95;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### RequireFilenameMarkup on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::RequireFilenameMarkup->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::RequireFilenameMarkup;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  $self->SUPER::command(@_);  # for $self->{'in_begin'}
  $self->command_as_textblock(@_);
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $pod_para) = @_;
  ### textblock: "linenum=$linenum"

  if (($self->{'allow_next'}||0) > 0) {
    $self->{'allow_next'}--;
    return '';
  }

  # process outside =begin, and inside =begin which is ":" markup
  unless ($self->{'in_begin'} eq '' || $self->{'in_begin'} =~ /^:/) {
    return '';
  }

  my $interpolated = $self->interpolate($text, $linenum);
  ### $text
  ### $interpolated

  while ($interpolated =~ m{(^ | (?<=[\([:space:]]))  # BOL or preceding space
                            (
                              /(bin|etc|dev|opt|proc|tmp|usr|var)
                              ($                 # EOL
                              |(?=[)[:space:]])  # or following space
                              |/\S*)             # or /chars
                            |
                              [cC]:\\\S*
                            )
                         }mgx) {
    my $before = $1;
    my $match = $2;
    $match =~ s/[.,;:]+$//;
    my $pos = pos($interpolated) - length($match);

    $self->violation_at_linenum_and_textpos
      ("Filename without F<> or other markup \"$match\"\n",
       $linenum, $interpolated, $pos);
  }
}

sub interior_sequence {
  my ($self, $cmd, $text, $pod_seq) = @_;
  ### $cmd
  ### $text

  if ($cmd eq 'E') {
    my $char = Pod::Escapes::e2char($text);
    if (! defined $char) {
      ### oops, unrecognised E<> ...
      return 'X';
    }
    return $char;
  }
  if ($cmd eq 'L') {
    my ($display, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($text);
    ### $display
    ### $inferred
    ### $name
    return $inferred;  # the display part, or the name part if no display
  }

  ### X,C keep only the newlines: $text
  $text =~ tr/\n//cd;
  return $text;
}

1;
__END__

=for stopwords Ryde filenames filename Filenames

=head1 NAME

Perl::Critic::Policy::Documentation::RequireFilenameMarkup - markup /foo filenames

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to use C<FE<lt>E<gt>> or other markup on filenames.

=for ProhibitVerbatimMarkup allow next 2

    /usr/bin       # bad

    F</usr/bin>    # ok
    C</bin/sh>     # ok

C<FE<lt>E<gt>> lets the formatters show filenames in a usual way, such as
italics in man pages.  This can help human readability but is a minor matter
and on that basis this policy is lowest severity and under the "cosmetic"
theme (see L<Perl::Critic/POLICY THEMES>).

Filenames in text are identified by likely forms.  Currently words starting
as follows are considered filenames.  F</usr> and F</etc> are the most
common.

    /bin
    /dev      
    /etc
    /opt         # some proprietary Unix
    /proc
    /tmp
    /usr
    /var
    C:\          # MS-DOS

Any markup on a filename satisfies this policy.  C<FE<lt>E<gt>> is usual,
but C<CE<lt>E<gt>> might suit for instance C<CE<lt>/bin/shE<gt>> to show
it's a command with path rather than a file as such.

C<=begin :foo> blocks with <:> POD type are checked since they can have
markup.  "Verbatim" paragraphs are ignored since of course they cannot have
markup.

=head2 Disabling

If you don't care about filename markup you can disable
C<RequireFilenameMarkup> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::RequireFilenameMarkup]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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

# /usr/local
# /opt.
# /tmp
# /dev/null
# /dev/
# /dev.
# blah/option
# 
# /option
# 
# blah/blah/etc
# 
# E<sol>dev
