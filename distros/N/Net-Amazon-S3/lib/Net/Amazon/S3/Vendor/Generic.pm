package Net::Amazon::S3::Vendor::Generic;
$Net::Amazon::S3::Vendor::Generic::VERSION = '0.99';
use Moose 0.85;

# ABSTRACT: Generic S3 vendor

extends 'Net::Amazon::S3::Vendor';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Vendor::Generic - Generic S3 vendor

=head1 VERSION

version 0.99

=head1 SYNOPSIS

	my $s3 = Net::Amazon::S3->new (
		vendor => Net::Amazon::S3::Vendor::Generic->new (
			host => ...,
			use_https => ...',
			use_virtual_host => ...,
			authorization_method => ...,
			default_region => ...,
		),
		...
	);

=head1 DESCRIPTION

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
