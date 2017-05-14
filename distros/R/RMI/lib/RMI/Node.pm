package RMI::Node;

use strict;
use warnings;
use version;
our $VERSION = qv('0.1');

# Note: if any of these get proxied as full classes, we'd have issues.
# Since it's impossible to proxy a class which has already been "used",
# we use them at compile time...

use RMI;
use Tie::Array;
use Tie::Hash;
use Tie::Scalar;
use Tie::Handle;
use Data::Dumper;
use Scalar::Util;
use Carp;
require 'Config_heavy.pl'; 


# public API

_mk_ro_accessors(qw/reader writer/);

sub new {
    my $class = shift;
    my $self = bless {
        reader => undef,
        writer => undef,
        _sent_objects => {},
        _received_objects => {},
        _received_and_destroyed_ids => [],
        _tied_objects_for_tied_refs => {},        
        @_
    }, $class;
    if (my $p = delete $self->{allow_packages}) {
        $self->{allow_packages} = { map { $_ => 1 } @$p };
    }
    for my $p (@RMI::Node::properties) {
        unless (exists $self->{$p}) {
            die "no $p on object!"
        }
    }
    return $self;
}

sub close {
    my $self = $_[0];
    $self->{writer}->close unless $self->{reader} == $self->{writer};
    $self->{reader}->close;
}

sub send_request_and_receive_response {
    my $self = shift;
    
    if ($RMI::DEBUG) {
        print "$RMI::DEBUG_MSG_PREFIX N: $$ calling via $self: @_\n";
    }
    
    my $wantarray = wantarray;
    $self->_send('query',[$wantarray, @_]) or die "failed to send! $!";
    
    for (1) {
        my ($message_type, $message_data) = $self->_receive();
        if ($message_type eq 'result') {
            if ($wantarray) {
                print "$RMI::DEBUG_MSG_PREFIX N: $$ returning list @$message_data\n" if $RMI::DEBUG;
                return @$message_data;
            }
            else {
                print "$RMI::DEBUG_MSG_PREFIX N: $$ returning scalar $message_data->[0]\n" if $RMI::DEBUG;
                return $message_data->[0];
            }
        }
        elsif ($message_type eq 'close') {
            return;
        }
        elsif ($message_type eq 'query') {
            $self->_process_query($message_data);            
            redo;
        }
        elsif ($message_type eq 'exception') {
            die $message_data->[0];
        }
        else {
            die "unexpected message type from RMI message: $message_type";
        }
    }    
}

sub receive_request_and_send_response {
    my ($self) = @_;
    my ($message_type, $message_data) = $self->_receive();
    if ($message_type eq 'query') {
        my ($response_type, $response_data) = $self->_process_query($message_data);
        return ($message_type, $message_data, $response_type, $response_data);
    }
    elsif ($message_type eq 'close') {
        return;
    }
    else {
        die "Unexpected message type $message_type!  message_data was:" . Dumper::Dumper($message_data);
    }        
}

# private API

_mk_ro_accessors(qw/_sent_objects _received_objects _received_and_destroyed_ids _tied_objects_for_tied_refs/);

sub _send {
    my ($self, $message_type, $message_data) = @_;
    my $s = $self->_serialize($message_type,$message_data);    
    
    print "$RMI::DEBUG_MSG_PREFIX N: $$ sending: $s\n" if $RMI::DEBUG;
    return $self->{writer}->print($s,"\n");                
}

sub _receive {
    my ($self) = @_;
    print "$RMI::DEBUG_MSG_PREFIX N: $$ receiving\n" if $RMI::DEBUG;

    my $serialized_blob = $self->{reader}->getline;
    if (not defined $serialized_blob) {
        # a failure to get data returns a message type of 'close', and undefined message_data
        print "$RMI::DEBUG_MSG_PREFIX N: $$ connection closed\n" if $RMI::DEBUG;
        $self->{is_closed} = 1;
        return ('close',undef);
    }
    print "$RMI::DEBUG_MSG_PREFIX N: $$ got $serialized_blob" if $RMI::DEBUG;
    print "\n" if $RMI::DEBUG and not defined $serialized_blob;
    
    my ($message_type,$message_data) = $self->_deserialize($serialized_blob);
    return ($message_type, $message_data);
}

