package TestApp;

use base 'Terse';

sub auth {
	return 0 if $_[1]->params->not;
	return 1;
}

sub hello_world {
	my ($self, $t) = @_;
	$t->logInfo('Hello this is a test');
	$t->delayed_response(sub {
		$t->response->hello = "world";
		return $t->response;
	});
}

sub web {
	my ($self, $t) = @_;
	$t->websocket(
		disconnect => sub {
		},
		connect => sub {
			my ($websocket) = @_;
			$websocket->send(1);
		},
		recieve => sub {
			my ($websocket) = @_;
			$websocket->send($_[1]);
		},
		error => sub {
			$t->logError('Kaput' . $_[2]);
		} 
	);
}	

sub error {
	$_[1]->logError('test an error', 500);
}

1;
