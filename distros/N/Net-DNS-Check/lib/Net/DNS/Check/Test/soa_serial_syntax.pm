package Net::DNS::Check::Test::soa_serial_syntax;

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

	# return unless ( $self->{config} );

	my $test_status = 1;
	my %compare_hash;
	my $test_detail = {};

    foreach my $nsquery ( @{$self->{nsquery}} ) {	
        my $soa_serial = $nsquery->soa_serial();
		my $ns_name	= $nsquery->ns_name();

		$test_detail->{$ns_name}->{desc} = $soa_serial;
		if ($soa_serial =~ /([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})/) {
			my $year 	= $1;
			my $month 	= $2;
			my $day 	= $3;
			my $rev		= $4;

			if ($year > 1900 
			    && $month >= 1 && $month <= 12 
				&& $day >= 1 && $day <= 31) {

				$test_detail->{$ns_name}->{status} = 1; 
			} else {
				$test_detail->{$ns_name}->{status} = 0; 
				$test_status = 0;
			}
		} else {
			$test_status = 0;
			$test_detail->{$ns_name}->{status} = 0; 
		}

	}

	$self->{test_status} = $test_status;
	$self->{test_detail} = $test_detail;

	return $test_status;
}

1;

__END__

=head1 NAME

Net::DNS::Check::Test::soa_serial_syntax - Check if the syntax of the serial number in the SOA RR are in the AAAAMMGGVV format

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::soa_serial_syntax>;

=head1 DESCRIPTION

Check if the syntax of the serial number in the SOA RR are in the AAAAMMGGVV format.

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi  - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

