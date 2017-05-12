#---------------------------------------------------------------------
package PostScript::ScheduleGrid::Role::Style;
#
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created:  5 Oct 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Something that customizes a cell's appearance
#---------------------------------------------------------------------

our $VERSION = '0.05'; # VERSION
# This file is part of PostScript-ScheduleGrid 0.05 (August 22, 2015)

use 5.010;
use Moose::Role;

use MooseX::Types::Moose qw(Str);

use namespace::autoclean;

#=====================================================================


has name => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);


requires 'define_style';


# Import _ps_eval method from PostScript::ScheduleGrid:
__PACKAGE__->meta->add_method(_ps_eval => \&PostScript::ScheduleGrid::_ps_eval);

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

PostScript::ScheduleGrid::Role::Style - Something that customizes a cell's appearance

=head1 VERSION

This document describes version 0.05 of
PostScript::ScheduleGrid::Role::Style, released August 22, 2015
as part of PostScript-ScheduleGrid version 0.05.

=head1 DESCRIPTION

This role describes a style for displaying the contents of a cell in
the grid.  The class must provide a C<define_style> method.

If a style has PostScript definitions that are invariant, it may
define them by adding a function block under its class name (with
C<::> replaced by C<_>).  If it needs more than one function block, it
may append a hyphen and an arbitrary identifier.

The definitions must begin with the class name (with
C<PostScript::ScheduleGrid::Style::> replaced by C<s> and any
remaining C<::> replaced by C<_>.  That prefix may be followed by a
hypen and any legal PostScript identifier.  For example,
C<PostScript::ScheduleGrid::Style::Stripe> can define PostScript
identifiers beginning with C<sStripe->.

The C<name> function created by the C<define_style> method will be
called with no parameters.  The clipping path is set to the boundaries
of the cell, and the current font is the grid's C<cell_font>.  The
graphics state has been saved and will be restored after the cell's
text is drawn.

The function must perform whatever drawing it wants to, and leave the
color and font set for the cell's text.

=head1 ATTRIBUTES

=head2 name

This is the name of the PostScript function that the Style must
define.  It may also use any identifiers beginning with C<name>
followed by a hyphen for any purposes it likes.

=head1 METHODS

=head2 _ps_eval

  $style->_ps_eval(\$string, ...);

This method is provided by this role.  It substitutes values from the
object into each C<$string> (which is modified in-place).  Any number
of string references may be passed.

The following substitutions are performed on each C<$string>:

First, any C<$> followed by an identifier are replaced by calling that
method on the object and passing its return value to
PostScript::File's C<str> function.

Second, any C<%{...}> is replaced with the result of evaluating ... (which
may not contain braces).


=head2 define_style

  $style->define_style($schedule_grid);

This method must return a string containg PostScript code to define
the function specified by C<name>.  C<$schedule_grid> is the
PostScript::ScheduleGrid object using the style.

=head1 CONFIGURATION AND ENVIRONMENT

PostScript::ScheduleGrid::Role::Style requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-ScheduleGrid AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-ScheduleGrid >>.

You can follow or contribute to PostScript-ScheduleGrid's development at
L<< https://github.com/madsen/postscript-schedulegrid >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

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
