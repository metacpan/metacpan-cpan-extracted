package Plack::App::Storage::Abstract;
$Plack::App::Storage::Abstract::VERSION = '0.001';
use v5.14;
use warnings;

use Storage::Abstract;
use Plack::MIME;
use HTTP::Date;
use Feature::Compat::Try;
use Scalar::Util qw(blessed);
use parent 'Plack::Component';

use Plack::Util::Accessor qw(encoding storage storage_config);

sub new
{
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);

	$self->storage(Storage::Abstract->new(%{$self->storage_config}))
		unless $self->storage;

	$self->encoding($self->encoding // 'utf-8');

	return $self;
}

sub call
{
	my ($self, $env) = @_;
	my $path = $env->{PATH_INFO};
	my $fh;
	my %info;

	try {
		$fh = $self->storage->retrieve($path, \%info);
	}
	catch ($e) {
		if (blessed $e && $e->isa('Storage::Abstract::X::NotFound')) {
			return $self->_error_code(404);
		}
		elsif (blessed $e && $e->isa('Storage::Abstract::X::PathError')) {
			return $self->_error_code(403);
		}
		else {
			# StorageError or HandleError or unblessed error
			$env->{'psgi.errors'}->print("$e");
			return $self->_error_code(500);
		}
	}

	my $content_type = Plack::MIME->mime_type($path) || 'text/plain';
	if ($content_type =~ m{^text/}) {
		$content_type .= "; charset=" . $self->encoding;
	}

	return [
		200,
		[
			'Content-Type' => $content_type,
			'Content-Length' => $info{size},
			'Last-Modified' => HTTP::Date::time2str($info{mtime}),
		],
		$fh
	];
}

sub _error_code
{
	my ($self, $code) = @_;

	my %text = (
		400 => 'Bad Request',
		403 => 'Forbidden',
		404 => 'Not Found',
	);

	return [
		$code,
		[
			'Content-Type' => 'text/plain',
			'Content-Length' => length $text{$code}
		],
		[$text{$code}]
	];
}

1;

__END__

=head1 NAME

Plack::App::Storage::Abstract - Serve files with Storage::Abstract

=head1 SYNOPSIS

	use Plack::App::Storage::Abstract;

	my $app1 = Plack::App::Storage::Abstract->new(
		storage_config => {
			driver => 'directory',
			directory => '/some/dir',
		},
	)->to_app;

=head1 DESCRIPTION

This plack application serves files through L<Storage::Abstract>. It is similar
to L<Plack::App::File>, but gives better control over file storage.

=head1 CONFIGURATION

=head2 storage

The constructed C<Storage::Abstract> object. If not present, will be
constructed from L</storage_config>.

=head2 storage_config

A hash reference with keys to be passed to L<Storage::Abstract/new>. Required,
but may be skipped if L</storage> is passed instead.

=head2 encoding

Encoding used for text MIME types. Default C<utf-8>.

=head1 CAVEATS

=head2 Handling errors

On error producing a C<500> page, stringified exception will be written to PSGI error stream.

=head1 SEE ALSO

L<Plack::App::File>

L<Storage::Abstract>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

