package MojoX::Dispatcher::Qooxdoo::Jsonrpc;

use strict;
use warnings;

use Mojo::JSON qw(encode_json decode_json);
use Mojo::Base 'Mojolicious::Controller';
use Encode;
use Data::Dumper;

our $toUTF8 = find_encoding('utf8');

BEGIN {
    warn "MojoX::Dispatcher::Qooxdoo::Jsonrpc is DEPRECATED. Please switch to using Mojolicious::Plugin::Qooxdoo.\n" unless $ENV{DISABLE_DEPRECATION_WARNING_MPQ};
}


our $VERSION = '0.96';

sub dispatch {
    my $self = shift;
    
    # We have to differentiate between POST and GET requests, because
    # the data is not sent in the same place..
    my $log = $self->app->log;

    # send warnings to log file preserving the origin
    local $SIG{__WARN__} = sub {
        my  $message = shift;
        $message =~ s/\n$//;
        @_ = ($log, $message);
        goto &Mojo::Log::warn;
    };
    my $id;    
    my $data;
    my $cross_domain;
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
            $id             = $data->{id};
            $cross_domain   = 0;
            next;
        };
        /^GET$/ && do {            
            my $v = $self->param('_ScriptTransport_data');
            $data = eval { decode_json($self->param('_ScriptTransport_data')) };
            if ($@){
        		my $error = "Invalid json string: " . $@ . " " .Dumper $self->param;
		        $log->error($error);
        		$self->render(text => $error, status=>500);
		        return;
    	    };

            $id = $self->param('_ScriptTransport_id') ;
            $cross_domain   = 1;
            next;
        };
        my $error = "request must be POST or GET. Can't handle '".$self->req->method."'";
        $log->error($error);
        $self->render(text => $error, status=>500);
        return;
    }        
    if (not defined $id){
        my $error = "Missing 'id' property in JsonRPC request.";
        $log->error($error);
        $self->render(text => $error, status=>500);
        return;
    }


    # Check if desired service is available
    my $service = $data->{service} or do {
        my $error = "Missing service property in JsonRPC request.";
        $log->error($error);
        $self->render(text => $error, status=>500);
        return;
    };

    # Check if method is not private (marked with a leading underscore)
    my $method = $data->{method} or do {
        my $error = "Missing method property in JsonRPC request.";
        $log->error($error);
        $self->render(text => $error, status=>500);
        return;
    };
    
    my $params  = $data->{params} || []; # is a reference, so "unpack" it
 
    # invocation of method in class according to request 
    my $reply = eval{
        # make sure there are not foreign signal handlers
        # messing with our problems
        local $SIG{__DIE__};
        # Getting available services from stash
        my $svc = $self->stash('services')->{$service};

        die {
            origin => 1,
            message => "service $service not available",
            code=> 2
        } if not ref $svc;

        die {
             origin => 1, 
             message => "your rpc service object (".ref($svc).") must provide an allow_rpc_access method", 
             code=> 2
        } unless $svc->can('allow_rpc_access');

        
        if ($svc->can('controller')){
            # initialize session if it does not exists yet
            $svc->controller($self);
        }

        if ($svc->can('mojo_session')){
            # initialize session if it does not exists yet
            $log->warn('mojo_session is deprecated. Use controller->session instead');
            my $session = $self->stash->{'mojo.session'} ||= {};
            $svc->mojo_session($session);
        }

        if ($svc->can('mojo_stash')){
            $log->warn('mojo_stash is deprecated. Use controller->stash instead');
            # initialize session if it does not exists yet
            $svc->mojo_stash($self->stash);
        }

        die {
             origin => 1, 
             message => "rpc access to method $method denied", 
             code=> 6
        } unless $svc->allow_rpc_access($method);

        die {
             origin => 1, 
             message => "method $method does not exist.", 
             code=> 4
        } if not $svc->can($method);

        $log->debug("call $method(".encode_json($params).")");
        # reply
        no strict 'refs';
        $svc->$method(@$params);
    };
       
    if ($@){ 
        my $error;
        for (ref $@){
            /HASH/ && $@->{message} && do {
                $error = {
                     origin => $@->{origin} || 2, 
                     message => $@->{message}, 
                     code=>$@->{code}
                };
                last;
            };
            /.+/ && $@->can('message') && $@->can('code') && do {
                $error = {
                      origin => 2, 
                      message => $@->message(), 
                      code=>$@->code()
                };
                last;
            };
            $error = {
                origin => 2, 
                message => "error while processing ${service}::$method: $@", 
                code=> 9999
            };
        }
        $reply = encode_json({ id => $id, error => $error });
        $log->error("JsonRPC Error $error->{code}: $error->{message}");
    }
    else {
        $reply = encode_json({ id => $id, result => $reply });
        $log->debug("return ".$reply);
    }

    if ($cross_domain){
        # for GET requests, qooxdoo expects us to send a javascript method
        # and to wrap our json a litte bit more
        $self->res->headers->content_type('application/javascript; charset=utf-8');
        $reply = "qx.io.remote.transport.Script._requestFinished( $id, " . $reply . ");";
    } else {
        $self->res->headers->content_type('application/json; charset=utf-8');
    }    
    # the render takes care of encoding the output, so make sure we re-decode
    # the json stuf
    $self->render(text => $toUTF8->decode($reply));
}

