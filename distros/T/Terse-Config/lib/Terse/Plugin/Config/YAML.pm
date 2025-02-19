package Terse::Plugin::Config::YAML;

use base 'Terse::Plugin::Config';

use YAML::XS qw/LoadFile/;

sub build_plugin {
	my ($self) = @_;
	if (!$self->config_file) {
		my $file = $0;
		($self->config_file = $0) =~ s/(\.psgi)?$/.yml/;
	}
	$self->data = LoadFile $self->config_file;
	return $self;
}

1;

__END__

=head1 NAME

Terse::Plugin::Config::YAML - YAML configs

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	package MyApp::Plugin::Config;

	use base 'Terse::Plugin::Config::YAML';

	1;

	$terse->plugin('config')->find('path/to/key');
	$terse->plugin('config')->data->path->to->key;

=head1 AUTHOR
 
LNATION, C<< <email at lnation.org> >>
 
=head1 LICENSE AND COPYRIGHT
 
L<Terse::Configs>.
 
=cut
