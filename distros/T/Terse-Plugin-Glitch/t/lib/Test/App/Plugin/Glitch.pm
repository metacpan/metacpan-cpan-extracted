package Test::App::Plugin::Glitch;

use base 'Terse::Plugin::Glitch';

sub build_glitch_config {
	my ($self) = @_;
	$self->{glitch_config} = 't/lib/glitch.conf';
	$self->{format} = 'YAML';
}

1;
