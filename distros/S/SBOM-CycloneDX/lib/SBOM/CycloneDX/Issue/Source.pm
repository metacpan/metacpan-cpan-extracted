package SBOM::CycloneDX::Issue::Source;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has name => (is => 'rw', isa => Str);
has url  => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{name} = $self->name if $self->name;
    $json->{url}  = $self->url  if $self->url;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Issue::Source - The source of the issue where it is documented

=head1 SYNOPSIS

    $issue = SBOM::CycloneDX::Issue->new(
        type   => 'security',
        source => SBOM::CycloneDX::Issue::Source->new(
            name => 'NVD',
            url  => 'https://nvd.nist.gov/vuln/detail/CVE-2021-44228'
        )
    );


=head1 DESCRIPTION

L<SBOM::CycloneDX::Issue::Source> provides the source of the issue where it is documented.

=head2 METHODS

L<SBOM::CycloneDX::Issue::Source> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Issue::Source->new( %PARAMS )

Properties:

=over

=item * C<name>, The name of the source.

=item * C<url>, The url of the issue documentation as provided by the source.

=back

=item $source->name

=item $source->value

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
