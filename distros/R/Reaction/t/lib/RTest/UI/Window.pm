package RTest::UI::Window;

use aliased 'Reaction::UI::ViewPort';

use base qw/Reaction::Test/;
use Reaction::Class;

use Test::More ();

BEGIN {
  eval q{
    package RTest::UI::Window::_::view;

    use base qw/Reaction::UI::Renderer::XHTML/;

    sub render {
      return $_[0]->{render}->(@_);
    }

    package RTest::UI::Window::_::TestViewPort;

    use Reaction::Class;

    extends 'Reaction::UI::ViewPort';

    register_inc_entry;

    sub handle_events {
      $_[0]->{handle_events}->(@_);
    }
  };
  if ($@) {
    Test::More::plan skip_all => "Caught exception generating basic classes to test: $@";
    exit;
  } 
};

use Reaction::UI::Window;
use aliased 'RTest::UI::Window::_::TestViewPort';

has 'window' => (isa => 'Reaction::UI::Window', is => 'rw', lazy_build => 1);

sub _build_window {
  my $self = shift;
  return Reaction::UI::Window->new(
           ctx => bless({}, 'Reaction::Test::Mock::Context'),
           view_name => 'Test',
           content_type => 'text/html',
         );
}

sub test_window :Tests {
  my $self = shift;
  my $window = $self->build_window;
  my $view = bless({}, 'RTest::UI::Window::_::view');
  $window->ctx->{view} = sub {
    Test::More::is($_[1], 'Test', 'View name ok');
    return $view;
  };
  Test::More::is($window->view, $view, 'View retrieved from context');
  my %param;
  $window->ctx->{req} = sub {
    return bless({
             query_parameters => sub { \%param },
             body_parameters => sub { {} },
           }, 'Reaction::Test::Mock::Request');
  };
  $window->ctx->{res} = sub {
    return bless({
             status => sub { 200 },
             body => sub { '' },
           }, 'Reaction::Test::Mock::Response');
  };
  eval { $window->flush };
  Test::More::like($@, qr/empty focus stack/, 'Error thrown without viewports');
  my @vp;
  push(@vp, $window->focus_stack
    ->push_viewport(ViewPort, ctx => $window->ctx));
  push(@vp, $window->focus_stack
    ->push_viewport(ViewPort, ctx => $window->ctx));
  my $i;
  $view->{render} = sub {
    my $expect_vp = $vp[$i++];
    Test::More::is($_[1], $window->ctx, 'Context ok');
    Test::More::is($_[2], 'component', 'Component template');
    Test::More::is($_[3]->{self}, $expect_vp, 'Viewport');
    $_[3]->{window}->render_viewport($expect_vp->inner);
    return "foo";
  };
  my $body;
  $window->ctx->{res} = sub {
    return bless({
             body => sub { shift; return '' unless @_; $body = shift; },
             content_type => sub { },
             status => sub { 200 },
           }, 'Reaction::Test::Mock::Response');
  };
  $window->flush;
  Test::More::is($body, 'foo', 'body set ok');
  my $test_vp = $vp[1]->create_tangent('foo')
                      ->push_viewport(TestViewPort,
                                      ctx => bless({}, 'Catalyst'));
  my $param_name = '1.foo.0:name';
  Test::More::is($test_vp->event_id_for('name'), $param_name, 'Event id ok');
  $param{$param_name} = 'blah';
  $test_vp->{handle_events} = sub {
    Test::More::is($_[1]->{name}, 'blah', 'Event delivered ok');
  };
  $window->flush_events;
}

1;
