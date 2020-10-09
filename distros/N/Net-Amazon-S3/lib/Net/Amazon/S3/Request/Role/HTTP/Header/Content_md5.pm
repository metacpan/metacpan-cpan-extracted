package Net::Amazon::S3::Request::Role::HTTP::Header::Content_md5;
# ABSTRACT: Content-MD5 header role
$Net::Amazon::S3::Request::Role::HTTP::Header::Content_md5::VERSION = '0.97';
use Moose::Role;
use Digest::MD5 qw[];
use MIME::Base64 qw[];

around _request_headers => sub {
	my ($inner, $self) = @_;
	my $content = $self->_http_request_content;

	my $value = MIME::Base64::encode_base64( Digest::MD5::md5( $content ) );
	chomp $value;

	return ($self->$inner, ('Content-MD5' => $value));
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Header::Content_md5 - Content-MD5 header role

=head1 VERSION

version 0.97

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
