package PerlGuard::Agent::Output::PerlGuardServer;
use Moo;
extends 'PerlGuard::Agent::Output';

use HTTP::Async;
use Encode;
use JSON;
use HTTP::Request;
use HTTP::Headers;
use Time::HiRes;

has api_key => ( is => 'rw', lazy => 1, default => \&_attempt_to_fetch_api_key_from_env_or_die);
has base_url => ( is => 'rw', lazy => 1, default => \&DEFAULT_BASE_URL );

has async_http => ( is => 'rw', lazy => 1, default => sub { HTTP::Async->new(timeout => 2, max_request_time=>2, slots=>1000000); });

has disabled_until => (is => 'rw', lazy => 1, default => sub { [0,0] });

has headers => (is => 'rw', lazy => 1, default => sub { 
  HTTP::Headers->new( 
      'X-API-KEY' => shift->api_key, 
      'content-type' => 'application/json'
    ) 
});

has json_encoder => ( is => 'rw', lazy => 1, default => sub { JSON->new->utf8->convert_blessed->allow_blessed });

sub DEFAULT_BASE_URL {
  return 'https://perlguard.com';
}

sub _attempt_to_fetch_api_key_from_env_or_die {
  my $self = shift;
  return $ENV{PERLGUARD_API_KEY} || die "No api_key specified, can be specified in PerlGuard::Agent->new() or with an ENV var named PERLGUARD_API_KEY";
}

sub save {
  my $self = shift;
  my $profile = shift;

  return unless $profile->should_save();
  my $content;

  do {
    no warnings 'uninitialized'; #Protect our end users from any future errors we might make here

    my $controller = $profile->controller || $profile->http_code;
    my $action = $profile->controller_action || $profile->url;

    $content = {
      "start_time" => $profile->start_time,
      "finish_time" => $profile->finish_time,
      "total_elapsed_time_in_ms" => $profile->total_elapsed_time_in_ms,
      "cross_application_tracing_id" => $profile->cross_application_tracing_id,
      # "project_id": 10,
      "type" => "web",
      "grouping_name" => $controller . '#' . $action,
      "database_transactions" => $self->format_database_transactions($profile),
      "web_transactions" => $self->format_webservice_transactions($profile),   
      "database_elapsed_time_in_ms" => $profile->database_elapsed_time_in_ms,
      "web_elapsed_time_in_ms" => $profile->webservice_elapsed_time_in_ms,
      "sum_of_database_transactions" => $profile->database_transaction_count,
      "sum_of_web_transactions" => $profile->webservice_transaction_count,
    };

    $content = $self->json_encoder->encode($content);

  };

  

  #warn $content;

  $self->check_responses();

  unless($self->can_run_yet()) {
    warn "Skipping due to previous errors\n";
    return;
  }

  #without_collectors_do {} - We can't really include sending this report in the request time..

  if($self->async_http->to_send_count > 250) {
    warn  "PerlGuard send queue has reached 250, dropping subsequent requests\n";
    return;
  }

  if($self->async_http->in_progress_count > 250) {
    warn  "PerlGuard in progress count queue has reached 250, dropping subsequent requests\n";
    return;
  }

  my $request_id = $self->async_http->add( HTTP::Request->new( 
    POST => $self->base_url . "/collector/v1/profile",
    $self->headers,
    $content
  ));

  while($self->async_http->to_send_count > 0) {
    $self->async_http->poke();
  }

  #warn "completed send";

  # This helped keep things cleaner on local but it quite obviously causes a race condition, 
  #$self->async_http->remove($request_id);


}

sub flush {
  my $self = shift;

  while($self->async_http->not_empty) {
    $self->async_http->next_response( $self->async_http->max_request_time );
  }
}

sub check_responses {
  my $self = shift;

  while(my $response = $self->async_http->next_response) {
    if($response->is_error) {
      #print STDERR "Response is " . $response->as_string ."\n";

      my $next_run_time = [Time::HiRes::gettimeofday];
      $next_run_time->[0]++;

      $self->disabled_until($next_run_time);

    }

  }; #Clear queue  
}

sub can_run_yet {
  my $self = shift;

  return Time::HiRes::tv_interval( $self->disabled_until ) >= 0 ? 1 : 0;
}

sub format_database_transactions {
  my $self = shift;
  my $profile = shift;

  my @results;

  foreach my $row(@{$profile->database_transactions}) {
    if($row->{start_time}) {
      $row->{start_time_offset} = $profile->calculate_time_index_in_ms($row->{start_time});
    }
    if($row->{finish_time}) {
      $row->{finish_time_offset} = $profile->calculate_time_index_in_ms($row->{finish_time});
    }

    push @results, $row;
  }

  return \@results;

}

sub format_webservice_transactions {
  my $self = shift;
  my $profile = shift;

  my @results;

  foreach my $row(@{$profile->webservice_transactions}) {
    if($row->{start_time}) {
      $row->{start_time_offset} = $profile->calculate_time_index_in_ms($row->{start_time});
    }
    if($row->{finish_time}) {
      $row->{finish_time_offset} = $profile->calculate_time_index_in_ms($row->{finish_time});
    }

    push @results, $row;

  }

  return \@results;

}




1;