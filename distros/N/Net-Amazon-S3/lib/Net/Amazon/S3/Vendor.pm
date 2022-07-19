package Net::Amazon::S3::Vendor;
$Net::Amazon::S3::Vendor::VERSION = '0.991';
use Moose 0.85;

# ABSTRACT: Base class for vendor specific behaviour

has host                    => (
	is          => 'ro',
	isa         => 'Str',
	required    => 1,
);

has authorization_method    => (
	is          => 'ro',
	isa         => 'Str',
	lazy        => 1,
	default     => sub {
		require Net::Amazon::S3::Signature::V2;
		'Net::Amazon::S3::Signature::V2',
	},
);

has use_https               => (
	is          => 'ro',
	isa         => 'Bool',
	lazy        => 1,
	default     => sub { 1 },
);

has use_virtual_host        => (
	is          => 'ro',
	isa         => 'Bool',
	lazy        => 1,
	default     => sub { $_[0]->authorization_method->enforce_use_virtual_host },
);

has default_region          => (
	is          => 'ro',
	required    => 0,
	default     => sub { 'us-east-1' },
);

has enforce_empty_content_length => (
	is          => 'ro',
	default     => sub { 1 },
);

sub guess_bucket_region {
	my ($self, $bucket) = @_;

	return $self->default_region;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Vendor - Base class for vendor specific behaviour

=head1 VERSION

version 0.991

=head1 SYNOPSIS

	# use it with Amazon AWS
	my $s3 = Net::Amazon::S3->new (
		vendor => Net::Amazon::S3::Vendor::Amazon->new,
		...,
	);

	# or build your own vendor description
	my $vendor = Net::Amazon::S3::Vendor::Generic->new (
		host                 => 'my.s3.service',
		use_https            => 1,
		use_virtual_host     => 1,
		authorization_method => 'Net::Amazon::S3::Signature::V2',
	);

	# or
	my $vendor = Net::Amazon::S3::Vendor::Generic->new (
		host                 => 'my.s3.service',
		use_https            => 1,
		use_virtual_host     => 1,
		authorization_method => 'Net::Amazon::S3::Signature::V4',
		default_region       => '...',
	);

	# and construct your s3 connection
	my $s3 = Net::Amazon::S3->new (
		vendor => $vendor,
		...
	);

=head1 DESCRIPTION

S3 protocol is used not only by Amazon AWS but by many other object-storage services.
They provide same API, but it's just there's a little difference.

Examples?

Allright, you can upload file but other provider does not support multipart uploads.

Or although some providers support Signature V4 they may not support HEAD bucket request
to fetch it automatically.

=head2 Properties

=head3 host

Required, where service is located.

Available here so one can move its parameters into its own vendor class.

=head3 authorization_method

Default: L<< Net::Amazon::S3::Signature::V2 >>

Signature class used to authorize requests.

=head3 use_https

Default: true.

Whether to use HTTPS or not.

=head3 use_virtual_host

Default: whatever C<authorization_method> enforces

Whether to use path or virtual host access style.
Path style uses single host with bucket contained in uri path whereas virtual host style
use bucket specific virtual hosts.

=head3 default_region

Default: undef

Value that C<guess_bucket_region> will return.

Use when your provider doesn't support HEAD region request but uses Signature V4 authorization
method.

=head2 Methods

=head3 guess_bucket_region ($bucket)

Returns bucket's region

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
