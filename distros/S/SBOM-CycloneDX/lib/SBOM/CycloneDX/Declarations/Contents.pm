package SBOM::CycloneDX::Declarations::Contents;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has attachment => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Attachment']);
has url        => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{attachment} = $self->attachment if $self->attachment;
    $json->{url}        = $self->url        if $self->url;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Contents - Data Contents

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Contents->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Contents> provide the contents or references to
the contents of the data being described.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Contents> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Contents->new( %PARAMS )

Properties:

=over

=item C<attachment>, An optional way to include textual or encoded data.

=item C<url>, The URL to where the data can be retrieved.

=back

=item $contents->attachment

=item $contents->url

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

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
