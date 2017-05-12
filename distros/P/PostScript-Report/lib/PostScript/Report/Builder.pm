#---------------------------------------------------------------------
package PostScript::Report::Builder;
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
# ABSTRACT: Build a PostScript::Report object
#---------------------------------------------------------------------

our $VERSION = '0.13';
# This file is part of PostScript-Report 0.13 (November 30, 2013)

use 5.008;
use Moose;
use MooseX::Types::Moose qw(Bool HashRef Int Str);
use PostScript::Report::Types ':all';

use Module::Runtime qw( require_module );
use PostScript::Report::HBox ();
use PostScript::Report::VBox ();
use String::RewritePrefix ();

use namespace::autoclean;

our %loaded_class;


has default_field_type => (
  is  => 'ro',
  isa => Str,
  default => 'Field',
);


has default_column_header => (
  is  => 'ro',
  isa => Str,
  default => 'Field',
);


has default_column_type => (
  is  => 'ro',
  isa => Str,
  default => 'Field',
);


has report_class => (
  is      => 'rw',
  isa     => Str,
  default => 'PostScript::Report',
);

has _fonts => (
  is       => 'rw',
  isa      => HashRef[FontObj],
  init_arg => undef,
  clearer  => '_clear_fonts',
);

# These parameters should simply be passed through to the Report constructor:
our @constructor_args = qw(
  align
  border
  bottom_margin
  detail_background
  first_footer
  footer_align
  landscape
  left_margin
  line_width
  padding_bottom
  padding_side
  paper_size
  ps_parameters
  right_margin
  row_height
  title
  top_margin
);
#---------------------------------------------------------------------


sub build
{
  my ($self, $descHash) = @_;

  my %desc = %$descHash;        # Don't want to change the original

  # If we're called as a package method, construct a temporary object:
  unless (ref $self) {
    $self = $self->new(\%desc);
  }

  # Construct the PostScript::Report object:
  $self->require_class( $self->report_class );

  my $rpt = $self->report_class->new( $self->get_report_parameters(\%desc) );

  # Create the fonts we'll be using:
  $self->create_fonts( $rpt, $desc{fonts} );

  # Set the report's default fonts:
  foreach my $type (qw(font)) {
    next unless exists $desc{$type};

    $rpt->$type( $self->get_font( $desc{$type} ) );
  }

  # Set any extra fonts:
  if (my $extra = $rpt->extra_styles) {
    foreach my $type (keys %$extra) {
      $extra->{$type} = $self->get_font( $extra->{$type} )
          if $type =~ /(?:^|_)font$/;
    } # end foreach key
  } # end if extra_styles

  # Prepare the columns:
  $self->create_columns(\%desc) if $desc{columns};

  # Construct the report sections:
  foreach my $sectionName ($rpt->_sections) {
    my $section = $desc{$sectionName} or next;

    $rpt->$sectionName( $self->build_section( $section ));
  } # end foreach $sectionName

  # Clean up and return the report:
  $self->_clear_fonts;

  $rpt;
} # end build

#---------------------------------------------------------------------
sub get_report_parameters
{
  my ($self, $desc) = @_;

  my %param;

  # Copy @constructor_args to %param:
  foreach my $key (@constructor_args) {
    $param{$key} = $desc->{$key} if exists $desc->{$key};
  }

  # Move any extra attributes to extra_styles:
  my %valid = (
     (map { $_ => 1 } qw(columns fonts stripe_page stripe)),
     (map { my $arg = $_->init_arg;
                    ((defined $arg ? $arg : $_->name) => 1) }
       $self->meta->get_all_attributes,
       $self->report_class->meta->get_all_attributes)
  );

  while (my $key = each %$desc) {
    $param{extra_styles}{$key} = $self->_extra_value($key, $desc->{$key})
        unless $valid{$key};
  } # end while each entry in %param

  # See if we're using zebra striping:
  my ($use_param, @colors) = 0;
  my $stripe_type;

  if ($desc->{stripe_page}) {
    die "Cannot combine stripe and stripe_page" if $desc->{stripe};
    $stripe_type = 'stripe_page';
    $use_param = 1;         # Use row-on-page instead of row-in-report
  } elsif ($desc->{stripe}) {
    $stripe_type = 'stripe';
  }

  if ($stripe_type) {
    @colors = @{ $desc->{$stripe_type} };

    die "Cannot combine $stripe_type and detail_background"
        if $param{detail_background};

    # Make sure each color is valid or undef:
    foreach my $color (@colors) {
      if (defined $color) {
        my $new = to_Color($color);
        defined($new) or die "Invalid color $color in $stripe_type";
        $color = $new;
      } # end if defined $color
    } # end foreach $color in @colors

    $param{detail_background} = sub { $colors[ $_[$use_param] % @colors ] };
  } # end if zebra striping

  \%param;
} # end get_report_parameters

