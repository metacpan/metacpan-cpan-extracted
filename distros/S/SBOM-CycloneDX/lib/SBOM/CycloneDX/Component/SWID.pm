package SBOM::CycloneDX::Component::SWID;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has tag_id      => (is => 'rw', isa => Str, required => 1);
has name        => (is => 'rw', isa => Str, required => 1);
has version     => (is => 'rw', isa => Str);
has tag_version => (is => 'rw', isa => Str);
has patch       => (is => 'rw', isa => Str);
has text        => (is => 'rw', isa => Str);
has url         => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {tagId => $self->tag_id, name => $self->name};

    $json->{version}    = $self->version     if $self->version;
    $json->{tagVersion} = $self->tag_version if $self->tag_version;
    $json->{patch}      = $self->patch       if $self->patch;
    $json->{text}       = $self->text        if $self->text;
    $json->{url}        = $self->url         if $self->url;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::SWID - SWID Tag

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::SWID->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::SWID> specifies metadata and content for
ISO-IEC 19770-2 Software Identification (SWID) Tags.

=head2 METHODS

L<SBOM::CycloneDX::Component::SWID> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::SWID->new( %PARAMS )

Properties:

=over

=item C<name>, Maps to the name of a SoftwareIdentity.

=item C<patch>, Maps to the patch of a SoftwareIdentity.

=item C<tag_id>, Maps to the tagId of a SoftwareIdentity.

=item C<tag_version>, Maps to the tagVersion of a SoftwareIdentity.

=item C<text>, Specifies the metadata and content of the SWID tag.

=item C<url>, The URL to the SWID file.

=item C<version>, Maps to the version of a SoftwareIdentity.

=back

=item $swid->name

=item $swid->patch

=item $swid->tag_id

=item $swid->tag_version

=item $swid->text

=item $swid->url

=item $swid->version

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
