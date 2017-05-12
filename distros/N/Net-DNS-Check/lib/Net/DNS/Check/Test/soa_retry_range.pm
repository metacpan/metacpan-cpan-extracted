package Net::DNS::Check::Test::soa_retry_range;

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

	return unless ( $self->{config} );

	my $soa_min_retry = $self->{config}->soa_min_retry();
	my $soa_max_retry = $self->{config}->soa_max_retry();

	my $test_status = 1;
	my $test_detail = {}; 

    foreach my $nsquery ( @{$self->{nsquery}} ) {	
        my $soa_retry = scalar $nsquery->soa_retry();
		my $ns_name	= $nsquery->ns_name();
		
		$test_detail->{$ns_name}->{desc} = $soa_retry; 

		if ($soa_min_retry > 0 && $soa_retry < $soa_min_retry ) {
			$test_status = 0;
			$test_detail->{$ns_name}->{status} = 0; 
		} elsif ($soa_max_retry > 0 && $soa_retry > $soa_max_retry ) {
			$test_status = 0;
			$test_detail->{$ns_name}->{status} = 0; 
		} else {
			$test_detail->{$ns_name}->{status} = 1; 
		}
	}

	$self->{test_status} = $test_status;
	$self->{test_detail} = $test_detail;

	return $test_status;
}

1;

__END__

=head1 NAME

Net::DNS::Check::Test::soa_retry_range - Check if the retry time in the SOA RR is within the range set in the configuration object

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::soa_retry_range>;

=head1 DESCRIPTION

Check if the retry time in the SOA RR is within the range set in the configuration object.

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi  - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

