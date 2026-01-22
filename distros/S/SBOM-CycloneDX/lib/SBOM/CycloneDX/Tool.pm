package SBOM::CycloneDX::Tool;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has vendor  => (is => 'rw', isa => Str);
has name    => (is => 'rw', isa => Str);
has version => (is => 'rw', isa => Str);

has hashes => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Hash']],
    default => sub { SBOM::CycloneDX::List->new }
);

has external_references => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::ExternalReference']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{vendor}             = $self->vendor              if $self->vendor;
    $json->{name}               = $self->name                if $self->name;
    $json->{version}            = $self->version             if $self->version;
    $json->{hashes}             = $self->hashes              if @{$self->hashes};
    $json->{externalReferences} = $self->external_references if @{$self->external_references};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Tool - Tool (legacy, deprecated)

=head1 SYNOPSIS

    SBOM::CycloneDX::Tool->new();


=head1 DESCRIPTION

[Deprecated] This will be removed in a future version. Use component or service
instead. Information about the automated or manual tool used

=head2 METHODS

L<SBOM::CycloneDX::Tool> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Tool->new( %PARAMS )

Properties:

=over

=item * C<external_references>, External references provide a way to document
systems, sites, and information that may be relevant, but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item * C<hashes>, The hashes of the tool (if applicable).

=item * C<name>, The name of the tool

=item * C<vendor>, The name of the vendor who created the tool

=item * C<version>, The version of the tool

=back

=item $tool->external_references

=item $tool->hashes

=item $tool->name

=item $tool->vendor

=item $tool->version

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
