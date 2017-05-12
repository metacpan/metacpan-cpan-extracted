package PerlGuard::Agent::Monitors::DBI;
use Moo;
use DBI;
use PerlGuard::Agent::Monitors::DBI::Tracer;
use Scalar::Util qw(blessed);

extends 'PerlGuard::Agent::Monitors';

has tracer => ( is => 'rw' );

sub start_monitoring {
  my $self = shift;

  #my $handle;
  #open ($handle,'>>','/tmp/dbi') or die("Cant open /tmp/dbi");
  #print $handle "\n * \n * \n * \n * \n";
  #use Data::Dumper;

  my $tracer = PerlGuard::Agent::Monitors::DBI::Tracer->new(
    sub {
        my %args = @_;

        unless(blessed($self->agent)) {
          #warn "Agent was not a blessed object in DBI monitor";
          #print $handle Dumper \%args;

          return;
        }

        $self->agent->add_database_transaction({
          start_time => $args{start},
          finish_time => $args{finish},
          query => $args{sql},
          rows_returned => $args{rows}
        });
    }
  );

  $self->tracer($tracer);

}

sub stop_monitoring {
  my $self = shift;

  $self->tracer(undef);
}

1;