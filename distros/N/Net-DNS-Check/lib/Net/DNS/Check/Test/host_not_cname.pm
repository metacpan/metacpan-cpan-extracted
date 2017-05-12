package Net::DNS::Check::Test::host_not_cname;

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

	
	foreach my $nsquery ( @{$self->{nsquery}} ) {
		foreach my $host ( $nsquery->hostslist()->get_list() ) {
			push ( @host_array, $nsquery->hostslist()->get_host($host) );
		}
	}

	foreach my $host ( $self->{hostslist}->get_list() ) {
		push ( @host_array, $self->{hostslist}->get_host($host) );
	}



    foreach my $host ( @host_array ) {	

		my $hostname = $host->get_hostname();
		next if ( exists $test_detail->{$hostname} );

		$test_detail->{$hostname}->{desc} = $hostname; 
		if ( $host->get_cname() ) {
			$test_detail->{$hostname}->{status} = 0;
			$test_status = 0; 
		} else {
			$test_detail->{$hostname}->{status} = 1;
		}

	}

	$self->{test_status} = $test_status;
	$self->{test_detail} = $test_detail;

	return $test_status;
}

1;


__END__

=head1 NAME

Net::DNS::Check::Test::host_not_cname - Check if the hosts found are CNAME or not 

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::host_not_cname>;

=head1 DESCRIPTION

Check if the hosts found are CNAME or not.

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

