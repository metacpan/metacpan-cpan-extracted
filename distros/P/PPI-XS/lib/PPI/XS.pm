package PPI::XS; # git description: release-0.904-4-g378ef4e

# See POD at end for documentation

use 5.005;
use strict;
use XSLoader;

# In the unlikely case they someone tries to manually load
# PPI::XS without PPI itself loaded, they probably MEAN for us
# to load in PPI as well. Pretty useless otherwise, because we
# need to _overwrite_ the PPI methods, we can't have it loading
# after we do.
use PPI 1.000 ();

# Define compatibility information
our $VERSION = '0.910';
our $PM_COMPATIBLE = '0.844';
our %EXCLUDE       = ();

# Does the main package define the minimum set of variables?
return 1 unless defined $PPI::VERSION;
return 1 unless defined $PPI::XS_COMPATIBLE;
return 1 if     $PPI::VERSION =~ /_/;

# Are we compatible with the main package
return 1 unless $VERSION      > $PPI::XS_COMPATIBLE;
return 1 unless $PPI::VERSION > $PM_COMPATIBLE;

# Provide an option to manually disable this package
return 1 if $PPI::XS_DISABLE;

# If we aren't EXACTLY the same version, determine
# which functions we might need to exclude.
if ( $VERSION > $PPI::VERSION ) {
	# We are newer, we have the option of excluding functions
	### NOTE: Nothing to exclude in this version
	# %EXCLUDE = map { $_ => 1 } qw{};
	# (example) PPI::Element::exclude_this
} elsif ( $VERSION < $PPI::VERSION ) {
	# It is newer, it has the option of excluding functions
	if ( @PPI::XS_EXCLUDE ) {
		# It as defined things for us to exclude
		%EXCLUDE = map { $_ => 1 } @PPI::XS_EXCLUDE;
	}
}

# Load the XS functions
XSLoader::load( 'PPI::XS' => $VERSION );

# Find all the functions in PPI::XS
no strict 'refs';
foreach ( sort grep { /^_PPI_/ and defined &{"PPI::XS::$_"} } keys %{"PPI::XS::"} ) {
	# Prepare
	/^_(\w+?)__(\w+)$/ or next;
	my ($class, $function) = ($1, $2);
	$class =~ s/_/::/g;

	if ( $EXCLUDE{$_} ) {
		# Remove the un-needed function.
		# The primary purpose of this is to recover the memory
		# occupied by the useless functions, but has the
		# additional benefit of allowing us to detect which
		# functions were actually mapped in by examining the
		# names of the functions remaining in the PPI::XS symbol
		# table.
		delete ${"PPI::XS::"}{$_};
	} else {
		# Map in the function
		*{"${class}::${function}"} = *{"PPI::XS::$_"};
	}
}

1;

__END__

=pod

=head1 NAME

PPI::XS - (Minor) XS acceleration for PPI

=head1 VERSION

version 0.910

=head1 DESCRIPTION

PPI::XS provides XS-based acceleration of the core PPI packages. It
selectively replaces a (small but growing) number of methods throughout
PPI with identical but much faster C versions.

Once installed, it will be auto-detected and loaded in by PPI completely
transparently.

Because the C implementations are linked to the perl versions of the
same function, it is preferable to upgrade PPI::XS any time you do a
major upgrade of PPI itself.

If the two fall out of sync, the integration between the two is designed
to degrade gracefully. PPI::XS is capable of determining which functions
are no longer equal, and will simple leave the perl version alone,
deleting the C version to free up the memory.

If the versions of the two get so far apart that they become completely
incompatible, PPI::XS will simply silently not load at all.

Beyond that, there isn't that much more you really need to know. :)

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PPI-XS>

For other issues or comments, contact the maintainer.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
