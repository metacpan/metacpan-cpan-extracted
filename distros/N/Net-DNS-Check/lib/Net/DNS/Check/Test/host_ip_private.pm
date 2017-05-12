package Net::DNS::Check::Test::host_ip_private;

use strict;
use vars qw(@ISA $VERSION);

@ISA     = qw(Net::DNS::Check::Test);

sub new {
   	my ($class) 	= shift; 

	my ($self) = bless {}, $class;

	if ( @_ ) {
		$self->_process_args(@_);
	}

	$self->test();

	return $self;
}


sub test() {
	my ($self) = shift;

	$self->{test_status} = 1;
	$self->{test_detail} = {};

	foreach my $nsquery ( @{$self->{nsquery}} ) {
		$self->_check_host( $nsquery->hostslist(), $nsquery->ns_name() );
	}

	$self->_check_host( $self->{hostslist} );

	return $self->{test_status};
}



sub _check_host() {
	my ($self) 		= shift;
	my $hostslist 	= shift;
	my $source 		= shift || 'Recursion';

	return unless ( $hostslist );

	foreach my $hostname ( $hostslist->get_list() ) {
		my $host	= $hostslist->get_host($hostname); 

		foreach my $ip_priv ( @{$self->{config}->ip_private()} ) {
			foreach my $ip ( @{$host->get_ip()} ) {
				$self->{test_detail}->{$source}->{$hostname}->{$ip}->{desc} = $ip;
				if ( $ip =~ /^$ip_priv\S+$/ ) { 	 
					$self->{test_detail}->{$source}->{$hostname}->{$ip}->{status} = 0;
					$self->{test_status} = 0; 
				} else {
					$self->{test_detail}->{$source}->{$hostname}->{$ip}->{status} = 1;
            	}
			}
		}
	}
}


1;

__END__

=head1 NAME

Net::DNS::Check::Test::host_ip_private - Check if the IP addresses found during the hosts resolution do not belong to IP private classes

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::host_ip_vs_ip_orig>;

=head1 DESCRIPTION

Check if the IP addresses found during the hosts resolution do not belong to IP private classes.

Due to a differnt internal structure, at present this is the only test that doesn't report detailed information about results of the single analisys for every nameserver. You can only know if the test fails or not.

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

