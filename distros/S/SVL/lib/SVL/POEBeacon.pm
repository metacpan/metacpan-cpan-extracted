package POEBeacon;
use strict;
use warnings;
use Sys::HostIP;
use POE qw(Component::Server::TCP Filter::Reference Filter::Stream);

# this is the beacon daemon port for beacon clients
POE::Component::Server::TCP->new(
  Port  => 5678,
  Error => \&error_handler,    # Optional.

  SessionParams => [ options => { debug => 1 } ],    # Optional.

  ClientInput        => \&handle_client_input,       # Required.
  ClientDisconnected => \&handle_client_disconnect,  # Optional.

  #   ClientError        => \&client_ha,      # Optional.
  ClientFilter => "POE::Filter::Reference",          # Optional.
);

sub error_handler {
  my ($syscall_name, $error_number, $error_string) = @_[ ARG0, ARG1, ARG2 ];
  die "Error in '$syscall_name': $error_string ($error_number)";
}

our $port      = 18000;
our $stream_id = 1;

our %streams;
our $alias = 1;
our %hosts;


sub handle_client_input {
  my $data   = $_[ARG0];

  if($data->{type} eq 'register') {
      $_[HEAP]->{host} = $data->{uuid};
      $hosts{$data->{uuid}} = $_[HEAP]->{client};
#      warn "Got uuid for '$data->{uuid}'\n";
      $_[HEAP]->{client}->put({ type => 'listen', address => hostip(), port => $port, uuid => $data->{uuid} });
      return;
  }


  my $client = $streams{ $data->{stream} };

  if($data->{data} =~/\( success \( 1 2 \( ANONYMOUS \) \( edit-pipeline \) \) \)/) {
      return;
  }

  $data->{data} =~s[(\( success \( \) \) \( success \( \d+\:.*? \d+\:svn\://.+?/)][${1}$_[HEAP]->{host}/];
  if($1) {
      $data->{data} =~/\( success \( \) \) \( success \( \d+\:.*? (\d+)\:svn\:/;
      my $length = $1 + 37;
      $data->{data} =~s[(\( success \( \) \) \( success \( \d+\:.*? )\d+(\:svn\:)][$1$length$2];
  }


#  warn "svl<-svn $data->{data}\n";
 
  $client->put($data->{data});
}

sub handle_client_disconnect {
  my $heap = $_[HEAP];
  foreach my $alias (keys %{ $heap->{aliases} }) {
    $poe_kernel->post($alias => 'shutdown');
  }

}

POE::Component::Server::TCP->new(
    Port          => 18000,
    Error         => \&error_handler,                  # Optional.
    SessionParams => [ options => { debug => 1 } ],    # Optional.   ),
    Alias         => "alias_$alias",
				 
    ClientConnected => sub {
	$_[HEAP]->{connected} = 0;
	$_[HEAP]->{stream} = $stream_id;
	$streams{ $stream_id++ } = $_[HEAP]->{client};
	$_[HEAP]->{client}->put("( success ( 1 2 ( ANONYMOUS ) ( edit-pipeline ) ) )\n");
    },
    ClientInput => sub {
      #warn $_[ARG0] . "\n";
      $_[ARG0] =~s[(edit-pipeline \) \d+\:svn\://.+?)/(.*?)/][$1/];
      my $host = $2;
      if($1) {
	  #warn "Data: " . $_[ARG0] . "\n";
	  $_[ARG0] =~/edit-pipeline \) \d+\:(.*?) \)/;
	  my $length = length($1);
	  $_[ARG0] =~s[edit-pipeline \) (\d+)\:][edit-pipeline \) $length:];
	  unless($_[HEAP]->{connected}) {
	      my $client = $hosts{$host};
	      $_[HEAP]->{remote_client} = $client;
	      die "We don't know host '$host'" unless $client;
	      $_[HEAP]->{connected} = 1;
	      $client->put
		  ({
		      type    => 'connect',
		      stream  => $_[HEAP]->{stream},
		      address => $_[HEAP]->{remote_ip}
		  });

	  }
	  #warn "Data '" . $_[ARG0] . "\n";
      }
#      warn "svl->svn" . $_[ARG0] . "\n";
      if($_[HEAP]->{remote_client}) {
	  $_[HEAP]->{remote_client}->put
	      ({ type => 'data', data => $_[ARG0], stream => $_[HEAP]->{stream} });
      } else {
	  warn "Haven't connected stream";
      }
	  			 

    },
    ClientDisconnected => sub {
      delete($streams{ $_[HEAP]->{stream} });
      #$heap->{client}
      #  ->put({ type => 'disconnect', stream => $_[HEAP]->{stream} }),;
    },
    ClientFilter => "POE::Filter::Stream",    # Optional.

    );


while (1) {
  eval { $poe_kernel->run(); };
  warn $@;
}
1;
