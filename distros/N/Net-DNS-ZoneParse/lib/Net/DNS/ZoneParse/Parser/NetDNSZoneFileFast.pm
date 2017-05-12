package Net::DNS::ZoneParse::Parser::NetDNSZoneFileFast;

use 5.008000;
use strict;
use warnings;
use vars qw($VERSION);

use Net::DNS;
use Net::DNS::ZoneFile::Fast;

$VERSION = 0.10;

=pod

=head1 NAME

Net::DNS::ZoneParse::Parser::NetDNSZoneFileFast - Glue for Net::DNS::ZoneParse
to use Net::DNS::ZoneFile::Fast.

=head1 DESCRIPTION

NetDNSZoneFileFast uses Net::DNS::ZoneFile::Fast as parsing engine. This provides an
Interface to a fast parser with support for most directives and the most
common RRs; though not all are supported.

=head2 EXPORT

=head3 parse

	$rr = Net::DNS::ZoneParse::Parser::NetDNSZoneFileFast->parse($param)

This will be called by Net::DNS::ZoneParse

=cut

sub parse {
	my ($self, $param) = @_;
	return Net::DNS::ZoneFile::Fast::parse(
		fh => $param->{fh},
	       	origin => $param->{origin},
	);
}


=pod

=head1 SEE ALSO

Net::DNS::ZoneParse
Net::DNS::ZoneFile::Fast

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
