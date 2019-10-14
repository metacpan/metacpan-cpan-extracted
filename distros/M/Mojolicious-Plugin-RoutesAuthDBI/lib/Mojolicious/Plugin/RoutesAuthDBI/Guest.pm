package Mojolicious::Plugin::RoutesAuthDBI::Guest;
use Mojo::Base -base;#'Mojolicious::Plugin::Authentication'
use Mojolicious::Plugin::RoutesAuthDBI::Util qw(json_enc json_dec);


has [qw(session_key stash_key app plugin model)];

sub new {
  state $self = shift->SUPER::new(@_);
}

sub current {# Fetch the current guest object from the stash - loading it if not already loaded
  my ($self, $c) = @_;
  
  my $stash_key = $self->stash_key;
  
  $self->_loader($c)
    unless
      defined($c->stash($stash_key))
      && ($c->stash($stash_key)->{no_guest}
        || defined($c->stash($stash_key)->{guest}));

  my $guest_def = defined($c->stash($stash_key))
                    && defined($c->stash($stash_key)->{guest});

  return $guest_def ? $c->stash($stash_key)->{guest} : undef;
}

# Unconditionally load the guest based on id in session
sub _loader {
  my ($self, $c) = @_;
  my $gid = $c->session($self->session_key);
  
  my $guest = defined($gid) && $self->load($gid);
    #~ if defined $gid;

  if ($guest) {
      $c->stash($self->stash_key => { guest => $guest });
  }
  else {
      # cache result that guest does not exist
      $c->stash($self->stash_key => { no_guest => 1 });
  }
}

sub load {
  my ($self, $gid) = @_;
  
  my $guest = $self->model->get_guest($gid);
  
  if ( $guest && $guest->{id}) {
    my $json = $guest->{data} && json_dec(delete $guest->{data});
  
    @$guest{ keys %$json } = values %$json
      if $json;
    
    $self->app->log->debug("Success loading guest by id=$gid");
    return $guest;
  }
  $self->app->log->debug("Failed loading guest by id=$gid");
  
  return undef;
}

 sub reload {
  my ($self, $c) = @_;
  # Clear stash to force a reload of the guest object
  delete $c->stash->{$self->stash_key};
  return $self->current($c);
}

sub is_guest {
  my ($self, $c) = @_;
  return defined($self->current($c)) ? 1 : 0;
}

sub logout {
  my ($self, $c) = @_;
  delete $c->stash->{$self->stash_key};
  delete $c->session->{$self->session_key};
}

 sub store {# new guest
    my ($self, $c, $data) = @_;
    
    $data ||= {};
    $data->{headers} = $c->req->headers->to_hash(1);
    $data->{IP} = $c->tx->remote_address;

    my $guest = $self->model->store(json_enc($data));
    $c->session($self->session_key => $guest->{id});
    $c->stash($self->stash_key => { guest => $guest });
    
    return $guest;
}


1;

=pod

=encoding utf8

Доброго всем



=head1 Mojolicious::Plugin::RoutesAuthDBI::Guest

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

Mojolicious::Plugin::RoutesAuthDBI::Guest - session for guests. Store guests in separate DBI table.

=head1 SYNOPSIS

    $app->plugin('RoutesAuthDBI', 
        ...
        guest => {< hashref options list below >},
        ...
    );

=head1 OPTIONS

=head2 namespace

String, default to 'Mojolicious::Plugin::RoutesAuthDBI'.

=head2 module

String, default to 'Guest' (this module).

=head2 session_key

String, session storage of guest data. Default to 'guest_data'.

=head2 tables

Hashref, any DB tables names. See L<Mojolicious::Plugin::RoutesAuthDBI::Schema#Default-variables-for-SQL-templates>.

=head2 table

String, DB table B<guests> name. See L<Mojolicious::Plugin::RoutesAuthDBI::Schema#Default-variables-for-SQL-templates>.


=head1 METHODS

=head2 current($controller)

Get current guest hashref by session and undef overwise.

  my $guest = $c->access->plugin->guest->current($c);

=head2 store($controller, $data)

Store guest data in DB table and set session_key. Headers of request save in "data" column.

  $c->access->plugin->guest->store($c, {"Glory"=>"is ♥ for me"});

=head2 is_guest($controller)

True if current session of guest.

  if( $c->access->plugin->guest->is_guest($c) ) {...}

=head2 load($id)

Loads guest data from DB table by its ID row. JSON column "data" will expand.

  my $data = $c->access->plugin->guest->load($id);

=head2 reload($controller)

Cleanup stash and reload guest data.

  my $guest = $c->access->plugin->guest->reload($c);

=head1 SEE ALSO

L<Mojolicious::Plugin::Authentication>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche [on] cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojolicious-Plugin-RoutesAuthDBI/issues>. Pull requests welcome also.

=head1 COPYRIGHT

Copyright 2016+ Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
