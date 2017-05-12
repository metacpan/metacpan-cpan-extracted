#---------------------------------------------------------------------
package PostScript::Report::Role::Component;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 12, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Something that can be drawn
#---------------------------------------------------------------------

our $VERSION = '0.10';
# This file is part of PostScript-Report 0.13 (November 30, 2013)

use Moose::Role;
use MooseX::AttributeTree 0.02 (); # fetch_method & default
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

my @inherited = (traits => [qw/TreeInherit/]);


has parent => (
  is       => 'ro',
  isa      => Parent,
  weak_ref => 1,
  writer   => '_set_parent',
);


has height => (
  is        => 'ro',
  isa       => Int,
  writer    => '_set_height',
  predicate => 'has_height',
  @inherited,
);


has width => (
  is        => 'ro',
  isa       => Int,
  writer    => '_set_width',
  predicate => 'has_width',
  @inherited,
);


has align => (
  is  => 'ro',
  isa => HAlign,
  @inherited,
);


has background => (
  is       => 'ro',
  isa      => Color,
  coerce   => 1,
  writer   => '_set_background', # Used by Report::_stripe_detail
);


has border => (
  is  => 'ro',
  isa => BorderStyle,
  coerce => 1,
  @inherited,
);


has font => (
  is  => 'ro',
  isa => FontObj,
  @inherited,
);


has line_width => (
  is  => 'ro',
  isa => Num,
  @inherited,
);


requires 'draw';

before draw => sub {
  my ($self, $x, $y, $rpt) = @_;

  if (defined(my $background = $self->background)) {
    $rpt->ps->add_to_page( sprintf(
      "%d %d %d %d %s fillBox\n",
      $x, $y, $x + $self->width, $y - $self->height,
      PostScript::File::str($background)
    ));
  }
}; # end before draw


sub draw_standard_border
{
  my ($self, $x, $y, $rpt) = @_;

  if ($self->border) {
    $rpt->ps->add_to_page( sprintf(
      "%d %d %d %d %s db%s\n",
      $x, $y, $x + $self->width, $y - $self->height,
      $self->line_width, $self->border
    ));
  }
} # end draw_standard_border


sub id
{
  my $class = blessed shift;
  $class =~ /([^:]+)$/ or confess "No class";

  $1;
} # end id


sub init
{
  my ($self, $parent, $report) = @_;

  $self->_set_parent($parent);
  $report->ps->use_functions('fillBox');
} # end init
#---------------------------------------------------------------------


sub report
{
  my $report = shift;

  while (my $parent = $report->can('parent')) {
    $report = $report->$parent or return undef;
  }

  return $report;
} # end report

#---------------------------------------------------------------------


sub dump
{
  my ($self, $level) = @_;
  $level ||= 0;

  my $indent = "  " x $level;

  printf "%s%s:\n", $indent, blessed $self;

  my @attrs = sort { $a->name cmp $b->name } $self->meta->get_all_attributes;

  my $is_container;
  ++$level;

  foreach my $attr (@attrs) {
    my $name = $attr->name;

    next if $name eq 'parent';

    if ($name eq 'children' and
        $self->does('PostScript::Report::Role::Component')) {
      $is_container = 1;
    } else {
      PostScript::Report->_dump_attr($self, $attr, $level);
    }
  } # end foreach $attr in @attrs

  return unless $is_container;

  print "$indent  children:\n";

  ++$level;
  foreach my $child (@{ $self->children }) {
    $child->dump($level);
  } # end foreach $child
} # end dump

#=====================================================================
# Package Return Value:

undef @inherited;
1;

__END__

=head1 NAME

PostScript::Report::Role::Component - Something that can be drawn

=head1 VERSION

This document describes version 0.10 of
PostScript::Report::Role::Component, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 DESCRIPTION

This role describes an object that knows how to draw itself on a
report.  A Component that contains other Components is a
L<Container|PostScript::Report::Role::Container>.

=head1 ATTRIBUTES


=head2 Inherited Attributes

These attributes control the component's formatting.  To avoid having
to set all of them on every component, their values are inherited much
like CSS styles are inherited in HTML.  If a component does not have
an explicit value set, then the value is inherited from the parent.
The inheritance may bubble up all the way to the Report object, which
will always provide a default value.

All dimensions are in points.


=head3 align

This controls text alignment.  It may be C<left>, C<center>, or
C<right>.


=head3 background

This is the background color for the Component.  The color is a number
in the range 0 to 1 (where 0 is black and 1 is white) for a grey
background, or an arrayref of three numbers C<[ Red, Green, Blue ]>
where each number is in the range 0 to 1.

