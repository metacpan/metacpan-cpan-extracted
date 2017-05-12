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


# perlcritic -s ProhibitDuplicateHeadings ProhibitDuplicateHeadings.pm
#
# duplicate BUGS
# perlcritic -s ProhibitDuplicateHeadings /usr/share/perl5/Acme/Tie/Eleet.pm

# duplicate toplevel CLASS METHODS
# perlcritic -s ProhibitDuplicateHeadings /usr/share/perl5/Games/Euchre/Trick.pm

# duplicate =head2 serialise
# perlcritic -s ProhibitDuplicateHeadings /usr/share/perl5/SVG/Extension.pm


package Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 93;

use constant supported_parameters =>
  ({ name           => 'uniqueness',
     description    => 'The scope for headings names, meaning to what extent they must not be duplicates.  Choices nested, all.',
     behavior       => 'string',
     default_string => 'default',
     parser         => \&_parse_uniqueness,
   });
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitDuplicateHeadings ...
  ### _uniqueness: $self->{'_uniqueness'}
  # ### content: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitDuplicateHeadings->new
    (policy     => $self);
  $parser->parse_from_elem ($elem);

  ### violations return: [ $parser->violations ]
  return $parser->violations;
}

my %known_uniqueness = (''       => 1, # for trailing comma
                        all      => 1,
                        ancestor => 1,
                        sibling  => 1,
                        adjacent => 1,
                        default  => 1,
                       );
my %uniqueness_expand = (default => [ 'ancestor', 'sibling', 'adjacent' ],
                        );
sub _parse_uniqueness {
  my ($self, $parameter, $str) = @_;
  ### _parse_uniqueness ...
  ### $parameter
  ### $str

  if (! defined $str) {
    $str = $parameter->get_default_string;
    ### default: $str
  }

  my %uhash;
  foreach my $key (split /,/, $str) {
    $key =~ s/^\s+//;
    $key =~ s/\s+$//;
    if (! $known_uniqueness{$key}) {
      $self->throw_parameter_value_exception
        ($parameter->get_name,
         $str,
         undef, # source
         'unrecognised uniqueness');
    }
    if (my $aref = $uniqueness_expand{$key}) {
      foreach my $key (@$aref) {
        $uhash{$key} = 1;
      }
    } else {
      $uhash{$key} = 1;
    }
  }

  ### %uhash
  $self->__set_parameter_value ($parameter, \%uhash);
}

#------------------------------------------------------------------------------
package Perl::Critic::Pulp::PodParser::ProhibitDuplicateHeadings;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  ### $command

  if ($command =~ /^head(\d*)$/) {
    my $level = $1 || 0;
    $text =~ s/^\s+//;  # leading whitespace
    $text =~ s/\s+$//;  # trailing whitespace
    $text =~ s/\s+/ /;  # collapse whitespace to single space each
    ### $text
    ### $level

    my $uniqueness = $self->{'policy'}->{'_uniqueness'};
    my $seen_linenum;
    my $seen_type;

    if ($uniqueness->{'all'}) {
      unless (defined $seen_linenum) {
        $seen_linenum = $self->{'seen_all'}->{$text};
        $seen_type = ' ';
      }

      $self->{'seen_all'}->{$text} = $linenum;
    }

    if ($uniqueness->{'adjacent'}) {
      unless (defined $seen_linenum) {
        if (defined $self->{'seen_adjacent'}
            && $text eq $self->{'seen_adjacent'}) {
          $seen_linenum = $self->{'seen_adjacent_linenum'};
          $seen_type = ' adjacent ';
        }
      }
      $self->{'seen_adjacent'} = $text;
      $self->{'seen_adjacent_linenum'} = $linenum;
    }

    if ($uniqueness->{'sibling'}) {
      ### seen_sibling: $self->{'seen_sibling'}
      unless (defined $seen_linenum) {
        $seen_linenum = $self->{'seen_sibling'}->{$level}->{$text};
        $seen_type = ' sibling ';
      }

      # discard anything > $level
      foreach my $l (keys %{$self->{'seen_sibling'}}) {
        if ($l > $level) {
          delete $self->{'seen_sibling'}->{$l};
        }
      }
      $self->{'seen_sibling'}->{$level}->{$text} = $linenum;
    }

    if ($uniqueness->{'ancestor'}) {
      foreach my $l (sort {$a<=>$b}  # biggest to smallest
                     keys %{$self->{'seen_ancestor'}}) {
        if ($l < $level) {
          if ($text eq $self->{'seen_ancestor'}->{$l}) {
            unless (defined $seen_linenum) {
              $seen_linenum = $self->{'seen_ancestor_linenum'}->{$l};
              $seen_type = ' ancestor ';
            }
          }
        } else {
          delete $self->{'seen_ancestor'}->{$l};
        }
      }
      $self->{'seen_ancestor'}->{$level} = $text;
      $self->{'seen_ancestor_linenum'}->{$level} = $linenum;
    }

    ### $seen_linenum
    ### $seen_type
    if (defined $seen_linenum) {
      $self->violation_at_linenum
        ("Duplicate$seen_type=head \"$text\", previously seen at line $seen_linenum",
         $linenum);
      ### violation at line: $linenum
    }
  }
  return '';
}

