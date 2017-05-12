package SVG::Rasterize::Specification;
use strict;
use warnings;

use Exporter 'import';

use SVG::Rasterize::Regexes qw(:attributes);

# $Id: Specification.pm 6630 2011-04-29 23:30:26Z powergnom $

=head1 NAME

C<SVG::Rasterize::Specification> - data structures derived from DTD

=head1 VERSION

Version 0.003007

=cut

our $VERSION = '0.003007';

our @EXPORT      = ();
our @EXPORT_OK   = qw(spec_is_element
                      spec_has_child
                      spec_has_pcdata
                      spec_has_attribute
                      spec_attribute_validation
                      spec_attribute_hints
                      spec_is_length
                      spec_is_color);
our %EXPORT_TAGS =  (all => [@EXPORT, @EXPORT_OK]);

our %CHILDREN = ('a'                   => 'Hyperlink',
                 'altGlyph'            => 'TextContent',
                 'altGlyphDef'         => 'Text',
                 'altGlyphItem'        => 'Misc',
                 'animate'             => 'Animation',
                 'animateColor'        => 'Animation',
                 'animateMotion'       => 'Animation',
                 'animateTransform'    => 'Animation',
                 'circle'              => 'Shape',
                 'clipPath'            => 'Clip',
                 'color-profile'       => 'ColorProfile',
                 'cursor'              => 'Cursor',
                 'definition-src'      => 'Misc',
                 'defs'                => 'Structure',
                 'desc'                => 'Description',
                 'ellipse'             => 'Shape',
                 'feBlend'             => 'FilterPrimitive',
                 'feColorMatrix'       => 'FilterPrimitive',
                 'feComponentTransfer' => 'FilterPrimitive',
                 'feComposite'         => 'FilterPrimitive',
                 'feConvolveMatrix'    => 'FilterPrimitive',
                 'feDiffuseLighting'   => 'FilterPrimitive',
                 'feDisplacementMap'   => 'FilterPrimitive',
                 'feDistantLight'      => 'Misc',
                 'feFlood'             => 'FilterPrimitive',
                 'feFuncA'             => 'Misc',
                 'feFuncB'             => 'Misc',
                 'feFuncG'             => 'Misc',
                 'feFuncR'             => 'Misc',
                 'feGaussianBlur'      => 'FilterPrimitive',
                 'feImage'             => 'FilterPrimitive',
                 'feMerge'             => 'FilterPrimitive',
                 'feMergeNode'         => 'Misc',
                 'feMorphology'        => 'FilterPrimitive',
                 'feOffset'            => 'FilterPrimitive',
                 'fePointLight'        => 'Misc',
                 'feSpecularLighting'  => 'FilterPrimitive',
                 'feSpotLight'         => 'Misc',
                 'feTile'              => 'FilterPrimitive',
                 'feTurbulence'        => 'FilterPrimitive',
                 'filter'              => 'Filter',
                 'font'                => 'Font',
                 'font-face'           => 'Font',
                 'font-face-format'    => 'Misc',
                 'font-face-name'      => 'Misc',
                 'font-face-src'       => 'Misc',
                 'font-face-uri'       => 'Misc',
                 'foreignObject'       => 'Extensibility',
                 'g'                   => 'Structure',
                 'glyph'               => 'Misc',
                 'glyphRef'            => 'Misc',
                 'hkern'               => 'Misc',
                 'image'               => 'Image',
                 'line'                => 'Shape',
                 'linearGradient'      => 'Gradient',
                 'marker'              => 'Marker',
                 'mask'                => 'Mask',
                 'metadata'            => 'Description',
                 'missing-glyph'       => 'Misc',
                 'mpath'               => 'Misc',
                 'path'                => 'Shape',
                 'pattern'             => 'Pattern',
                 'polygon'             => 'Shape',
                 'polyline'            => 'Shape',
                 'radialGradient'      => 'Gradient',
                 'rect'                => 'Shape',
                 'script'              => 'Script',
                 'set'                 => 'Animation',
                 'stop'                => 'Misc',
                 'style'               => 'Style',
                 'svg'                 => 'Structure',
                 'switch'              => 'Conditional',
                 'symbol'              => 'Structure',
                 'text'                => 'Text',
                 'textPath'            => 'TextContent',
                 'title'               => 'Description',
                 'tref'                => 'TextContent',
                 'tspan'               => 'TextContent',
                 'use'                 => 'Use',
                 'view'                => 'View',
                 'vkern'               => 'Misc');

