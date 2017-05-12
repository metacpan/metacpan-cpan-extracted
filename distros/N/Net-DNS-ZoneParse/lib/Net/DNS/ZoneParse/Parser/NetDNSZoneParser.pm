package Net::DNS::ZoneParse::Parser::NetDNSZoneParser;

use 5.008000;
use strict;
use warnings;
use vars qw($VERSION);

use Net::DNS;
use Net::DNS::Zone::Parser;
use IO::File;
use POSIX qw(tmpnam);

$VERSION = 0.10;

=pod

=head1 NAME

Net::DNS::ZoneParse::Parser::NetDNSZoneParser - Glue for Net::DNS::ZoneParse
to use Net::DNS::Zone::Parser

=head1 DESCRIPTION

NetDNSZoneParser uses Net::DNS::Zone::Parser as parsing engine. This can
perform to different tasks. On the one hand it is a pre-parser, helping
other parsers to read zonefile, on the other hand it can be used to generate
the corresponding Records directly.

=head2 EXPORT

=head3 parse

	$rr = Net::DNS::ZoneParse::Parser::NetDNSZoneParser->parse($param)

This will be called by Net::DNS::ZoneParse.
The parameters filehandle will be modified to point to the preparsed
zone.
If NetDNSZoneParser is called with CREATE_RR set, the Records read will be
returned.

=cut

sub parse {
	my ($self, $param) = @_;
	my $oldfh;
	unless($param->{file}) {
		$oldfh = $param->{fh};
		do { $param->{file} = tmpnam(); }
	       		until $param->{fh} = IO::File->new($param->{file},
				O_RDWR|O_CREAT|O_EXCL);
		my $fh = $param->{fh};
		while(<$oldfh>) {
			printf $fh $_;
		}
		seek($param->{fh}, 0, 0);
	}
	my $parser = Net::DNS::Zone::Parser->new();
	$param->{parser_arg}->{ORIGIN} = $param->{origin};
	$parser->read($param->{file}, $param->{parser_arg});
	if($oldfh) {
		close($param->{fh});
		unlink($param->{file});
		delete($param->{file});
	}
	$param->{fh} = $parser->get_io;
	$param->{origin} = $parser->get_origin;
	return $param->{parser_arg}->{CREATE_RR}?$parser->get_array: undef();
}


=pod

=head1 SEE ALSO

Net::DNS::ZoneParse
Net::DNS::Zone::Parser

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
