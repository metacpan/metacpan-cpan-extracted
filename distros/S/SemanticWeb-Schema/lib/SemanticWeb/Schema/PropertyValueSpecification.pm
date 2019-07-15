use utf8;

package SemanticWeb::Schema::PropertyValueSpecification;

# ABSTRACT: A Property value specification.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'PropertyValueSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has default_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'defaultValue',
);



has max_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'maxValue',
);



has min_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'minValue',
);



has multiple_values => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'multipleValues',
);



has readonly_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'readonlyValue',
);



has step_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'stepValue',
);



has value_max_length => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'valueMaxLength',
);



has value_min_length => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'valueMinLength',
);



has value_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'valueName',
);



has value_pattern => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'valuePattern',
);



has value_required => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'valueRequired',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PropertyValueSpecification - A Property value specification.

=head1 VERSION

version v3.8.1

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

=head2 C<max_value>

C<maxValue>

The upper value of some characteristic or property.

A max_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<min_value>

C<minValue>

The lower value of some characteristic or property.

A min_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<multiple_values>

C<multipleValues>

Whether multiple values are allowed for the property. Default is false.

A multiple_values should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<readonly_value>

C<readonlyValue>

Whether or not a property is mutable. Default is false. Specifying this for
a property that also has a value makes it act similar to a "hidden" input
in an HTML form.

A readonly_value should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<step_value>

C<stepValue>

The stepValue attribute indicates the granularity that is expected (and
required) of the value in a PropertyValueSpecification.

A step_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<value_max_length>

C<valueMaxLength>

Specifies the allowed range for number of characters in a literal value.

A value_max_length should be one of the following types:

=over

=item C<Num>

=back

=head2 C<value_min_length>

C<valueMinLength>

Specifies the minimum allowed range for number of characters in a literal
value.

A value_min_length should be one of the following types:

=over

=item C<Num>

=back

=head2 C<value_name>

C<valueName>

Indicates the name of the PropertyValueSpecification to be used in URL
templates and form encoding in a manner analogous to HTML's input@name.

A value_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<value_pattern>

C<valuePattern>

Specifies a regular expression for testing literal values according to the
HTML spec.

A value_pattern should be one of the following types:

=over

=item C<Str>

=back

=head2 C<value_required>

C<valueRequired>

Whether the property must be filled in to complete the action. Default is
false.

A value_required should be one of the following types:

=over

=item C<Bool>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
