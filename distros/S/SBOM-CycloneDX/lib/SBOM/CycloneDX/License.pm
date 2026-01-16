package SBOM::CycloneDX::License;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;
use SBOM::CycloneDX::License::Licensing;

use Carp;
use List::Util      qw(first);
use Types::Standard qw(Str Enum InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

use constant DEBUG => $ENV{SBOM_DEBUG} || 0;

# TODO Incomplete

around BUILDARGS => sub {

    my ($orig, $class, @args) = @_;

    if (@args == 1 && defined $args[0] && !ref $args[0]) {

        my $license = $args[0];
        $license =~ s/^\s+|\s+$//g;

        if ($license =~ /(\bWITH\b|\bOR\b|\bAND\b)/i) {
            return {expression => $license};
        }
        else {
            return {id => $license};
        }
    }

    return $class->$orig(@args);

};

extends 'SBOM::CycloneDX::Base';

sub BUILD {
    my ($self, $args) = @_;
    Carp::croak('"id" and "name" cannot be used at the same time') if exists $args->{id} && exists $args->{name};
}

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has id              => (is => 'rw', isa => Str, trigger => 1);
has name            => (is => 'rw', isa => Str);
has acknowledgement => (is => 'rw', isa => Enum [qw(declared concluded)]);
has text            => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Attachment']);
has url             => (is => 'rw', isa => Str, trigger => 1);
has expression      => (is => 'rw', isa => Str);    # TODO check SPDX expression

has expression_details => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::License::ExpressionDetail']],
    default => sub { SBOM::CycloneDX::List->new }
);

has licensing => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::License::Licensing'],
    default => sub { SBOM::CycloneDX::License::Licensing->new }
);

has properties => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']],
    default => sub { SBOM::CycloneDX::List->new }
);


sub _trigger_id {

    my ($self) = @_;

    if ($self->id && $self->id =~ /(\bWITH\b|\bOR\b|\bAND\b)/i) {
        DEBUG and say STDERR '-- Detected SPDX expression';
        $self->expression($self->id);
        $self->{id} = undef;
    }

    if ($self->id && $self->id =~ /^(NOASSERTION|NONE)$/) {
        DEBUG and say STDERR "-- Detected $1 license identifier (unset license identifier)";
        $self->{id} = undef;
    }

}


sub _trigger_url {
    my ($self) = @_;
    $self->url('https://opensource.org/license/' . $self->id) if $self->url eq '1';
}

