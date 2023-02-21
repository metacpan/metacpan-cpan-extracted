package TestApp;

use base 'Terse';
use Terse::Plugin::Glitch;

sub build_terse {
        $_[0]->glitch = Terse::Plugin::Glitch->new(
		glitch_config => 't/lib/glitch.conf',
		format => 'YAML'
	);
}

sub auth {
	return 0 if $_[1]->params->not;
	return 1;
}

sub hello_world {
	my ($self, $t) = @_;
	my $data = $self->glitch->call('one');
	$t->response->raiseError($data->hash);
	$t->response->hello = "world";
}

sub error {
	$_[1]->logError('test an error', 500);
}

1;
