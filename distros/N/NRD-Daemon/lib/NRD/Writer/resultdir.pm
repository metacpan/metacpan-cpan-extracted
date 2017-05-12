package NRD::Writer::resultdir;

use strict;
use warnings;

use base 'NRD::Writer';

use File::Temp qw//;
use POSIX;

use Time::HiRes qw(gettimeofday time);

sub new {
  my ($class, $options) = @_;
  $options = {} if (not defined $options);
  my $self = {
    check_result_path => undef,
    %$options
  };

  die "No check_result_path specified" if (not defined $self->{'check_result_path'});
  die "check_result_path doesn't exist" if (not -d $self->{'check_result_path'});

  bless($self, $class);
}

sub _file_header {
  my ($self, $result_time) = @_;

  # We take time to be the first result in the list - this maybe extended in future
  # so that we use the time of each result independently
  #my $result_time = $result_list->[0]->{time};

  my $nagios_str  =         "### Passive Check Result File ###\n";
  $nagios_str .= sprintf("file_time=%d\n", $result_time);
  $nagios_str .=         "### NRD Check ###\n";
  $nagios_str .= sprintf("# Time: %s\n\n", scalar(localtime($result_time)));

  return $nagios_str;
}

sub write {
  my ($self, $result_list) = @_;
  my $config = $self->{'server'};

  if (ref $result_list ne "ARRAY") {
    $result_list = [ $result_list ];
  }

  if (not defined $self->{'_fh'}){
    # Filename must be prefixed with c to be read by Nagios
    ($self->{'_fh'}, $self->{'_filename'}) = File::Temp::tempfile( 'cXXXXXX', DIR => $self->{'check_result_path'});

     # We take time to be the first result in the list - this maybe extended in future
     # so that we use the time of each result independently
     # Also, check that the client time is not ahead of server time
     my $result_time = $result_list->[0]->{time};
     my ($now, $usecs) = gettimeofday();
     if ($result_time > $now) {
        $result_time = $now;
     }
     $self->{'_fh'}->print($self->_file_header($result_time));

  }

  foreach my $result (@$result_list) {
    $self->{'_fh'}->print($self->single_result($result));
  }
}

sub commit {
  my ($self) = @_;

  # someone can just connect and commit
  die "No results spooled" if (not defined $self->{'_fh'});

  close $self->{'_fh'};
  $self->{'_fh'} = undef;

  # Now that we've written the result, we have to signal Nagios that it's OK to process it
  my $signal_file = "$self->{'_filename'}.ok";
  $self->{'_filename'} = undef;

  sysopen my $signal, $signal_file, POSIX::O_WRONLY|POSIX::O_CREAT|POSIX::O_NONBLOCK|POSIX::O_NOCTTY or die("Can't create signal $signal_file: $!");
  close $signal or die("Can't close signal $signal_file: $!");
}

sub single_result {
  my ($self, $result) = @_;

  my $nagios_str;

  # TODO: Where to put time: file_time? start_time? finish_time?

  $nagios_str .= sprintf("host_name=%s\n",   $result->{host_name});

  if (defined $result->{svc_description}){
    $nagios_str .= sprintf("service_description=%s\n", $result->{svc_description});
  }

  $nagios_str .=         "check_type=1\n"; # 1 is for passive checks
  $nagios_str .=         "scheduled_check=0\n";
  $nagios_str .=         "reschedule_check=0\n";

  # Check that the client time is not ahead of server time
  my ($now, $usecs) = gettimeofday();
  if ($result->{time} > $now) {
    $result->{time} = $now;
  }

  # Make this the difference between now and the time in the result
  my $latency = time() - $result->{time};
  $nagios_str .=         sprintf("latency=%0.5f\n", $latency);

  # Not sure what this should be. The .0 is required for Nagios to read the value correctly
  $nagios_str .=         "start_time=".$result->{'time'}.".0\n";
  $nagios_str .=         "finish_time=".$result->{'time'}.".0\n";
  $nagios_str .= sprintf("return_code=%d\n", $result->{return_code});
  $nagios_str .= sprintf("output=%s\n\n",   $result->{plugin_output});

  return $nagios_str;
}

1;
