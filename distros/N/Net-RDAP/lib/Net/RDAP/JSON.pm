package Net::RDAP::JSON;
use JSON qw(-no_export);
use vars qw(@EXPORT $JSON);
use base qw(Exporter);
use strict;

@EXPORT = qw(encode_json decode_json to_json from_json);

$JSON = JSON->new->utf8->canonical;

sub encode_json { $JSON->encode(@_) }
sub to_json     { $JSON->encode(@_) }
sub decode_json { $JSON->decode(@_) }
sub from_json   { $JSON->decode(@_) }

1;

__END__

=pod

=head1 NAME

L<Net::RDAP::JSON> - a wrapper to allow JSON backends to be switched.

=head1 DESCRIPTION

This module is a wrapper around L<JSON>. It exists to make it easier to switch
the JSON module used by L<Net::RDAP>. You should not use it directly.

It exports the same default functions as L<JSON> (C<encode_json>,
C<decode_json>, C<to_json> and C<from_json>), but ensures that UTF-8 and
canonicalisation are enabled.

=head1 COPYRIGHT

Copyright 2024-2025 Gavin Brown. For licensing information, please see the
C<LICENSE> file in the L<Net::RDAP> distribution.

=cut
