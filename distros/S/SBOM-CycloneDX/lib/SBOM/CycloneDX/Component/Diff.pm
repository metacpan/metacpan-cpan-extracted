package SBOM::CycloneDX::Component::Diff;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has text => (is => 'rw', isa => Str);
has url  => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{text} = $self->text if $self->text;
    $json->{url}  = $self->url  if $self->url;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::Diff - Diff

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::Diff->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::Diff> provides the patch file (or diff) that shows
changes. Refer to L<https://en.wikipedia.org/wiki/Diff>

=head2 METHODS

L<SBOM::CycloneDX::Component::Diff> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::Diff->new( %PARAMS )

Properties:

=over

=item * C<text>, Specifies the text of the diff

=item * C<url>, Specifies the URL to the diff

=back

=item $diff->text

=item $diff->url

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
