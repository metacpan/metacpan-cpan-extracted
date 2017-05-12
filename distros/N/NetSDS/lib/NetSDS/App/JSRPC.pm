#===============================================================================
#
#         FILE:  JSRPC.pm
#
#  DESCRIPTION:  NetSDS admin
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  10.08.2009 20:57:57 EEST
#===============================================================================

=head1 NAME

NetSDS::App::JSRPC - JSON-RPC server framework

=head1 SYNOPSIS

	#!/usr/bin/env perl
	# JSON-RPC server
	
	use 5.8.0;
	use warnings;
	use strict;

	JServer->run();

	1;

	# Server application logic

	package JServer;

	use base 'NetSDS::App::JSRPC';

	# This method is available via JSON-RPC
	sub sum {
		my ($self, $param) = @_;
		return $$param[0] + $$param[1];
	}

	1;

=head1 DESCRIPTION

C<NetSDS::App::JSRPC> module implements framework for common JSON-RPC based
server application. JSON-RPC is a HTTP based protocol providing remote
procudure call (RPC) functionality using JSON for requests and responses
incapsulation.

This implementation is based on L<NetSDS::App::FCGI> module and expected to be
executed as FastCGI or CGI application.

Diagram of class inheritance:

	  [NetSDS::App::JSRPC] - JSON-RPC server
	           |
	  [NetSDS::App::FCGI] - CGI/FCGI application
	           |
	     [NetSDS::App] - common application
	           |
	[NetSDS::Class::Abstract] - abstract class

Both request and response are JSON-encoded strings represented in HTTP protocol
as data of 'application/json' MIME type.


=head1 APPLICATION DEVELOPMENT

To develop new JSON-RPC server application you need to create application
class inherited from C<NetSDS::App::JSRPC>:

It's just empty application:

	#!/usr/bin/env perl
	
	JSApp->run(
		conf_file => '/etc/NetSDS/jsonapp.conf'
	);

	package JSApp;

	use base 'NetSDS::App::JSRPC';

	1;

Alsoe you may want to add some specific code for application startup:

	sub start {
		my ($self) = @_;

		connect_to_dbms();
		query_for_external_startup_config();
		do_other_initialization();

	}

And of course you need to add methods providing necessary functions:

	sub send_sms {
		my ($self, $params) = @_;

		return $self->{kannel}->send(
			from => $params{'from'},
			to => $params{'to'},
			text => $params{'text'},
		);
	}

	sub kill_smsc {
		my ($self, $params) = @_;

		# 1M of MT SM should be enough to kill SMSC!
		# Otherwise we call it unbreakable :-)

		for (my $i=1; $<100000000; $i++) {
			$self->{kannel}->send(
				%mt_sm_parameters,
			);
		}

		if (smsc_still_alive()) {
			return $self->error("Can't kill SMSC! Need more power!");
		}
	}

=head1 ADVANCED FUNCTIONALITY

C<NetSDS::App::JSRPC> module provides two methods that may be used to implement
more complex logic than average RPC to one class.

=over

=item B<can_method()> - method availability checking

By default it is just wrapper around C<UNIVERSAL::can> function.
However it may be rewritten to check for methods in other classes
or even construct necessary methods on the fly.

=item B<process_call()> - method dispatching

By default it just call local class method with the same name as in JSON-RPC call.
Of course it can be overwritten and process query in some other way.

=back

This code describes logic of call processing:

	# It's not real code

	if (can_method($json_method)) {
		process_call($json_method, $json_params);
	}

For more details read documentation below.

=cut

package NetSDS::App::JSRPC;

use 5.8.0;
use strict;
use warnings;

use JSON;
use base 'NetSDS::App::FCGI';


use version; our $VERSION = '1.301';

#===============================================================================

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

It's internally used constructor that shouldn't be used from application directly.

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	return $self;

}

#***********************************************************************

=item B<process()> - main JSON-RPC iteration

This is internal method that implements JSON-RPC call processing.

=cut

#-----------------------------------------------------------------------