sub _process_query {
    my ($self, $message_data) = @_;

    my $wantarray = shift @$message_data;
    my $call_type = shift @$message_data;
    
    do {    
        no warnings;
        print "$RMI::DEBUG_MSG_PREFIX N: $$ processing query $call_type in wantarray context $wantarray with : @$message_data\n" if $RMI::DEBUG;
    };
    
    
    # swap call_ for _respond_to_
    my $method = '_respond_to_' . substr($call_type,5);
    
    my @result;

    push @RMI::executing_nodes, $self;
    eval {
        if (not defined $wantarray) {
            print "$RMI::DEBUG_MSG_PREFIX N: $$ object call with undef wantarray\n" if $RMI::DEBUG;
            $self->$method(@$message_data);
        }
        elsif ($wantarray) {
            print "$RMI::DEBUG_MSG_PREFIX N: $$ object call with true wantarray\n" if $RMI::DEBUG;
            @result = $self->$method(@$message_data);
        }
        else {
            print "$RMI::DEBUG_MSG_PREFIX N: $$ object call with false wantarray\n" if $RMI::DEBUG;
            my $result = $self->$method(@$message_data);
            @result = ($result);
        }
    };
    pop @RMI::executing_nodes;

    # we MUST undef these in case they are the only references to remote objects which need to be destroyed
    # the DESTROY handler will queue them for deletion, and _send() will include them in the message to the other side
    @$message_data = ();
    
    my ($return_type, $return_data);
    if ($@) {
        print "$RMI::DEBUG_MSG_PREFIX N: $$ executed with EXCEPTION (unserialized): $@\n" if $RMI::DEBUG;
        ($return_type, $return_data) = ('exception',[$@]);
    }
    else {
        print "$RMI::DEBUG_MSG_PREFIX N: $$ executed with result (unserialized): @result\n" if $RMI::DEBUG;
        ($return_type, $return_data) =  ('result',\@result);
    }
    
    $self->_send($return_type, $return_data);    
    return ($return_type, $return_data);
}

# private API for the server-ish role

sub _respond_to_function {
    my ($self, $fname, @params) = @_;
    no strict 'refs';
    $fname->(@params);
}

sub _respond_to_class_method {
    my ($self, $class, $method, @params) = @_;
    $class->$method(@params);
}

sub _respond_to_object_method {
    my ($self, $object, $method, @params) = @_;
    $object->$method(@params);
}

sub _respond_to_use {
    my ($self,$class,$module,$has_args,@use_args) = @_;

    no strict 'refs';
    if ($class and not $module) {
        $module = $class;
        $module =~ s/::/\//g;
        $module .= '.pm';
    }
    elsif ($module and not $class) {
        $class = $module;
        $class =~ s/\//::/g;
        $class =~ s/.pm$//; 
    }
    
    my $n = $RMI::Exported::count++;
    my $tmp_package_to_catch_exports = 'RMI::Exported::P' . $n;
    my $src = "
        package $tmp_package_to_catch_exports;
        require $class;
        my \@exports = ();
        if (\$has_args) {
            if (\@use_args) {
                $class->import(\@use_args);
                \@exports = grep { ${tmp_package_to_catch_exports}->can(\$_) } keys \%${tmp_package_to_catch_exports}::;
            }
            else {
                # print qq/no import because of empty list!/;
            }
        }
        else {
            $class->import();
            \@exports = grep { ${tmp_package_to_catch_exports}->can(\$_) } keys \%${tmp_package_to_catch_exports}::;
        }
        return (\$INC{'$module'}, \@exports);
    ";
    my ($path, @exported) = eval($src);
    die $@ if $@;
    return ($class,$module,$path,@exported);
}

sub _respond_to_use_lib {
    my $self = shift; 
    my $lib = shift;
    require lib;
    return lib->import($lib);
}

sub _respond_to_eval {
    my $self = shift;
    my $src = shift;
    if (wantarray) {
        my @result = eval $src;
        die $@ if $@;
        return @result;        
    }
    else {
        my $result = eval $src;
        die $@ if $@;
        return $result;
    }
}

