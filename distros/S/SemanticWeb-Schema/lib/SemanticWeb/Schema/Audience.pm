use utf8;

package SemanticWeb::Schema::Audience;

# ABSTRACT: Intended audience for an item, i

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Audience';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has audience_type => (
    is        => 'rw',
    predicate => '_has_audience_type',
    json_ld   => 'audienceType',
);



has geographic_area => (
    is        => 'rw',
    predicate => '_has_geographic_area',
    json_ld   => 'geographicArea',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Audience - Intended audience for an item, i

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

Intended audience for an item, i.e. the group for whom the item was
created.

=head1 ATTRIBUTES

=head2 C<audience_type>

C<audienceType>

The target group associated with a given audience (e.g. veterans, car
owners, musicians, etc.).

A audience_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_audience_type>

A predicate for the L</audience_type> attribute.

=head2 C<geographic_area>

C<geographicArea>

The geographic area associated with the audience.

A geographic_area should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=back

=head2 C<_has_geographic_area>

A predicate for the L</geographic_area> attribute.

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
