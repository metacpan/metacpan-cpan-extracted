package Net::Amazon::S3::Authorization::IAM;
$Net::Amazon::S3::Authorization::IAM::VERSION = '0.90';
# ABSTRACT: IAM authorization information

use Moose 0.85;
use MooseX::StrictConstructor 0.16;

extends 'Net::Amazon::S3::Authorization::Basic';

has '+aws_access_key_id' => (
	lazy => 1,
	default => sub { $_[0]->_credentials->accessKeyId },
);

has '+aws_secret_access_key' => (
	lazy => 1,
	default => sub { $_[0]->_credentials->secretAccessKey },
);

has aws_session_token => (
	is => 'ro',
	lazy => 1,
	default => sub { $_[0]->_credentials->sessionToken },
);

has _credentials => (
	is => 'ro',
	init_arg => undef,
	lazy => 1,
	builder => '_build_credentials',
);

sub _build_credentials {
	eval "require VM::EC2::Security::CredentialCache" or die $@;
	my $creds = VM::EC2::Security::CredentialCache->get();
	defined($creds) || die("Unable to retrieve IAM role credentials");

	return $creds;
}

around authorization_headers => sub {
	my ($orig, $self) = @_;

	return +(
		$self->$orig,
		'x-amz-security-token' => $self->aws_session_token,
	);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Authorization::IAM - IAM authorization information

=head1 VERSION

version 0.90

=head1 SYNOPSIS

	use Net::Amazon::S3;
	use Net::Amazon::S3::Authorization::IAM;

	# obtain instance credentials
	use VM::EC2::Security::CredentialCache;
	my $s3 = Net::Amazon::S3->new (
		authorization_context => Net::Amazon::S3::Authorization::IAM->new,
		...
	);

	# or just provide your values
	my $s3 = Net::Amazon::S3->new (
		authorization_context => Net::Amazon::S3::Authorization::IAM->new (
			aws_access_key_id     => ...,
			aws_secret_access_key => ...,
			aws_session_token     => ...,
		),
		...
	);

=head1 DESCRIPTION

Authorization context using instance session credentials.

Unless specified authorization context obtains credentials via L<< VM::EC2::Security::CredentialCache >>.
It is not listed as a L<< Net::Amazon::S3 >> dependency.

=head1 INCOMPATIBILITY WARNING

This module with its dependencies will be moved out and distributed separately
without dependency from L<Net::Amazon::S3>.

If you use IAM, please consider to add proper C<use> statement into your code.

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