In addition, you can specify an RGB color in the HTML hex triplet form
prefixed by C<#> (like C<#FFFF00> or C<#FF0> for yellow).

Unlike the other formatting attributes, its value is not actually
inherited, but since a Container draws the background for all its
Components, the effect is the same.


=head3 border

This is the border style.  It may be 1 for a solid border or 0 for no
border.  In addition, you may specify any combination of the letters
T, B, L, and R (meaning top, bottom, left, and right) to have a border
only on the specified side(s).

The thickness of the border is controlled by L</line_width>.

(Note: The string you give will be converted into the canonical
representation, which has the letters upper case and in the order
TBLR.)


=head3 font

This is the font used to draw normal text in the Component.


=head3 height

This is the height of the component.


=head3 line_width

This is the line width.  It's used mainly as the border width.
A line width of 0 means "as thin as possible".


=head3 width

This is the width of the component.  In most cases, you will need to
set this explicitly.


=head2 Optional Attributes

The following attributes are not present in all components, but when
they are present, they should behave as described here.  Attributes
whose value can be inherited from the parent are marked (Inherited).


=head3 padding_bottom

(Inherited) This is the amount of space between the bottom of the
component and the baseline of the text inside it.  If this is too
small, then the descenders (on letters like "p" and "y") will be cut
off.  (The exact minimum necessary depends on the selected font and
size.)


=head3 padding_side

(Inherited) This is the amount of space between the side of the
component and the text inside it.


=head3 value

This is the C<$value_source> that the component will use to retrieve
its contents.  See L<PostScript::Report/get_value>.


=head2 Internal Attribute

You probably won't need to use this attribute directly.


=head3 parent

This attribute contains a reference to the Container or Report that is
the direct parent of this Component.  It is used for inheritance of
attribute values.  It is filled in by the L</init> method, and you
will probably never deal with it directly.

=head1 METHODS

=head2 draw

  $component->draw($x, $y, $report);

This method draws the component on the current page of the report at
position C<$x>, C<$y>.  This method must be provided by the component.
The Component role provides a C<before draw> modifier to draw the
component's background.


=head2 draw_standard_border

  $component->draw_standard_border($x, $y, $report);

This method draws a border around the component as specified by the
L</border> and L</line_width> attributes.  It can be called by a
component's C<draw> method, or added as an C<after> modifier:

  after draw => \&draw_standard_border;


=head2 dump

  $component->dump($level);

This method (for debugging purposes only) prints a representation of
the component to the currently selected filehandle.  (Inherited values
are not shown.)  Note that layout calculations are not done until the
report is run, so you will normally see additional C<height> and
C<width> values after calling L</run>.

C<$level> (default 0) indicates the level of indentation to use.

The default implementation should be sufficient for most components.


=head2 id

  $psID = $component->id;

In order to avoid stepping on each other's PostScript code, any
PostScript identifiers created by a component should begin with this
string.  The default implementation returns the last component of the
class name.


=head2 init

  $component->init($parent, $report);

The init method of each component is called at the beginning of each
report run.  The default implementation sets the parent link to enable
inheritance of attribute values.

Most components will need to provide an C<after> modifier to do
additional initialization, such as calculating C<height> or C<width>.
Also, the component should add its standard procedures to
C<< $report->ps_functions >>.


=head2 report

  $component->report;

This returns the PostScript::Report object that this Component
ultimately belongs to, or C<undef> if it is not currently owned by a
Report.  (You should only call this after the C<init> method has been
called.)

=head1 SEE ALSO

The following components are available by default:

=over

=item L<Checkbox|PostScript::Report::Checkbox>

This displays a box, which contains a checkmark if the associated
value is true.

=item L<Field|PostScript::Report::Field>

This is a standard text field.

=item L<FieldTL|PostScript::Report::FieldTL>

This is a text field with a label in the corner.  It also (optionally)
supports multiple lines with word wrap.

=item L<HBox|PostScript::Report::HBox>

This Container draws its children in a horizontal row.

=item L<Image|PostScript::Report::Image>

This allows you to include an EPS file.

=item L<Spacer|PostScript::Report::Spacer>

This is just an empty box for padding.

=item L<VBox|PostScript::Report::VBox>

This Container draws its children in a vertical column.

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-Report AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-Report >>.

You can follow or contribute to PostScript-Report's development at
L<< https://github.com/madsen/postscript-report >>.

=head1 ACKNOWLEDGMENTS

I'd like to thank Micro Technology Services, Inc.
L<http://www.mitsi.com>, who sponsored development of
PostScript-Report, and fREW Schmidt, who recommended me for the job.
It wouldn't have happened without them.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Christopher J. Madsen.

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
