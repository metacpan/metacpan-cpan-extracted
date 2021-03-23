package Net::Amazon::S3::Authorization::Basic;
$Net::Amazon::S3::Authorization::Basic::VERSION = '0.98';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;

extends 'Net::Amazon::S3::Authorization';

# ABSTRACT: Basic authorization information

has aws_access_key_id => (
	is => 'ro',
);

has aws_secret_access_key => (
	is => 'ro',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Authorization::Basic - Basic authorization information

=head1 VERSION

version 0.98

=head1 SYNOPSIS

	use Net::Amazon::S3;

	my $s3 = Net::Amazon::S3->new (
		authorization_context => Net::Amazon::S3::Authorization::Basic->new (
			aws_access_key_id     => ...,
			aws_secret_access_key => ...,
		),
		...
	);

=head1 DESCRIPTION

Basic authorization context for access_key / secret_key authorization.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
