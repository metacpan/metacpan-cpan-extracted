package Net::AmazonS3::Simple::Object::File;
use strict;
use warnings;

use parent 'Net::AmazonS3::Simple::Object';

use Class::Tiny qw(file_path);

=head1 NAME

Net::AmazonS3::Simple::Object::File - S3 object in file 

=head1 SYNOPSIS

    Net::AmazonS3::Simple::Object::File->create_from_response(
        response  => $response,
        file_path => path(...),
    );

=head1 DESCRIPTION

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

attributes from L<Net::AmazonS3::Simple::Object>

=head4 file_path

=cut

sub BUILD {
    my ($self) = @_;

    foreach my $req ( qw/file_path/ ) {
        die "$req attribute required" if! defined $self->$req;
    }

    my $content_md5 = uc $self->file_path->digest('MD5');
    my $expected_md5 = uc $self->etag;

    if ($self->validate && $content_md5 ne $expected_md5) {
        die sprintf 
            'Object content %s (md5:%s) isn\'t expected ETag (md5:%s)',
            $self->file_path,
            $content_md5,
            $expected_md5;
    }
}

=head2 create_from_response(%options)

=head3 %options

=head4 validate

=head4 response

=head4 file_path

=cut

sub create_from_response {
    my ($class, %options) = @_;

    foreach my $req (qw/validate response file_path/) {
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
        file_path        => $options{file_path},
    );
}

=head2 content

return content of response

=cut

sub content {
    my ($self) = @_;

    return $self->file_path->slurp();
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;