sub TO_JSON {

    my $self = shift;

    my $json = {};

    if ($self->expression) {
        $json->{expression}      = $self->expression;
        $json->{acknowledgement} = $self->acknowledgement if $self->acknowledgement;
        $json->{'bom-ref'}       = $self->bom_ref         if $self->bom_ref;
    }
    else {

        my $spdx_license = $self->id;
        my $license_name = $self->name;

        if (defined $spdx_license and not first { $_ eq $spdx_license } @{SBOM::CycloneDX::Enum->SPDX_LICENSES()}) {
            DEBUG and say STDERR "-- SPDX license not found ($spdx_license)";
        }

        $json->{license} = {};

        $json->{license}->{id}   = $spdx_license if $spdx_license;
        $json->{license}->{name} = $license_name if $license_name;

        $json->{license}->{'bom-ref'}         = $self->bom_ref            if $self->bom_ref;
        $json->{license}->{acknowledgement}   = $self->acknowledgement    if $self->acknowledgement;
        $json->{license}->{text}              = $self->text               if $self->text;
        $json->{license}->{url}               = $self->url                if $self->url;
        $json->{license}->{properties}        = $self->properties         if @{$self->properties};
        $json->{license}->{licensing}         = $self->licensing          if %{$self->licensing->TO_JSON};
        $json->{license}->{expressionDetails} = $self->expression_details if @{$self->expression_details};

    }

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::License - Specifies the details and attributes related to a software license

=head1 SYNOPSIS

    # SPDX license

    $license = SBOM::CycloneDX::License->new(
        id => 'Apache-2.0'
    );

    # or

    $license = SBOM::CycloneDX::License->new('MIT');

    # SPDX license expression

    $license = SBOM::CycloneDX::License->new(
        expression => 'MIT AND (LGPL-2.1-or-later OR BSD-3-Clause)'
    );

    # or

    $license = SBOM::CycloneDX::License->new('MIT AND (LGPL-2.1-or-later OR BSD-3-Clause)');

    # Non-SPDX license

    $license = SBOM::CycloneDX::License->new(
        name => 'Acme Software License'
    );


=head1 DESCRIPTION

L<SBOM::CycloneDX::License> specifies the details and attributes related to a software
license.

It can either include a valid SPDX license identifier or a named license,
along with additional properties such as license acknowledgment, comprehensive
commercial licensing information, and the full text of the license.

=head2 METHODS

L<SBOM::CycloneDX::License> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::License->new( $id | $expression | %PARAMS )

Properties:

=over

=item * C<bom_ref>, An identifier which can be used to reference the license
elsewhere in the BOM. Every bom-ref must be unique within the BOM.

Value SHOULD not start with the BOM-Link intro C<urn:cdx:> to avoid conflicts with BOM-Links.

=item * C<id>, A valid SPDX license identifier. If specified, this value must be
one of the enumeration of valid SPDX license identifiers defined in L<SBOM::CycloneDX::Enum> C<SPDX_LICENSES>.

=item * C<expression>, A tuple of exactly one SPDX License Expression.

Refer to L<https://spdx.org/specifications> for syntax requirements.

=item * C<expression_details>, Details for parts of the C<expression>.

See L<SBOM::CycloneDX::License::ExpressionDetail>

=item * C<name>, The name of the license. This may include the name of a commercial
or proprietary license or an open source license that may not be defined by SPDX.

=item * C<acknowledgement>, 

=item * C<text>, An way to include the textual content of a license.
See L<SBOM::CycloneDX::Attachment>

=item * C<url>, The URL to the license file. If C<1> is provided, the license URL is
automatically generated.

=item * C<licensing>, Declared licenses and concluded licenses represent two different
stages in the licensing process within software development. Declared licenses refer
to the initial intention of the software authors regarding the licensing terms
under which their code is released. On the other hand, concluded licenses are the
result of a comprehensive analysis of the project's codebase to identify and confirm
the actual licenses of the components used, which may differ from the initially
declared licenses. While declared licenses provide an upfront indication of the
licensing intentions, concluded licenses offer a more thorough understanding of
the actual licensing within a project, facilitating proper compliance and risk
management. Observed licenses are defined in C<$bom->evidence->licenses>. Observed
licenses form the evidence necessary to substantiate a concluded license.

See L<SBOM::CycloneDX::License::Licensing>


=item * C<properties>, Provides the ability to document properties in a name-value
store. This provides flexibility to include data not officially supported in the
standard without having to use additional namespaces or create extensions.
Unlike key-value stores, properties support duplicate names, each potentially
having different values. Property names of interest to the general public are
encouraged to be registered in the CycloneDX Property Taxonomy. Formal
registration is optional. See L<SBOM::CycloneDX::Property>

=back

=item $license->bom_ref

=item $license->id

    # SPDX license

    $license = SBOM::CycloneDX::License->new(
        id => 'Apache-2.0'
    );

    # or

    $license = SBOM::CycloneDX::License->new('MIT');

=item $license->name

=item $license->acknowledgement

=item $license->text

    $license->text(SBOM::CycloneDX::Attachment(file => '/path/LICENSE.md'));

=item $license->url

=item $license->expression

    # SPDX license expression

    $license = SBOM::CycloneDX::License->new(
        expression => 'MIT AND (LGPL-2.1-or-later OR BSD-3-Clause)'
    );

    # or

    $license = SBOM::CycloneDX::License->new('MIT AND (LGPL-2.1-or-later OR BSD-3-Clause)');

=item $license->expression_details

=item $license->licensing

    $license->licensing->alt_ids(['acme', 'acme-license']);


    $licensing = SBOM::CycloneDX::License::Licensing->new(
        alt_ids        => ['acme', 'acme-license'],
        purchase_order => 'PO-12345',
        license_types  => ['appliance'],
    );

    $license->licensing($licensing);

=item $license->properties

    $license->properties->add(SBOM::CycloneDX::Property->new(name => 'foo', value => 'bar'));

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
