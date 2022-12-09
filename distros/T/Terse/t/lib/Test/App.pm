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

1;