sub _respond_to_coderef {
    # This is used when a CODE ref is proxied, since you can't tie CODE refs.
    # It does not have a matching caller in RMI::Client.
    # The other reference types are handled by "tie" to RMI::ProxyReferecnce.

    # NOTE: It's important to shift these two parameters off since goto must 
    # pass the remainder of @_ to the subroutine.
    my $self = shift;
    my $sub_id = shift;
    my $sub = $self->{_sent_objects}{$sub_id};
    die "$sub is not a CODE ref.  came from $sub_id\n" unless $sub and ref($sub) eq 'CODE';
    goto $sub;
}

# The private API for the client-ish role of the RMI::Node is still in the RMI::Client module,
# where it is documented.  All of that API is a thin wrapper for methods here.

# serialize params when sending a query, or results when sending a response

sub _serialize {
    my ($self, $message_type, $message_data) = @_;    
    
    my $sent_objects = $self->{_sent_objects};
    my $received_and_destroyed_ids = $self->{_received_and_destroyed_ids};

    my @serialized = ([@$received_and_destroyed_ids]);
    @$received_and_destroyed_ids = ();
    
    Carp::confess() unless ref($message_data);
    for my $o (@$message_data) {
        if (my $type = ref($o)) {
            if ($type eq "RMI::ProxyObject" or $RMI::proxied_classes{$type}) {
                my $key = $RMI::Node::remote_id_for_object{$o};
                print "$RMI::DEBUG_MSG_PREFIX N: $$ proxy $o references remote $key:\n" if $RMI::DEBUG;
                push @serialized, 3, $key;
                next;
            }
            elsif ($type eq "RMI::ProxyReference") {
                # This only happens from inside of AUTOLOAD in RMI::ProxyReference.
                # There is some other reference in the system which has been tied, and this object is its
                # surrogate.  We need to make sure that reference is deserialized on the other side.
                my $key = $RMI::Node::remote_id_for_object{$o};
                print "$RMI::DEBUG_MSG_PREFIX N: $$ tied proxy special obj $o references remote $key:\n" if $RMI::DEBUG;
                push @serialized, 3, $key;
                next;
            }            
            else {
                # TODO: use something better than stringification since this can be overridden!!!
                my $key = "$o";
                
                # TODO: handle extracting the base type for tying for regular objects which does not involve parsing
                my $base_type = substr($key,index($key,'=')+1);
                $base_type = substr($base_type,0,index($base_type,'('));
                my $code;
                if ($base_type ne $type) {
                    # blessed reference
                    $code = 1;
                    if (my $allowed = $self->{allow_packages}) {
                        unless ($allowed->{ref($o)}) {
                            die "objects of type " . ref($o) . " cannot be passed from this RMI node!";
                        }
                    }
                }
                else {
                    # regular reference
                    $code = 2;
                }
                
                push @serialized, $code, $key;
                $sent_objects->{$key} = $o;
            }
        }
        else {
            push @serialized, 0, $o;
        }
    }
    print "$RMI::DEBUG_MSG_PREFIX N: $$ $message_type translated for serialization to @serialized\n" if $RMI::DEBUG;

    @$message_data = (); # essential to get the DESTROY handler to fire for proxies we're not holding on-to
    print "$RMI::DEBUG_MSG_PREFIX N: $$ destroyed proxies: @$received_and_destroyed_ids\n" if $RMI::DEBUG;    
    
    my $serialized_blob = Data::Dumper->new([[$message_type, @serialized]])->Terse(1)->Indent(0)->Useqq(1)->Dump;
    print "$RMI::DEBUG_MSG_PREFIX N: $$ $message_type serialized as $serialized_blob\n" if $RMI::DEBUG;
    if ($serialized_blob =~ s/\n/ /gms) {
        die "newline found in message data!";
    }
    
    return $serialized_blob;
}

# deserialize params when receiving a query, or results when receiving a response

