use utf8;

package SemanticWeb::Schema::GovernmentService;

# ABSTRACT: A service provided by a government organization

use Moo;

extends qw/ SemanticWeb::Schema::Service /;


use MooX::JSON_LD 'GovernmentService';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has jurisdiction => (
    is        => 'rw',
    predicate => '_has_jurisdiction',
    json_ld   => 'jurisdiction',
);



has service_operator => (
    is        => 'rw',
    predicate => '_has_service_operator',
    json_ld   => 'serviceOperator',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::GovernmentService - A service provided by a government organization

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A service provided by a government organization, e.g. food stamps, veterans
benefits, etc.

=head1 ATTRIBUTES

=head2 C<jurisdiction>

Indicates a legal jurisdiction, e.g. of some legislation, or where some
government service is based.

A jurisdiction should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=item C<Str>

=back

=head2 C<_has_jurisdiction>

A predicate for the L</jurisdiction> attribute.

=head2 C<service_operator>

C<serviceOperator>

The operating organization, if different from the provider. This enables
the representation of services that are provided by an organization, but
operated by another organization like a subcontractor.

A service_operator should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_service_operator>

A predicate for the L</service_operator> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Service>

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