our %PCDATA = ('a'             => 1,
               'altGlyph'      => 1,
               'desc'          => 1,
               'foreignObject' => 1,
               'metadata'      => 1,
               'script'        => 1,
               'style'         => 1,
               'text'          => 1,
               'textPath'      => 1,
               'title'         => 1,
               'tspan'         => 1);

our %ATTR_VAL = ();

our %ATTR_HINTS = ();

sub _load_module {
    my ($element) = @_;

    return undef if(!$element or ref($element));

    if($CHILDREN{$element}) {
	if(ref($CHILDREN{$element}) eq 'HASH') { return 1 }
	else {
	    # if we arrive here the module has not been loaded
	    # load the module
	    my $prefix = 'SVG::Rasterize::Specification::';
	    my $module = "$prefix$CHILDREN{$element}";
	    eval "require $module";
	    SVG::Rasterize->ex_se_lo($module, $@) if($@);

	    # incorporate the values
	    {
		no strict 'refs';
		my $ch_name = "${module}::CHILDREN";
		my $av_name = "${module}::ATTR_VAL";
		my $ah_name = "${module}::ATTR_HINTS";
		foreach(keys %$ch_name) {
		    $CHILDREN{$element}   = $ch_name->{$element};
		    $ATTR_VAL{$element}   = $av_name->{$element};
		    $ATTR_HINTS{$element} = $ah_name->{$element};
		}
	    }
	    return 2;
	}
    }
    else { return undef }
}

sub spec_is_element {
    my ($element) = @_;

    return undef if(!$element or ref($element));
    return($CHILDREN{$element} ? 1 : 0);
}

sub spec_has_child {
    my ($parent, $child) = @_;

    return undef if(!$parent or ref($parent) or !$child or ref($child));
    return undef if(!exists($CHILDREN{$parent}));

    _load_module($parent);
    return($CHILDREN{$parent}->{$child} ? 1 : 0);
}

sub spec_has_pcdata {
    my ($element) = @_;

    return undef if(!$element or ref($element));
    return undef if(!exists($CHILDREN{$element}));
    return($PCDATA{$element} ? 1 : 0);
}

sub spec_has_attribute {
    my ($element, $attr) = @_;

    return undef if(!$element or ref($element) or !$attr or ref($attr));

    _load_module($element);
    return undef if(!exists($ATTR_VAL{$element}));  # after load!
    return($ATTR_VAL{$element}->{$attr} ? 1 : 0);
}

sub spec_attribute_validation {
    my ($element) = @_;

    return undef if(!$element or ref($element));

    _load_module($element);
    return undef if(!exists($ATTR_VAL{$element}));  # after load!
    return($ATTR_VAL{$element});
}

sub spec_attribute_hints {
    my ($element) = @_;

    return undef if(!$element or ref($element));

    _load_module($element);
    return undef if(!exists($ATTR_HINTS{$element}));  # after load!
    return($ATTR_HINTS{$element});
}

sub spec_is_length {
    my ($element, $attr) = @_;

    return undef if(!$element or ref($element) or !$attr or ref($attr));

    my $hints = spec_attribute_hints($element);
    
    return undef if(!defined($hints));
    return(($hints->{$attr} and $hints->{$attr}->{length}) ? 1 : 0);
}

sub spec_is_color {
    my ($element, $attr) = @_;

    return undef if(!$element or ref($element) or !$attr or ref($attr));

    my $hints = spec_attribute_hints($element);
    
    return undef if(!defined($hints));
    return(($hints->{$attr} and $hints->{$attr}->{color}) ? 1 : 0);
}

1;


__END__

=pod

=head1 DESCRIPTION

This file was automatically generated using the SVG DTD available
under
L<http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-flat-20030114.dtd>.

The data structures are used mainly by
L<SVG::Rasterize::State|SVG::Rasterize::State> for validation and
processing of the SVG input tree.

=head1 ADDITIONS

=head2 Datatypes

The datatypes are defined by entities in the DTD, but they all
expand to 'CDATA'. C<SVG::Rasterize> makes use of this finer
granularity of the DTD by overriding this entity expansion.

=head2 Classes

