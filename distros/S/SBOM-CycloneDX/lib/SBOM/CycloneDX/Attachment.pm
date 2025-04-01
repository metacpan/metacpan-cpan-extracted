package SBOM::CycloneDX::Attachment;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use Types::Standard       qw(Str FileHandle Enum);
use MIME::Base64          qw(encode_base64);
use SBOM::CycloneDX::Util qw(file_read);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

my $BASE64_REGEXP = qr{^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$};

has file         => (is => 'rw', isa      => FileHandle | Str);
has content_type => (is => 'rw', isa      => Str);
has encoding     => (is => 'rw', isa      => Enum [qw(base64)]);
has content      => (is => 'rw', required => 1);

sub TO_JSON {

    my $self = shift;

    # TODO  use trigger
    # TODO  guess mime/type from content

    Carp::croak '"file" and "content" cannot be used at the same time.' if ($self->file && $self->content);

    my $content = $self->content;

    if ($self->encoding) {

        my $b64_content = undef;

        if ($self->file && !$content) {
            $b64_content = encode_base64(file_read($self->file), '');
        }

        if (!$self->file && $content) {
            $b64_content = ($content =~ /$BASE64_REGEXP/) ? $content : encode_base64($content, '');
        }

        Carp::croak 'Empty content' unless $b64_content;

        $content = $b64_content;

    }

    my $json = {content => $content};

    $json->{contentType} = $self->content_type if $self->content_type;
    $json->{encoding}    = $self->encoding     if $self->encoding;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Attachment - Attachment utility

=head1 SYNOPSIS

    use SBOM::CycloneDX::Attachment;

    # Base64 content

    $attachment = SBOM::CycloneDX::Attachment->new(
        content      => 'Y29uc29sZS5sb2coJ0dvb2RCeWUnKQ==',
        content_type => 'text/javascript'
    );

    # Plain content

    $attachment = SBOM::CycloneDX::Attachment->new(
        content      => 'Copyright (C) Acme - All Rights Reserved',
        content_type => 'text/plain'
    );

    # File handler

    open(my $fh, "<", "/path/LICENSE.md");

    $attachment = SBOM::CycloneDX::Attachment->new(
        file => $fh
    );

    # File path

    $attachment = SBOM::CycloneDX::Attachment->new(
        file => $fh
    );


=head1 DESCRIPTION

L<SBOM::CycloneDX::Attachment> is a attachment utility.


=head2 METHODS

L<SBOM::CycloneDX::Attachment> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Attachment->new( %PARAMS )

Create a new attachment object.

Parameters:

=over

=item * C<file>, File handle or file path

=item * C<content>, Plain content (text or BASE64 encoded)

=item * C<content_type>, content MIME/Type

=back

B<NOTE>: C<file> and C<content> cannot be used at the same time.

    # Base64 content

    $attachment = SBOM::CycloneDX::Attachment->new(
        content      => 'Y29uc29sZS5sb2coJ0dvb2RCeWUnKQ==',
        content_type => 'text/javascript'
    );

    # Plain content

    $attachment = SBOM::CycloneDX::Attachment->new(
        content      => 'Copyright (C) Acme - All Rights Reserved',
        content_type => 'text/plain'
    );

    # File handler

    open(my $fh, "<", "/path/LICENSE.md");

    $attachment = SBOM::CycloneDX::Attachment->new(
        file => $fh
    );

    # File path

    $attachment = SBOM::CycloneDX::Attachment->new(
        file => '/path/LICENSE.md'
    );

=item $attachment->file

File handle or file path

=item $attachment->content_type

Specifies the format and nature of the data being attached, helping systems
correctly interpret and process the content.

=item $attachment->content

Specifies the optional encoding the text is represented in.

=item $c->TO_JSON

Convert the attachment in JSON.

    say encode_json($attachment);

    # {
    #   "content": "Y29uc29sZS5sb2coJ0dvb2RCeWUnKQ==",
    #   "contentType": "text/javascript",
    #   "encoding": "base64"
    # }


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
