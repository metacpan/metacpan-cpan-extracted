package HakkefuinTestSimple::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::Util qw(secure_compare dumper);

# User :
my $USERS = {yusrideb => 's3cr3t1', another => 's3cr3t2'};

sub login {
  my $c = shift;

  # Query or POST parameters
  my $user = $c->param('user') || '';
  my $pass = $c->param('pass') || '';

  if ($USERS->{$user} && secure_compare $USERS->{$user}, $pass) {

    return $c->render(
      text => $c->mhf_signin($user) ? 'login success' : 'error login');
  }
  else {
    return $c->render(text => 'error user or pass');
  }
}

sub login_custom {
  my $c = shift;

  my $user = $c->param('user') || '';
  my $pass = $c->param('pass') || '';
  my %opts;
  for my $key (qw(c_time s_time cl_time)) {
    my $val = $c->param($key);
    $opts{$key} = $val if defined $val && $val ne '';
  }

  if ($USERS->{$user} && secure_compare $USERS->{$user}, $pass) {
    my $res = $c->mhf_signin($user, \%opts);
    my $ok  = $res && ref $res eq 'HASH' ? $res->{code} : undef;
    return $c->render(text => $ok
        && $ok == 200 ? 'login success' : 'error login');
  }

  return $c->render(text => 'error user or pass');
}

sub csrf_reset {
  my $c = shift;

  my $data_result = 'can\'t reset';
  my $result      = $c->mhf_has_auth();
  if ($result->{result} == 1) {
    $data_result = 'error reset';
    my $do_reset = $c->mhf_csrf_regen($c->stash('mhf.backend-id'));
    $data_result = 'success reset' if ($do_reset->[0]->{result} == 1);
  }
  $c->render(text => $data_result);
}

sub lock {
  my $c      = shift;
  my $result = $c->mhf_lock();
  my $text
    = $result->{result} == 1 ? 'locked'
    : $result->{result} == 2 ? 'already locked'
    :                          'lock failed';

  $c->render(text => $text);
}

sub unlock {
  my $c      = shift;
  my $result = $c->mhf_unlock();
  my $text   = $result->{result} == 1 ? 'unlocked' : 'unlock failed';

  $c->render(text => $text);
}

sub update {
  my $c = shift;

  my $data_result = 'can\'t update auth';
  my $result      = $c->mhf_has_auth();
  if ($result->{result} == 1) {
    $data_result = 'error update auth';
    my $do_reset = $c->mhf_auth_update($c->stash('mhf.backend-id'));
    $data_result = 'success update auth' if ($do_reset->{code} == 200);
  }
  $c->render(text => $data_result);
}

sub update_custom {
  my $c = shift;

  my %opts;
  for my $key (qw(c_time s_time cl_time)) {
    my $val = $c->param($key);
    $opts{$key} = $val if defined $val && $val ne '';
  }

  my $data_result = 'can\'t update auth';
  my $result      = $c->mhf_has_auth();
  if ($result->{result} == 1) {
    my $do_reset = $c->mhf_auth_update($c->stash('mhf.backend-id'), \%opts);
    $data_result = 'success update auth custom' if ($do_reset->{code} == 200);
  }
  $c->render(text => $data_result);
}

sub stash_check {
  my $c = shift;
  my $check_stash
    = $c->mhf_has_auth()->{code} == 200
    ? $c->stash->{'mhf.identify'}
    : 'fail stash login';
  $c->render(text => $check_stash);
}

sub logout {
  my $c = shift;

  my $check_auth = $c->mhf_has_auth();
  if ($check_auth->{'code'} == 200) {
    if ($c->mhf_signout($c->stash->{'mhf.identify'})->{code} == 200) {
      $c->render(text => 'logout success');
    }
  }
}

1;
