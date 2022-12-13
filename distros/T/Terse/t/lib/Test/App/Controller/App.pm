package Test::App::Controller::App;

use base 'Terse::Controller';

sub build_controller {
	my ($self) = @_;
	#$self->namespace = 'stock';
	return $self;
}

sub hidden :get :path(app/hidden) {
	my ($self, $t) = @_;
	unless ($t->plugin('validateparam')->az($t->params->name)) {
		$t->raiseError('param name contains more than just A-Z', 500);
		return 0;
	}
	$t->response->hits = '1';
	$t->response->test = "kaput";
}

sub hello :any(hello_world) {
	$_[1]->response->hello = "world";
}

sub hello_get :get(hello_world) {
	$_[1]->response->hello = "world 2";
}

sub hello_get_with_params :get(hello_world) :params(test => 'okay') {
	$_[1]->response->hello = "world 3";
}


1;
