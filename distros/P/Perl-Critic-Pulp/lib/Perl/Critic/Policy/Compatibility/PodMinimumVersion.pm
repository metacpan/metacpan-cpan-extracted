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


package Perl::Critic::Policy::Compatibility::PodMinimumVersion;
use 5.006;
use strict;
use warnings;

# 1.084 for Perl::Critic::Document highest_explicit_perl_version()
use Perl::Critic::Policy 1.084;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 97;

use constant supported_parameters =>
  ({ name        => 'above_version',
     description => 'Check only things above this version of Perl.',
     behavior    => 'string',
     parser      => \&Perl::Critic::Pulp::Utils::parameter_parse_version,
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => qw(pulp compatibility);
use constant applies_to       => 'PPI::Document';


# but actually Pod::MinimumVersion is a hard dependency at the moment ...
sub initialize_if_enabled {
  my ($self, $config) = @_;
  # when Pod::MinimumVersion is available
  return (eval { require Pod::MinimumVersion; 1 } || 0);
}

sub violates {
  my ($self, $document) = @_;
  ### $self

  # whichever of highest_explicit_perl_version() or "above_version" is greater
  my $above_version = $self->{'_above_version'};
  if (defined (my $doc_version = $document->highest_explicit_perl_version)) {
    if (! defined $above_version || $doc_version > $above_version) {
      $above_version = $doc_version;
    }
  }

  my $str = $document->serialize;
  my $pmv = Pod::MinimumVersion->new (string => $str,
                                      above_version => $above_version,
                                      one_report_per_version => 1,
                                     );
  my @reports = $pmv->reports;
  @reports = sort {$a->{'version'} <=> $b->{'version'}} @reports;
  return map {
    my $report = $_;
    my $violation = $self->violation
      ("Pod requires perl $report->{'version'} due to: $report->{'why'}.",
       '',
       $document);
    Perl::Critic::Pulp::Utils::_violation_override_linenum
        ($violation, $str, $report->{'linenum'});

  } @reports;
}

package Perl::Critic::Pulp::PodMinimumVersionViolation;
use base 'Perl::Critic::Violation';
sub location {
  my ($self) = @_;
  my $offset = ($self->{_Pulp_linenum_offset} || 0);

  my @location = @{$self->SUPER::location()};
  $location[0] += $offset;    # line
  if ($#location >= 3) {
    $location[3] += $offset;  # logical line, new in ppi 1.205
  }
  return \@location;
}

1;
__END__

=for stopwords CPAN config Ryde

=head1 NAME

Perl::Critic::Policy::Compatibility::PodMinimumVersion - check Perl version declared against POD features used

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It checks that the POD features you use don't exceed your target
Perl version as indicated by C<use 5.008> etc.

=for ProhibitVerbatimMarkup allow next 3

    use 5.005;

    =pod

    C<< something >>    # bad, double angles needs 5.006

POD doesn't affect how the code runs, so this policy is low severity, and
under the "compatibility" theme (see L<Perl::Critic/POLICY THEMES>).

See L<C<Pod::MinimumVersion>|Pod::MinimumVersion> for the POD version checks
applied.  The key idea is for example when targeting Perl 5.005 you avoid
things like double-angles S<C<CE<lt>E<lt> E<gt>E<gt>>>, since C<pod2man> in
5.005 didn't support them.  It may be possible to get newer versions of the
POD translators from CPAN, but whether they run on an older Perl and whether
you want to require that of users is another matter.

Adding the sort of C<use 5.006> etc to declare a target Perl can be a bit
tedious.  The config option below lets you set a base version you use.  As
always if you don't care at all about this sort of thing you can disable the
policy from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Compatibility::PodMinimumVersion]

=head2 C<RequirePodLinksIncludeText> Policy

The C<Documentation::RequirePodLinksIncludeText> policy asks you to use the
C<LE<lt>target|displayE<gt>> style always.  That feature is new in Perl
5.005 and will be reported by C<PodMinimumVersion> unless you've got C<use
5.005> or higher or set C<above_version> below.

=head1 CONFIGURATION

=over 4

=item C<above_version> (version string, default none)

Report only things about Perl versions above this.  The string is anything
the L<C<version.pm>|version> module understands.  For example if you always
use Perl 5.6 or higher then set

    [Compatibility::PodMinimumVersion]
    above_version = 5.006

The effect is that all POD features up to and including Perl 5.6 are
allowed, only things above that will be reported (and still only those
exceeding any C<use 5.xxx> in the file).

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Pod::MinimumVersion>, L<Perl::Critic>

L<Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText>,
L<Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy>,
L<Perl::Critic::Policy::Modules::PerlMinimumVersion>

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
