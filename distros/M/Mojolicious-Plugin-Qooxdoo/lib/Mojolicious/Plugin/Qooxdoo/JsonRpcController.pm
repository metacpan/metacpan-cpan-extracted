package Mojolicious::Plugin::Qooxdoo::JsonRpcController;

use strict;
use warnings;

use Mojo::JSON qw(encode_json decode_json);
use Mojo::Base 'Mojolicious::Controller';
use Encode;


has toUTF8 => sub { find_encoding('utf8') };

our $VERSION = '0.905';

has 'service';

has 'crossDomain';
has 'requestId';
has 'methodName';

has log => sub { shift->app->log };

sub dispatch {
    my $self = shift;
    
    # We have to differentiate between POST and GET requests, because
    # the data is not sent in the same place..
    my $log = $self->log;

    # send warnings to log file preserving the origin
    local $SIG{__WARN__} = sub {
        my  $message = shift;
        $message =~ s/\n$//;
        @_ = ($log, $message);
        goto &Mojo::Log::warn;
    };
    my $data;
    for ( $self->req->method ){
        /^POST$/ && do {
            # Data comes as JSON object, so fetch a reference to it
            $data = eval { decode_json($self->req->body) };
	    	if ($@) {
				my $error = "Invalid json string: " . $@;
				$log->error($error);
				$self->render(text => $error, status=>500);
				return;
	    	};
            $self->requestId($data->{id});
            $self->crossDomain(0);
            last;
        };
        /^GET$/ && do {

            $data= eval { decode_json($self->param('_ScriptTransport_data')) };

            if ($@) {
				my $error = "Invalid json string: " . $@;
				$log->error($error);
				$self->render(text => $error, status=>500);
				return;
	    	};

            $self->requestId($self->param('_ScriptTransport_id')) ;
            $self->crossDomain(1);
            last;
        };

        my $error = "request must be POST or GET. Can't handle '".$self->req->method."'";
        $log->error($error);
        $self->render(text => $error, status=>500);
        return;
    }        
    if (not defined $self->requestId){
        my $error = "Missing 'id' property in JsonRPC request.";
        $log->error($error);
        $self->render(text => $error, status=>500);
        return;
    }


    # Check if service is property is available
    my $service = $data->{service} or do {
        my $error = "Missing service property in JsonRPC request.";
        $log->error($error);
        $self->render(text => $error, status=>500);
        return;
    };

    # Check if method is specified in the request
    my $method = $data->{method} or do {
        my $error = "Missing method property in JsonRPC request.";
        $log->error($error);
        $self->render(text => $error, status=>500);
        return;
    };
    $self->methodName($method);

    my $params  = $data->{params} || []; # is a reference, so "unpack" it
 
    # invocation of method in class according to request 
    my $reply = eval {
        # make sure there are not foreign signal handlers
        # messing with our problems
        local $SIG{__DIE__};
        # Getting available services from stash


        die {
            origin => 1,
            message => "service $service not available",
            code=> 2
        } if not $self->service eq $service;

        die {
             origin => 1, 
             message => "your rpc service controller (".ref($self).") must provide an allow_rpc_access method", 
             code=> 2
        } unless $self->can('allow_rpc_access');

        
        die {
             origin => 1, 
             message => "rpc access to method $method denied", 
             code=> 6
        } unless $self->allow_rpc_access($method);

        die {
             origin => 1, 
             message => "method $method does not exist.", 
             code=> 4
        } if not $self->can($method);
        if ($log->level eq 'debug'){
            my $debug = encode_json($params);
            if (not $ENV{MOJO_QX_FULL_RPC_DETAILS}){
                if (length($debug) > 60){
                    $debug = substr($debug,0,60) . ' [...]';
                }
            }
            $log->debug("call $method(".$debug.")");
        }
        # reply
        no strict 'refs';
        $self->$method(@$params);
    };
    if ($@){
        $self->renderJsonRpcError($@);
    }
    else {
    	# do NOT render if
    	if (not $self->stash->{'mojo.rendered'}){
    		$self->renderJsonRpcResult($reply);
    	}
    }
}

sub renderJsonRpcResult {
	my $self = shift;
	my $data = shift;
    my $reply = encode_json({ id => $self->requestId, result => $data });
    if ($self->log->level eq 'debug'){
        my $debug = $reply;
        if (not $ENV{MOJO_QX_FULL_RPC_DETAILS}){
            if (length($debug) > 60){
               $debug = substr($debug,0,60) . ' [...]';
            }
        }
        $self->log->debug("return ".$debug);
    }
    $self->finalizeJsonRpcReply($reply);
}

