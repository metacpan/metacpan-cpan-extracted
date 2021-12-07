package Net::Amazon::S3::Request::Role::Query::Param;
# ABSTRACT: request query params role
$Net::Amazon::S3::Request::Role::Query::Param::VERSION = '0.99';
use MooseX::Role::Parameterized;

parameter param => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

parameter query_param => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { $_[0]->param },
);

parameter constraint => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

parameter required => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

parameter default => (
	is => 'ro',
	isa => 'Str|CodeRef',
	required => 0,
);

role {
	my ($params) = @_;

	my $param = $params->param;
	my $query_param = $params->query_param;

	has $param => (
		is => 'ro',
		isa => $params->constraint,
		required => $params->required,
		(default => $params->default) x!! defined $params->default,
	);

	around _request_query_params => eval <<"INLINE";
	sub {
		my (\$inner, \$self) = \@_;
		my \$value = \$self->$param;

		return (\$self->\$inner, (q[$query_param] => \$value) x!! defined \$value);
	};
INLINE
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::Query::Param - request query params role

=head1 VERSION

version 0.99

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
