package Net::DNS::Check::Test::soa_master_in_ns;

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


sub test()
{
	my ($self) = shift;

	return unless ( $self->{nsauth} );

	my $test_status = 1;
	my $test_detail = {};

	foreach my $nsquery ( @{$self->{nsquery}} ) {	
		my $found = 0;
		my $ns_name = $nsquery->ns_name();
		foreach my $ns ( $nsquery->ns_list() ) {
			if ( $nsquery->soa_mname() eq $ns ) {
				$found = 1;
				last;
			}
		}

		$test_detail->{$ns_name}->{desc} 	= $nsquery->soa_mname() . " (NS " . join(' ', sort $nsquery->ns_list ) . ")"; 

		if ( $found ) {
			$test_detail->{$ns_name}->{status} = 1; 
		} else {
			$test_status = 0;
			$test_detail->{$ns_name}->{status} 	= 0; 
		}
	}

	$self->{test_status} = $test_status;
	$self->{test_detail} = $test_detail;

	return $test_status;
}

1;

__END__

=head1 NAME

Net::DNS::Check::Test::soa_master_in_ns - Check if the NS RR exists for the master nameserver specified in the SOA RR

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::soa_master_in_ns>;

=head1 DESCRIPTION

Check if the NS RR exists for the master nameserver specified in the SOA RR.

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi  - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