1;
__END__


#  within a
# nested tree scope.  This is designed to be how  A subheading can be repeated if under a
# different containing heading.
# 
# Headings are thought of as a tree and a given heading must not duplicate a
# sibling or an ancestor.
# 
#    head1 head2 head3    no duplicate
#    ----- ----- -----    ------------
# 
#      A--+--B            A,J        head1 siblings
#         |         
#         +--C--+--D      B,C,F,I,A  head2 siblings and parent
#         |     |
#         |     +--E      D,E,A,C    head3 siblings and ancestors
#         |         
#         +--F--+--G      G,H,A,F    head3 siblings and ancestors
#         |     |   
#         |     +--H
#         |
#         +--I
# 
#      J--+--K            K,L,M,J    head2 siblings and parent
#         |
#         +--L
#         |
#         +--M
# 
# "B" must be unique to its siblings C,F,I and its parent A.
# 
# "D" must be unique to its sibling E and its ancestors A,C.  But "D" doesn't
# have to be unique to F,G,H since F is not a direct ancestor and G,H are not
# siblings but cousins under the different branch F.
# 
# This rule suits a construction like "A+C+D" to make a path to identify a
# point in the document (with some suitable separator between the parts).


=for stopwords Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings - don't duplicate =head names

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to duplicate heading names in C<=head> POD
commands.

    =head1 SOMETHING

    =head1 SOMETHING      # bad, duplicate

Duplication is usually a mistake, perhaps too much cut-and-paste, or a
leftover from a template, or perhaps text in two places which ought to be
together.  On that basis this policy is medium severity and under the "bugs"
theme (see L<Perl::Critic/POLICY THEMES>).

=head2 Default Uniqueness

The policy default is to demand that a given heading is unique to its
ancestors, siblings, and to the immediately adjacent heading irrespective of
level.  This is designed to be how human readers perceive the scope of
headings and subheadings, plus adjacency in case a mixture of heading levels
would let a duplicate otherwise go undetected.  For example

    =head1 Top

    =head2 Subhead

    =head3 Top              # bad, duplicates its ancestor head1

Or siblings

    =head1 Top

    =head2 Down

    =head2 Another

    =head2 Down             # bad, duplicates sibling head2

Or adjacent

    =head2 Blah

    =head1 Blah             # bad, duplicates adjacent

A subheading can be repeated if it's under a different higher heading.  For
example the following two "Details" are cousins, so allowed.

    =head1 One

    =head2 Details

    =head1 Two

    =head2 Details          # ok

=head2 All Unique

Option C<uniqueness=all> (see L</CONFIGURATION> below) applies a stricter
rule so that all C<=head> names must be unique throughout the document,
irrespective of levels and structure.

    =head3 Foo

    =head1 Bar

    =head3 Foo             # bad

One use for this is to ensure all headings can be reached by an
C<LE<lt>E<gt>> link.  An C<LE<lt>E<gt>> only has the heading name, no level
or path, so if there's any duplication among the names then only the first
of each duplicate will be reachable.  (The POD browsers usually go to the
first among duplicates.)

This rule is often too strict.  It can be good to have similar subheadings
like "Details" as shown above, with no need to make such sub-parts reachable
by a link.

=head2 Disabling

If you don't care at all about this you can disable
C<ProhibitDuplicateHeadings> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitDuplicateHeadings]

=head1 CONFIGURATION

=over 4

=item C<uniqueness> (string, default "default")

The uniqueness to be enforced on each heading.  The value is a
comma-separated list of

    default     currently "ancestor,sibling,adjacent"
    ancestor    don't duplicate parent, grandparent, etc
    sibling     same level and parent
    adjacent    immediately preceding, irrespective of level
    all         all headings

The default is "default" and the intention is to have default mean a
sensible set of restrictions, though precisely what it might be could
change.

For example in your F<.perlcriticrc> file

    [Documentation::ProhibitDuplicateHeadings]
    uniqueness=ancestor,adjacent

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

L<Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso>,
L<Perl::Critic::Policy::Documentation::RequirePodSections>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

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

=cut
