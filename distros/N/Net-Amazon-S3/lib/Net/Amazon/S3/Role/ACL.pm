package Net::Amazon::S3::Role::ACL;
# ABSTRACT: ACL specification
$Net::Amazon::S3::Role::ACL::VERSION = '0.99';
use Moose::Role;
use Moose::Util::TypeConstraints;

use Carp ();

use Net::Amazon::S3::ACL::Set;
use Net::Amazon::S3::ACL::Canned;
use Net::Amazon::S3::Constraint::ACL::Canned;

has acl => (
	is          => 'ro',
	isa         => union ([
		'Net::Amazon::S3::ACL::Set',
		'Net::Amazon::S3::ACL::Canned',
	]),
	required    => 0,
	coerce      => 1,
);

around BUILDARGS => sub {
	my ($orig, $class) = (shift, shift);
	my $args = $class->$orig (@_);

	if (exists $args->{acl_short}) {
		my $acl_short = delete $args->{acl_short};

		Carp::carp "'acl_short' parameter is ignored when 'acl' specified"
			if exists $args->{acl};

		$args->{acl} = $acl_short
			unless exists $args->{acl};
	}

	delete $args->{acl} unless defined $args->{acl};

	return $args;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Role::ACL - ACL specification

=head1 VERSION

version 0.99

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