sub process {

	my ($self) = @_;
	# TODO - implement request validation
	# Parse JSON-RPC2 request
	my $http_request = $self->param('POSTDATA');

	# Set response MIME type
	$self->mime('application/json');

	# Parse JSON-RPC call
	if ( my ( $js_method, $js_params, $js_id ) = $self->_request_parse($http_request) ) {

		# Try to call method
		if ( $self->can_method($js_method) ) {

			# Call method and hope it will give some response
			my $result = $self->process_call( $js_method, $js_params );
			if ( defined($result) ) {

				# Make positive response
				$self->data(
					$self->_make_result(
						result => $result,
						id     => $js_id
					)
				);

			} else {

				# Can't get positive result
				$self->data(
					$self->_make_error(
						code    => -32000,
						message => $self->errstr || "Error response from method $js_method",
						id      => undef,
					)
				);
			}

		} else {

			# Can't find proper method
			$self->data(
				$self->_make_error(
					code    => -32601,
					message => "Can't find JSON-RPC method",
					id      => undef,
				)
			);
		}

	} else {

		# Send error object as a response
		$self->data(
			$self->_make_error(
				code    => -32700,
				message => "Can't parse JSON-RPC call",
				id      => undef,
			)
		);
	}

} ## end sub process


#***********************************************************************

=item B<can_method($method_name)> - check method availability

This method allows to check if some method is available for execution.
By default it use C<UNIVERSAL::can> but may be rewritten to implement
more complex calls dispatcher.

Paramters: method name (string)

Return true if method execution allowed, false otherwise.

Example:

	# Rewrite can_method() to search in other class
	sub can_method {
		my ($self, $method) = @_;
		return Other::Class->can($method);
	}

=cut 

#-----------------------------------------------------------------------

sub can_method {

	my ($self, $method) = @_;

	return $self->can($method);

}

#***********************************************************************

=item B<process_call($method, $params)> - execute method call

Paramters: method name, parameters.

Returns parameters from executed method as is.

Example:

	# Rewrite process_call() to use other class
	sub process_call {
		my ( $self, $method, $params ) = @_;
		return Other::Class->$method($params);
	}

=cut 

#-----------------------------------------------------------------------

sub process_call {

	my ( $self, $method, $params ) = @_;

	return $self->$method($params);

}

#***********************************************************************

=item B<_request_parse($post_data)> - parse HTTP POST

Paramters: HTTP POST data as string

Returns: request method, parameters, id

=cut 

#-----------------------------------------------------------------------

sub _request_parse {

	my ( $self, $post_data ) = @_;

	my $js_request = eval { decode_json($post_data) };
	return $self->error("Can't parse JSON data") if $@;

	return ( $js_request->{'method'}, $js_request->{'params'}, $js_request->{'id'} );

}

#***********************************************************************

=item B<_make_result(%params)> - prepare positive response

This is internal method for encoding JSON-RPC response string.

Paramters:

=over

=item B<id> - the same as request Id (see specification)

=item B<result> - method result

=back

Returns JSON encoded response message.

=cut 

#-----------------------------------------------------------------------

sub _make_result {

	my ( $self, %params ) = @_;

	# Prepare positive response

	return encode_json(
		{
			jsonrpc => '2.0',
			id      => $params{'id'},
			result  => $params{'result'},
		}
	);

}

#***********************************************************************

=item B<_make_error(%params)> - prepare error response

Internal method implementing JSON-RPC error response.

Paramters:

=over

=item B<id> - the same as request Id (see specification)

=item B<code> - error code (default is -32603, internal error)

=item B<message> - error message

=back

Returns JSON encoded error message

=cut 

#-----------------------------------------------------------------------

sub _make_error {

	my ( $self, %params ) = @_;

	# Prepare error code and message
	# http://groups.google.com/group/json-rpc/web/json-rpc-1-2-proposal

	my $err_code = $params{code}    || -32603;              # 	Internal JSON-RPC error.
	my $err_msg  = $params{message} || "Internal error.";

	# Return JSON encoded error object
	return encode_json(
		{
			jsonrpc => '2.0',
			id      => $params{'id'},
			error   => {
				code    => $err_code,
				message => $err_msg,
			},
		}
	);

} ## end sub _make_error

1;

__END__

=back

=head1 EXAMPLES

See C<samples/app_jsrpc.fcgi> appliction.

=head1 SEE ALSO

L<JSON>

L<JSON::RPC2>

L<http://json-rpc.org/wiki/specification> - JSON-RPC 1.0

L<http://groups.google.com/group/json-rpc/web/json-rpc-1-2-proposal> - JSON-RPC 2.0

=head1 TODO

1. Move error codes to constants to provide more clear code.

2. Implement objects/classes support.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


