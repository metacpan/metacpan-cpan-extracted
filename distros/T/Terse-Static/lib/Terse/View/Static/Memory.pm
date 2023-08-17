package Terse::View::Static::Memory;

use base 'Terse::View::Static';

sub build_view {
	my ($self) = @_;
	$self->SUPER::build_view();
	$self->memory_cached_templates = $self->_read_directory_content($self->dir) ;
	return $self;
}

sub _read_directory_content {
	my ($self, $dir) = @_;
	my $allowed = $self->allowed;
	return { map {
		( $_ => $self->_read_file("$dir/$_") );
	} $self->_recurse_directory("${dir}") };
}

sub _recurse_directory {
        my ($self, $dir, $path, @files) = @_;
	return () unless -d $dir;
        opendir my $d, $dir or $self->logError("Cannot read controller directory: $!", 500, 1);
	my $allowed = $self->allowed;
        for (readdir $d) {
                next if $_ =~ m/^\./;
                if (-d "$dir/$_") {
                        push @files, $self->_recurse_directory("$dir/$_", $path ? "$path/$_" : $_);
                } elsif ($_ =~ m/\.($allowed)$/) {
			push @files, $path ? "$path/$_" : $_;
                }
        }
        closedir $d;
        return @files;
}

sub render {
        my ($self, $t, $data) = @_;
	my $template = $t->captured->[0] || $data->template || $t->template || $t->req;
	$template = 'html/' . $template . '.html' if ($template !~ m/\.[^\.]+$/);
	my $allowed = $self->allowed;
	my ($mime) = $template =~ m/($allowed)$/;
	return $t->logError('Invalid file mime type for file: ' . $template, 500, 1) unless $mime && $self->mime->$mime;
	return $t->logError('File not found: ' . $template, 500, 1) unless $self->memory_cached_resourcess->{$template};
	return ($self->mime->$mime, $self->memory_cached_resources->{$template});
}

1;

=head1 NAME

Terse::View::Static::Memory - Serve static resources in memory view

=cut

=head1 VERSION

Version 0.09

=cut

=head1 SYNOPSIS

	package MyApp::View::Static;

	use base 'Terse::View::Static::Memory';

	1;

=cut

=head1 LICENSE AND COPYRIGHT

L<Terse::Static>.

=cut
