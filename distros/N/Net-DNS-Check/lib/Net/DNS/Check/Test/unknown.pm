package Net::DNS::Check::Test::unknown;

use strict;
use vars qw(@ISA $VERSION);

@ISA     = qw(Net::DNS::Check::Test);


sub new {
   	my ($class) 	= shift; 
	my ($self) 		= {};

	return bless $self, $class;
}

sub test {
   	my ($self) 	= shift; 

	return;
}

1;

__END__


=head1 NAME

Net::DNS::Check::Test::unknown - Unknown Test 

=head1 SYNOPSIS

C<use Net::DNS::Check::Test::unknown>;

=head1 DESCRIPTION

This class is used when we can't find the requested test class

=head1 METHODS

=cut

=head1 new

=cut

=head1 COPYRIGHT

Copyright (c) 2004 IIT-CNR Lorenzo Luconi Trombacchi  - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

