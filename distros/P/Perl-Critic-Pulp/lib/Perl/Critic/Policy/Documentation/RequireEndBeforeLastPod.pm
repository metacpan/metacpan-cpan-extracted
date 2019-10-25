# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Rydepod

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


package Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

our $VERSION = 97;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

# only ever gives one violation
use constant default_maximum_violations_per_document => 1;

sub violates {
  my ($self, $elem, $document) = @_;

  $elem = $elem->last_element
    || return;  # empty file

  if ($elem->isa('PPI::Statement::End')
      || $elem->isa('PPI::Statement::Data')) {
    # $document ends with __END__, ok
    # or ends with __DATA__, in which case you can't use __END__ after last
    # code, so ok
    return;
  }

  for (;;) {
    if ($elem->significant) {
      # document ends with code, ie. no pod after the last code, so ok
      return;
    }
    if ($elem->isa('PPI::Token::Pod')) {
      # found the last pod
      last;
    }
    # otherwise skip PPI::Token::Comment and possibly PPI::Token::Whitespace
    $elem = $elem->previous_sibling
      || return; # $document is empty, or only comments and whitespace, so ok
  }

  if (! $elem->sprevious_sibling) {
    # there's no code before the last pod, either a pod-only file, or pod
    # plus comments etc, so ok
    return;
  }

  return $self->violation
    ('Put __END__ before POD at the end of a file.',
     '',
     $elem);
}

1;
__END__

=for stopwords ok SelfLoader Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod - require __END__ before POD at end of file

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It requires that you put an C<__END__> before POD which is at the
end of a file.  For example,

    program_code();
    1;
    __END__     # good

    =head1 NAME
    ...

and not merely

    program_code();
    1;          # bad

    =head1 NAME
    ...

This is primarily a matter of personal preference, so the policy is low
severity and only under the "cosmetic" theme (see L<Perl::Critic/POLICY
THEMES>).  An C<__END__> like this has no effect on execution, but it's a
fairly common convention since it's a good human indication you mean the
code to end there, and it stops Perl parsing through the POD which may save
a few nanoseconds.

This policy is looser than C<Documentation::RequirePodAtEnd>.  This policy
allows POD to be anywhere in among the code, the requirement is only that if
the file ends with POD then you should have an C<__END__> between the last
code and last POD.

A file of all POD, or all code, or which ends with code, is ok.  Ending with
code is usual if you write your POD at the start of the file or in among the
functions etc,

    =pod

    And that's all.

    =cut

    cleanup ();
    exit 0;     # good

A file using C<__DATA__> is always ok, since you can't have C<__END__>
followed by C<__DATA__>, wherever you want your POD.  If the C<__DATA__> is
in fact C<SelfLoader> code then it can helpfully have an C<__END__> within
it, but as of C<perlcritic> version 1.092 no checks at all are applied to
SelfLoader sections.

=head2 Disabling

As always if you don't care about C<__END__> you can disable
C<RequireEndBeforeLastPod> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::RequireEndBeforeLastPod]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Documentation::RequirePodAtEnd>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
