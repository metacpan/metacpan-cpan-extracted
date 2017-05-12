package Net::Z3950::ZOOM; 

use 5.008;
use strict;
use warnings;

our $VERSION = '1.30';

require XSLoader;
XSLoader::load('Net::Z3950::ZOOM', $VERSION);

my($vs, $ss) = ("x" x 100, "x" x 100); # allocate space for these strings
my $version = Net::Z3950::ZOOM::yaz_version($vs, $ss);
if ($version < 0x040000 && ! -f "/tmp/ignore-ZOOM-YAZ-version-mismatch") {
    warn <<__EOT__;
*** WARNING!
ZOOM-Perl requires at least version 4.0.0 of YAZ, but is currently
running against only version $vs (sys-string '$ss').
Some things may not work.
__EOT__
}

# The only thing this module does is define the following constants,
# which MUST BE KEPT SYNCHRONISED with the definitions in <yaz/zoom.h>

# Error codes, as returned from connection_error()
sub ERROR_NONE { 0 }
sub ERROR_CONNECT { 10000 }
sub ERROR_MEMORY { 10001 }
sub ERROR_ENCODE { 10002 }
sub ERROR_DECODE { 10003 }
sub ERROR_CONNECTION_LOST { 10004 }
sub ERROR_INIT { 10005 }
sub ERROR_INTERNAL { 10006 }
sub ERROR_TIMEOUT { 10007 }
sub ERROR_UNSUPPORTED_PROTOCOL { 10008 }
sub ERROR_UNSUPPORTED_QUERY { 10009 }
sub ERROR_INVALID_QUERY { 10010 }
sub ERROR_CQL_PARSE { 10011 }
sub ERROR_CQL_TRANSFORM { 10012 }
sub ERROR_CCL_CONFIG { 10013 }
sub ERROR_CCL_PARSE { 10014 }

# Event types, as returned from connection_last_event()
sub EVENT_NONE { 0 }
sub EVENT_CONNECT { 1 }
sub EVENT_SEND_DATA { 2 }
sub EVENT_RECV_DATA { 3 }
sub EVENT_TIMEOUT { 4 }
sub EVENT_UNKNOWN { 5 }
sub EVENT_SEND_APDU { 6 }
sub EVENT_RECV_APDU { 7 }
sub EVENT_RECV_RECORD { 8 }
sub EVENT_RECV_SEARCH { 9 }
sub EVENT_END { 10 }		# In YAZ 2.1.17 and later

# CCL error-codes, which are in a different space from the ZOOM errors
sub CCL_ERR_OK                { 0 }
sub CCL_ERR_TERM_EXPECTED     { 1 }
sub CCL_ERR_RP_EXPECTED       { 2 }
sub CCL_ERR_SETNAME_EXPECTED  { 3 }
sub CCL_ERR_OP_EXPECTED       { 4 }
sub CCL_ERR_BAD_RP            { 5 }
sub CCL_ERR_UNKNOWN_QUAL      { 6 }
sub CCL_ERR_DOUBLE_QUAL       { 7 }
sub CCL_ERR_EQ_EXPECTED       { 8 }
sub CCL_ERR_BAD_RELATION      { 9 }
sub CCL_ERR_TRUNC_NOT_LEFT   { 10 }
sub CCL_ERR_TRUNC_NOT_BOTH   { 11 }
sub CCL_ERR_TRUNC_NOT_RIGHT  { 12 }


=head1 NAME

Net::Z3950::ZOOM - Perl extension for invoking the ZOOM-C API.

=head1 SYNOPSIS

 use Net::Z3950::ZOOM;
 $conn = Net::Z3950::ZOOM::connection_new($host, $port);
 $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
 Net::Z3950::ZOOM::connection_option_set($conn, databaseName => "foo");
 # etc.

=head1 DESCRIPTION

This module provides a simple thin-layer through to the ZOOM-C
functions in the YAZ toolkit for Z39.50 and SRW/U communication.  You
should not be using this very nasty, low-level API.  You should be
using the C<ZOOM> module instead, which implements a nice, Perlish API
on top of this module, conformant to the ZOOM Abstract API described at
http://zoom.z3950.org/api/

To enforce the don't-use-this-module prohibition, I am not even going
to document it.  If you really, really, really want to use it, then it
pretty much follows the API described in the ZOOM-C documentation at
http://www.indexdata.dk/yaz/doc/zoom.tkl

The only additional (non-ZOOM-C) function provided by this module is
C<event_str()>, which takes as its argument an event code such as
C<Net::Z3950::ZOOM::EVENT_SEND_APDU>, and returns a corresponding
short string.

=cut

sub event_str {
    my($code) = @_;

    if ($code == EVENT_NONE) {
	return "none";
    } elsif ($code == EVENT_CONNECT) {
	return "connect";
    } elsif ($code == EVENT_SEND_DATA) {
	return "send data";
    } elsif ($code == EVENT_RECV_DATA) {
	return "receive data";
    } elsif ($code == EVENT_TIMEOUT) {
	return "timeout";
    } elsif ($code == EVENT_UNKNOWN) {
	return "unknown";
    } elsif ($code == EVENT_SEND_APDU) {
	return "send apdu";
    } elsif ($code == EVENT_RECV_APDU) {
	return "receive apdu";
    } elsif ($code == EVENT_RECV_RECORD) {
	return "receive record";
    } elsif ($code == EVENT_RECV_SEARCH) {
	return "receive search";
    } elsif ($code == EVENT_END) {
	return "end";
    }
    return "impossible event " . $code;
}


# Switch API variant depending on $type.  This works because the
# get_string() and get_binary() functions have different returns
# types, one of which is implemented as a NUL-terminated string and
# the other as a pointer-and-length structure.
#
# Some Z39.50 servers, when asked for an OPAC-format record in the
# case where no circulation information is available, will return a
# USMARC record rather than an OPAC record containing only a
# bibliographic part.  This non-OPAC records is not recognised by the
# underlying record_get() code in ZOOM-C, which ends up returning a
# null pointer.  To make life a little less painful when dealing with
# such servers until ZOOM-C is fixed, this code recognises the
# wrong-record-syntax case and returns the XML for the bibliographic
# part anyway.
#
sub record_get {
    my($rec, $type) = @_;

    my $simpletype = $type;
    $simpletype =~ s/;.*//;
    if (grep { $type eq $_ } qw(database syntax schema)) {
	return record_get_string($rec, $type);
    } else {
	my $val = record_get_binary($rec, $type);
	if ($simpletype eq "opac" && !defined $val) {
	    my $newtype = $type;
	    if ($newtype !~ s/.*?;/xml;/) {
		$newtype = "xml";
	    }
	    $val = record_get_binary($rec, $newtype);
	    $val = ("<opacRecord>\n  <bibliographicRecord>\n" . $val .
		    "  </bibliographicRecord>\n</opacRecord>");

	}
	return $val;
    }
}


=head1 SEE ALSO

The C<ZOOM> module, included in the same distribution as this one.

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2005-2014 by Index Data.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
