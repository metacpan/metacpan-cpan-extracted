# vim: filetype=perl:noexpandtab:ts=3:sw=3
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>
use strict;
use warnings;

package SRS::EPP::Response;
{
  $SRS::EPP::Response::VERSION = '0.22';
}
use Moose;
use Moose::Util::TypeConstraints qw(subtype coerce as where enum);
extends 'SRS::EPP::Message';

use SRS::EPP::SRSResponse;
use XML::EPP::Extension;

has 'code' =>
	is => 'ro',
	isa => "XML::EPP::resultCodeType",
	required => 1,
	;

has 'extra' =>
	is => "ro",
	isa => "Str",
	;

has 'msgQ' =>
	is => "ro",
	isa => "XML::EPP::msgQType";

has 'payload' =>
	is => "ro",
	;

has 'extension' =>
	is => "ro",
	;

use XML::EPP;
has "+message" =>
	isa => "XML::EPP",
	lazy => 1,
	default => sub {
	my $self = shift;
	$self->build_response;
	},
	;

sub build_response {
    my $self = shift;
    
	my $server_id = $self->server_id;
	my $client_id = $self->client_id;
	my $tx_id;
	if ($server_id) {
		$tx_id = XML::EPP::TrID->new(
			server_id => $server_id,
			($client_id ? (client_id => $client_id) : () ),
		);
	}
	my $msg = $self->extra;
	my $result = XML::EPP::Result->new(
		($msg ? (msg => $msg) : ()),
		code => $self->code,
	);
	my ($payload, $extension);
	if ( $self->payload ) {
		$payload = XML::EPP::SubResponse->new(
			payload => $self->payload,
		);
	}
	
	if ($self->extension) {
		# We only support one extension at the moment...
		$extension = XML::EPP::Extension->new(
			ext_objs => [$self->extension],
		);

	}

	
	XML::EPP->new(
		message => XML::EPP::Response->new(
			result => [$result],
			($payload ? (response => $payload) : ()),
			($extension ? (extension => $extension) : ()),
			($self->msgQ ? (msgQ => $self->msgQ) : ()),
			($tx_id ? (tx_id => $tx_id) : () ),
		),
	);
}

has "client_id" =>
	is => "ro",
	isa => "XML::EPP::trIDStringType",
	;

# not all response types require a server_id
has "server_id" =>
	is => "ro",
	isa => "XML::EPP::trIDStringType",
	;

use Module::Pluggable
	require => 1,
	search_path => [__PACKAGE__],
	;

sub ids {
	my $self = shift;
	return (
		$self->server_id || sprintf("0x%x",(0+$self)),
		$self->client_id||(),
	);
}

__PACKAGE__->plugins;

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

SRS::EPP::Response - EPP XML

=head1 SYNOPSIS

 ...

=head1 DESCRIPTION

This is a base class for all EPP responses.

=head1 SEE ALSO

L<SRS::EPP::Message>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
