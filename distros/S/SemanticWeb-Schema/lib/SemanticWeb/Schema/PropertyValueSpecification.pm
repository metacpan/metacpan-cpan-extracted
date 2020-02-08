use utf8;

package SemanticWeb::Schema::PropertyValueSpecification;

# ABSTRACT: A Property value specification.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'PropertyValueSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has default_value => (
    is        => 'rw',
    predicate => '_has_default_value',
    json_ld   => 'defaultValue',
);



has max_value => (
    is        => 'rw',
    predicate => '_has_max_value',
    json_ld   => 'maxValue',
);



has min_value => (
    is        => 'rw',
    predicate => '_has_min_value',
    json_ld   => 'minValue',
);



has multiple_values => (
    is        => 'rw',
    predicate => '_has_multiple_values',
    json_ld   => 'multipleValues',
);



has readonly_value => (
    is        => 'rw',
    predicate => '_has_readonly_value',
    json_ld   => 'readonlyValue',
);



has step_value => (
    is        => 'rw',
    predicate => '_has_step_value',
    json_ld   => 'stepValue',
);



has value_max_length => (
    is        => 'rw',
    predicate => '_has_value_max_length',
    json_ld   => 'valueMaxLength',
);



has value_min_length => (
    is        => 'rw',
    predicate => '_has_value_min_length',
    json_ld   => 'valueMinLength',
);



has value_name => (
    is        => 'rw',
    predicate => '_has_value_name',
    json_ld   => 'valueName',
);



has value_pattern => (
    is        => 'rw',
    predicate => '_has_value_pattern',
    json_ld   => 'valuePattern',
);



has value_required => (
    is        => 'rw',
    predicate => '_has_value_required',
    json_ld   => 'valueRequired',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PropertyValueSpecification - A Property value specification.

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

A Property value specification.

=head1 ATTRIBUTES

=head2 C<default_value>

C<defaultValue>

The default value of the input. For properties that expect a literal, the
default is a literal value, for properties that expect an object, it's an
ID reference to one of the current values.

A default_value should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<_has_default_value>

A predicate for the L</default_value> attribute.

=head2 C<max_value>

C<maxValue>

The upper value of some characteristic or property.

A max_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_max_value>

A predicate for the L</max_value> attribute.

=head2 C<min_value>

C<minValue>

The lower value of some characteristic or property.

A min_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_min_value>

A predicate for the L</min_value> attribute.

=head2 C<multiple_values>

C<multipleValues>

Whether multiple values are allowed for the property. Default is false.

A multiple_values should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_multiple_values>

A predicate for the L</multiple_values> attribute.

=head2 C<readonly_value>

C<readonlyValue>

Whether or not a property is mutable. Default is false. Specifying this for
a property that also has a value makes it act similar to a "hidden" input
in an HTML form.

A readonly_value should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_readonly_value>

A predicate for the L</readonly_value> attribute.

=head2 C<step_value>

C<stepValue>

The stepValue attribute indicates the granularity that is expected (and
required) of the value in a PropertyValueSpecification.

A step_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_step_value>

A predicate for the L</step_value> attribute.

=head2 C<value_max_length>

C<valueMaxLength>

Specifies the allowed range for number of characters in a literal value.

A value_max_length should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_value_max_length>

A predicate for the L</value_max_length> attribute.

=head2 C<value_min_length>

C<valueMinLength>

Specifies the minimum allowed range for number of characters in a literal
value.

A value_min_length should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_value_min_length>

A predicate for the L</value_min_length> attribute.

=head2 C<value_name>

C<valueName>

Indicates the name of the PropertyValueSpecification to be used in URL
templates and form encoding in a manner analogous to HTML's input@name.

A value_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_value_name>

A predicate for the L</value_name> attribute.

=head2 C<value_pattern>

C<valuePattern>

Specifies a regular expression for testing literal values according to the
HTML spec.

A value_pattern should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_value_pattern>

A predicate for the L</value_pattern> attribute.

=head2 C<value_required>

C<valueRequired>

Whether the property must be filled in to complete the action. Default is
false.

A value_required should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_value_required>

A predicate for the L</value_required> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
