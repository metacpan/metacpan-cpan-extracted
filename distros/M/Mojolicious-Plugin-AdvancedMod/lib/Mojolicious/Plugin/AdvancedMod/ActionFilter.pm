package Mojolicious::Plugin::AdvancedMod::ActionFilter;

sub init {
  my $app     = shift;
  my $helpers = shift;

  $helpers->{action_filter} = sub {
    my $self    = shift;
    my %filters = @_;
    
    $self->app->defaults( action_filters => \%filters );

    $self->app->hook(
      before_dispatch => sub {
        my $self = shift;
        _filter( $self, 'BEFORE' );
      }
    );

    $self->app->hook(
      after_dispatch => sub {
        my $self = shift;
        _filter( $self, 'AFTER' );
      }
    );
  };
}

sub _filter {
  my $self     = shift;
  my $type     = shift;
  my $subs     = $self->stash( 'action_filters' );
  my $patterns = {};

  foreach my $ch ( @{ $self->app->routes->children } ) {
    my $pt = $ch->pattern;
    $patterns->{ $pt->pattern || '/' } = $pt->defaults;
  }

  foreach my $pt ( keys %$patterns ) {
    next unless $pt eq $self->req->url->path;

    foreach my $class ( @{ $self->app->routes->namespaces } ) {
      next if lc( $class ) !~ /$patterns->{$pt}{controller}$/;

      my $filters = eval 'return $' . $class . '::' . $type . '_FILTERS';
      next unless $filters;

      foreach my $name ( keys %{$filters} ) {
        foreach my $action ( @{ $filters->{$name} } ) {
          next if $patterns->{$pt}{action} ne $action;

          if ( exists $subs->{$name} ) {
            $self->app->log->info(
              "** ActionFilter: applying " . lc( $type ) . "_filter $name for $patterns->{$pt}{controller}#$patterns->{$pt}{action}" );
            $subs->{$name}->( $self );
          }
          else {
            $self->app->log->error( "** ActionFilter: filter $name not found" );
          }
        }
      }
    }
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod::ActionFilter - Analogue of Rails: before_filter, after_filter

=head1 METHOD

=head2 action_filter

$self->action_filter( filter_name => sub { ... } );

=head1 SYNOPSIS

  # Main app file
  sub startup {
    my $self = shift;
    ...
    $self->action_filter(
      is_auth => sub { shift->render( text => "is_auth filter" ) },
      test    => sub { shift->render( text => "test before_filter" ); },
    );
  }
  
  # Controller
  our $BEFORE_FILTERS = { is_auth => [qw/show/] };
  our $AFTER_FILTERS  = { test    => [qw/show/] };

  sub show {
    my ( $self, $filter, $action ) = @_;
    $self->render( text => 'show action' );
  }

  sub index {
    my $self = shift;
    $self->render( text => 'index action' );
  }
  
  # Log
  [info] Applying before_filter is_auth for example#show
  [info] Applying after_filter test for example#show
  [debug] GET "/show".

=head1 AUTHOR

=over 2

=item

Grishkovelli L<grishkovelli@gmail.com>

=item

https://github.com/grishkovelli/Mojolicious-Plugin-AdvancedMod

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, 2014
Grishkovelli L<grishkovelli@gmail.com>

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
