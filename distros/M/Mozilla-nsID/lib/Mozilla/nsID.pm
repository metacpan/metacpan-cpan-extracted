package Mozilla::nsID;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mozilla::nsID ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Mozilla::nsID', $VERSION);

# Preloaded methods go here.

1;
__END__
=head1 NAME

Mozilla::nsID - Perl extension wrapping Mozilla nsID class.

=head1 SYNOPSIS

	use Mozilla::nsID;
	my $id1 = Mozilla::nsID->new(0x95611356, 0xf583 , 0x46f5, [
			0x81, 0xff, 0x4b, 0x3e, 0x01, 0x62, 0xc6, 0x19 ]);
	is($id1->ToString, '{95611356-f583-46f5-81ff-4b3e0162c619}');

	my $id2 = Mozilla::nsID->new_empty;
	$id2->Parse('{95611356-f583-46f5-81ff-4b3e0162c619}');

	# And now $id1 equals $id2

=head1 DESCRIPTION

This module wraps Mozilla nsID interface. Please see Mozilla documentation for
more details.

=head1 AUTHOR

Boris Sukholitko, E<lt>boriss@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Boris Sukholitko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
