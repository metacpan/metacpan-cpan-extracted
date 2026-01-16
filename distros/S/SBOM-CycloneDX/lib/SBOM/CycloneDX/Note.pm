package SBOM::CycloneDX::Note;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(StrMatch InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has locale => (is => 'rw', isa => StrMatch [qr{^([a-z]{2})(-[A-Z]{2})?$}]);
has text => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Attachment'], required => 1);

sub TO_JSON {

    my $self = shift;

    my $json = {text => $self->text};

    $json->{locale} = $self->locale if $self->locale;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Note - A note containing the locale and content

=head1 SYNOPSIS

    $note = SBOM::CycloneDX::Note->new(
        locale => 'en_US',
        text   => SBOM::CycloneDX::Attachment->new(
            file => '/path/note.txt'
        )
    );


=head1 DESCRIPTION

L<SBOM::CycloneDX::Note> provides a note containing the locale and content.

=head2 METHODS

L<SBOM::CycloneDX::Note> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Note->new( %PARAMS )

Properties:

=over

=item * C<locale>, The ISO-639 (or higher) language code and optional ISO-3166
(or higher) country code.

=item * C<text>, Specifies the full content of the release note.
See L<SBOM::CycloneDX::Attachment>.

=back

=item $note->locale

=item $note->text

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
