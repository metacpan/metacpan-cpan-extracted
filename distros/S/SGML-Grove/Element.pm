#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Element.pm,v 1.2 1998/01/18 00:21:13 ken Exp $
#


package SGML::Element;

use strict;
use Class::Visitor;

visitor_class 'SGML::Element', 'Class::Visitor::Base',
    [
     'contents' => '@',		# [0]
     'gi' => '$',		# [1]
     'attributes' => '@',	# [2]
    ];

=head1 NAME

SGML::Element - an element of an SGML, XML, or HTML document

=head1 SYNOPSIS

  $element->gi;
  $element->name;
  $element->attr ($attr[, $value]);
  $element->attr_as_string ($attr[, $context, ...]);
  $element->attributes [($attributes)];
  $element->contents [($contents)];

  $element->as_string([$context, ...]);

  $element->iter;

  $element->accept($visitor, ...);
  $element->accept_gi($visitor, ...);
  $element->children_accept($visitor, ...);
  $element->children_accept_gi($visitor, ...);

=head1 DESCRIPTION

An C<SGML::Element> represents an element in an SGML or XML document.
An Element contains a generic identifier, or name, for the element,
the elements attributes and the ordered contents of the element.

C<$element-E<gt>gi> and C<$element-E<gt>name> are synonyms, they
return the generic identifier of the element.

C<$element-E<gt>attr> returns the value of an attribute, if a second
argument is given then that value is assigned to the attribute and
returned.  The value of an attribute may be an array of scalar or
C<SGML::SData> objects, an C<SGML::Notation>, or an array of
C<SGML::Entity> or C<SGML::ExtEntity> objects.  C<attr> returns
C<undef> for implied attributes.

C<$element-E<gt>attr_as_string> returns the value of an attribute as a
string, possibly modified by C<$context>. (XXX undefined results if
the attribute is not cdata/sdata.)

C<$element-E<gt>attributes> returns a reference to a hash containing
the attributes of the element, or undef if there are no attributes
defined for for this element.  The keys of the hash are the attribute
names and the values are as defined above.
C<$element-E<gt>attributes($attributes)> assigns the attributes from
the hash C<$attributes>.  No hash entries are made for implied
attributes.

C<$element-E<gt>contents> returns a reference to an array containing
the children of the element.  The contents of the element may contain
other elements, scalars, C<SGML::SData>, C<SGML::PI>, C<SGML::Entity>,
C<SGML::ExtEntity>, or C<SGML::SubDocEntity> objects.
C<$element-E<gt>contents($contents)> assigns the contents from the
array C<$contents>.

C<$element-E<gt>as_string> returns the entire hierarchy of this
element as a string, possibly modified by C<$context>.  See
L<SGML::SData> and L<SGML::PI> for more detail.  (XXX does not expand
entities.)

C<$element-E<gt>iter> returns an iterator for the element, see
C<Class::Visitor> for details.

C<$element-E<gt>accept($visitor[, ...])> issues a call back to
S<C<$visitor-E<gt>visit_SGML_Element($element[, ...])>>.  See examples
C<visitor.pl> and C<simple-dump.pl> for more information.

C<$element-E<gt>accept_gi($visitor[, ...])> issues a call back to
S<C<$visitor-E<gt>visit_gi_I<GI>($element[, ...])>> where I<GI> is the
generic identifier of this element.  C<accept_gi> maps strange
characters in the GI to underscore (`_') [XXX more specific].

C<children_accept> and C<children_accept_gi> call C<accept> and
C<accept_gi>, respectively, on each object in the element's content.

Element handles scalars internally for C<as_string>,
C<children_accept>, and C<children_accept_gi>.  For C<children_accept>
and C<children_accept_gi> (both), Element calls back with
S<C<$visitor-E<gt>visit_scalar($scalar[, ...])>>.

For C<as_string>, Element will use the string unless
C<$context-E<gt>{cdata_mapper}> is defined, in which case it returns the
result of calling the C<cdata_mapper> subroutine with the scalar and
the remaining arguments.  The actual implementation is:

    &{$context->{cdata_mapper}} ($scalar, @_);

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), SGML::Grove(3), Text::EntityMap(3), SGML::SData(3),
SGML::PI(3), Class::Visitor(3).

=cut

sub name {
    gi(@_);
}

sub attr {
    my $self = shift;
    my $attr = shift;

    if (@_) {
	my $value = shift;
	if (ref ($value) eq 'ARRAY') {
	    return $self->[2]->{$attr} = $value;
	} else {
	    return $self->[2]->{$attr} = [$value];
	}	    
    } else {
	if (!defined $self->[2]) {
	    return undef;
	} else {
	    return $self->[2]->{$attr};
	}
    }
}

# $element->attr_as_string($attr[, $context]);
sub attr_as_string {
    my $self = shift;
    my $attr = shift;

    my $attributes = $self->[2];
    return "" if (!defined $attributes);

    my $value = $attributes->{$attr};
    return "" if (!defined($value));
    return $value if (!ref ($value)); # return tokens

    my ($ii, @string);
    for ($ii = 0; $ii <= $#{$value}; $ii ++) {
	my $child = $value->[$ii];
	if (!ref ($child)) {
	    my $context = shift;
	    if (defined ($context->{'cdata_mapper'})) {
		push (@string, &{$context->{'cdata_mapper'}}($child, @_));
	    } else {
		push (@string, $child);
	    }
	} else {
	    push (@string, $child->as_string(@_));
	}
    }
    return (join ("", @string));
}

# $element->as_string($context);
sub as_string {
    my $self = shift;
    my $context = shift;

    my @string;
    my $ii;
    for ($ii = 0; $ii <= $#{$self->[0]}; $ii ++) {
	my $child = $self->[0][$ii];
	if (!ref ($child)) {
	    if (defined ($context->{'cdata_mapper'})) {
		push (@string, &{$context->{'cdata_mapper'}}($child, @_));
	    } else {
		push (@string, $child);
	    }
	} else {
	    push (@string, $child->as_string($context, @_));
	}
    }
    return (join ("", @string));
}

sub accept_gi {
    my $self = shift;
    my $visitor = shift;

    my $gi = $self->gi;

    # convert all non-word characters to `_' (matched in
    # SpecBuilder.pm)
    $gi =~ s/\W/_/g;
    my $alias = "visit_gi_" . $gi;
    $visitor->$alias ($self, @_);
}

sub children_accept_gi {
    my $self = shift;
    my $visitor = shift;

    my $ii;
    for ($ii = 0; $ii <= $#{$self->[0]}; $ii ++) {
	my $child = $self->[0][$ii];
	if (!ref ($child)) {
	    $visitor->visit_scalar ($child, @_);
	} else {
	    $child->accept_gi ($visitor, @_);
	}
    }
}

1;
