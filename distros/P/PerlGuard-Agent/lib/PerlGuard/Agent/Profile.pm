# This is a single web request, or a single execution of a script

package PerlGuard::Agent::Profile;
use 5.010001;
use Moo;
use Time::HiRes;

has agent => ( is => 'ro', required => 1, weak_ref => 1);

has uuid => ( is => 'lazy' );
has start_time => ( is => 'ro' );
has finish_time => ( is => 'ro' );
has start_time_hires => ( is => 'ro' );
has finish_time_hires => ( is => 'ro' );

has url => ( is => 'rw' );
has http_method => ( is => 'rw' );
has controller => ( is => 'rw' );
has controller_action => ( is => 'rw' );
has http_code => ( is => 'rw' );

has should_save => ( is => 'rw', default => sub { 1 } );

# has user; # A user definable value
# has script_name; # Superceeded by grouping_name which is more generic
# has hostname;
# has server_name;

has database_transactions => ( is => 'rw', default => sub {[]});
has webservice_transactions => ( is => 'rw', default => sub {[]});;

has cross_application_tracing_id => ( is => 'rw', default => sub { undef });

sub _build_uuid {
  my $self = shift;

  return "$self"; # Switch to an actual UUID later
}

sub start_recording {
  my $self = shift;

  $self->{start_time_hires} =  [Time::HiRes::gettimeofday()];
  $self->{start_time} = DateTime->now();
}

sub pause_recording {

}

sub finish_recording {
  my $self = shift;

  $self->{finish_time_hires} =  [Time::HiRes::gettimeofday()];
  $self->{finish_time} = DateTime->now();
}

sub has_finished {
  my $self = shift;

  return 1 if defined $self->{finish_time_hires};
  return 0;
}

sub save {
  my $self = shift;

  $self->agent->output->save($self);
}

sub total_elapsed_time {
  my $self = shift;

  return Time::HiRes::tv_interval( $self->{start_time_hires}, $self->{finish_time_hires} );
}

sub total_elapsed_time_in_ms {
  my $self = shift;

  $self->convert_to_ms($self->total_elapsed_time);
}

sub database_transaction_count {
  my $self = shift;

  scalar(@{$self->database_transactions});
}

sub webservice_transaction_count {
  my $self = shift;

  scalar(@{$self->webservice_transactions});
}

sub database_elapsed_time {
  my $self = shift;

  my $total = 0;
  foreach my $database_transaction(@{$self->database_transactions}) {

    #warn $database_transaction->{start_time};

    #warn "start " . join(",", @{$database_transaction->{start_time}});
    #warn "finish " . join(",", @{$database_transaction->{finish_time}});
    #warn "interval " . Time::HiRes::tv_interval( $database_transaction->{start_time}, $database_transaction->{finish_time});

    $total += Time::HiRes::tv_interval( $database_transaction->{start_time}, $database_transaction->{finish_time});
  }

  return $total;
}

sub webservice_elapsed_time {
  my $self = shift;

  my $total = 0;
  foreach my $webservice_transaction(@{$self->webservice_transactions}) {
    $total += Time::HiRes::tv_interval( $webservice_transaction->{start_time}, $webservice_transaction->{finish_time});
  }

  return $total;
}

sub database_elapsed_time_in_ms {
  my $self = shift;

  $self->convert_to_ms($self->database_elapsed_time)
}

sub webservice_elapsed_time_in_ms {
  my $self = shift;

  $self->convert_to_ms($self->webservice_elapsed_time)
}

sub add_database_transaction {
  my $self = shift;
  my $database_transaction = shift;

  push(@{$self->database_transactions}, $database_transaction);
}

sub add_webservice_transaction {
  my $self = shift;
  my $webservice_transaction = shift;

  push(@{$self->webservice_transactions}, $webservice_transaction);
}

sub calculate_time_index_in_ms {
  my $self = shift;
  my $other_time = shift;

  return( $self->convert_to_ms( Time::HiRes::tv_interval($self->{start_time_hires}, $other_time  )));
}

sub convert_to_ms {
  my $self = shift;
  my $thing_to_convert = shift;

  return sprintf("%.0f", $thing_to_convert * 1000)
}

sub do_not_save {
  my $self = shift;

  $self->should_save(0);
}

# Putting the application ID in here would really help the server later on but we aren't requiring the user to specify it yet
sub generate_new_cross_application_tracing_id {
  my $self = shift;

  return $self->{uuid} . '@' . join(',', (Time::HiRes::gettimeofday()));
}

sub DESTROY {
  my $self = shift;

  $self->agent->output->flush();
  $self->agent->remove_profile($self->uuid);
}



1;