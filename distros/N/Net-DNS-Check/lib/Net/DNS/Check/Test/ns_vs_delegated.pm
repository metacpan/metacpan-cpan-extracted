package Net::DNS::Check::Test::ns_vs_delegated;

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

	if ( $self->{nsauth} ) {
		my $nsauth = lc(join('|', sort @{$self->{nsauth} }));

    	foreach my $nsquery ( @{$self->{nsquery}} ) {	
        	my $nslist = lc(join('|', sort $nsquery->ns_list ));
			my $ns_name = $nsquery->ns_name();
	
			$test_detail->{$ns_name}->{desc} 	= "NS " . join(' ', sort $nsquery->ns_list ); 
			if ($nsauth ne $nslist) {
				$test_status = 0;
				$test_detail->{$ns_name}->{status} 	= 0; 
			}
			else {
				$test_detail->{$ns_name}->{status} 	= 1; 
			}
		}
	} else {
		# Error
	}


	$self->{test_status} = $test_status;
	$self->{test_detail} = $test_detail;

	return $test_status;
}

1;

__END__

=head1 NAME

Net::DNS::Check::Test::ns_vs_delegated - Compare the NS RR found with the effectively delegated nameservers (NS RR in the parent zone of the domain name being checked)

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::ns_vs_delegated>;

=head1 DESCRIPTION

Compare the NS RR found with the effectively delegated nameservers (NS RR in the parent zone of the domain name being checked)

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi  - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