1;



=head1 NAME

MojoX::Dispatcher::Qooxdoo::Jsonrpc - Dispatcher for Qooxdoo Json Rpc Calls

=head1 SYNOPSIS

THIS MODULE IS DEPRECATED. USE L<Mojolicious::Plugin::Qooxdoo> INSTEAD.

 # lib/your-application.pm

 use base 'Mojolicious';
 
 use RpcService;

 sub startup {
    my $self = shift;
    
    # instantiate all services
    my $services= {
        Test => RpcService->new(),
        
    };
    
    
    # add a route to the Qooxdoo dispatcher and route to it
    my $r = $self->routes;
    $r->route('/qooxdoo') -> to(
                'Jsonrpc#dispatch', 
                services    => $services, 
                debug       => 0,
                namespace   => 'MojoX::Dispatcher::Qooxdoo'
            );
        
 }

    

=head1 DESCRIPTION

L<MojoX::Dispatcher::Qooxdoo::Jsonrpc> dispatches incoming
rpc requests from a qooxdoo application to your services and renders
a (hopefully) valid json reply.


=head1 EXAMPLE 

This example exposes a service named "Test" in a folder "RpcService".
The Mojo application is named "QooxdooServer". The scripts are in
the 'example' directory.
First create this application using 
"mojolicious generate app QooxdooServer".

Then, lets write the service:

Change to the root directory "qooxdoo_server" of your fresh 
Mojo-Application and make a dir named 'qooxdoo-services' 
for the services you want to expose.

Our "Test"-service could look like:

 package RpcService;

 use Mojo::Base -base;

 # if you want to access mojo specific information
 # provide a controller property, it will be set to the
 # current controller as the request is dispached.
 # see L<Mojolicious::Controller> for documentation.
 has 'controller';
 
 # MANDADROY access check method. The method is called right before the actual
 # method call, after assigning mojo_session and mojo_stash properties are set.
 # These can be used for providing dynamic access control

 our %access = (
    add => 1,
 );

 sub allow_rpc_access {
    my $self = shift;
    my $method = shift;              
    # check if we can access
    return $access{$method};
 }

 sub add{
    my $self = shift;
    my @params = @_;
    
    # Debug message on Mojo-server console (or log)
    print "Debug: $params[0] + $params[1]\n";
    
    # uncomment if you want to die without further handling
    # die;
    
    # uncomment if you want to die with a message in a hash
    # die {code => 20, message => "Test died on purpose :-)"};
    
    
    # uncomment if you want to die with your homemade error object 
    # die MyException->new(code=>123,message=>'stupid error message');
    
    my $result =  $params[0] + $params[1]
    return $result;    
 }

 package MyException;
 use Mojo::Base -base;
 has 'code';
 has 'message';
 1;

The Dispatcher executes all calls to your service module within an eval
wrapper and will send any execptions you generate within back to the
qooxdoo application as well as into the Mojolicious logfile.

Now, lets write our application. Normally one would use the services of
L<Mojolicious::Plugin::QooxdooJsonrpc> for this. If you want to use the
dipatcher directly, this is how it is done.

 package QooxdooServer;

 use strict;
 use warnings;
 
 use RpcService::Test;

 use Mojo::Base 'Mojolicious';

 # This method will run once at server start
 sub startup {
    my $self = shift;
    
    my $services= {
        Test => RpcService::Test->new(),
        # more services here
    };
    
    # tell Mojo about your services:
    my $r = $self->routes;
    
    # this sends all requests for "/qooxdoo" in your Mojo server 
    # to our little dispatcher.
    # change this at your own taste.
    $r->route('/qooxdoo')->to('
        jsonrpc#dispatch', 
        services    => $services, 
        namespace   => 'MojoX::Dispatcher::Qooxdoo'
    );
    
 }

 1;

Now start your Mojo Server by issuing C<script/QooxdooServer daemon>. 
If you want to change any options, type C<script/QooxdooServer help>. 

=head2 Security

MojoX::Dispatcher::Qooxdoo::Jsonrpc calls the C<allow_rpc_access>
method to check if rpc access should be allowed. The result of this
request is NOT cached, so you can use this method to provide dynamic access control
or even do initialization tasks that are required before handling each request.

=head1 AUTHOR

S<Matthias Bloch, E<lt>matthias@puffin.chE<gt>>,
S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>.

This Module is sponsored by OETIKER+PARTNER AG

=head1 COPYRIGHT

Copyright (C) 2010 by :m)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
