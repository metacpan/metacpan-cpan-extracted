package Test::App::Controller::App::Hello;

use base 'Terse::Controller';

sub build_controller {
	my ($self) = @_;
	#$self->required_captured = 2;
	#$self->capture = 'app/(.*)/hello/(.*)';
	return $self;
}

sub hidden {

}

sub hello :get {
	$_[1]->response->captured = $_[1]->captured;
	$_[1]->response->hello = $_[1]->model('test')->something();
}

sub hello_get :get :path(app/(.*)/hello/world) :captured(1) {
	$_[1]->response->hello = "world 2";
}

sub hello_get_with_params :get(hello_world) :params(test => 'okay') {
	$_[1]->response->hello = "world 3";
}

1;
