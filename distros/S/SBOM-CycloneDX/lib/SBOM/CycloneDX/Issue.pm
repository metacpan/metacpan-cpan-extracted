package SBOM::CycloneDX::Issue;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str Enum InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has type        => (is => 'rw', isa => Enum [qw(defect enhancement security)], required => 1);
has id          => (is => 'rw', isa => Str);
has name        => (is => 'rw', isa => Str);
has description => (is => 'rw', isa => Str);
has source      => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Source']);
has references  => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

sub TO_JSON {

    my $self = shift;

    my $json = {type => $self->type};

    $json->{id}          = $self->id          if $self->id;
    $json->{name}        = $self->name        if $self->name;
    $json->{description} = $self->description if $self->description;
    $json->{source}      = $self->source      if $self->source;
    $json->{references}  = $self->references  if @{$self->references};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Issue - An individual issue that has been resolved

=head1 SYNOPSIS

    $release_notes->resolves->add(
        SBOM::CycloneDX::Issue->new(
            type   => 'security',
            source => SBOM::CycloneDX::Source->new(
                name => 'NVD',
                url  => 'https://nvd.nist.gov/vuln/detail/CVE-2021-44228'
            )
        )
    );

=head1 DESCRIPTION

L<SBOM::CycloneDX::Issue> provides an individual issue that has been resolved.

=head2 METHODS

L<SBOM::CycloneDX::Issue> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Issue->new( %PARAMS )

Properties:

=over

=item * C<type>, Specifies the type of issue (C<defect>, C<enhancement> or C<security>)

=item * C<id>, The identifier of the issue assigned by the source of the issue

=item * C<name>, The name of the issue

=item * C<description>, A description of the issue

=item * C<source>, The source of the issue where it is documented. See L<SBOM::CycloneDX::Source>

=item * C<references>, A collection of URL's for reference. Multiple URLs are allowed.

=back

=item $issue->type

=item $issue->id

=item $issue->name

=item $issue->description

=item $issue->source

=item $issue->references

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
