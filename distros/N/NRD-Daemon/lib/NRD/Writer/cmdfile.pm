package NRD::Writer::cmdfile;

use strict;
use warnings;

use base 'NRD::Writer';

use POSIX;

sub new {
  my ($class, $options) = @_;
  $options = {} if (not defined $options);
  my $self = {
    'nagios_cmd' => undef,
    'alternate_dump_file' => undef,
    %$options
  };

  die "No nagios_cmd file specified" if (not defined $self->{'nagios_cmd'});

  bless($self, $class);
}


sub write {
  my ($self, $result) = @_;
  my $config = $self->{'server'};
  my $nagios_str;
  if ( defined $result->{svc_description} ) {
     $nagios_str = sprintf('[%d] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s',
                           $result->{time},
                           $result->{host_name},
                           $result->{svc_description},
                           $result->{return_code},
                           $result->{plugin_output});
# Format got from POE-Component-Server-NSCA documentation
#     $string = "[$time] PROCESS_SERVICE_CHECK_RESULT";
#     $string = join ';', $string, $message->{host_name}, $message->{svc_description},
#                 $message->{return_code}, $message->{plugin_output};
  } else {
      $nagios_str = sprintf('[%d] PROCESS_HOST_CHECK_RESULT;%s;%d;%s',
                            $result->{time},
                            $result->{host_name},
                            $result->{return_code},
                            $result->{plugin_output});
# Format got from POE-Component-Server-NSCA documentation
#     $string = "[$time] PROCESS_HOST_CHECK_RESULT";
#     $string = join ';', $string, $message->{host_name}, $message->{return_code},
#                 $message->{plugin_output};
  }

  if (sysopen (my $fh , $self->{'nagios_cmd'}, POSIX::O_WRONLY)){
    print $fh "$nagios_str\n";
    close $fh;
  } elsif (defined $self->{'alternate_dump_file'}) {
    open (my $alt, '>>', $self->{'alternate_dump_file'}) or die "Couldn't write to alternate_dump_file $!";
    print $alt "$nagios_str\n";
    close $alt;
  } else {
    die "Couldn't write to nagios_cmd file";
  }
#  print { sysopen (my $fh , $self->{'nagios_cmd'}, POSIX::O_WRONLY) or die "$!\n"; $fh } $nagios_str, "\n";
}

sub commit {
   # commit is a noop for cmdfile
   # each result gets written inmediately to Nagios
}

1;
