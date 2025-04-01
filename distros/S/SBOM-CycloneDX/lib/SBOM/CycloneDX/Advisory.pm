package SBOM::CycloneDX::Advisory;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has title => (is => 'rw', isa => Str);
has url => (is => 'rw', isa => Str, required => 1);

sub TO_JSON {

    my $self = shift;

    my $json = {url => $self->url};

    $json->{title} = $self->title if $self->title;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Advisory - Advisory

=head1 SYNOPSIS

    SBOM::CycloneDX::Advisory->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Advisory> provide the title and location where advisory information
can be obtained. An advisory is a notification of a threat to a component,
service, or system.

=head2 METHODS

L<SBOM::CycloneDX::Advisory> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Advisory->new( %PARAMS )

Properties:

=over

=item C<title>, An optional name of the advisory.

=item C<url>, Location where the advisory can be obtained.

=back

=item $advisory->title

=item $advisory->url

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
