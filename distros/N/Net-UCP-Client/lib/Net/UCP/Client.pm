package Net::UCP::Client;

use strict;
use warnings;

use Net::UCP;
use IO::Socket;
use IO::Select;
use Time::HiRes qw(usleep setitimer ITIMER_REAL);
use Encode;
#use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(NONOTIFY NOTIFY BYPASS NOBYPASS);

our $VERSION = '0.01';

use constant NONOTIFY => 0;
use constant NOTIFY   => 1;
use constant NOBYPASS => 0;
use constant BYPASS   => 1;

use vars qw($childpid);

sub new {
    my $class = shift || die "Missing class";

    my $args  = @_ == 1 ? shift : {@_};
    my $self  = bless {server => { %$args }}, $class;

    $self->{server}->{alert_wait} = 0;
    $self->{ucp_stuff} = new Net::UCP(FAKE => 1);
    return $self;
}

sub run {
    my $self = ref($_[0]) ? shift() : shift->new(@_);

    #print Dumper(\@_);

    if ($self->establish_smsc_connection()) {

	if ($self->{server}->{user} && $self->{server}->{password}) {
	    $self->login() ? $self->_run_loop() : die "Unable to login";
	}
 
	$self->_run_loop() if (defined $self->{server}->{bypass_auth} && $self->{server}->{bypass_auth});
	   
    } else {
	die "Unable to establish connection with $self->{server}->{smsc_host} on $self->{server}->{smsc_port} [$!]";    
    }
    
}

sub establish_smsc_connection {
    my $self = shift;

    #print Dumper($self);

    $self->{server}->{socket} = IO::Socket::INET->new(
						      LocalAddr => (defined $self->{server}->{src_addr}) ? $self->{server}->{src_addr} : "",
						      LocalPort => (defined $self->{server}->{src_port}) ? $self->{server}->{src_port} : 0,
						      PeerAddr  => $self->{server}->{smsc_host},
						      PeerPort  => $self->{server}->{smsc_port},
						      Proto     => 'tcp',
						      Reuse     => 1,
						      ) or return(0);
    
    return 1;
}

sub login {
    my $self = shift;
    
    my $ucp_login = $self->{ucp_stuff}->make_message(op        => '60',
						     operation => 1,
						     styp      => 1,
						     oadc      => $self->{server}->{user},
						     pwd       => $self->{server}->{password},
						     vers      => '0100',
						     );

    if (defined $ucp_login) {

	$self->{ucp_stuff}->{SOCK} = $self->{server}->{socket};
	my ($ack, $e_num, $resp) = $self->{ucp_stuff}->transmit_msg($ucp_login, $self->{server}->{timeout}, 1);
	
	$self->log("UCP Client login() : ACK = $ack, Error Number = $e_num, Message = $resp");
	return 0 if ($e_num)
	
    } else {
	return 0;
    }
    
    return 1;
}

sub log {
    my $self = shift;
    my $msg  = shift;

    if (defined ($self->{server}->{log_file})) {
	if (open(LOG, ">>$self->{server}->{log_file}")) {
	    print LOG $msg . "\n"; 
	} else {
	    warn "[Unable to open log file $!]";
	}	
    } else {
	print $msg . "\n" if defined($self->{server}->{debug}) && $self->{server}->{debug};
    }
    
    return;
}

sub _run_loop {
    my $self = shift;
    my $pid;

    if ($pid = fork) {
	$self->log("UCP Client : Forking child listener [$pid]");
	$self->set_signal();
	$childpid = $pid;
    } elsif (defined($pid)) {
	$self->start_listener();
    } else {
	$self->log("Unable to start listener");
	die "Unable to start listener [$!]"; 
    }
    
    for (;;) { usleep(500_000); }
    return;
}

sub set_signal {
    my $self = shift;

    $SIG{CHLD} = \&child_die;
    $SIG{INT}  = \&must_die;
    $SIG{HUP}  = \&must_die;
    $SIG{TERM} = \&must_die;

    if (exists $self->{server}->{send_hook_time} && $self->{server}->{send_hook_time} =~ m/\d+/) {
	#print "Set signal\n";
	$SIG{ALRM} = sub { 
	    setitimer(ITIMER_REAL, 0, 0);
	    $self->{server}->{alert_wait} += $self->{server}->{send_hook_time};
	    if ($self->{server}->{alert_time} <= $self->{server}->{alert_wait}) {
		$self->{server}->{alert_wait} = 0;         #init alert time counter :: TODO ::
		$self->send_alert("0123456789", "0539");   #you will see an error in ucp response, but it will work as a keep alive :)
	    }
	    $self->{server}->{send_hook}(); 
	    setitimer(ITIMER_REAL, $self->{server}->{send_hook_time}, 0); 
	};
	setitimer(ITIMER_REAL, $self->{server}->{send_hook_time}, 0);
    }

    return;
}

