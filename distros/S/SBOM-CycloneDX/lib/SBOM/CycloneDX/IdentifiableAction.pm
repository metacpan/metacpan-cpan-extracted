package SBOM::CycloneDX::IdentifiableAction;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has timestamp => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has name  => (is => 'rw', isa => Str);
has email => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{timestamp} = $self->timestamp if $self->timestamp;
    $json->{name}      = $self->name      if $self->name;
    $json->{email}     = $self->email     if $self->email;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::IdentifiableAction - Identifiable Action

=head1 SYNOPSIS

    SBOM::CycloneDX::IdentifiableAction->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::IdentifiableAction> specifies an individual commit.

=head2 METHODS

L<SBOM::CycloneDX::IdentifiableAction> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::IdentifiableAction->new( %PARAMS )

Properties:

=over

=item C<email>, The email address of the individual who performed the
action

=item C<name>, The name of the individual who performed the action

=item C<timestamp>, The timestamp in which the action occurred

=back

=item $identifiable_action->email

=item $identifiable_action->name

=item $identifiable_action->timestamp

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
