package Terse::View::Static;

use base 'Terse::View';

sub build_view {
	my ($self) = @_;
	$self->static_directory ||= 'root/static';
	$self->allowed = 'js|css|png|svg|jpeg|gif|json|html|txt';
	$self->mime = {
		js => 'application/javascript',
		css => 'text/css',
		png => 'image/png',
		svg => 'image/svg',
		jpeg => 'image/jpeg',
		gif => 'image/gif',
		json => 'application/json',
		html => 'text/html',
		txt => 'text/plain'
	};
	my $path = $0;
	$path =~ s/[^\/]+$//g;
	$self->dir = $path . $self->static_directory;
	return $self;
}

sub render {
        my ($self, $t, $data) = @_;
	my $template = $t->captured->[0] !~ m/^1$/ && $t->captured->[0] || $data->template || $t->template || $t->req;
	$template = 'html/' . $template . '.html' if ($template !~ m/\.[^\.]+$/);
	my $allowed = $self->allowed;
	my ($mime) = $template =~ m/($allowed)$/;
	return $t->logError('Invalid file mime type for file: ' . $template, 500, 1) unless $mime && $self->mime->$mime;
	my $file = $self->_read_file($self->dir . '/' . $template);
	$t->logError('File not found: ' . $template, 500, 1) && return unless $file;
	return ($self->mime->$mime, $file);
}

sub _read_file {
	my ($self, $file) = @_;
	return unless -f $file;
	open my $fh, '<', $file or die "Cannot read html file: $file:" . $@;
	my $data = do { local $/; <$fh> };
	close $fh;
	return $data;
}

1;

=head1 NAME

Terse::View::Static - Serve static resources view

=cut

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

	package MyApp::View::Static;

	use base 'Terse::View::Static';

	1;

=cut

=head1 LICENSE AND COPYRIGHT

L<Terse::Static>.

=cut
