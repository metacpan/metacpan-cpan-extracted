package PerlGuard::Agent;
use 5.010001;
use Moo;
use PerlGuard::Agent::Profile;
use Scalar::Util;
use Data::UUID;

our @ISA = qw();
our $VERSION = '0.15';

has output_method => ( is => 'rw', lazy => 1, default => sub { 'PerlGuard::Agent::Output::PerlGuardServer' } );
has output => (is => 'lazy' );

has profiles => ( is => 'rw', default => sub { {} });
has monitors => ( is => 'rw', default => sub { [] });

has async_mode => (is => 'rw', default => sub { 0 });
has api_key => (is => 'rw');

has data_uuid => (is => 'ro', default => sub { Data::UUID->new });

has warnings => (is => 'rw', default => sub { 0 });

our $CURRENT_PROFILE_UUID = undef;

# Current profile only makes sense in a sync app which can only have one request running at a time
# Alternatively it could be used with a local statment elsewhere in an async app to make use of lexical scoping
sub current_profile {
  my $self = shift;

  warn "current_profile is meaningless when running in async mode" if $self->async_mode();

  #Check if $CURRENT_PROFILE has a value in is
  if(defined $CURRENT_PROFILE_UUID) {
    if($self->profiles->{$CURRENT_PROFILE_UUID}) {
      if($self->warnings) {
        warn "Profile identified has finished, this should not happen" if $self->profiles->{$CURRENT_PROFILE_UUID}->has_finished();
      }
      return $self->profiles->{$CURRENT_PROFILE_UUID};
    }
    else {
      if($self->warnings) {
        warn "the package variable CURRENT_PROFILE_UUID is not defined, this is potentially a race condition bug";
      }
    }
  }
  else {
    if($self->warnings) {
      warn "Using fallback mechanism to identify profile";
    }

    # This is not safe, as we could get monitors reporting on the wrong profile
    my @uuids = keys %{ $self->profiles };
    if(scalar(@uuids) == 1) {
      return $self->profiles->{$uuids[0]};
    }
    else {
      if($self->warnings) {
        warn "Could not identify the most recent profile, we had " . scalar(@uuids) . "  profiles currently active with keys @uuids and the current profile var thinks its " . $CURRENT_PROFILE_UUID  ;
      }
      return;
    }
  }

}

sub _build_output {
  my $self = shift;

  my $output_method = $self->output_method();
  eval "require $output_method";
  die "Cannot require module $output_method, perhaps you specified an invalid module name in output_method" if $@;

  my @params;
  push(@params, api_key => $self->api_key) if($self->api_key);

  return $output_method->new( @params );
}


# This supports a transaction being added for a specific profile, which is a future feature we will need to support async apps
# For now though when this is called there should only ever be one profile in process (sync app)
sub add_database_transaction {
  my $self = shift;
  my $database_transaction = shift;
  my $intended_profile_uuid = shift;

  if($intended_profile_uuid and (my $profile = $self->profiles->{$intended_profile_uuid})) {
    $profile->add_database_transaction($database_transaction);
  } else {
    # Profile not specified! Time to guess

    my $current_profile = $self->current_profile;
    if($current_profile && Scalar::Util::blessed($current_profile)) {
      $current_profile->add_database_transaction($database_transaction);
    }
    else {
      if($self->warnings) {
        warn "Caught a database transaction occuring outside of a profile";
      }
    }
    
    
  }
}

sub add_webservice_transaction {
  my $self = shift;
  my $web_transaction = shift;
  my $intended_profile_uuid = shift;

  if($intended_profile_uuid and (my $profile = $self->profiles->{$intended_profile_uuid})) {
    $profile->add_webservice_transaction($web_transaction);
  } else {
    # Profile not specified
    my $current_profile = $self->current_profile;
    if($current_profile && Scalar::Util::blessed($current_profile)) {
      $current_profile->add_webservice_transaction($web_transaction);;
    }
    else {
      if($self->warnings) {
        warn "Caught a web transaction occuring outside of a profile"
      }
    }    
  }

}

sub create_new_profile {
  my $self = shift;

  my $profile = PerlGuard::Agent::Profile->new({
    # Set some things
    uuid => $self->data_uuid->create_str(),
    agent => $self
  });

  $self->profiles->{$profile->uuid} = $profile;
  Scalar::Util::weaken($self->profiles->{$profile->uuid});

  return $profile;
}

sub remove_profile {
  my $self = shift;
  my $profile_id = shift;
  $profile_id = $profile_id->uuid() if Scalar::Util::blessed($profile_id);

  delete $self->profiles->{$profile_id};
}

sub detect_monitors {
  my $self = shift;

  foreach my $monitor(qw( PerlGuard::Agent::Monitors::DBI PerlGuard::Agent::Monitors::NetHTTP  )) {
    eval {
      eval "require $monitor; 1" or die "skipping loading monitor $monitor";
      my $monitor = $monitor->new(agent => $self);
      $monitor->die_unless_suitable();
      push(@{$self->monitors}, $monitor);
      1;
    } or do {
      warn "Error when loading monitor $monitor: " . $@;
      next;
    }
  }

}

sub start_monitors {
  my $self = shift;

  foreach my $monitor(@{$self->monitors}) { $monitor->start_monitoring() }
}

sub stop_monitors {
  my $self = shift;

  foreach my $monitor(@{$self->monitors}) { $monitor->stop_monitoring() }
}

1;
__END__
=head1 NAME

PerlGuard::Agent - Trace your application performance with PerlGuard

=head1 SYNOPSIS

  use PerlGuard::Agent;
  my $agent = PerlGuard::Agent->new($config);
  my $profile = $agent->create_new_profile();
  $profile->start_recording;
  $profile->url( $my_url );
  $profile->http_method( $my_http_method );
  $profile->controller( "My::Controller" );
  $profile->controller_action( "index_pages" );
  $profile->finish_recording;
  # Let variables fall out of scope to perform cleanup

=head1 DESCRIPTION

This is the PerlGuard agent which will help you collect and store 
metrics also known as application performance monitoring. You will usually use
on of the plugins to integrate assuming you are using a supported framework.

DBI is required for DBI monitoring
Net::HTTP is requires for HTTP monitoring

=head1 AUTHOR

Jonathan Taylor, E<lt>jon@stackhaus.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Stackhaus LTD

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