sub child_die {
    my $waitedpid = wait;
    $SIG{CHLD} = \&child_die;    
    return;
}

sub must_die {
    kill 9, $childpid if ($childpid);
    exit;
}

sub start_listener {
    my $self    = shift;
    
    my (@ready, $fh);
    my $s = new IO::Select($self->{server}->{socket});

    while(@ready = $s->can_read) {
        foreach $fh (@ready) { #we have only one handler but it could be useful in the future
	    my ($buffer, $response);

	    $buffer   = '';
	    $response = '';

            do {
                read($self->{server}->{socket}, $buffer, 1);
                $response .= $buffer;
	    } until ($buffer eq $self->{ucp_stuff}->{OBJ_EMI_COMMON}->ETX);
	    
#	    print "RESP : " . $response . "\n";

	    $self->{ucp_stuff}->remove_ucp_enclosure(\$response);
	    my $ref_mes     = $self->{ucp_stuff}->parse_message($response);
	    
#	    print "RESP 2 : " . $response . "\n";
#	    print Dumper($ref_mes);

	    if ($self->control_checksum($ref_mes)) {
		$self->log("Checksum control : Checksum OK for $response");
	    }

	    if ($ref_mes->{ot} eq "01") {
		$self->{server}->{op_01}($ref_mes);
	    } elsif ($ref_mes->{ot} eq "02")  {
		$self->{server}->{op_02}($ref_mes)
	    } elsif ($ref_mes->{ot} eq "31") {
		$self->{server}->{op_31}($ref_mes);
	    } elsif ($ref_mes->{ot} eq "51") {
		$self->{server}->{op_51}($ref_mes);
	    } elsif ($ref_mes->{ot} eq "52") {
		$self->{server}->{op_52}($ref_mes);
	    } elsif ($ref_mes->{ot} eq "53") {
		$self->{server}->{op_53}($ref_mes);
	    } else {
		$self->log("No hook for this operation NUM : [$ref_mes->{op}] Contact the author and tell him to add something in this module...");
	    }
	}
    }
    
}

sub control_checksum {
    shift;
    my $mes = shift;
    ($mes->{my_checksum} eq $mes->{checksum}) ? return 1 : return 0; 
}

sub send_alert {
    my $self = shift;
    my ($adc, $pid) = @_;

    my $ucp_alert = $self->{ucp_stuff}->make_31(operation => 1,
						adc       => defined($adc) ? $adc : "", #<-- you need to pass it
						pid       => defined($pid) ? $pid : "0539",
						);
    
    my ($ack, $e_num, $resp) = $self->{ucp_stuff}->transmit_msg($ucp_alert, $self->{server}->{timeout}, 0);
    return;
}

sub send_sms {
    my $self = shift;
    my ($phone_number, $from, $text, $delivery_notification) = @_;
    
    if (defined $self->{ucp_stuff} ) {
     
	my $ucp_string = $self->{ucp_stuff}->make_message(
							  op        => '51',
							  operation => 1,
							  adc       => $phone_number,
							  oadc      => $from,
							  mt        => 3,
							  amsg      => $text,
							  mcls      => 1,
							  otoa      => "5039",
							  );
        if (defined($ucp_string)) {
	    
	    print $ucp_string . "\n"; 

	    $self->{ucp_stuff}->transmit_msg($ucp_string, $self->{server}->{timeout}, 0);
            $self->log("UCP Client op51 send_sms(): $phone_number, $from, $text");
	    
	} else {
            $self->log("Error while making UCP String OP 51 $phone_number $from $text");
        }
	
        return 1;
    }
 
   return 0;
}

#Overwritable methods 
#sub op_01 {};
#sub op_31 {}; 
#sub op_51 {};
#sub op_52 {};
#sub op_53 {};

1;
__END__

=head1 NAME

Net::UCP::Client - Perl extension for EMI - UCP Protocol [ Simple Client Implementation ]

Alfa release. 

=head1 SYNOPSIS

  use Net::UCP::Client;

  ### nothing to say... see client.pl

=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 SEE ALSO

Net::UCP

=head1 AUTHOR

Marco Romano, E<lt>nemux@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Marco Romano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
