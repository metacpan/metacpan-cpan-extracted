package Terse::Plugin::Config;

use base 'Terse::Plugin';

use Data::LNPath qw/lnpath/;

sub build_plugin {
	my ($self) = @_;
	if (!$self->config_file) {
		my $file = $0;
		($self->config_file = $0) =~ s/(\.psgi)?$/.json/;
	}
	$self->data = $self->_read_file($self->config_file);
	return $self;
}

sub find {
	my ($self, $path) = @_;
	return lnpath($self->config, $path);
}

sub _read_file {
	my ($self, $file) = @_;
	open my $fh, '<', $file or die "Cannot open config file: $file";
	my $content = do { local $/; <$fh> };
	close $fh;
	$self->_parse_config($content);
}

sub _parse_config {
	my ($self, $content) = @_;
	$self->graft('data', $content);
}

1;

__END__

=head1 NAME

Terse::Plugin::Config - JSON configs

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	package MyApp::Plugin::Config;

	use base 'Terse::Plugin::Config';

	1;

	$terse->plugin('config')->find('path/to/key');
	$terse->plugin('config')->data->path->to->key;

=head1 AUTHOR
 
LNATION, C<< <email at lnation.org> >>
 
=head1 LICENSE AND COPYRIGHT
 
L<Terse::Configs>.
 
=cut
