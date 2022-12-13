package Test::App;

use base 'Terse::App';

sub build_app {
	$_[0]->response_view = 'pretty';
}

sub login :any {
	return 1;
}

sub auth_prevent :any(auth) {
	return 0;
}

sub auth_okay :req(auth) :get :post  {
	return 1;
}

sub logout {
	return 1;
}

sub web :websocket {
	my ($self, $t) = @_;
	return (
		disconnect => sub {
		},
		connect => sub {
			my ($websocket) = @_;
			$websocket->send('Hello');
		},
		recieve => sub {
			my ($websocket) = @_;
			$websocket->send('response');
		},
		error => sub {
			$t->logError('Kaput' . $_[1]);
		} 
	);
}

1;