sub renderJsonRpcError {
	my $self = shift;
	my $exception = shift;
	my $error;
	for (ref $exception){
        /HASH/ && $exception->{message} && do {
            $error = {
                origin => $exception->{origin} || 2, 
                message => $exception->{message}, 
                code=>$exception->{code}
            };
            last;
        };
        /.+/ && $exception->can('message') && $exception->can('code') && do {
            $error = {
                origin => 2, 
                message => $exception->message(), 
                code=>$exception->code()
            };
            last;
        };
        $error = {
            origin => 2, 
            message => "error while processing ".$self->service."::".$self->methodName.": $exception", 
            code=> 9999
        };
    }
    $self->log->error("JsonRPC Error $error->{code}: $error->{message}");
    $self->finalizeJsonRpcReply(encode_json({ id => $self->requestId, error => $error}));
}

sub finalizeJsonRpcReply {
	my $self  = shift;
	my $reply = shift;
    if ($self->crossDomain){
        # for GET requests, qooxdoo expects us to send a javascript method
        # and to wrap our json a litte bit more
        $self->res->headers->content_type('application/javascript; charset=utf-8');
        $reply = "qx.io.remote.transport.Script._requestFinished( ".$self->requestId.", " . $reply . ");";
    } else {
        $self->res->headers->content_type('application/json; charset=utf-8');
    }    
    # the render takes care of encoding the output, so make sure we re-decode
    # the json stuf
    $self->render(text => $self->toUTF8->decode($reply));
}

1;


=head1 NAME

Mojolicious::Plugin::Qooxdoo::JsonRpcController - A controller base class for Qooxdoo JSON-RPC Calls

=head1 SYNOPSIS

 # lib/MyApp.pm

 use base 'Mojolicious';
 
 sub startup {
    my $self = shift;
    
    # add a route to the Qooxdoo dispatcher and route to it
    my $r = $self->routes;
    $r->route('/RpcService') -> to(
        controller => 'MyJsonRpcController',
        action => 'dispatch',
    );        
 }

 package MyApp::MyJsonRpcController;

 use Mojo::Base qw(Mojolicious::Plugin::Qooxdoo::JsonRpcController);
 
 has service => sub { 'Test' };
 
 out %allow = ( echo => 1, bad =>  1, async => 1);

 sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    return $allow{$method};;
 }

 sub echo {
    my $self = shift;
    my $text = shift;
    return $text;
 } 

 sub bad {

    die MyException->new(code=>1323,message=>'I died');

    die { code => 1234, message => 'another way to die' };
 }

 sub async {
    my $self=shift;
    $self->render_later;
    xyzWithCallback(callback=>sub{
        eval {
            local $SIG{__DIE__};
            $self->renderJsonRpcResult('Late Reply');
        }
        if ($@) {
            $self->renderJsonRpcError($@);
        }
    });
 }

 package MyException;

 use Mojo::Base -base;
 has 'code';
 has 'message';
 1;

=head1 DESCRIPTION

All you have todo to process incoming JSON-RPC requests from a qooxdoo
application, is to make your controller a child of
L<Mojolicious::Plugin::Qooxdoo::JsonRpcController>.  And then route all
incoming requests to the inherited dispatch method in the new controller.

If you want your Mojolicious app to also serve the qooxdoo application
files, you can use L<Mojolicous::Plugin::Qooxdoo> to have everything setup for you.

=head2 Exception processing

Errors within the methods of your controller are handled by an eval call,
encapsulating the method call.  So if you run into trouble, just C<die>.  If
if you die with a object providing a C<code> and C<message> property or with
a hash containing a C<code> and C<message> key, this information will be
used to populate the JSON-RPC error object returned to the caller.

=head2 Security

The C<dispatcher> method provided by
L<Mojolicious::Plugin::Qooxoo::JsonRpcController> calls the C<allow_rpc_access>
method to check if rpc access should be allowed.  The result of this request
is NOT cached, so you can use this method to provide dynamic access control
or even do initialization tasks that are required before handling each
request.

=head2 Async Processing

If you want to do asyncronoous data processing, call the C<render_later> method
to let the dispatcher know that it should not bother with trying to render anyting.
In the callback, call the C<renderJsonRpcResult> method to render your result. Note
that you have to take care of any exceptions in the callback yourself and use
the C<renderJsonRpcError> method to send the exception to the client.

=head2 Debugging

To see full details of your rpc request and the answers sent back to the
browser in your debug log, set the MOJO_QX_FULL_RPC_DETAILS environment
variable to 1.  Otherwise you will only see the first 60 characters even
when logging at debug level.

=head1 AUTHOR

S<Matthias Bloch, E<lt>matthias@puffin.chE<gt>>,
S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>.

This Module is sponsored by OETIKER+PARTNER AG.

=head1 COPYRIGHT

Copyright (C) 2010,2013

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
