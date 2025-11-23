package Net::Amazon::S3::Request::Role::HTTP::Header::Content_type;
# ABSTRACT: Content-Type header role
$Net::Amazon::S3::Request::Role::HTTP::Header::Content_type::VERSION = '0.992';
use MooseX::Role::Parameterized;

parameter content_type => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

role {
	my ($params) = @_;
	my $content_type = $params->content_type;

	around _request_headers => sub {
		my ($inner, $self) = @_;

		return ($self->$inner, ('Content-Type' => $content_type));
	};
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Header::Content_type - Content-Type header role

=head1 VERSION

version 0.992

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
