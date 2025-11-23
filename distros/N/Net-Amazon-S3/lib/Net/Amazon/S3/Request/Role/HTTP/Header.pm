package Net::Amazon::S3::Request::Role::HTTP::Header;
# ABSTRACT: HTTP Header Role
$Net::Amazon::S3::Request::Role::HTTP::Header::VERSION = '0.992';
use MooseX::Role::Parameterized;

parameter name => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

parameter header => (
	is => 'ro',
	isa => 'Str',
);

parameter constraint => (
	is => 'ro',
	isa => 'Str',
	init_arg => 'isa',
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

	my $name = $params->name;
	my $header = $params->header;

	has $name => (
		is => 'ro',
		isa => $params->constraint,
		(init_arg => undef) x!! ($name =~ m/^_/),
		required => $params->required,
		(default => $params->default) x!! defined $params->default,
	);

	around _request_headers => eval <<"INLINE";
	sub {
		my (\$inner, \$self) = \@_;
		my \$value = \$self->$name;

		return (\$self->\$inner, (q[$header] => \$value) x!! defined \$value);
	};
INLINE
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Header - HTTP Header Role

=head1 VERSION

version 0.992

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
