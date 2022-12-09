package TestAppController;

use base 'Terse::Controller';

use TestAppController::Model;
use TestAppController::View;

sub build_controller {
	$_[0]->models->test = TestAppController::Model->new();
	$_[0]->views->test = TestAppController::View->new();
	$_[0]->response_view = 'test';
}

sub hidden {

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

sub hello :any(hello_world) :path(hello/world) {
	$_[1]->response->hello = "world";
}

sub hello_get :get :path(hello/(.*)/get) :captured(1) {
	$_[1]->response->hello = $_[1]->model('test')->something;
}

sub hello_get_with_params :get(hello_world) :params(test => 'okay') {
	$_[1]->response->hello = "world 3";
}

1;
