package PAGI::App::Storage::Abstract;
$PAGI::App::Storage::Abstract::VERSION = '0.001';
use v5.18;
use warnings;

use Storage::Abstract;
use Future::AsyncAwait;
use Feature::Compat::Try;
use Scalar::Util qw(blessed);
use HTTP::Date qw(time2str);
use MIME::Types;

use constant ERROR_MESSAGES => {
	400 => 'Bad Request',
	403 => 'Forbidden',
	404 => 'Not Found',
	405 => 'Method Not Allowed',
};

sub new
{
	my ($class, %args) = @_;

	# either storage or storage_config is required
	my $storage = $args{storage}
		// Storage::Abstract->new(%{$args{storage_config}});

	return bless {
		storage => $storage,
		mime => MIME::Types->new,
	}, $class;
}

sub storage { shift->{storage} }
sub mime { shift->{mime} }

async sub call
{
	my ($self, $scope, $receive, $send) = @_;

	die "Unsupported scope type: $scope->{type}" if $scope->{type} ne 'http';

	try {
		my $method = uc($scope->{method} // '');

		die {status => 405}
			unless $method eq 'GET' || $method eq 'HEAD';

		my $path = $scope->{path};
		my $fh = $self->storage->retrieve($path, \my %info);
		my ($ext) = $path =~ m{\.([^.]+)$};
		my $content_type = $ext ? $self->mime->mimeTypeOf($ext) : 'application/octet-stream';

		await $send->(
			{
				type => 'http.response.start',
				status => 200,
				headers => [
					['content-type', $content_type],
					['content-length', $info{size}],
					['last-modified', time2str($info{mtime})],
				],
			}
		);

		if ($method eq 'HEAD') {
			await $send->({type => 'http.response.body', body => '', more => 0});
		}
		else {
			await $send->(
				{
					type => 'http.response.body',
					fh => $fh,
				}
			);
		}
	}
	catch ($e) {
		if (blessed $e && $e->isa('Storage::Abstract::X::NotFound')) {
			$self->_send_error($send, 404);
		}
		elsif (blessed $e && $e->isa('Storage::Abstract::X::PathError')) {
			$self->_send_error($send, 403);
		}
		elsif (ref $e eq 'HASH' && $e->{status}) {
			$self->_send_error($send, $e->{status});
		}
		else {
			# other error - let server handle it as 500
			die $e;
		}
	}
}

async sub _send_error
{
	my ($self, $send, $status) = @_;

	my $message = ERROR_MESSAGES->{$status};

	await $send->(
		{
			type => 'http.response.start',
			status => $status,
			headers => [['content-type', 'text/plain'], ['content-length', length($message)]],
		}
	);

	await $send->({type => 'http.response.body', body => $message, more => 0});
}

sub to_app
{
	my ($self) = @_;

	return sub { $self->call(@_) };
}

1;

__END__

=head1 NAME

PAGI::App::Storage::Abstract - Storage::Abstract for PAGI

=head1 SYNOPSIS

	use PAGI::App::Storage::Abstract;

	my $app1 = PAGI::App::Storage::Abstract->new(
			storage_config => {
					driver => 'directory',
					directory => '/some/dir',
			},
	)->to_app;

=head1 DESCRIPTION

This module is a PAGI app to serve static files with L<Storage::Abstract>. See
its documentation to understand how to properly configure the app in the
constructor.

Upon constructing and mounting the application, it starts serving static files
right away - no extra steps are required.

B<Beta quality>: this module will remain beta as long as PAGI itself is not
fully stabilized. Moreover, its interface may change if a base class for PAGI
apps is introduced.

=head1 SEE ALSO

L<Plack::App::Storage::Abstract>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

