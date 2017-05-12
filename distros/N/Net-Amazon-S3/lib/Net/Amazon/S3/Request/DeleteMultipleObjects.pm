package Net::Amazon::S3::Request::DeleteMultipleObjects;
$Net::Amazon::S3::Request::DeleteMultipleObjects::VERSION = '0.80';
use Moose 0.85;
use Moose::Util::TypeConstraints;
use XML::LibXML;
use Digest::MD5;
use MIME::Base64;
extends 'Net::Amazon::S3::Request';

# ABSTRACT: An internal class to delete multiple objects

has 'bucket' => ( is => 'ro', isa => 'BucketName', required => 1 );
has 'keys'    => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );
__PACKAGE__->meta->make_immutable;

sub http_request {
    my $self = shift;

    my $doc = XML::LibXML::Document->new("1.0", 'utf-8');
    my $docroot = $doc->createElement("Delete");
    $doc->setDocumentElement($docroot);

    my $quiet_node = $doc->createElement("Quiet");
    $quiet_node->appendChild($doc->createTextNode('false'));
    $docroot->appendChild($quiet_node);

    foreach my $key (@{$self->keys}) {
      my $n = $doc->createElement('Object');
      my $k = $doc->createElement('Key');
      $k->appendChild($doc->createTextNode($key));
      $n->appendChild($k);
      $docroot->appendChild($n);
    }

    my $delete_content = $doc->toString(1);
    my $md5_hex = Digest::MD5::md5_hex($delete_content);
    my $md5 = pack( 'H*', $md5_hex );
    my $md5_base64 = encode_base64($md5);
    chomp $md5_base64;

    my $conf = {
        'Content-MD5'    => $md5_base64,
        'Content-Length' => length($delete_content),
    };

    return Net::Amazon::S3::HTTPRequest->new(
        s3     => $self->s3,
        method => 'POST',
        path   => $self->_uri() . "?delete",
        headers => $conf,
        content => $delete_content,
    )->http_request;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::DeleteMultipleObjects - An internal class to delete multiple objects

=head1 VERSION

version 0.80

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Request::DeleteMultipleObjects->new(
    s3     => $s3,
    bucket => $bucket,
    keys    => $keys,
  )->http_request;

=head1 DESCRIPTION

This module deletes multiple objects.

=head1 NAME

Net::Amazon::S3::Request::DeleteMultipleObjects - An internal class to delete multiple objects

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head1 AUTHOR

Rusty Conover <rusty@luckydinosaur.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
