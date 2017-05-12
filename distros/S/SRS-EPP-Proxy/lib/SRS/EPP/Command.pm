# vim: filetype=perl:noexpandtab:ts=3:sw=3
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

package SRS::EPP::Command;
{
  $SRS::EPP::Command::VERSION = '0.22';
}

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw(subtype coerce as where class_type);
use Carp;

extends 'SRS::EPP::Message';

with 'MooseX::Log::Log4perl::Easy';

use XML::EPP;
use XML::SRS::Error;

has "+message" =>
	isa => "XML::EPP",
	;

use Module::Pluggable search_path => [__PACKAGE__];

sub rebless_class {
	my $object = shift;
	our $map;
	if ( !$map ) {
		$map = {
			map {
				$_->can("match_class")
					? ( $_->match_class => $_ )
					: ();
				}# map { print "rebless_class checking plugin $_\n"; $_ }
				grep m{${\(__PACKAGE__)}::[^:]*$},
			__PACKAGE__->plugins,
		};
	}
	$map->{ref $object};
}

sub action_class {
	my $action = shift;
	our $action_classes;
	if ( !$action_classes ) {
		$action_classes = {
			map {
				$_->can("action")
					? ($_->action => $_)
					: ();
				}# map { print "action_class checking plugin $_\n"; $_ }
				grep m{^${\(__PACKAGE__)}::[^:]*$},
			__PACKAGE__->plugins,
		};
	}
	$action_classes->{$action};
}

sub REBLESS {

}

sub BUILD {
	my $self = shift;
	if ( my $epp = $self->message ) {
		my $class;
		$class = rebless_class( $epp->message );
		if (
			!$class
			and $epp->message
			and
			$epp->message->can("action")
			)
		{
			$class = action_class($epp->message->action);
		}
		if ($class) {

			#FIXME: use ->meta->rebless_instance
			bless $self, $class;
			$self->REBLESS;
		}
	}
}

sub simple { 0 }
sub authenticated { 1 }
sub done { 1 }

# Indicates whether we'd normally expect multiple responses to be returned to the client
#  e.g. check domain allows multiple domains to be checked at once, and therefore multiple
#  responses, whereas info domain is only one response. This is used to decide whether we
#  return multiple SRS errors back to the client (as some actions that map to multiple
#  SRS queries only want to return at most one error to the client)
sub multiple_responses { 0 }

BEGIN {
	class_type "SRS::EPP::Session";
	class_type "SRS::EPP::SRSResponse";
}

has 'session' =>
	is => "rw",
	isa => "SRS::EPP::Session",
	weak_ref => 1,
	;

has 'server_id' =>
	is => "rw",
	isa => "XML::EPP::trIDStringType",
	lazy => 1,
	predicate => "has_server_id",
	default => sub {
	my $self = shift;
	my $session = $self->session;
	if ($session) {
		$session->new_server_id;
	}
	else {
		our $counter = "aaaa";
		$counter++;
	}
	}
	;

BEGIN {
	class_type "SRS::EPP::Session";
}

# process a simple message - the $session is for posting back events
sub process {
    my $self = shift;
    
    my ( $session ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Session' },
    );    
    
	$self->session($session);

	# default handler is to return an unimplemented message
	return $self->make_response(code => 2101);
}

sub notify {
    my $self = shift;
    
	return $self->make_response(code => 2400);
}

sub make_response {
	my $self = shift;
	my $type = "SRS::EPP::Response";
	if ( @_ % 2 ) {
		$type = shift;
		$type = "SRS::EPP::Response::$type" if $type !~ /^SRS::/;
	}
	my %fields = @_;
	$fields{client_id} ||= $self->client_id if $self->has_client_id;
	$fields{server_id} ||= $self->server_id;
	$self->log_debug("making a response: @{[%fields]}")
		if $self->log->is_debug;
	$type->new(
		%fields,
	);
}

# this one is for convenience in returning errors
sub make_error {
    my $self = shift;
    
    my ( $code, $message, $value, $reason, $exception ) = validated_list(
        \@_,
        code => { isa => 'Int' },
        message => { isa => 'Str', optional => 1  },
        value => { isa => 'Str', optional => 1 },
        reason => { isa => 'Str', optional => 1 },
        exception => { optional => 1 },
    );       
    
	if ( defined $reason ) {
		$exception ||= XML::EPP::Error->new(
			value => $value//"",
			reason => $reason,
		);
	}

	return $self->make_response(
		Error => (
			($code ? (code => $code) : ()),
			($exception ? (exception => $exception) : ()),
			($message ? (extra => $message) : ()),
		),
	);
}

# this one is intended for commands to override particular error
# cases, so must use a simpler calling convention.
sub make_error_response {
    my $self = shift;
    
    my ( $srs_error ) = pos_validated_list(
        \@_,
        { isa => 'XML::SRS::Error|ArrayRef[XML::SRS::Error]' },
    );    
    
	return SRS::EPP::Response::Error->new(
		server_id => $self->server_id,
		($self->client_id ? (client_id => $self->client_id) : () ),
		exception => $srs_error,
	);
}

has "client_id" =>
	is => "rw",
	isa => "XML::EPP::trIDStringType",
	predicate => "has_client_id",
	;

after 'message_trigger' => sub {
	my $self = shift;
	my $message = $self->message;
	if ( my $client_id = eval { $message->message->client_id } ) {
		$self->client_id($client_id);
	}
};

use Module::Pluggable
	require => 1,
	search_path => [__PACKAGE__],
	;

sub ids {
	my $self = shift;
	return (
		$self->server_id,
		$self->client_id||(),
	);
}

__PACKAGE__->plugins;

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

SRS::EPP::Command - encapsulation of received EPP commands

=head1 SYNOPSIS

  my $cmd = SRS::EPP::Command::SubClass->new
            (
               xmlschema => ...
               xmlstring => ...
            );

  my $response = $cmd->process;

=head1 DESCRIPTION

This module is a base class for EPP commands; these are messages sent
from the client to the server.

=head1 ATTRIBUTES

=over

=item xmlschema

The XML schema for this message, as a string.  (XXX - this should be a
class data variable)

=item xmlstring

The data of the message.

=back

=head1 SEE ALSO

L<SRS::EPP::Command::Login>, L<SRS::EPP::Message>,
L<SRS::EPP::Response>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# tab-width: 8
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
