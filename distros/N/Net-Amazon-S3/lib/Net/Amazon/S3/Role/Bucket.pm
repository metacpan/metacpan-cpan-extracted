package Net::Amazon::S3::Role::Bucket;
# ABSTRACT: Bucket role
$Net::Amazon::S3::Role::Bucket::VERSION = '0.97';
use Moose::Role;
use Scalar::Util;
use Safe::Isa ();

around BUILDARGS => sub {
	my ($orig, $class, %params) = @_;

	# bucket can be optional in HTTPRequest
	if ($params{bucket}) {
		my $region = $params{region};
		$region = $params{bucket}->region
			if $params{bucket}
			and Scalar::Util::blessed( $params{bucket} )
			and ! $params{region}
			and $params{bucket}->has_region
			;

		$params{bucket} = $params{bucket}->name
			if $params{bucket}->$Safe::Isa::_isa ('Net::Amazon::S3::Client::Bucket');

		$params{bucket} = Net::Amazon::S3::Bucket->new(
			bucket => $params{bucket},
			account => $params{s3},
			(region => $region) x!! $region,
		) if $params{bucket} and ! ref $params{bucket};

		delete $params{region};
	}

	$class->$orig( %params );
};

has bucket => (
	is => 'ro',
	isa => 'Net::Amazon::S3::Bucket',
	required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Role::Bucket - Bucket role

=head1 VERSION

version 0.97

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
