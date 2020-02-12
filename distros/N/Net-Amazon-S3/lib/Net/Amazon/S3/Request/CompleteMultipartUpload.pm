package Net::Amazon::S3::Request::CompleteMultipartUpload;
$Net::Amazon::S3::Request::CompleteMultipartUpload::VERSION = '0.89';
use Moose 0.85;
use Digest::MD5 qw/md5 md5_hex/;
use MIME::Base64;
use Carp qw/croak/;
use XML::LibXML;

extends 'Net::Amazon::S3::Request::Object';

with 'Net::Amazon::S3::Request::Role::Query::Param::Upload_id';
with 'Net::Amazon::S3::Request::Role::HTTP::Header::Content_length';
with 'Net::Amazon::S3::Request::Role::HTTP::Header::Content_md5';
with 'Net::Amazon::S3::Request::Role::HTTP::Header::Content_type' => { content_type => 'application/xml' };
with 'Net::Amazon::S3::Request::Role::HTTP::Method::POST';

has 'etags'         => ( is => 'ro', isa => 'ArrayRef',   required => 1 );
has 'part_numbers'  => ( is => 'ro', isa => 'ArrayRef',   required => 1 );

__PACKAGE__->meta->make_immutable;

sub _request_content {
    my ($self) = @_;

    #build XML doc
    my $xml_doc = XML::LibXML::Document->new('1.0','UTF-8');
    my $root_element = $xml_doc->createElement('CompleteMultipartUpload');
    $xml_doc->addChild($root_element);

    #add content
    for(my $i = 0; $i < scalar(@{$self->part_numbers}); $i++ ){
        my $part = $xml_doc->createElement('Part');
        $part->appendTextChild('PartNumber' => $self->part_numbers->[$i]);
        $part->appendTextChild('ETag' => $self->etags->[$i]);
        $root_element->addChild($part);
    }

    return $xml_doc->toString;
}

sub BUILD {
    my ($self) = @_;

    croak "must have an equally sized list of etags and part numbers"
        unless scalar(@{$self->part_numbers}) == scalar(@{$self->etags});
}

1;

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::CompleteMultipartUpload - An internal class to complete a multipart upload

=head1 VERSION

version 0.89

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::CompleteMultipartUpload->new(
    s3                  => $s3,
    bucket              => $bucket,
    etags               => \@etags,
    part_numbers        => \@part_numbers,
  )->http_request;

=head1 DESCRIPTION

This module completes a multipart upload.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: An internal class to complete a multipart upload

