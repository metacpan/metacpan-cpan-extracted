package SBOM::CycloneDX::Property;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has name => (is => 'rw', isa => Str, required => 1);
has value => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {name => $self->name};

    $json->{value} = $self->value if $self->value;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Property - Provides the ability to document properties in a
name-value store

=head1 SYNOPSIS

    $bom->properties->add(
        SBOM::CycloneDX::Property->new( name => 'Foo', value => 'Bar' )
    );


=head1 DESCRIPTION

L<SBOM::CycloneDX::Manufacture> provides the ability to document properties in a
name-value store. This provides flexibility to include data not officially
supported in the standard without having to use additional namespaces or create
extensions. Unlike key-value stores, properties support duplicate names, each
potentially having different values. Property names of interest to the general
public are encouraged to be registered in the CycloneDX Property Taxonomy
(L<https://github.com/CycloneDX/cyclonedx-property-taxonomy>).

Formal registration is optional. Each item of this array must be a Lightweight
name-value pair object.

=head2 METHODS

L<SBOM::CycloneDX::Property> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Property->new( %PARAMS )

Properties:

=over

=item * C<name>, The name of the property. Duplicate names are allowed, each
potentially having a different value.

=item * C<value>, The value of the property.

=back

=item $property->name

=item $property->value

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
