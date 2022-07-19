package Net::Amazon::S3::Operation::Bucket::Location::Response;
# ABSTRACT: An internal class to handle bucket location response
$Net::Amazon::S3::Operation::Bucket::Location::Response::VERSION = '0.991';
use Moose;

extends 'Net::Amazon::S3::Response';

sub location {
	$_[0]->_data->{location};
}

sub _parse_data {
	my ($self) = @_;

	my $xpc = $self->xpath_context;

	my $data = {
		location => scalar $xpc->findvalue ("//s3:LocationConstraint"),
	};

	# S3 documentation: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGETlocation.html
	# When the bucket's region is US East (N. Virginia),
	# Amazon S3 returns an empty string for the bucket's region
	$data->{location} = 'us-east-1'
		if defined $data->{location} && $data->{location} eq '';

	return $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Location::Response - An internal class to handle bucket location response

=head1 VERSION

version 0.991

=head1 DESCRIPTION

Implements operation L<< GetBucketLocation|https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLocation.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