sub _deserialize {
    my ($self, $serialized_blob) = @_;
    
    my $serialized = eval "no strict; no warnings; $serialized_blob";
    if ($@) {
        die "Exception de-serializing message: $@";
    }        

    my $message_type = shift @$serialized;
    if (! defined $message_type) {
        die "unexpected undef type from incoming message:" . Data::Dumper::Dumper($serialized);
    }    

    do {
        no warnings;    
        print "$RMI::DEBUG_MSG_PREFIX N: $$ processing (serialized): @$serialized\n" if $RMI::DEBUG;
    };
    
    my @message_data;

    my $sent_objects = $self->{_sent_objects};
    my $received_objects = $self->{_received_objects};
    my $received_and_destroyed_ids = shift @$serialized;
    
    while (@$serialized) { 
        my $type = shift @$serialized;
        my $value = shift @$serialized;
        if ($type == 0) {
            # primitive value
            print "$RMI::DEBUG_MSG_PREFIX N: $$ - primitive " . (defined($value) ? $value : "<undef>") . "\n" if $RMI::DEBUG;
            push @message_data, $value;
        }
        elsif ($type == 1 or $type == 2) {
            # exists on the other side: make a proxy
            my $o = $received_objects->{$value};
            unless ($o) {
                my ($remote_class,$remote_shape) = ($value =~ /^(.*?=|)(.*?)\(/);
                chop $remote_class;
                my $t;
                if ($remote_shape eq 'ARRAY') {
                    $o = [];
                    $t = tie @$o, 'RMI::ProxyReference', $self, $value, "$o", 'Tie::StdArray';                        
                }
                elsif ($remote_shape eq 'HASH') {
                    $o = {};
                    $t = tie %$o, 'RMI::ProxyReference', $self, $value, "$o", 'Tie::StdHash';                        
                }
                elsif ($remote_shape eq 'SCALAR') {
                    my $anonymous_scalar;
                    $o = \$anonymous_scalar;
                    $t = tie $$o, 'RMI::ProxyReference', $self, $value, "$o", 'Tie::StdScalar';                        
                }
                elsif ($remote_shape eq 'CODE') {
                    my $sub_id = $value;
                    $o = sub {
                        $self->send_request_and_receive_response('call_coderef', $sub_id, @_);
                    };
                    # TODO: ensure this cleans up on the other side when it is destroyed
                }
                elsif ($remote_shape eq 'GLOB' or $remote_shape eq 'IO') {
                    $o = \do { local *HANDLE };
                    $t = tie *$o, 'RMI::ProxyReference', $self, $value, "$o", 'Tie::StdHandle';
                }
                else {
                    die "unknown reference type for $remote_shape for $value!!";
                }
                if ($type == 1) {
                    if ($RMI::proxied_classes{$remote_class}) {
                        bless $o, $remote_class;
                    }
                    else {
                        bless $o, 'RMI::ProxyObject';    
                    }
                }
                $received_objects->{$value} = $o;
                Scalar::Util::weaken($received_objects->{$value});
                my $o_id = "$o";
                my $t_id = "$t" if defined $t;
                $RMI::Node::node_for_object{$o_id} = $self;
                $RMI::Node::remote_id_for_object{$o_id} = $value;
                if ($t) {
                    # ensure calls to work with the "tie-buddy" to the reference
                    # result in using the orinigla reference on the "real" side
                    $RMI::Node::node_for_object{$t_id} = $self;
                    $RMI::Node::remote_id_for_object{$t_id} = $value;
                }
            }
            
            push @message_data, $o;
            print "$RMI::DEBUG_MSG_PREFIX N: $$ - made proxy for $value\n" if $RMI::DEBUG;
        }
        elsif ($type == 3) {
            # exists on this side, and was a proxy on the other side: get the real reference by id
            my $o = $sent_objects->{$value};
            print "$RMI::DEBUG_MSG_PREFIX N: $$ reconstituting local object $value, but not found in my sent objects!\n" and die unless $o;
            push @message_data, $o;
            print "$RMI::DEBUG_MSG_PREFIX N: $$ - resolved local object for $value\n" if $RMI::DEBUG;
        }
    }
    print "$RMI::DEBUG_MSG_PREFIX N: $$ remote side destroyed: @$received_and_destroyed_ids\n" if $RMI::DEBUG;
    my @done = grep { defined $_ } delete @$sent_objects{@$received_and_destroyed_ids};
    unless (@done == @$received_and_destroyed_ids) {
        print "Some IDS not found in the sent list: done: @done, expected: @$received_and_destroyed_ids\n";
    }

    return ($message_type,\@message_data);
}

# this proxies a single variable

sub bind_local_var_to_remote {
    my $self = shift;
    my $local_var = shift;
    my $remote_var = (@_ ? shift : $local_var);
    
    my $type = substr($local_var,0,1);
    if (index($local_var,'::')) {
        $local_var = substr($local_var,1);
    }
    else {
        my $caller = caller();
        $local_var = $caller . '::' . substr($local_var,1);
    }

    unless ($type eq substr($remote_var,0,1)) {
        die "type mismatch: local var $local_var has type $type, while remote is $remote_var!";
    }
    if (index($remote_var,'::')) {
        $remote_var = substr($remote_var,1);
    }
    else {
        my $caller = caller();
        $remote_var = $caller . '::' . substr($remote_var,1);
    }
    
    my $src = '\\' . $type . $remote_var . ";\n";
    my $r = $self->call_eval($src);
    die $@ if $@;
    $src = '*' . $local_var . ' = $r' . ";\n";
    eval $src;
    die $@ if $@;
    return 1;
}

# this proxies an entire class instead of just a single object

sub bind_local_class_to_remote {
    my $self = shift;
    my ($class,$module,$path,@exported) = $self->call_use(@_);
    my $re_bind = 0;
    if (my $prior = $RMI::proxied_classes{$class}) {
        if ($prior != $self) {
            die "class $class has already been proxied by another RMI client: $prior!";
        }
        else {
            # re-binding a class to the same remote side doesn't hurt,
            # and allowing it allows the effect of export to occur
            # in multiple places on the client side.
        }
    }
    elsif (my $path = $INC{$module}) {
        die "module $module has already been used locally from path: $path";
    }
    no strict 'refs';
    for my $sub (qw/AUTOLOAD DESTROY can isa/) {
        *{$class . '::' . $sub} = \&{ 'RMI::ProxyObject::' . $sub }
    }
    if (@exported) {
        my $caller ||= caller(0);
        if (substr($caller,0,5) eq 'RMI::') { $caller = caller(1) }
        for my $sub (@exported) {
            my @pair = ('&' . $caller . '::' . $sub => '&' . $class . '::' . $sub);
            print "$RMI::DEBUG_MSG_PREFIX N: $$ bind pair $pair[0] $pair[1]\n" if $RMI::DEBUG;
            $self->bind_local_var_to_remote(@pair);
        }
    }
    $RMI::proxied_classes{$class} = $self;
    $INC{$module} = $self;
    print "$class used remotely via $self.  Module $module found at $path remotely.\n" if $RMI::DEBUG;    
}

# used for testing

sub _remote_has_ref {
    my ($self,$obj) = @_;
    my $id = "$obj";
    my $has_sent = $self->send_request_and_receive_response('call_eval', 'exists $RMI::executing_nodes[-1]->{_received_objects}{"' . $id . '"}');
}

sub _remote_has_sent {
    my ($self,$obj) = @_;
    my $id = "$obj";
    my $has_sent = $self->send_request_and_receive_response('call_eval', 'exists $RMI::executing_nodes[-1]->{_sent_objects}{"' . $id . '"}');
}

# this generate basic accessors w/o using any other Perl modules which might have proxy effects

sub _mk_ro_accessors {
    no strict 'refs';
    my $class = caller();
    for my $p (@_) {
        my $pname = $p;
        *{$class . '::' . $pname} = sub { die "$pname is read-only!" if @_ > 1; $_[0]->{$pname} };
    }
    no warnings;
    push @{ $class . '::properties'}, @_;
}

=pod

=head1 NAME

RMI::Node - base class for RMI::Client and RMI::Server 

=head1 SYNOPSIS
    
    # applications should use B<RMI::Client> and B<RMI::Server>
    # this example is for new client/server implementors
    
    pipe($client_reader, $server_writer);  
    pipe($server_reader,  $client_writer);     
    $server_writer->autoflush(1);
    $client_writer->autoflush(1);
    
    $c = RMI::Node->new(
        reader => $client_reader,
        writer => $client_writer,
    );
    
    $s = RMI::Node->new(
        writer => $server_reader,
        reader => $server_writer,
    );
    
    sub main::add { return $_[0] + $_[1] }
    
    if (fork()) {
        # service one request and exit
        require IO::File;
        $s->receive_request_and_send_response();
        exit;
    }
    
    # send one request and get the result
    $sum = $c->send_request_and_receive_response('call_function', 'main::add', 5, 6);
    
    # we might have also done..
    $robj = $c->send_request_and_receive_response('call_class_method', 'IO::File', 'new', '/my/file');
    
    # this only works on objects which are remote proxies:
    $txt = $c->send_request_and_receive_response('call_object_method', $robj, 'getline');
    
=head1 DESCRIPTION

This is the base class for RMI::Client and RMI::Server.  RMI::Client and RMI::Server
both implement a wrapper around the RMI::Node interface, with convenience methods
around initiating the sending or receiving of messages.

An RMI::Node object embeds the core methods for bi-directional communication.
Because the server often has to make counter requests of the client, the pair
will often switch functional roles several times in the process of servicing a
particular call. This class is not technically abstract, as it is fully functional in
either the client or server role without subclassing.  Most direct coding against
this API, however, should be done by implementors of new types of clients/servers.

See B<RMI::Client> and B<RMI::Server> for the API against which application code
should be written.  See B<RMI> for an overview of how clients and servers interact.
The documentation in this module will describe the general piping system between
clients and servers.

An RMI::Node requires that the reader/writer handles be explicitly specified at
construction time.  It also requires and that the code which uses it is be wise
about calling methods to send and recieve data which do not cause it to block
indefinitely. :)

