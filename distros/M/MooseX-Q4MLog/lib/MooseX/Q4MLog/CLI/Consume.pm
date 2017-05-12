# $Id: /mirror/coderepos/lang/perl/MooseX-Q4MLog/trunk/lib/MooseX/Q4MLog/CLI/Consume.pm 66297 2008-07-16T13:33:55.974156Z daisuke  $

package MooseX::Q4MLog::CLI::Consume;
use Moose::Role;
use Queue::Q4M;
use YAML ();

with 'MooseX::Daemonize';
with 'MooseX::ConfigFromFile';

requires 'consume';

has 'is_running' => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 1
);

has 'table' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'connect_info' => (
    is => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    required => 1,
);

after 'start' => sub {
    my $self = shift;
    return unless $self->is_daemon;

    $self->run;
};

no Moose;

sub get_config_from_file {
    my ($self, $file) = @_;

    return YAML::LoadFile($file);
}

sub run {
    my $self = shift;

    my $queue = Queue::Q4M->new(connect_info => [ $self->connect_info ] );
    while( $self->is_running ) {
        while ( $queue->next( $self->table ) ) {
            $self->consume( $queue->fetch_hashref );
        }
    }
}

1;

__END__

=head1 NAME

MooseX::Q4MLog::CLI::Consume - Daemon Role To Consume Q4M Log

=head1 SYNOPSIS

  package MyConsume;
  use Moose;

  with 'MooseX::Q4MLog::CLI::Consume';

  no Moose;

  sub consume {
    my ($self, $data) = @_;

    # do whatever you want with $data, which is a hashref
  }

  # myconsume.pl
  use MyConsume;
  my $app = MyConsume->new_with_options();
  my ($command) = @{ $app->extra_argv };
  if (! defined $command) {
    die "no command specified";
  }

  $app->start    if $command eq 'start';
  # see MooseX::Daemonize for the rest

=head1 METHODS

=head2 get_config_from_file

Parses a YAML file to get the configuration out of a config file

=head2 run

Starts a loop that consumes the q4m log

=cut
