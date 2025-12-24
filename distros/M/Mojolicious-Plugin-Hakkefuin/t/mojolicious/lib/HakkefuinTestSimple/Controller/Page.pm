package HakkefuinTestSimple::Controller::Page;
use Mojo::Base 'Mojolicious::Controller';

sub homepage {
  my $c = shift;
  $c->render(
    text => 'Welcome to Sample testing Mojolicious::Plugin::Hakkefuin');
}

sub login_page {
  my $c = shift;
  $c->render(text => 'login');
}

sub page {
  my $c = shift;
  $c->render(
    text => $c->mhf_has_auth()->{'code'} == 200 ? 'page' : 'Unauthenticated');
}

1;
