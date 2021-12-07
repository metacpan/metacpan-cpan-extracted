package Net::Amazon::S3::Request::Object;
# ABSTRACT: Base class for all S3 Object operations
$Net::Amazon::S3::Request::Object::VERSION = '0.99';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request::Bucket';

has key => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

override _request_path => sub {
	my ($self) = @_;

	return super . (join '/', map {$self->s3->_urlencode($_)} split /\//, $self->key);
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Object - Base class for all S3 Object operations

=head1 VERSION

version 0.99

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
