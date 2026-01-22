package SBOM::CycloneDX::Version;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str Enum InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

sub BUILD {
    my ($self, $args) = @_;
    Carp::croak('"version" and "range" cannot be used at the same time')
        if exists $args->{version} && exists $args->{range};
}

has version => (is => 'rw', isa => Str);
has range   => (is => 'rw', isa => InstanceOf ['URI::VersionRange'], coerce => sub { _vers_parse($_[0]) });
has status  => (is => 'rw', isa => Enum [qw(affected unaffected unknown)]);

sub _vers_parse {

    my $vers = shift;

    return $vers if (ref $vers eq 'URI::VersionRange');
    return URI::VersionRange->from_string($vers);

}

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{versions} = $self->versions         if $self->versions;
    $json->{range}    = $self->range->to_string if $self->range;
    $json->{status}   = $self->status           if $self->status;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Version - Version

=head1 SYNOPSIS

    SBOM::CycloneDX::Version->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Version> provide the version object.

=head2 METHODS

L<SBOM::CycloneDX::Version> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Version->new( %PARAMS )

Properties:

=over

=item * C<range>, A version range specified in Package URL Version Range
syntax (vers) which is defined at
L<https://github.com/package-url/purl-spec/blob/master/VERSION-RANGE-SPEC.rst>

=item * C<status>, The vulnerability status for the version or range of
versions.

=item * C<version>, A single version of a component or service.

=back

=item $version->range

=item $version->status

=item $version->version

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