=head1 METHODS

=head2 new()
  
 $n = RMI::Node->new(reader => $fh1, writer => $fh2);

The constructor for RMI::Node objects requires that a reader and writer handle be provided.  They
can be the same handle if the handle is bi-directional (as with TCP sockets, see L<RMI::Client::Tcp>).

=head2 close()

 $n->close();

Closes handles, and does any additional required bookeeping.
 
=head2 send_request_and_recieve_response()

 @result = $n->send_request_and_recieve_response($call_type,$object,$method,$params,$opts)

 $fh = $n->send_request_and_receive_response('call_class_method', 'IO::File', 'new', ['/my/file'], {});

This is the primary method used by nodes acting in a client-like capacity.

 $call_type:    one of: call_object_method, call_class_method, or call_function, or one of several internal types
 $object:       the object or class on which the method is being called, may be undef for subroutine/function calls
 $method:       the method to call on $object (even if $object is a class name), or the fully-qualified sub name
 @params:       an optional array of values which should be passed to $method

Return values:

 $result|@result: the return value will be either a scalar or list, depending on the value of $wantarray

This method sends a method call request through the writer, and waits on a response from the reader.
It will handle a response with the answer, exception messages, and also handle counter-requests
from the server, which may occur b/c the server calls methods on objects passed as parameters.

