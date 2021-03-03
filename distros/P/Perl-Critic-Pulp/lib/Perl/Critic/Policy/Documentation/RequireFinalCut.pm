# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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


# perlcritic -s RequireFinalCut RequireFinalCut.pm
# perlcritic -s RequireFinalCut /usr/share/perl5/Class/InsideOut.pm
# perlcritic -s RequireFinalCut /usr/share/perl5/Lingua/Any/Numbers.pm


package Perl::Critic::Policy::Documentation::RequireFinalCut;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 99;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### RequireFinalCut on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::RequireFinalCut->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::RequireFinalCut;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  $self->parseopts(-process_cut_cmd => 1);
  return $self;
}

# Pod::Parser doesn't hold the current line number except in a local
# variable, so have to note it here for use in end_input().
#
sub begin_input {
  my $self = shift;
  $self->SUPER::begin_input(@_);
  $self->{'last_linenum'} = 0;
}
sub preprocess_line {
  my ($self, $line, $linenum) = @_;
  ### preprocess_line(): "linenum=$linenum"
  $self->{'last_linenum'} = $linenum;
  return $line;
}

sub end_input {
  my $self = shift;
  $self->SUPER::begin_input(@_);
  if ($self->{'in_pod'}
     && ! $self->{'saw_cut_in_text'}) {
    $self->violation_at_linenum_and_textpos
      ("POD doesn't end with =cut directive",
       $self->{'last_linenum'} + 1,  # end of file as the position
       '',
       0);
  }
}

sub command {
  my $self = shift;
  $self->SUPER::command(@_);
  my ($command, $text, $linenum, $paraobj) = @_;
  ### $command
  ### $text

  if ($command eq 'cut') {
    $self->{'in_pod'} = 0;

  } elsif ($command eq 'end' || $command eq 'for') {

  } elsif ($command eq 'pod') {
    $self->{'in_pod'} = 1;

  } else {
    unless ($self->{'in_begin'}) {
      $self->{'in_pod'} = 1;
    }
  }
  ### now in_pod: $self->{'in_pod'}

  $self->my_notice_cut($text);
  return '';
}

sub verbatim {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### verbatim ...

  # ignore entirely whitespace runs of blank lines
  return '' if $text =~ /^\s*$/;

  unless ($self->{'in_begin'}) {
    $self->{'in_pod'} = 1;
  }
  $self->my_notice_cut($text);
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock ...
  ### $text

  unless ($self->{'in_begin'}) {
    $self->{'in_pod'} = 1;
  }
  $self->my_notice_cut($text);
  return '';
}

sub my_notice_cut {
  my ($self, $text) = @_;
  $self->{'saw_cut_in_text'} = ($text =~ /\n=cut\b[^\n]*/);
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::RequireFinalCut - end POD with =cut directive

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to end POD with a C<=cut> directive at the end of a
file.

    =head1 DOCO

    Some text.

    =cut             # ok

The idea is to have a definite end indication for human readers.  Perl and
the POD processors don't require a final C<=cut>.  On that basis this policy
is lowest severity and under the "cosmetic" theme (see L<Perl::Critic/POLICY
THEMES>).

If there's no POD in the file then a C<=cut> is not required.  Or if the
file ends with code rather than POD then a C<=cut> after that code is not
required.

    =head2 About foo

    =cut

    sub foo {
    }              # ok, file ends with code not POD

If there's POD at end of file but consists only of C<=begin/=end> blocks
then a C<=cut> is not required.  It's reckoned the C<=end> is enough in this
case.

    =begin wikidoc

    Entire document in wiki style.

    =end wikidoc          # ok, =cut not required

If the file ends with a mixture of ordinary POD and C<=begin> blocks then a
is still required.  The special allowance is when only C<=begin> blocks,
presumably destined for some other markup system.

=head2 Blank Line

Generally a C<=cut> should have a blank line before it, the same as other
POD commands.  But Perl execution doesn't enforce that and the same
looseness is permitted here,

    =pod

    Blah blah blah
    =cut                  # ok without preceding newline

A check for blanks around POD commands is left to other policies.  The
C<podchecker> program reports this (L<Pod::Checker>).

=cut

# The POD parsers vary a little in their treatment of this sort of thing.
# C<Pod::Parser> takes it as part of the paragraph, C<Pod::Simple> takes it as
# a command but may issue warnings.  

=pod

=head2 Disabling

If you don't care about a final C<=cut> you can disable C<RequireFinalCut>
from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::RequireFinalCut]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

L<Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod>,
L<Perl::Critic::Policy::Documentation::RequirePodAtEnd>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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
