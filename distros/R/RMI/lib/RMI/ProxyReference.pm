package RMI::ProxyReference;

use strict;
use warnings;   
use version;
our $VERSION = $RMI::VERSION;

use RMI;


# When references are "passed" to a remote client/server, the proxy is tied using this package to proxy back all data access.
# NOTE: if the reference is blessed, the proxy will also be blessed into RMI::ProxyObject, in addition to being _tied_ to this package.

*TIEARRAY   = \&TIE;
*TIEHASH    = \&TIE;
*TIESCALAR  = \&TIE;
*TIEHANDLE  = \&TIE;

# CODE references are handled specially, using an anonymous sub on the proxy side, without tie, since tie does not support them

sub TIE {
    my $obj = bless [@_], $_[0];
    return $obj;
}

sub AUTOLOAD {
    no strict 'refs';
    my $method = $RMI::ProxyReference::AUTOLOAD;
    $method =~ s/^.*:://g;
    my $o = $_[0];
    my ($c,$n,$v,$t,$delegate_class) = @$o;
    my $node = $RMI::Node::node_for_object{$t} || $n;
    print "$RMI::DEBUG_MSG_PREFIX R: $$ reference calling $method in $delegate_class from $o ($n,$v,$t) through node $node with " . join(",", @_) . "\n" if $RMI::DEBUG;
    unless ($node) {
        die "no node for reference $o: method $method for @_ (@$o)?" . Data::Dumper::Dumper(\%RMI::Node::node_for_object);
    }
    # inheritance doesn't work this one method
    # TODO: make a custom sub-class for these instead of using Tie::StdX directly
    if ($delegate_class eq 'Tie::StdArray' and $method eq 'EXTEND') {
        $delegate_class = 'Tie::Array';
    }
    $node->send_request_and_receive_response('call_function', $delegate_class . '::' . $method, @_);
}

sub DESTROY {
    my $self = $_[0];
    my ($c,$node,$remote_id,$t) = @$self;
    $node = delete $RMI::Node::node_for_object{$t};
    print "$RMI::DEBUG_MSG_PREFIX R: $$ DESTROYING $self wrapping $remote_id from $node with $t\n" if $RMI::DEBUG;
    delete $node->{_received_objects}{$remote_id};
    push @{ $node->{_received_and_destroyed_ids} }, $remote_id;
}

# NOTE: this module uses Tie::Std* modules in non-standard ways
#
# AUTOLOAD makes a remote function call for every operation to one of the Tie::Std*
# family of modules.  The code for these modules works by beautiful coincidence
# on the side which originated the reference, even though that reference is not
# actually tied to that package in that process (nor in the remote process, b/c
# there it is tied to _this_ package).
#
# It is not known yet whether this has unseen limitations, and we will eventually
# need custom packages to manage remote operations on references.

1;

=pod

=head1 NAME

RMI::ProxyReference - used internally by RMI to tie references
    
=head1 VERSION

This document describes RMI::ProxyReference v0.10.

=head1 DESCRIPTION

When an refrerence is detected in the params or return value for an RMI
call, the sending RMI::Node (client sending params or server sending
results) captures a reference to the item internally, generates an "id"
for that object, and sends the "id" across the handle instead.

When the remote side recieves the "id", it also recieves an indication
that this is the id of a proxied reference, an indication of what Perl
base type it is (SCALAR,ARRAY,HASH,CODE,GLOB/IO), and what class it is
blessed-into, if any.  The remote side constructs a reference of
the appropriate type, and uses "tie" to bind it to this package.

All subsequent attempst to use the reference fire AUTOLOAD,
and result in a request across the "wire" to the other side.

Note: if the reference is blessed, it also blesses the object as an
B<RMI::ProxyObject>.  Because bless and tie are independent, a
single reference can (and will) be blessed and tied to two different
packages, one for method call resolution, and one for usage of
the reference as a HASH ref, ARRAY ref, CODE ref, etc.

Details of Perl tie are somewhat esoteric, but it is worth mentioning
that tying a reference $o results in an additional, separate object
being created, which is the invocant above whenever activity on the
reference occurs.  That second object is managed internally by Perl,
though we are able to use it to store the identify of $o on the "real" side,
along with information about the RMI::Node through which to proxy
calls.

Note: CODE references are not tied, and do not use this class.  A
proxy for a code reference is generated as an anonymous subrotine
which makes a remote call via its RMI::Node upon execute.

=head1 METHODS

The RMI::ProxyReference implements TIEHASH TIEARRAY TIESCALAR and
TIEHANDLE with a single implementation.  All other methods are
implemented by proxying back to the original side via AUTOLOAD.

On the local side, all attempts to access the real reference go through
Tie::StdArray, Tie::StdHash, Tie::StdScalar and Tie::StdHandle.  Note
that we do not _actually_ "tie" the real reference on the original side
before sending it.  These methods work just fine with the 

=head1 BUGS AND CAVEATS

See general bugs in B<RMI> for general system limitations

=head1 SEE ALSO

B<RMI> B<RMI::ProxyObject> B<RMI::Node> B<RMI::Client> B<RMI::Server>

B<Tie::Scalar> B<Tie::Array> B<Tie::Hash> B<Tie::Handle>

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

