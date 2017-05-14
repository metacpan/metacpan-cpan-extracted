package RMI::Client;

use strict;
use warnings;
our $VERSION = $RMI::VERSION; 

use base 'RMI::Node';

# all methods in this module are convenience wrappers for RMI::Node generic methods.

*call_sub = \&call_function;

sub call_function {
    my ($self,$fname,@params) = @_;
    return $self->send_request_and_receive_response('call_function', $fname, @params);
}

sub call_class_method {
    my ($self,$class,$method,@params) = @_;
    return $self->send_request_and_receive_response('call_class_method', $class, $method, @params);
}

sub call_object_method {
    my ($self,$object,$method,@params) = @_;
    return $self->send_request_and_receive_response('call_object_method', $object, $method, @params);
}

sub call_eval {
    my ($self,$src,@params) = @_;
    return $self->send_request_and_receive_response('call_eval', $src, @params);    
}

sub call_use {
    my ($self,$class,$module,$use_args) = @_;

    my @exported;
    my $path;
    
    ($class,$module,$path, @exported) = 
        $self->send_request_and_receive_response(
            'call_use',
            $class,
            $module,
            defined($use_args),
            ($use_args ? @$use_args : ())
        );
        
    return ($class,$module,$path,@exported);
}

sub call_use_lib {
    my ($self,$lib) = @_;
    return $self->send_request_and_receive_response('call_use_lib', $lib);
}

sub use_remote {
    my $self = shift;
    my $class = shift;
    $self->bind_local_class_to_remote($class, undef, @_);
    $self->bind_local_var_to_remote('@' . $class . '::ISA');
    return 1;
}

sub use_lib_remote {
    my $self = shift;
    unshift @INC, $self->virtual_lib;
}

sub virtual_lib {
    my $self = shift;
    my $virtual_lib = sub {
        my $module = pop;
        $self->bind_local_class_to_remote(undef,$module);
        my $sym = Symbol::gensym();
        my $done = 0;
        return $sym, sub {
            if (! $done) {
                $_ = '1;';
                $done++;
                return 1;
            }
            else {
                return 0;
            }
        };
    }
}

sub bind {
    my $self = shift;
    if (substr($_[0],0,1) =~ /\w/) {
        $self->bind_local_class_to_remote(@_);
    }
    else {
        $self->bind_local_var_to_remote(@_);
    }
}


=pod

=head1 NAME

RMI::Client - connection to an RMI::Server

=head1 SYNOPSIS

 # simple
 $c = RMI::Client::ForkedPipes->new(); 

 # typical
 $c = RMI::Client::Tcp->new(host => 'server1', port => 1234);
 
 # roll-your-own...
 $c = RMI::Client->new(reader => $fh1, writer => $fh2); # generic
 
 $c->call_use('IO::File');
 $c->call_use('Sys::Hostname');

 $remote_obj = $c->call_class_method('IO::File','new','/tmp/myfile');
 print $remote_obj->getline;
 print <$remote_obj>;

 $host = $c->call_function('Sys::Hostname::hostname')
 $host eq 'server1'; #!
 
 $remote_hashref = $c->call_eval('$main::h = { k1 => 111, k2 => 222, k3 => 333}'); 
 $remote_hashref->{k4} = 444;
 print sort keys %$remote_hashref;
 print $c->call_eval('sort keys %$main::h'); # includes changes!

 $c->use_remote('Sys::Hostname');   # this whole package is on the other side
 $host = Sys::Hostname::hostname(); # possibly not this hostname...

 our $c;
 BEGIN {
    $c = RMI::Client::Tcp->new(port => 1234);
    $c->use_lib_remote;
 }
 use Some::Class;               # remote!
  
=head1 DESCRIPTION

This is the base class for a standard RMI connection to an RMI::Server.

In most cases, you will create a client of some subclass, typically
B<RMI::Client::Tcp> for a network socket, or B<RMI::Client::ForkedPipes>
for a private out-of-process object server.

=head1 METHODS
 
=head2 call_use_lib($path);

Calls "use lib '$path'" on the remote side.

 $c->call_use_lib('/some/path/on/the/server');

=head2 call_use($class)

Uses the Perl package specified on the remote side, making it available for later
calls to call_class_method() and call_function().

 $c->call_use('Some::Package');

=head2 call_class_method($class, $method, @params)

Does $class->$method(@params) on the remote side.

