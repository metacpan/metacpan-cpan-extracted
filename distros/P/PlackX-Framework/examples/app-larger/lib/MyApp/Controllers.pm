use v5.36;
package MyApp::Controllers {
  use MyApp::Router;
  use Time::HiRes ();

  base '/app';

  route ['/', '/home'] => sub ($request, $response) {
    $response->template->set(page_name => 'Home');
    return $response->render_template('index.html');
  };

  route get => '/feedback' => sub ($request, $response) {
    $response->template->set(page_name => 'Form');
    return $response->render_template('feedback.html');
  };

  route post => '/feedback' => sub ($request, $response) {
    $response->template->set(
      page_name         => 'Thank You',
      user_lucky_number => length($request->param('comments')),
    );
    return $response->render_template('feedback-thanks.html');
    return $response;
  };

  # Example hashref+arrayref combo
  route { get => ['/dump', '/dump.txt'] } => sub ($request, $response) {
    # Shallow copy and remove circular reference
    my %request_copy = %$request;
    $request_copy{'stash'} = 'DUMMY';

    require Data::Dumper;
    $response->render_text(Data::Dumper::Dumper({ request => \%request_copy }));
  };

  ### Secret Area #####################################################

  filter before => sub ($request, $response) {
    $response->status(403);
    return $response;
  };

  route '/admin' => sub ($request, $response) {
    $response->print('You should not be here! This is impossible!');
    return $response;
  }

}

1;
