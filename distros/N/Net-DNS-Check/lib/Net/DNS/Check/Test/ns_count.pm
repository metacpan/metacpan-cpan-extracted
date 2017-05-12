package Net::DNS::Check::Test::ns_count;

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

	my $ns_min_count = $self->{config}->ns_min_count();
	my $ns_max_count = $self->{config}->ns_max_count();

	my $test_status = 1;
	my $test_detail = {};

    foreach my $nsquery ( @{$self->{nsquery}} ) {	
        my $nscount = scalar $nsquery->ns_list();
		my $ns_name	= $nsquery->ns_name();
		
		$test_detail->{$ns_name}->{desc} = "$nscount"; 

		if ($ns_min_count > 0 && $nscount < $ns_min_count  ) {
			$test_status = 0;
			$test_detail->{$ns_name}->{status} = 0;
		} elsif ($ns_max_count > 0 && $nscount > $ns_max_count  ) {
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

Net::DNS::Check::Test::ns_count - Check if the number of NS RR are within the range set in the configuration object

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::ns_count>;

=head1 DESCRIPTION

Check if the number of NS RR are within the range set in the configuration object

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi  - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