#---------------------------------------------------------------------
sub get_font
{
  my ($self, $fontname) = @_;

  $self->_fonts->{$fontname}
      or die "$fontname was not listed in 'fonts'";
} # end get_font

#---------------------------------------------------------------------
sub create_fonts
{
  my ($self, $rpt, $desc) = @_;

  my %font;

  for my $name (sort keys %$desc) {
    $desc->{$name} =~ /^(.+)-(\d+(?:\.\d+)?)/
        or die "Invalid font description $desc->{$name} for $name";

    $font{$name} = $rpt->get_font($1, $2);
  }

  $self->_fonts(\%font);
} # end create_fonts

#---------------------------------------------------------------------
sub create_columns
{
  my ($self, $desc) = @_;

  confess "Can't use both detail and columns" if $desc->{detail};

  my $columns = $desc->{columns};

  foreach my $key (qw(stripe stripe_page)) {
    confess "$key does not belong inside columns" if $columns->{$key};
  }

  my @header = (HBox => $columns->{header} || {});
  my @detail = (HBox => $columns->{detail} || {});

  my $colNum = 0;
  foreach my $col (@{ $columns->{data} }) {
    my (%headerDef, %detailDef);

    %headerDef = %{ $col->[2] } if $col->[2];
    %detailDef = %{ $col->[3] } if $col->[3];

    $headerDef{width} = $detailDef{width} = $col->[1];

    $headerDef{_class} ||= $self->default_column_header;
    $detailDef{_class} ||= $self->default_column_type;

    $headerDef{value} ||= { qw(_class Constant  value), $col->[0] };
    $detailDef{value} ||= $colNum++;

    push @header, \%headerDef;
    push @detail, \%detailDef;
  } # end foreach $col

  if ($desc->{page_header}) {
    # Can't just push, because we don't want to modify the original:
    $desc->{page_header} = [ @{ $desc->{page_header} }, \@header ];
  } else {
    $desc->{page_header} = \@header;
  }

  $desc->{detail} = \@detail;
} # end create_columns

#---------------------------------------------------------------------
sub build_section
{
  my ($self, $desc) = @_;

  my $type = ref $desc or die "Expected reference";

  # A section could be just a single object:
  return $self->build_object($desc, $self->default_field_type)
      if $type eq 'HASH';

  die "Expected array reference" unless $type eq 'ARRAY';

  # By default, we want a VBox, but if it appears we have just one
  # arrayref, assume we want an HBox:
  my $boxType = ((ref($desc->[0]) || q{}) eq 'HASH'
                 ? 'HBox' : 'VBox');

  # Recursively build the box:
  return $self->build_box($desc, $boxType, $self->default_field_type);
} # end build_section

