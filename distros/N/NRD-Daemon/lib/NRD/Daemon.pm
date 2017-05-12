package NRD::Daemon;

use warnings;
use strict;

use Data::Dumper;
use NRD::Packet;
use NRD::Serialize;

use NRD::Writer;

use vars qw($VERSION);
$VERSION = '0.04';

use base qw/Net::Server::MultiType/;

sub _read_from_client {
  my $self = shift;
  my $data = undef;
  eval {
    local $SIG{ALRM} = sub { alarm(0); die "timeout" };
    alarm $self->{'server'}->{'timeout'};
    $data = $self->{'oPacker'}->unpack( $self->{'server'}->{client} );
  };
  alarm(0);
  if ($@) {
    if ($@ =~ m/timeout/){
      $self->log(1, 'Client timeout');
    } else {
      $self->log(2, "Couldn't process packet: $@");
    }
    return undef;
  }
  return $data;
}

sub process_request {
  my $self = shift;
  
  $self->log(4, 'Process Request start');
  my $config = $self->{'server'};
  my $packer = $self->{'oPacker'};

  my $serializer = $self->{'oSerializer'};
  $self->log(4, "Serializer $self->{'oSerializer'}");

  if ($serializer->needs_helo){
    my $helo = $self->_read_from_client;
    return if (not defined $helo);
    #$self->log(4, 'Got HELO: ' . Dumper($helo));
    $serializer->helo($helo);
  }

  my $request = undef;

  while ($request = $self->_read_from_client){
    $self->log(4, "Got Data: " . Dumper($request));

    eval {
      $request = $serializer->unfreeze($request);
    };
    if ($@){
      $self->log(1, "Couldn't unserialize a request: $@");
      next;
    }

    my $command = lc($request->{command});
    if ($command eq "commit") {
        eval {
            $self->{'oWriter'}->commit
        };
        if ($@){
            $self->log(1, "Couldn't commit: $@"); 
        } else {
            # Confirmation of packet processing
            print $packer->pack($serializer->freeze({'command'=>'finished'}));
        }
        last;
    } elsif ($command eq "result") {
        $self->process_result($request->{data});
    } else {
        die "Bad command: $command";
    }
  }
}

sub post_process_request_hook {
  my $self = shift;  
  $self->log(4, 'Disconnected client');
}

sub process_result {
  my ($self, $result) = @_;

  # Don't tell anyone (for the moment) that a writer can write an array of results
  if (ref($result) ne 'HASH') {
    $self->log(1, "Couldn't process a non-hash result");
    return;
  }

  eval {
    $self->{'oWriter'}->write($result);
  };
  if ($@){
    # Error in the write
    $self->log(0, "NRD Writer error: $@");
  }
}

sub options {
  my ($self, $template) = @_;
  my $prop = $self->{'server'};
  $self->SUPER::options($template);

  $prop->{'nagios_cmd'} ||= undef;
  $template->{'nagios_cmd'} = \ $prop->{'nagios_cmd'};

  $prop->{'timeout'} ||= undef;
  $template->{'timeout'} = \ $prop->{'timeout'};

  $prop->{'serializer'} ||= undef;
  $template->{'serializer'} = \ $prop->{'serializer'};

  $prop->{'writer'} ||= undef;
  $template->{'writer'} = \ $prop->{'writer'};

  $prop->{'encrypt_key'} ||= undef;
  $template->{'encrypt_key'} = \ $prop->{'encrypt_key'};

  $prop->{'encrypt_type'} ||= undef;
  $template->{'encrypt_type'} = \ $prop->{'encrypt_type'};

  $prop->{'digest_key'} ||= undef;
  $template->{'digest_key'} = \ $prop->{'digest_key'};

  $prop->{'digest_type'} ||= undef;
  $template->{'digest_type'} = \ $prop->{'digest_type'};

  $prop->{'alternate_dump_file'} ||= undef;
  $template->{'alternate_dump_file'} = \ $prop->{'alternate_dump_file'};

  $prop->{'check_result_path'} ||= undef;
  $template->{'check_result_path'} = \ $prop->{'check_result_path'};

}

sub post_configure_hook {
  my ($self) = @_;

  my $config = $self->{'server'};

  if (not defined $config->{'timeout'}){
    $config->{'timeout'} = 30;
  }

  die "No serializer defined in config" if (not defined $config->{'serializer'});
  $self->log(0, "Using serializer: $config->{'serializer'}");

  eval {
    my $serializer = NRD::Serialize->instance_of($config->{'serializer'},$config);
    $self->{'oSerializer'} = $serializer;
  };
  if ($@) {
    $self->log(0, "Error loading the serializer. $@");
    $self->log(0, "Aborting server start");
    die "\n"; 
  }

  die "No writer defined in config" if (not defined $config->{'writer'});
  $self->log(0, "Using writer: $config->{'writer'}");

  eval {
    my $writer = NRD::Writer->instance_of($config->{'writer'}, $config);
    $self->{'oWriter'} = $writer;
  };
  if ($@) {
    $self->log(0, "Error loading the result writer. $@");
    $self->log(0, "Aborting server start");
    die "\n";
  }

  eval {
    my $packer = NRD::Packet->new();
    $self->{'oPacker'} = $packer;
  };
  if ($@) {
    $self->log(0, "Error loading NRD::Packet. $@");
    $self->log(0, "Aborting server start");
    die "\n";
  }

  return 1;
}


#################### main pod documentation begin ###################

=head1 NAME

NRD::Daemon - NRD Nagios Result Distributor

=head1 SYNOPSIS

  use NRD::Daemon;
  NRD::Daemon->run(conf_file => '/etc/nrd.conf');

=head1 DESCRIPTION

Daemon that attends NRD requests. Is a subclass of Net::Server.

Project Home Page: http://code.google.com/p/nrd/

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

=head1 CONTRIBUTORS

    Ton Voon
    CPAN ID: TONVOON
    Opsera

=head1 COPYRIGHT

Copyright (c) 2010 by Jose Luis Martinez Torres

Licensed under the GNU General Public License v3

The full text of the license can be found in the
LICENSE file included with this module.

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

