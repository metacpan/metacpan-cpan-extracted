package SBOM::CycloneDX::Component::Patch;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf Enum);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has type     => (is => 'rw', isa => Enum [qw(unofficial monkey backport cherry-pick)]);
has diff     => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component::Diff']);
has resolves => (is => 'rw', isa => ArrayLike [InstanceOf ['SBOM::CycloneDX::Issue']]);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{type}     = $self->type     if $self->type;
    $json->{diff}     = $self->diff     if $self->diff;
    $json->{resolves} = $self->resolves if @{$self->resolves};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::Patch - Patch

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::Patch->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::Patch> specifies an individual patch

=head2 METHODS

L<SBOM::CycloneDX::Component::Patch> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::Patch->new( %PARAMS )

Properties:

=over

=item C<diff>, The patch file (or diff) that shows changes. Refer to
L<https://en.wikipedia.org/wiki/Diff>

=item C<resolves>, A collection of issues the patch resolves

=item C<type>, Specifies the purpose for the patch including the resolution
of defects, security issues, or new behavior or functionality.

=back

=item $patch->diff

=item $patch->resolves

=item $patch->type

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