#---------------------------------------------------------------------
sub build_box
{
  my ($self, $desc, $boxType, $defaultClass) = @_;

  die "Empty box is not allowed" unless @$desc;

  my $start = 0;
  my %param;

  # If [ className => { ... } ], use it:
  if (not ref $desc->[0]) {
    $boxType  = $desc->[0];
    %param = %{ $desc->[1] };
    $defaultClass = delete $param{_default} if exists $param{_default};
    $start = 2;
  }
  my $class = $self->get_class($boxType);
  $self->_fixup_parms(\%param, $class);

  my @children = map {
    ref $_ eq 'HASH'
        ? $self->build_object($_, $defaultClass)
        : $self->build_box($_, ($boxType eq 'HBox' ? 'VBox' : 'HBox'),
                           $defaultClass)
  } @$desc[$start .. $#$desc];

  # Construct the box:
  $class->new(children => \@children, %param);
} # end build_box

#---------------------------------------------------------------------
sub build_object
{
  my ($self, $desc, $class, $prefix) = @_;

  my %parms = %$desc;

  $class = $self->get_class(delete($parms{_class}) || $class, $prefix);

  $self->_fixup_parms(\%parms, $class);

  $class->new(\%parms);
} # end build_object

#---------------------------------------------------------------------
sub get_class
{
  my ($self, $class, $prefix) = @_;

  die "Unable to determine class" unless $class;

  return String::RewritePrefix->rewrite(
    {'=' => q{},  q{} => ($prefix || 'PostScript::Report::')},
    $class
  );
} # end get_class

#---------------------------------------------------------------------
sub _fixup_parms
{
  my ($self, $parms, $class) = @_;

  $self->require_class($class);

  my %valid = map { my $arg = $_->init_arg;
                    defined $arg ? ($arg => 1) : () }
      $class->meta->get_all_attributes;

  my $extra = $parms->{extra_styles};

  while (my ($key, $val) = each %$parms) {
    if ($key =~ /(?:^|_)font$/) {
      $parms->{$key} = $self->get_font($val);
    } elsif ($key eq 'value' and ref $val) {
      if (ref $val eq 'SCALAR') {
        $self->require_class('PostScript::Report::Value::Constant');
        $parms->{$key} = PostScript::Report::Value::Constant->new(
          value => $$val
        );
      } else {
        $parms->{$key} = $self->build_object($val, undef,
                                             'PostScript::Report::Value::');
      }
    } # end elsif key 'value' and ref $val

    # Move non-standard attributes to extra_styles:
    $extra->{$key} = $self->_extra_value($key, delete $parms->{$key})
        unless $valid{$key};
  } # end while each ($key, $val) in %$parms

  $parms->{extra_styles} = $extra if $extra;
} # end _fixup_parms

#---------------------------------------------------------------------
# Coerce a value for the extra_styles hash:

sub _extra_value
{
  my ($self, $key, $val) = @_;

  if ($key =~ /(?:^|_)color$/) {
    defined(my $color = to_Color($val)) or die "Invalid $key $val";
    return $color;
  }

  return $val;
} # end _extra_value

#---------------------------------------------------------------------
sub require_class
{
  my ($self, $class) = @_;

  return if $loaded_class{$class};
  require_module($class);

  $loaded_class{$class} = 1;
} # end require_class

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

PostScript::Report::Builder - Build a PostScript::Report object

=head1 VERSION

This document describes version 0.13 of
PostScript::Report::Builder, released November 30, 2013
as part of PostScript-Report version 0.13.

=head1 SYNOPSIS

    use PostScript::Report ();

    my $rpt = PostScript::Report->build(\%report_description);

=head1 DESCRIPTION

Because a PostScript::Report involves constructing a number of related
objects, it's usually more convenient to pass a description of the
report to a builder object.

You can find example reports in the F<examples> directory of this
distribution.

The C<%report_description> is a hash with keys as follows:

=head2 Report Attributes

Any of the Report attributes listed under
L<PostScript::Report/"Report Formatting"> or
L<PostScript::Report/"Component Formatting"> may be
set by the report description.

=head2 Builder Attributes

Any of the attributes listed in L</ATTRIBUTES> may be set by the
report description I<when C<build> is called as a class method>.

=head2 Font Specifications

All fonts used in a report must be defined in a hashref under the
C<fonts> key (unless you only want to use the report's default fonts).
The keys in this hashref are arbitrary strings, and the values are
strings in the form FONTNAME-SIZE.

If you use the same value more than once, then both keys will refer to
the same font object.  This allows you to use the same font for
different purposes, while retaining the ability to substitute a
different font for one of those purposes just by changing the C<fonts>
hash.

When you set a C<font> or C<label_font> attribute, its value must be
one of the keys in the C<fonts> hash.

Example:

  fonts => {
    label    => 'Helvetica-6',
    text     => 'Helvetica-9',
  },

  font       => 'text',
  label_font => 'label',


=head2 Report Sections

Any of the sections listed under L<PostScript::Report/"Report Sections">
may be defined by the report description.
The value is interpreted as follows:

Components are created by hashrefs.  Containers are created by arrayrefs.

If the section is a container, the initial container type is chosen
like this: If the first value in the arrayref is a hashref, you get an
HBox.  Otherwise, you get a VBox.

After that, the box types alternate.  If you place an arrayref in an
HBox, it becomes a VBox.  An arrayref in a VBox becomes an HBox.

You can override the box type (or pass parameters to its constructor),
by making the first entry in the arrayref a string (the container
type) and the second entry a hashref to pass to its constructor.  If
that hashref contains a C<_default> key, its value becomes the default
component class inside this container.

The hashref that represents a Component is simply passed to its
constructor, with one exception.  If the hash contains the C<_class>
key, that value is removed and used as the class name.

=head3 Constant Values

As a special case, you can pass a scalar reference as the C<value> for
a Component.  This creates a
L<constant value|PostScript::Report::Value::Constant>.  That is,

  value => \'Label:',

is equivalent to

  value => { _class => 'Constant',  value => 'Label:' },

=head3 A Note on Class Names

Anywhere you specify a class name, C<PostScript::Report::> is
automatically prepended to the name you give.  To use a class outside
that namespace, prefix the class name with C<=>.

There are two exceptions to this:

=over

=item 1.

When you give a hashref as the value of a C<value> attribute, the
prefix is C<PostScript::Report::Value::> instead of just
C<PostScript::Report::>.

=item 2.

The C<report_class> is always a complete class name.

=back

=head2 Report Columns

The C<columns> key is provided as a shortcut for the common case of a
report with column headers and a single-row C<detail> section.

The value should be a hashref with the following keys:

=over

=item header

A hashref of parameters to pass to the constructor of the HBox that
holds the column headers.  Optional.

=item detail

A hashref of parameters to pass to the constructor of the HBox that
forms the C<detail> section.  Optional.

=item data

An arrayref of arrayrefs, one per column.  Required.  Each arrayref
has 4 elements.  The first two are the column title and the column
width.  The third is an optional hashref of parameters for the header
component, and the fourth is an optional hashref of parameters for the
detail component.

If you don't specify a C<_class> for the header component, it defaults
to L</default_column_header>, and if you don't specify a C<_class> for
the detail component, it defaults to L</default_column_type>.

If you don't specify a C<value> for the header component, it defaults
to the column title (as a L<Constant|PostScript::Report::Value::Constant>).

If you don't specify a C<value> for the detail component, it defaults
to the next column number.  (If you do specify a C<value>, the column
number is B<not> incremented.)

=back

This assumes that the C<page_header> is a VBox (or that there is no
C<page_header> aside from the column headers).

If you need a more complex layout than this, don't use C<columns>.
Instead, define the C<detail> and C<page_header> sections as needed.

=head2 Zebra Striping

The C<stripe> and C<stripe_page> keys are provided as a shortcut for
the common case of a report with a detail section that cycles through
a pattern of
L<background colors|PostScript::Report::Role::Component/background>.

The value should be a arrayref of colors.  The first row uses the
first color, the second row uses the second color, and so on (wrapping
around to the beginning of the array).

Use C<stripe_page> if you want the pattern to start over on every
page, or C<stripe> if you want it to continue from where the previous
page left off.

For example,

  stripe => [ 1, 0.85 ],

will give every other row a light grey background.

If you need a more complex color scheme, set
L<PostScript::Report/detail_background> directly.

Note that C<stripe> and C<stripe_page> are B<not> placed inside the
C<columns> hash, because they can be used even if you define the
C<detail> section manually.

=for Pod::Coverage
build_.*
create_.*
get_.*
require_class

=head1 ATTRIBUTES

=head2 default_column_header

This is the default component class used for column headers.
It defaults to L<Field|PostScript::Report::Field>.


=head2 default_column_type

This is the default component class used for column fields.
It defaults to L<Field|PostScript::Report::Field>.


=head2 default_field_type

This is the default component class used when building the report
sections.  It defaults to L<Field|PostScript::Report::Field>.

You can temporarily override this by specifying the C<_default> key as
a container's parameter.


=head2 report_class

This is the class of object that will be constructed.
It defaults to L<PostScript::Report>.
This must always be a full class name.

=head1 METHODS

=head2 build

  $rpt = $builder->build(\%report_description)
  $rpt = PostScript::Report::Builder->build(\%report_description)

This can be called as either an object or class method.  When called
as a class method, it constructs a temporary object by passing the
description to C<new>.

=head1 CONFIGURATION AND ENVIRONMENT

PostScript::Report::Builder requires no configuration files or environment variables.

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
