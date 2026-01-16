package SBOM::CycloneDX::Declarations::Data;

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

has name           => (is => 'rw', isa => Str);
has contents       => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Declarations::Contents']);
has classification => (is => 'rw', isa => Str);
has sensitive_data => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });
has governance     => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::DataGovernance']);


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{name}           = $self->name           if $self->name;
    $json->{contents}       = $self->contents       if $self->contents;
    $json->{classification} = $self->classification if $self->classification;
    $json->{sensitiveData}  = $self->sensitive_data if @{$self->sensitive_data};
    $json->{governance}     = $self->governance     if $self->governance;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Declarations::Data - Data

=head1 SYNOPSIS

    SBOM::CycloneDX::Declarations::Data->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Declarations::Data> provides the output or analysis that
supports claims.

=head2 METHODS

L<SBOM::CycloneDX::Declarations::Data> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Declarations::Data->new( %PARAMS )

Properties:

=over

=item C<classification>, 

=item C<contents>, The contents or references to the contents of the data
being described.

=item C<governance>, Data Governance

=item C<name>, The name of the data.

=item C<sensitive_data>, A description of any sensitive data included.

=back

=item $data->classification

=item $data->contents

=item $data->governance

=item $data->name

=item $data->sensitive_data

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