Calling remote constructors is the primary way to make a remote object.

 $remote_obj = $client->call_class_method('Some::Class','new',@params);
 
 $possibly_another_remote_obj = $remote_obj->some_method(@p);
 
=head2 call_function($fname, @params)

A plain function call made by name to the remote side.  The function name must be fully qualified.

 $c->call_use('Sys::Hostname');
 my $server_hostname = $c->call_function('Sys::Hostname::hostname');

=head2 call_sub($subname, @params)

An alias for call_function();

=head2 call_eval($src,@args)

Calls eval $src on the remote side.

Any additional arguments are set to @_ before eval on the remote side, after proxying.

    my $a = $c->call_eval('@main::x = (11,22,33); return \@main::x;');  # pass an arrayref back
    push @$a, 44, 55;                                                   # changed on the server
    scalar(@$a) == $c->call_eval('scalar(@main::x)');                   # ...true! 
 
=head2 use_remote($class)

Creases the effect of "use $class", but all calls of any kind for that
namespace are proxied through the client.  This is the most transparent way to
get remote objects, since you can just call normal constructors and class methods
as though the module were local.  It does means that ALL objects of the given
class must come from through this client.

 # NOTE: you probably shouldn't do this with IO::File unless you
 # _really_ want all of its files to open on the server,
 # while open() opens on the client...
 
 $c->use_remote('IO::File');    # never touches IO/File.pm on the client                                
 $fh = IO::File->new('myfile'); # actually a remote call
 print <$fh>;                   # printing rows from a remote file

 require IO::File;              # does nothing, since we've already "used" IO::File
 
The @ISA array is also bound to the remote @ISA, but all other variables
must be explicitly bound on the client to be accessible.  This may be changed in a
future release.

Exporting does work.  To turn it off, use empty braces as you would empty parens.

 $c->use_remote('Sys::Hostname',[]);

To get this effect (and prevent export of the hostame() function).

 use Sys::Hostname ();

=head2 use_lib_remote($path)

Installs a special handler into the local @INC which causes it to check the remote
side for a class.  If available, it will do use_remote() on that class.

 use A;
 use B; 
 BEGIN { $c->use_remote_lib; }; # do everything remotely from now on if possible...
 use C; #remote!
 use D; #remote!
 use E; #local, b/c not found on the remote side

=head2 bind($varname)

Create a local transparent proxy for a package variable on the remote side.

  $c->bind('$Some::Package::somevar')
  $Some::Package::somevar = 123; # changed remotely
  
  $c->bind('@main::foo');
  push @main::foo, 11, 22 33; #changed remotely

=head1 ADDITIONAL EXAMPLES

=head2 create and use a remote hashref

This makes a hashref on the server, and makes a proxy on the client:

    my $remote_hashref = $c->call_eval('{}');

This seems to put a key in the hash, but actually sends a message to the server
to modify the hash.

    $remote_hashref->{key1} = 100;

Lookups also result in a request to the server:

    print $remote_hashref->{key1};

When we do this, the hashref on the server is destroyed, as since the ref-count
on both sides is now zero:

    $remote_hashref = undef;

=head2 put remote objects from one server in a remote hash on another

$c1 = RMI::Client::Tcp->new(host => 'host1', port => 1234);
$c2 = RMI::Client::Tcp->new(host => 'host2', port => 1234);
$c3 = RMI::Client::Tcp->new(host => 'host3', port => 1234);

$o1 = $c1->call_class_method('IO::File','new','/etc/passwd');
$o2 = $c2->call_class_method('IO::File','new','/etc/passwd');

$h  = $c3->call_eval('{ handle1 => $_[0] }', $o1);

$h->{handle2} = $o2;

=head2 making a remote CODE ref, and using it with local and remote objects

    my $local_fh = IO::File->new('/etc/passwd');
    my $remote_fh = $c->call_class_method('IO::File','new','/etc/passwd');
    my $remote_coderef = $c->call_eval('
                            sub {
                                my $f1 = shift; my $f2 = shift;
                                my @lines = (<$f1>, <$f2>);
                                return scalar(@lines)
                            }
                        ');
    my $total_line_count = $remote_coderef->($local_fh, $remote_fh);

=head1 BUGS AND CAVEATS

See general bugs in B<RMI> for general system limitations

=head1 SEE ALSO

B<RMI>, B<RMI::Client::Tcp>, B<RMI::Client::ForkedPipes>, B<RMI::Server>

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