=head2 receive_request_and_send_response()

This method waits for a single request to be received from its reader handle, services
the request, and sends the results through the writer handle.
 
It is possible that, while servicing the request, it will make counter requests, and those
counter requests, may yield counter-counter-requests which call this method recursively.

=head2 virtual_lib()

This method returns an anonymous subroutine which can be used in a "use lib $mysub"
call, to cause subsequent "use" statements to go through this node to its partner.
 
 e.x.:
    use lib RMI::Client::Tcp-new(host=>'myserver',port=>1234)->virtual_lib;
 
If a client is constructed for other purposes in the application, the above
can also be accomplished with: $client->use_lib_remote().  (See L<RMI::Client>)

=head1 INTERNALS

The RMI internals are built around sending a "message", which has a type, and an
array of data. The interpretation of the message data array is based on the message
type.

The following message types are passed within the current implementation:

=head2 query

A request that logic execute on the remote side on behalf of the sender.
This includes object method calls, class method calls, function calls,
remote calls to eval(), and requests that the remote side load modules,
add library paths, etc.
  
This is the type for standard remote method invocatons.
  
The message data contains, in order:

 - wantarray    1, '', or undef, depending on the requestor's calling context.
                This is passed to the remote side, and also used on the
                local side to control how results are returned.

 - object/class A class name, or an object which is a proxy for something on the remote side.
                This value is not present for plain function calls, or evals.

 - method_name  This is the name of the method to call.
                This is a fully-qualified function name for plain function calls.

 - param1       The first parameter to the function/method call.
                Note that parameters are "passed" to eval as well by exposing @_.

 - ...          The next parameter to the function/method call, etc.


