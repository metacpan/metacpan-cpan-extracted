package SBOM::CycloneDX::Schema;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter qw(import);

our @EXPORT = qw(
    schema_dir
    schema_file
);

use SBOM::CycloneDX;

use File::Basename        qw(dirname);
use File::Spec::Functions qw(catfile);
use JSON::Validator;

use Types::Standard qw(HashRef InstanceOf);

use Moo;

use constant DEBUG => $ENV{SBOM_DEBUG} || 0;

our @JSON_SCHEMA_REGISTRY = (
    'bom-1.2-strict.schema.json', 'bom-1.2.schema.json', 'bom-1.3-strict.schema.json', 'bom-1.3.schema.json',
    'bom-1.4.schema.json',        'bom-1.5.schema.json', 'bom-1.6.schema.json',        'bom-1.7.schema.json',
    'jsf-0.82.schema.json',       'spdx.schema.json',    'cryptography-defs.schema.json'
);

has bom => (is => 'ro', isa => InstanceOf ['SBOM::CycloneDX'] | HashRef, required => 1);

sub schema_dir  { catfile(dirname(__FILE__), 'schema') }
sub schema_file { catfile(schema_dir,        shift) }

sub validator {

    my ($self) = @_;

    my $jv = JSON::Validator->new;

    foreach my $json_schema_file (@JSON_SCHEMA_REGISTRY) {
        DEBUG and say sprintf('-- Preload JSON Schema file %s', $json_schema_file);
        $jv->store->load(schema_file($json_schema_file));
    }

    my $spec_version          = (ref $self->bom eq 'HASH') ? $self->bom->{specVersion} : $self->bom->spec_version;
    my $cyclonedx_json_schema = $SBOM::CycloneDX::JSON_SCHEMA{$spec_version};

    DEBUG and say sprintf('-- Use %s JSON schema for validation', $cyclonedx_json_schema);

    $jv->schema($cyclonedx_json_schema)->schema->coerce('bool,num');

    return $jv;

}

sub validate {
    my ($self) = @_;
    return $self->validator->validate($self->bom);
}


1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Schema - JSON Schema Validator

=head1 SYNOPSIS

    use SBOM::CycloneDX::Schema;

    my $validator = SBOM::CycloneDX::Schema->new(bom => sbom);

    my @errors = $validator->validate;

    say $_ for @errors;


=head1 DESCRIPTION

Validate CycloneDX objects using JSON Schema.

=head2 METHODS

=over

=item SBOM::CycloneDX::Schema->new(object => $object)

=item $schema->bom

L<SBOM::CycloneDX> instance or HASH.

=item $schema->validator

Return L<JSON::Validator> object.

=item $schema->validate

Validate and return the L<JSON::Validator> errors.

=back

=head2 FUNCTIONS

=over

=item schema_dir

Return the CycloneDX schema path.

=item schema_file ($json_schema_file)

Return the CycloneDX schema file path.

    schema_file('bom-1.6.schema.json'); # ../SBOM/CycloneDX/schema/bom-1.6.schema.json

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
