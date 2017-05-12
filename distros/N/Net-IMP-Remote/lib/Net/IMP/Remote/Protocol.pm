use strict;
use warnings;
package Net::IMP::Remote::Protocol;
use Scalar::Util 'dualvar';
use Carp;

use Exporter 'import';
our @EXPORT = qw(
    IMPRPC_GET_INTERFACE
    IMPRPC_SET_INTERFACE
    IMPRPC_NEW_ANALYZER
    IMPRPC_DEL_ANALYZER
    IMPRPC_DATA
    IMPRPC_SET_VERSION
    IMPRPC_EXCEPTION
    IMPRPC_INTERFACE
    IMPRPC_RESULT
);


use constant IMPRPC_GET_INTERFACE => dualvar(0x4001,'get_interface');
use constant IMPRPC_SET_INTERFACE => dualvar(0x4002,'set_interface');
use constant IMPRPC_NEW_ANALYZER  => dualvar(0x4003,'new_analyzer');
use constant IMPRPC_DEL_ANALYZER  => dualvar(0x4004,'delete_analyzer');
use constant IMPRPC_DATA          => dualvar(0x4005,'data');
use constant IMPRPC_SET_VERSION   => dualvar(0x4006,'set_version');

use constant IMPRPC_EXCEPTION     => dualvar(0x4101,'exception');
use constant IMPRPC_INTERFACE     => dualvar(0x4102,'interface');
use constant IMPRPC_RESULT        => dualvar(0x4103,'result');

sub load_implementation {
    shift;
    my $impl = shift || 'Storable';
    $impl = "Net::IMP::Remote::$impl";
    $impl =~m{^[\w:]+$} and eval "require $impl" 
	or croak("bad wire implementation $impl: $@");
    return $impl;
}



__END__

=head1 NAME

Net::IMP::Remote::Protocol - protocol description for IMP RPC

=head1 DESCRIPTION

=head2 Basic Ideas

=over 4

=item *

There is a single connection between data provider and IMP RPC server per
factory, e.g. no separate connections per analyzer. This enables fast
creation and teardown of analyzers.

=item *

Most messages are asynchronous, e.g. expect no reply, so that the analyzer can
continue even if the messages are not fully send yet.
Only C<get_interface> is synchronous.

=back

=head2 Messages from Data Provider to IMP RPC Server

=over 4

=item set_version(version)

This exchanges the version of the protocol spoken.
It is the first operation of IMP RPC server after a new client connected.
The client will verify the version and close if it cannot speak it.

=item get_interface( list<data_type, list<result_type>> provider_ifs )

This sends the interface supported by the data provider and returns the
matching interfaces from the IMP plugins inside the IMP RPC server.
It's the only synchronous operation, expecting a C<interface> message back.
It will be called after establishing the connection, before any analyzers are
created.

=item set_interface( <data_type, list<result_type>> provider_if )

This will be called by the data provider to fix the interface to the given one.
If this given interface is not supported an exception will be generated
asynchronously. But this should usually not happen, because the supported
interfaces were queried before with C<get_interface>.
This function should be called after C<get_interface> and before creating
analyzers.

=item new_analyzer( analyzer_id, hash context )

This will create a new analyzer. 
The uniq integer C<analyzer_id> will be created by the data provider, so that
the operation can be done asynchronously. The C<analyzer_Id> will be used in
subsequent C<data>, C<result> or C<exception> calls in the context of the new
analyzer. The C<analyzer_id> should not be 0.
The context is expected as a hash with string keys and string values.

If the IMP plugin is not interested in analyzing data inside the given
C<context> it can simply send IMP_PASS for both directions with offset
set to IMP_MAX_OFFSET.

=item delete_analyzer( analyzer_id )

This will cause the deletion of the analyzer with the given C<analyzer_id>.

=item data( analyzer_id, dir, offset, data_type_id, char data[] )

This will send data from the data provider into the IMP plugin.
For the meaning of the parameters see L<Net::IMP> interface.

=back

=head2 Messages back from IMP RPC Server

=over 4

=item exception(analyzer_id, char msg[])

This notifies the data provider about problems with the given analyzer, which
will usually result in closing the analyzer.
If C<analyzer_id> is 0 it will be interpreted as an exception for the whole
factory and the factory including all analyzers should better shut down.

=item interface( list<data_type, list<result_type>> analyzer_ifs 

This is the reply message to a C<get_interface> message from the data provider.

=item result( analyzer_id, result_type, ... )

This will return the result for processing data.
The arguments following the C<result_type> are specific to the type, e.g.

=over 8

=over 4 IMP_PASS|IMP_PREPASS: dir,offset

=over 4 IMP_REPLACE: dir,offset, char newdata[]

=over 4 IMP_DENY: dir, char reason[], char key1[], char value1[], ....

=over 4 IMP_DROP: no more arguments

=over 4 IMP_FATAL: char reason[]

=over 4 IMP_TOSENDER: dir, char data[]

=over 4 IMP_PAUSE: dir

=over 4 IMP_CONTINUE: dir

=over 4 IMP_REPLACE_LATER: dir,offset,endoffset

=over 4 IMP_LOG: dir,offset,len,level,char msg[], char key1[], char value1[], ....

=over 4 IMP_ACCTFIELD: string key, char value[]
    
=back    

=back