=head2 result

The return value from a succesful "query" which does not result in an
exception being thrown on the remote side.
  
The message data contains, the return value or vaues of that query.
  
=head2 exception

The response to a query which resulted in an exception on the remote side.
  
The message data contains the value thrown via die() on the remote side.
  
=head2 close

Indicatees that the remote side has closed the connection.  This is actually
constructed on the receiver end when it fails to read from the input stream.
  
The message data is undefined in this case.
  
The _send() and _receive() methods are symmetrical.  These two methods are used
by the public API to encapsulate message transmission and reception.  The _send()
method takes a message_type and a message_data arrayref, and transmits them to
the other side of the RMI connection. The _receive() method returns a message
type and message data array.

Internal to _send() and _receive() the message type and data are passed through
_serialize and _deserialize and then transmitted along the writer and reader handles.

The _serialize method turns a message_type and message_data into a string value
suitable for transmission.  Conversely, the _deserialize method turns a string
value in the same format into a message_type and message_data array.

The serialization process has two stages:

=head2 replacing references with identifiers used for remoting

An array of message_data of length n to is converted to have a length of n*2.
Each value is preceded by an integer which categorizes the value.

  0    a primitive, non-reference value
       
       The value itself follows, and is passed by-copy.
       
  1    an object reference originating on the sender's side
 
       A unique identifier for the object follows instead of the object.
       The remote side should construct a transparent proxy which uses that ID.
       
  2    a non-object (unblessed) reference originating on the sender's side
       
       A unique identifier for the reference follows, instead of the reference.
       The remote side should construct a transparent proxy which uses that ID.
       
  3    passing-back a proxy: a reference which originated on the receiver's side
       
       The following value is the identifier the remote side sent previously.
       The remote side should substitue the original object when deserializing

Note that all references are turned into primitives by the above process.

=head2 stringification

The "wire protocol" for sending and receiving messages is to pass an array via Data::Dumper
in such a way that it does not contain newlines.  The receiving side uses eval to reconstruct
the original message.  This is terribly inefficient because the structure does not contain
objects of arbitrary depth, and is parsable without tremendous complexity.

Details on how proxy objects and references function, and pose as the real item
in question, are in B<RMI>, and B<RMI::ProxyObject> and B<RMI::ProxyReference>

=head1 BUGS AND CAVEATS

See general bugs in B<RMI> for general system limitations

=head2 the serialization mechanism needs to be made more robust and efficient

It's really just enough to "work".

The current implementation uses Data::Dumper with options which should remove
newlines.  Since we do not flatten arbitrary data structures, a simpler parser
would be more efficient.

The message type is currently a text string.  This could be made smaller.

The data type before each paramter or return value is an integer, which could
also be abbreviated futher, or we could go the other way and be more clear. :)

This should switch to sysread and pass the message length instead of relying on
buffers, since the non-blocking IO might not have issues.

=head1 SEE ALSO

B<RMI>, B<RMI::Server>, B<RMI::Client>, B<RMI::ProxyObject>, B<RMI::ProxyReference>

B<IO::Socket>, B<Tie::Handle>, B<Tie::Array>, B<Tie:Hash>, B<Tie::Scalar>

=head1 AUTHORS

Scott Smith <sakoht@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008 - 2009 Scott Smith <sakoht@cpan.org>  All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this
module.

=cut

1;

