package Vehicle;

use strict;
use vars qw($VERSION);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.12 $ =~ /: (\d+)\.(\d+)/;
}

use base qw( VehicleImplementation );
use VehicleImplementation; 

sub do_maintenance {
	my $self = shift;
	print "Maintenance on Vehicle: " . $self->{name} . " ... done.\n";
}

1;
__END__

=head1 NAME

Vehicle - Example of a Ginsu class with no table.

=head1 DESCRIPTION

This is an example of a Ginsu class which inherits fields, but does not
add any fields of its own. Such a class could be used to modify behavior
without any additional persistent fields. It's fine to inherit from a
class like this as well.

=head1 COPYRIGHT

Copyright (c) 2001-2004 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

  Ray Zimmerman, <rz10@cornell.edu>

=cut
