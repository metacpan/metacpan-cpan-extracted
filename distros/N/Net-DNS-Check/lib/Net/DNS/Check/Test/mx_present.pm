package Net::DNS::Check::Test::mx_present;

use strict;
use vars qw(@ISA $VERSION);

@ISA     = qw(Net::DNS::Check::Test);


sub new {
   	my ($class) 	= shift; 

	my ($self) = bless {}, $class;

	if ( @_ ) {
		$self->_process_args(@_);
	}

	$self->test(); return $self;
}


sub test()
{
	my ($self) = shift;

	# return unless ( $self->{config} );

	my $test_status = 1;
	my %compare_hash;
	my $test_detail = {};

    foreach my $nsquery ( @{$self->{nsquery}} ) {	
        my @mx_list = $nsquery->mx_list();
		my $ns_name	= $nsquery->ns_name();

		$test_detail->{$ns_name}->{desc} = join(' ', @mx_list); 

		if ( (scalar @mx_list) > 0 ) {
			$test_detail->{$ns_name}->{status} = 1; 
		} else {
			$test_detail->{$ns_name}->{status} = 0; 
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

Net::DNS::Check::Test::mx_present - Check if mx RR is present or not 

=head1 SYNOPSIS

C<use Net::DNS::Test::mx_compare>;

=head1 DESCRIPTION

Check if MX RR is present or not

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi  - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

