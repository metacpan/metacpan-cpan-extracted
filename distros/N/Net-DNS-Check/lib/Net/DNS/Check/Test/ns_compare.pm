package Net::DNS::Check::Test::ns_compare;

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
        my @ns_list = sort $nsquery->ns_list();
        my $ns_name = $nsquery->ns_name();
        my $nskey = lc(join('|', @ns_list));

        if ($nskey) {
            $compare_hash{$nskey}++;
        }

        $test_detail->{$ns_name}->{desc} = join(' ', @ns_list);
    }

    if ((scalar keys %compare_hash) > 1) {
        $test_status = 0;
    }

    $self->{test_status} = $test_status;
    $self->{test_detail} = $test_detail;

    return $test_status;
}

1;

__END__

=head1 NAME

Net::DNS::Check::Test::ns_compare - Check if the NS RR are the same in all the authoritative nameservers

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::ns_compare>;

=head1 DESCRIPTION

Check if the NS RR are the same in all the authoritative nameservers

=head1 METHODS

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi  - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

