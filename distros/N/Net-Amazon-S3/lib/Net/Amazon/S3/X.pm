package Net::Amazon::S3::X;
$Net::Amazon::S3::X::VERSION = '0.99';
# ABSTRACT: Net::Amazon::S3 exceptions

use Moose;
use Moose::Meta::Class;

has request => (
	is => 'ro',
);

has response => (
	is => 'ro',
	handles => [
		'error_code',
		'error_message',
		'http_response',
	],
);

my %exception_map;
sub import {
	my ($class, @exceptions) = @_;

	for my $exception (@exceptions) {
		next if exists $exception_map{$exception};
		Moose::Meta::Class->create (
			$exception_map{$exception} = __PACKAGE__ . "::$exception",
			superclasses => [ __PACKAGE__ ],
		);
	}
}

sub build {
	my ($self, $exception, @params) = @_;

	$self->import ($exception);

	$exception_map{$exception}->new (@params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::X - Net::Amazon::S3 exceptions

=head1 VERSION

version 0.99

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
