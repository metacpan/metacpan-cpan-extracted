package Net::DNS::Check::Test::host_syntax;

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
		push (@host_array, $nsquery->hostslist()->get_list());
	}

	push (@host_array, $self->{hostslist}->get_list()); 

    foreach my $hostname ( @host_array ) {	

		next if ( exists $test_detail->{$hostname} );

		my $status = 1;
		if (length($hostname) > 255 ) {
    		$status  = 0;
		}

		my @labels =  split('\.', $hostname);
		my $tld = pop @labels;

		unless ( $tld =~ /^[a-z]+$/ ) {
			$status = 0;
		}

    	foreach my $label ( @labels ) {
        	if ( length($label) > 63 || $label !~ /^([0-9a-z]+(-+[0-9a-z]+)*|[a-z0-9]+)$/  ) {
            	$status = 0;
        	} 
		}
		$test_detail->{$hostname}->{status} 	= $status;
		$test_detail->{$hostname}->{desc} 		= ''; 
		$test_status &&= $status;
	}

	$self->{test_status} = $test_status;
	$self->{test_detail} = $test_detail;

	return $test_status;
}

1;

__END__

=head1 NAME

Net::DNS::Check::Test::host_syntax - Verify the correctness of the hosts syntax 

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::host_syntax>;

=head1 DESCRIPTION

Verify the correctness of the hosts syntax

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

