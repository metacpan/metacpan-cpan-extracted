package Mojolicious::Sessions::Storage;
use Mojo::Base 'Mojolicious::Sessions';
use Digest::SHA1 ();

our $VERSION = '0.01';

has 'session_store';
has token_name => "token";


has sid_generator => sub{
    sub{
      Digest::SHA1::sha1_hex( rand() . $$ . {} . time );
    };
  };

sub new{
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  
  if($self->session_store
    && !Mojolicious::Controller->can('session_options'))
  {
    Mojolicious::Controller->attr(
      session_options => sub{
        $_[0]->stash->{'mojox.session.options'} ||= {};
      },
    );
  }
  
  return $self;
}

sub load{
  my ( $self, $c ) = @_;
  
  return $self->SUPER::load($c) unless( $self->session_store );
  
  my $stash = $c->stash;
  
  my ( $session_id, $session ) = $self->get_session($c);
  unless($session_id && $session){
    $session_id = $self->generate_id($c->req->env);
  }
  $stash->{'mojox.session.options'} = {id => $session_id};
  return unless($session);
  
  # "expiration" value is inherited
  my $expiration = $session->{expiration} // $self->default_expiration;
  return if(!(my $expires = delete $session->{expires}) && $expiration);
  return if(defined $expires && $expires <= time);
  
  return unless($stash->{'mojo.active_session'} = keys %{$session});
  $stash->{'mojo.session'} = $session;
  $session->{flash} = delete $session->{new_flash} if($session->{new_flash});
}

sub store{
  my ( $self, $c ) = @_;
  
  return $self->SUPER::store($c) unless( $self->session_store );
  
  # Make sure session was active
  my $stash = $c->stash;
  return unless(my $session = $stash->{'mojo.session'});
  return unless(keys %{$session} || $stash->{'mojo.active_session'});
  
  # Don't reset flash for static files
  my $old = delete $session->{flash};
  @{ $session->{new_flash} }{ keys %{$old} } = values %{$old}
    if($stash->{'mojo.static'});
  delete $session->{new_flash} unless(keys %{ $session->{new_flash} });
  
  # Generate "expires" value from "expiration" if necessary
  my $expiration = $session->{expiration} // $self->default_expiration;
  my $default = delete $session->{expires};
  $session->{expires} = $default || time + $expiration
    if($expiration || $default);
  
  $self->set_session($c, $session) unless($c->session_options->{no_store});
  
  my $options = {
    domain   => $self->cookie_domain,
    expires  => $session->{expires},
    httponly => 1,
    path     => $self->cookie_path,
    secure   => $self->secure
  };
  $c->signed_cookie(
    $self->cookie_name,
    $c->session_options->{id},
    $options,
  );
}

sub generate_id{
  my ( $self, $env ) = @_;
  $self->sid_generator->($env);
}

sub get_session{
  my ( $self, $c ) = @_;
  
  my $session_id = $c->param($self->token_name) || $c->signed_cookie($self->cookie_name) or return;
  my $session = $self->session_store->fetch($session_id) or return;
  
  return ( $session_id, $session );
}

sub set_session{
  my ( $self, $c, $session ) = @_;
  
  if($c->session_options->{expire} || ( defined $session->{expires} && $session->{expires} <= time )){
    $session->{expires} = 1;
    $self->session_store->remove($c->session_options->{id});
  }
  elsif($c->session_options->{change_id}){
    $self->session_store->remove($c->session_options->{id});
    $c->session_options->{id} = $self->generate_id($c->req->env);
    $self->session_store->store($c->session_options->{id}, $session);
  }
  else{
    $self->session_store->store($c->session_options->{id}, $session);
  }
}

1;

1; # End of Mojolicious::Sessions::Storage
