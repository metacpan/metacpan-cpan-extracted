package Net::DNS::ZoneParse::Generator::Native;

use 5.008000;
use strict;
use warnings;
use vars qw($VERSION);

use Net::DNS;

$VERSION = 0.101;

=pod

=head1 NAME

Net::DNS::ZoneParse::Generator::Native - Net::DNS::ZoneParse's native generator.

=head1 DESCRIPTION

The native generator generates valid files, which can be read by most parsers.
If the corresponding information is available, it will generate correct
$TTL and $ORIGIN directives and - at least for the name of the resource records
shorten the names, if applicable.

=cut

#####################
# private functions #
#####################

# return one line of text for one RR
sub _writerr {
	my ($rr, $zre, $ttl) = @_;
	my $name = $rr->{name};
	if($name =~ $zre) {
		$name = $1;
	} elsif( $name !~ m/\.$/) {
		$name .= ".";
	}
	$ttl = 0 unless $ttl;
	$ttl = (($rr->{ttl} == $ttl)?"":$rr->{ttl}) || "";
	my $data = $rr->rdatastr;
	$data = '; no data' unless $data;
	return join("\t", $name, $ttl, $rr->{class}, $rr->{type}, $data);
}

=pod

=head2 EXPORT

=head3 generate

This will be called by the Interface of Net::DNS:ZoneParse and return the
corresponding zonetext.

=cut

sub generate {
	my ($self, $param) = @_;
	my $ret = "";
	my $zre = qr/^\(\)$/;
	if($param->{origin}) {
		$ret .= "\$ORIGIN\t$param->{origin}\n";
		$zre = qr/^(.*)\.$param->{origin}$/;
	}
	$ret .= "\$TTL\t$param->{ttl}\n" if($param->{ttl});
	return $ret.join("\n", map { _writerr($_, $zre, $param->{ttl}); } @{$param->{rr}})."\n";
}

=pod

=head1 SEE ALSO

Net::DNS::ZoneParse

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
