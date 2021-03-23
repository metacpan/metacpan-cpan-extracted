package Net::Amazon::S3::Request::Role::Tags::Add;
# ABSTRACT: Add tags request parts common to Bucket and Object
$Net::Amazon::S3::Request::Role::Tags::Add::VERSION = '0.98';
use Moose::Role;

with 'Net::Amazon::S3::Request::Role::HTTP::Method::PUT';
with 'Net::Amazon::S3::Request::Role::Query::Action::Tagging';
with 'Net::Amazon::S3::Request::Role::XML::Content';

has 'tags' => (
	is => 'ro',
	isa => 'HashRef',
	required => 1,
);

sub _request_content {
	my ($self) = @_;

	$self->_build_xml (Tagging => [
		{ TagSet => [
			map +{ Tag => [
				{ Key => $_ },
				{ Value => $self->tags->{$_} },
			]}, sort keys %{ $self->tags }
		]},
	]);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::Tags::Add - Add tags request parts common to Bucket and Object

=head1 VERSION

version 0.98

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
