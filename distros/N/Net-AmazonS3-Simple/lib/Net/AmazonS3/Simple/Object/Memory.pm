package Net::AmazonS3::Simple::Object::Memory;
use strict;
use warnings;

use parent 'Net::AmazonS3::Simple::Object';

use Digest::MD5 qw(md5_hex);

use Class::Tiny qw(content);

=head1 NAME

Net::AmazonS3::Simple::Object::Memory - S3 object in memory

=head1 SYNOPSIS
    Net::AmazonS3::Simple::Object::File->create_from_response(
        response  => $response,
        content   => '...',
    );


=head1 DESCRIPTION

This class represents downloaded object with content in memory.
This class is based on L<Net::AmazonS3::Simple::Object>.

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

attributes from L<Net::AmazonS3::Simple::Object>

=head4 content

=cut

sub BUILD {
    my ($self) = @_;

    foreach my $req (qw/content/) {
        die "$req attribute required" unless defined $self->$req;
    }

    my $content_md5  = uc md5_hex($self->content);
    my $expected_md5 = uc $self->etag;

    if ($self->validate && $content_md5 ne $expected_md5) {
        die "Object content (md5:$content_md5) isn't expected ETag (md5:$expected_md5)";
    }
}

=head2 create_from_response(%options)

=head3 %options

=head4 validate

=head4 response

=cut

sub create_from_response {
    my ($class, %options) = @_;

    foreach my $req (qw/validate response/) {
        die "$req parameter required" unless defined $options{$req};
    }

    my $etag = $options{response}->header('ETag');
    $etag =~ s/"//g;

    my $content_encoding = $options{response}->content_encoding() || undef;

    return $class->new(
        validate         => $options{validate},
        etag             => $etag,
        content_encoding => $content_encoding,
        content_type     => $options{response}->content_type(),
        content_length   => $options{response}->content_length(),
        last_modified    => $options{response}->last_modified(),
        content          => $options{response}->content(),
    );
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
