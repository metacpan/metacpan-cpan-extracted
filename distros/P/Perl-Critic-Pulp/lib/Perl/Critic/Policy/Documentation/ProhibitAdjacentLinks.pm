# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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

package Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

# perlcritic -s ProhibitAdjacentLinks ProhibitAdjacentLinks.pm
# perlcritic -s ProhibitAdjacentLinks /usr/share/perl5/SVG.pm

# cf /usr/lib/perl5/Template/Context.pm
#    L<Template> L<new()|Template#new()>
#    the "#" separator is wrong though 
#
# cf /usr/share/perl5/DBIx/Class/Storage/DBI.pm
#    L<DBI|DBI/ATTRIBUTES_COMMON_TO_ALL_HANDLES>
#    L<connection|DBI/Database_Handle_Attributes>
#
# /usr/share/perl5/DhMakePerl/PodParser.pm
#    L<Pod::Parser> L<command|Pod::Parser/command>
#

our $VERSION = 93;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitAdjacentLinks on: $elem->content

  my $parser = Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks::Parser->new
    (policy       => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

#------------------------------------------------------------------------------
package Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks::Parser;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

my %command_non_text = (for   => 1,
                        begin => 1,
                        end   => 1,
                        cut   => 1);
sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  $self->SUPER::command(@_);  # maintain 'in_begin'

  if ($command_non_text{$command}) {
    # skip directives
    return '';
  }
  $self->textblock ($text, $linenum, $paraobj);
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $pod_para) = @_;
  ### textblock
  ### $text

  # process outside =begin, and inside =begin which is ":" markup
  unless ($self->{'in_begin'} eq '' || $self->{'in_begin'} =~ /^:/) {
    return '';
  }

  my $expand = $self->interpolate ($text, $linenum);
  ### $expand
  my $ptree = $self->parse_text ($text, $linenum);
  my @pending = reverse $ptree->children;
  my $last_L = 0;
  my $last_L_name = '';
  my $last_L_display;
  my $last_L_linenum = 0;

  while (@pending) {
    my $obj = pop @pending;
    if (! ref $obj) {
      # plain text
      if ($obj !~ /^\s*$/) {
        # some text, not just whitespace
        $last_L = 0;
      }

    } else {
      # a Pod::InteriorSequence
      my $cmd = $obj->cmd_name;

      if ($cmd eq 'L') {
        (undef, $linenum) = $obj->file_line;

        my $obj_text = join ('',
                             map {ref $_ ? $_->raw_text : $_}
                             $obj->parse_tree);
        my ($display, $inferred, $name, $section, $type)
          = Pod::ParseLink::parselink ($obj_text);
        ### $obj_text
        ### $display
        ### $name
        if (! defined $name) { $name = ''; }

        if ($last_L
            && ! ($name eq $last_L_name
                  && (defined $display || defined $last_L_display))) {
          $self->violation_at_linenum_and_textpos
            ("Adjacent L<> sequences, perhaps a comma or words should be in between",
             $last_L_linenum, '', 0);
        }
        $last_L = 1;
        $last_L_name = $name;
        $last_L_display = $display;
        $last_L_linenum = $linenum;

      } elsif ($cmd eq 'X' || $cmd eq 'Z') {
        # ignore X<> index entries, maybe Z<> crunched already

      } else {
        # descend into other like C<>
        if (my $subtree = $obj->parse_tree) {
          push @pending, reverse $subtree->children;
        }
      }
    }
  }
  if ($text !~ /^\s.*$/) {
    $self->{'last'} = '';
  }
  ### last now: $self->{'last'}
  return;
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks - consecutive LE<lt>E<gt> links

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to have two adjacent LE<lt>E<gt> sequences in a
paragraph.  For example,

=for ProhibitVerbatimMarkup allow next 2

    =head1 SEE ALSO

    L<Foo>               # bad
    L<Bar>

The idea is adjacent LE<lt>E<gt> like this is probably a missing comma or
missing text.  It's easy to make this mistake in a "SEE ALSO" list.

This is normally only very minor and on that basis this policy is lowest
severity and under the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

=head2 Exceptions

An exception is made for two links to the same page where one (or both) have
display text,

=for ProhibitVerbatimMarkup allow next

    See L<My::Package> L<new()|My::Package/Contructors> for more.

This hyperlinks both the package name and a function etc within it.  Perhaps
exactly when to allow or disallow this might be loosened or tightened in the
future.  Adjacent linking is fairly unusual though, and too much linking is
often not a good thing since the meaning ought to be made clear in plain
text too.

=head2 Disabling

If you don't care about this sort of thing at all you can disable
C<ProhibitAdjacentLinks> from your F<.perlcriticrc> in the usual way
(see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitAdjacentLinks]

=head1 BUGS

The column position of the offending adjacency is not included in the
violation reported.  You may need to look carefully at the line to see the
problem, and at the following line if the adjacent link is on the next line.

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic::Policy::Documentation::ProhibitDuplicateSeeAlso>,
L<Perl::Critic::Policy::Documentation::ProhibitLinkToSelf>,
L<Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText>,
L<Perl::Critic::Policy::Documentation::RequireLinkedURLs>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
