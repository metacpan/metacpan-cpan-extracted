#---------------------------------------------------------------------
package Pod::Loom::Role::Extender;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 16, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Role to simplify extending a template
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '0.03';
# This file is part of Pod-Loom 0.08 (March 23, 2014)

use Moose::Role;
#---------------------------------------------------------------------


around _build_sections => sub {
  my $orig = shift;
  my $self = shift;

  my $sections = $self->$orig(@_);

  my $remap = $self->can('remap_sections');

  if ($remap) {
    $remap = $self->$remap;

    $sections = [ map { $remap->{$_} ? @{$remap->{$_}} : $_ } @$sections ];
  } # end if remap

  $sections;
}; # end around _build_sections
#---------------------------------------------------------------------


around collect_commands => sub {
  my $orig = shift;
  my $self = shift;

  my $commands = $self->$orig(@_);

  if (my $additional = $self->can('additional_commands')) {
    my %command = map { $_ => undef } @$commands;

    $command{$_} = undef for @{ $self->$additional };

    $commands = [ keys %command ];
  } # end if additional_commands

  $commands;
}; # end around collect_commands

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

Pod::Loom::Role::Extender - Role to simplify extending a template

=head1 VERSION

This document describes version 0.03 of
Pod::Loom::Role::Extender, released March 23, 2014
as part of Pod-Loom version 0.08.

=head1 SYNOPSIS

  use Moose;
  extends 'Pod::Loom::Template::Default';
  with 'Pod::Loom::Role::Extender';

  sub remap_sections { {
    AUTHOR => [qw[ AUTHOR ACKNOWLEDGMENTS ]],
  } }

  sub section_ACKNOWLEDGMENTS ...

=head1 DESCRIPTION

The Extender role simplifies creating a custom Pod::Loom template.
You should not use this for templates uploaded to CPAN, because you
can only use it once per template.  It's intended for creating a
custom template for a distribution.

=head1 METHODS

Your template class may provide any or all of the following methods.
(If you don't provide any of these methods, then there's no point in
using Extender.)

=head2 additional_commands

If your class provides C<additional_commands>, it should return an
arrayref just like C<collect_commands>.  This list will be merged with
the list of C<collect_commands> from the template being extended.


=head2 remap_sections

If your class provides C<remap_sections>, it should return a hashref
keyed by section title.  The values should be arrayrefs of section
titles.  Each section in the hash will be replaced by the listed
sections.  You can use this to insert or remove sections from the
template you're extending.

=head1 CONFIGURATION AND ENVIRONMENT

Pod::Loom::Role::Extender requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Pod-Loom AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-Loom >>.

You can follow or contribute to Pod-Loom's development at
L<< https://github.com/madsen/pod-loom >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
