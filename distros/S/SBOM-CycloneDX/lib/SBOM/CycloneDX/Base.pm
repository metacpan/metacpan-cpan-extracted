package SBOM::CycloneDX::Base;

use 5.010001;
use strict;
use warnings;
use utf8;

use Cpanel::JSON::XS;

use overload '""' => \&to_string, fallback => 1;

sub TO_JSON { Carp::croak 'TO_JSON is not extended by subclass' }

sub to_string {

    my $self = shift;

    my $json = Cpanel::JSON::XS->new->utf8->canonical->allow_nonref->allow_unknown->allow_blessed->convert_blessed
        ->stringify_infnan->escape_slash(0)->allow_dupkeys->pretty->space_before(0);

    return $json->encode($self->TO_JSON);

}

sub to_hash {

    my $self = shift;

    my $json = $self->to_string;
    my $hash = Cpanel::JSON::XS->new->decode($json);

    return $hash;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Base - Base class for SBOM::CycloneDX

=head1 SYNOPSIS

    $component->to_string; # Convert object in JSON

    $license->to_hash; # Convert object in HASH

    $bom->TO_JSON; Helper for JSON packages


=head1 DESCRIPTION

L<SBOM::CycloneDX::BomRef> represents the BOM reference in L<SBOM::CycloneDX>.

=head2 METHODS

=over

=item SBOM::CycloneDX::Base->new( %PARAMS )

=item $base->to_string

Stringify BOM object in JSON.

=item $base->to_hash

Convert BOM object in HASH.

=item $base->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

    use Mojo::JSON qw(encode_json);

    say encode_json($bom);

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
