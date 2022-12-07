package TestApp;

use base 'Terse';

sub auth {
	return 0 if $_[1]->params->not;
	return 1;
}

sub hello_world {
	$_[1]->response->hello = "world";
}

sub error {
	$_[1]->logError('test an error', 500);
}

1;
