package SBOM::CycloneDX::Standard::Level;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has identifier   => (is => 'rw', isa => Str);
has title        => (is => 'rw', isa => Str);
has description  => (is => 'rw', isa => Str);
has requirements => (is => 'rw', isa => ArrayLike [Str]);    # Like bom-ref

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}    = $self->bom_ref      if $self->bom_ref;
    $json->{identifier}   = $self->identifier   if $self->identifier;
    $json->{title}        = $self->title        if $self->title;
    $json->{description}  = $self->description  if $self->description;
    $json->{requirements} = $self->requirements if @{$self->requirements};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Standard::Level - Standard Level

=head1 SYNOPSIS

    SBOM::CycloneDX::Standard::Level->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Standard::Level> provides the level associated with the standard.
Some standards have different levels of compliance.

=head2 METHODS

L<SBOM::CycloneDX::Standard::Level> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Standard::Level->new( %PARAMS )

Properties:

=over

=item * C<bom_ref>, An identifier which can be used to reference the
object elsewhere in the BOM. Every bom-ref must be unique within the BOM.

=item * C<description>, The description of the level.

=item * C<identifier>, The identifier used in the standard to identify a
specific level.

=item * C<requirements>, The list of requirement `bom-ref`s that comprise the
level.

=item * C<title>, The title of the level.

=back

=item $level->bom_ref

=item $level->description

=item $level->identifier

=item $level->requirements

=item $level->title

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