The C<SVG> elements are divided into classes in the DTD. This is
used to split the generated data structures into a set of
modules. Thus it is possible to load only those parts of the
specification that are needed for a specific C<SVG> document.

=head2 Additions

Some manual additions are made to the automatically generated data
structures. Currently, this is only the C<xmlns:svg> attribute which
is set by default by the C<SVG> module. I am not sure if this is
against the C<SVG> specification or not. The DTD allows to enable
prefixes which then might allow to set this attribute. Therefore, I
decided to allow it as well.


=head1 INTERFACE

As mentioned above, the data structures are distributed over several
modules in order to improve loading time of C<SVG::Rasterize>. The
price of this is that the data structures must not be accessed
directly. Instead, s set of subroutines handle the access and load
the required modules when necessary.

=head2 Subroutines offered for Import

Because of the length of the class name
C<SVG::Rasterize::Specification> I have decided to offer the
subroutines for import. However, to minimize the danger of name
clashes and to clearly label them for any reader of the code, the
subroutine names are prefixed with 'spec'.

The subroutines throw as few exceptions as possible. The only one is
if a necessary specification module cannot be loaded. Besides, the
subroutines return C<undef> on bad input. I see this behaviour
vindicated by the fact that these subroutines are deeply internal
and in the normal flow of the rasterization process the validity of
the parameters has already been checked upstream.

All subroutines return C<undef> if one of the parameters is C<undef>
or a reference. For the additional behaviour, see below.

=head3 spec_is_element

  spec_is_element($element_name)

Returns C<1> if there is an C<SVG> element of name C<$element_name>,
C<0> otherwise.

=head3 spec_has_child

  spec_has_child($parent_element_name, $child_element_name)

Returns C<undef> if there is no C<SVG> element of name
C<$parent_element_name>. Otherwise, returns C<1> if the element is
allowed to have child elements of name C<$child_element_name>, C<0>
if it is not allowed.

=head3 spec_has_pcdata

  spec_has_pcdata($element_name)

Returns C<undef> if there is no C<SVG> element of name
C<$element_name>. Otherwise, returns C<1> if the element is allowed
to contain parsed character data (other than white space), C<0> if
it is not allowed.

=head3 spec_has_attribute

  spec_has_attribute($element_name, $attribute_name)

Returns C<undef> if there is no C<SVG> element of name
C<$element_name>. Otherwise, returns C<1> if the element is allowed
to have an attribute of name C<$attribute_name>, C<0> if it is not
allowed.

=head3 spec_attribute_validation

  spec_attribute_validation($element_name)

Returns C<undef> if there is no C<SVG> element of name
C<$element_name>. Otherwise, returns a HASH reference that can be
passed to L<Params::Validate::validate|Params::Validate> or
L<Params::Validate::validate_with|Params::Validate> for validation
of an attribute hash.

=head3 spec_attribute_hints

  spec_attribute_hints($element_name)

Returns C<undef> if there is no C<SVG> element of name
C<$element_name>. Otherwise, returns a HASH reference with further
information about the element's attributes. If an attribute is a
color then the C<color> entry of the hash has value C<1>. If an
attribute is a length then the C<length> entry of the hash has value
C<1>.

=head3 spec_is_length

  spec_is_length($element_name, $attribute_name)

Returns C<undef> if there is no C<SVG> element of name
C<$element_name>. NB: Because most attributes have no hints only
those which have hints are present in the data structure. Therefore
it cannot be distinguished if an attribute is no length or if the
attribute is not an allowed attribute of the given element at
all. In both cases, C<0> is returned. If the attribute is a color,
C<1> is returned.

Only a few attributes change their behaviour depending on their
element. However, they exist. To be future safe, both the element
name and the attribute name have to be specified.

=head3 spec_is_color

  spec_is_color($element_name, $attribute_name)

As C<spec_is_length>.


=head1 ACKNOWLEDGEMENTS

The parsing of the C<SVG> DTD in order to generate the data
structures in this module was done using L<XML::DTD|XML::DTD> by
Brendt Wohlberg. Brendt was very responsive and helpful with all
issues that arose during the process of solving this task.


=head1 SEE ALSO

=over 4

=item * L<SVG::Rasterize|SVG::Rasterize>

=item * L<XML::DTD|XML::DTD>

=back


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
