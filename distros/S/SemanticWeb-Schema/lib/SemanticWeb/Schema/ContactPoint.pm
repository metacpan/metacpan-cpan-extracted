use utf8;

package SemanticWeb::Schema::ContactPoint;

# ABSTRACT: A contact point&#x2014;for example

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'ContactPoint';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has area_served => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'areaServed',
);



has available_language => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableLanguage',
);



has contact_option => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'contactOption',
);



has contact_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'contactType',
);



has email => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'email',
);



has fax_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'faxNumber',
);



has hours_available => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hoursAvailable',
);



has product_supported => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'productSupported',
);



has service_area => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'serviceArea',
);



has telephone => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'telephone',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ContactPoint - A contact point&#x2014;for example

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A contact point&#x2014;for example, a Customer Complaints department.

=head1 ATTRIBUTES

=head2 C<area_served>

C<areaServed>

The geographic area where a service or offered item is provided.

A area_served should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<available_language>

C<availableLanguage>

=for html A language someone may use with or at the item, service or place. Please
use one of the language codes from the <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard</a>. See also
<a class="localLink" href="http://schema.org/inLanguage">inLanguage</a>

A available_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=item C<Str>

=back

=head2 C<contact_option>

C<contactOption>

An option available on this contact point (e.g. a toll-free number or
support for hearing-impaired callers).

A contact_option should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPointOption']>

=back

=head2 C<contact_type>

C<contactType>

A person or organization can have different contact points, for different
purposes. For example, a sales contact point, a PR contact point and so on.
This property is used to specify the kind of contact point.

A contact_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<email>

Email address.

A email should be one of the following types:

=over

=item C<Str>

=back

=head2 C<fax_number>

C<faxNumber>

The fax number.

A fax_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<hours_available>

C<hoursAvailable>

The hours during which this service or contact is available.

A hours_available should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::OpeningHoursSpecification']>

=back

=head2 C<product_supported>

C<productSupported>

The product or service this support contact point is related to (such as
product support for a particular product line). This can be a specific
product or product line (e.g. "iPhone") or a general category of products
or services (e.g. "smartphones").

A product_supported should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<Str>

=back

=head2 C<service_area>

C<serviceArea>

The geographic area where the service is provided.

A service_area should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<telephone>

The telephone number.

A telephone should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

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
