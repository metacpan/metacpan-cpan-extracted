package Net::DNS::Check::Test::host_ip_vs_ip_orig;

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

	my $test_status = 1;
	my @host_array;
	my $test_detail = {};

	
	# Local hostslist
	foreach my $nsquery ( @{$self->{nsquery}} ) {
		foreach my $host ( $nsquery->hostslist()->get_list() ) {
			push ( @host_array, $nsquery->hostslist()->get_host($host) );
		}
	}

	# Gnereal Hostslist
	foreach my $host ( $self->{hostslist}->get_list() ) {
		push ( @host_array, $self->{hostslist}->get_host($host) );
	}



    foreach my $host ( @host_array ) {	

		my $hostname = $host->get_hostname();
		# next if ( exists $test_detail->{$hostname} );

#		print "$hostname: "; 

		my $ip_orig = join('|', sort @{$host->get_ip_orig()});
		next unless ( $ip_orig );
		my $ip		= join('|', sort @{$host->get_ip()});

		print "$ip vs $ip_orig\n";
		
		if ( $ip eq $ip_orig ) {
			$test_detail->{$hostname}->{status} = 1;
			$test_detail->{$hostname}->{desc} = join(' ', sort @{$host->get_ip()});
		} else {
			$test_detail->{$hostname}->{status} = 0;

            if ( $host->error() ) {
                $test_detail->{$hostname}->{desc} = $host->{error};
            } else {
                $test_detail->{$hostname}->{desc} = join(' ', sort @{$host->get_ip_orig()}) . ' vs ' . join(' ', sort @{$host->get_ip()});
            }
	
			$test_status = 0; 
		}

	}

	$self->{test_status} = $test_status;
	$self->{test_detail} = $test_detail;

	return $test_status;
}

1;

__END__

=head1 NAME

Net::DNS::Check::Test::host_ip_vs_ip_orig - Compare the IP addresses found during the hosts resolution with the IP addresses given with nserver argument (if exists) in method "new".

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::host_ip_vs_ip_orig>;

=head1 DESCRIPTION

Compare the IP addresses found during the hosts resolution with the IP addresses given with nserver argument (if exists) in method "new".
=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

