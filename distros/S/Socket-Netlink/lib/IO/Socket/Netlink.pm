#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2016 -- leonerd@leonerd.org.uk

package IO::Socket::Netlink;

use strict;
use warnings;
use base qw( IO::Socket );

our $VERSION = '0.05';

use Carp;

use Socket qw( SOCK_RAW );

use Socket::Netlink qw(
   PF_NETLINK AF_NETLINK
   NLMSG_NOOP NLMSG_DONE NLMSG_ERROR
   NLM_F_REQUEST NLM_F_MULTI
   pack_sockaddr_nl unpack_sockaddr_nl
);

__PACKAGE__->register_domain( AF_NETLINK );

=head1 NAME

C<IO::Socket::Netlink> - Object interface to C<PF_NETLINK> domain sockets

=head1 SYNOPSIS

 use Socket::Netlink;
 use IO::Socket::Netlink;
 
 my $sock = IO::Socket::Netlink->new( Protocol => 0 ) or die "socket: $!";
 
 $sock->send_nlmsg( $sock->new_request(
    nlmsg_type  => 18,
    nlmsg_flags => NLM_F_DUMP,
    nlmsg       => "\0\0\0\0\0\0\0\0", 
 ) ) or die "send: $!";
 
 $sock->recv_nlmsg( my $message, 65536 ) or die "recv: $!";
 
 printf "Received type=%d flags=%x:\n%v02x\n",
    $message->nlmsg_type, $message->nlmsg_flags, $message->nlmsg;

=head1 DESCRIPTION

This module provides an object interface to C<PF_NETLINK> sockets on Linux, by
building on top of the L<IO::Socket> class. While useful on its own, it is
intended itself to serve as a base class, for particular netlink protocols to
extend.

=cut

=head1 CLASS METHODS

=head2 register_protocol

   $class->register_protocol( $proto )

May be called by a subclass implementing a Netlink protocol. If so, then any
object constructed using a known protocol on this base class will be
automatically reblessed into the appropriate package.

=cut

my %protocol2pkg;

sub register_protocol
{
   my ( $pkg, $proto ) = @_;
   $protocol2pkg{$proto} = $pkg;
}

=head1 CONSTRUCTOR

=cut

=head2 new

   $sock = IO::Socket::Netlink->new( %args )

Creates a new C<IO::Socket::Netlink> object.

The recognised arguments are:

=over 8

=item Protocol => INT

The netlink protocol. This is a required argument.

=item Pid => INT

Socket identifier (usually the process identifier)

=item Groups => INT

32bit bitmask of multicast groups to join

=back

=cut

sub new
{
   my $class = shift;
   $class->SUPER::new( Domain => PF_NETLINK, @_ );
}

sub configure
{
   my $self = shift;
   my ( $arg ) = @_;

   my $type = $arg->{Type} || SOCK_RAW;

   if( !exists $arg->{Protocol} ) {
      croak "Require a Protocol for a Netlink socket";
   }

   $self->socket( AF_NETLINK, $type, $arg->{Protocol} ) or return undef;

   $self->bind( pack_sockaddr_nl( $arg->{Pid} || 0, $arg->{Groups} || 0 ) ) or return undef;

   if( ref($self) eq __PACKAGE__ ) {
      my $class = $protocol2pkg{$arg->{Protocol}} or return $self;
      bless $self, $class;

      return $self->configure( $arg );
   }
   else {
      return $self;
   }
}

=head1 METHODS

=cut

=head2 sockpid

   $pid = $sock->sockpid

Returns the socket identifier

=cut

sub sockpid
{
   my $self = shift;
   ( unpack_sockaddr_nl( $self->sockname ) )[0];
}

=head2 sockgroups

   $groups = $sock->sockgroups

Returns the 32bit bitmask of multicast groups

=cut

sub sockgroups
{
   my $self = shift;
   ( unpack_sockaddr_nl( $self->sockname ) )[1];
}

# It is intended subclasses override this
sub message_class
{
   return "IO::Socket::Netlink::_Message";
}

# And possibly this
sub command_class
{
   return shift->message_class;
}

=head2 new_message

   $msg = $sock->new_message( %args )

Returns a new message object containing the given arguments. The named
arguments are in fact read as an list of key/value pairs, not a hash, so order
is significant. The basic C<nlmsg_*> keys should come first, followed by any
required by the inner level header.

For more detail, see the L</MESSAGE OBJECTS> section below.

=cut

sub new_message
{
   my $self = shift;
   return $self->message_class->new( @_ );
}

=head2 new_request

   $msg = $sock->new_request( %args )

A convenience wrapper around C<new_message> which sets the C<NLM_F_REQUEST>
flag on the returned message.

=cut

sub new_request
{
   my $self = shift;
   my $message = $self->new_message( @_ );
   $message->nlmsg_flags( ($message->nlmsg_flags||0) | NLM_F_REQUEST );
   return $message;
}

=head2 new_command

   $sock->new_command( %args )

As C<new_request>, but may use a different class for messages. This is for
such netlink protocols as C<TASKSTATS>, which uses a different set of message
attributes for userland-to-kernel commands, as for kernel-to-userland event
messages.

=cut

sub new_command
{
   my $self = shift;
   my $message = $self->command_class->new( @_ );
   $message->nlmsg_flags( ($message->nlmsg_flags||0) | NLM_F_REQUEST );
   return $message;
}

# undoc'ed for now
sub unpack_message
{
   my $self = shift;
   return $self->message_class->unpack( @_ );
}

=head2 send_nlmsg

   $sock->send_nlmsg( $message )

Sends the given message object to the kernel. C<$message> should be a message
object, constructed using the socket's C<new_message> factory method.

=cut

sub send_nlmsg
{
   my $self = shift;
   my ( $message ) = @_;

   $self->send( $message->pack );
}

=head2 recv_nlmsg

   $sock->recv_nlmsg( $message, $maxlen )

Receives a single message from the kernel. The C<$message> parameter should be
a variable, which will contain the new message object when this method returns
successfully.

Sometimes the kernel will respond multiple messages in reply to just one. If
this may be the case, see instead C<recv_nlmsgs>.

This method returns success or failure depending only on the result of the
underlying socket C<recv> call. If a message was successfully received it
returns true, even if that message contains an error. To detect the error, see
the C<nlerr_error> accessor.

=cut

sub recv_nlmsg
{
   my $self = shift;
   my ( undef, $maxlen ) = @_;
   # Holes in @_ because we'll unpack to here

   my $ret;

   do {
      $ret = $self->recv( my $buffer, $maxlen );
      defined $ret or return undef;

      $_[0] = $self->unpack_message( $buffer );
      # Ignore NLMSG_NOOP and try again
   } while( $_[0]->nlmsg_type == NLMSG_NOOP );

   return $ret;
}

=head2 recv_nlmsgs

   $sock->recv_nlmsgs( \@messages, $maxlen )

Receives message from the kernel. If the first message received has the
C<NLM_F_MULTI> flag, then messages will be collected up until the final
C<NLMSG_DONE> which indicates the end of the list. Each message is pushed
into the C<@messages> array (which is I<not> cleared initially), excluding
the final C<NLMSG_DONE>.

This method returns success or failure depending only on the result of the
underlying socket C<recv> call or calls. If any calls fails then the method
will return false. If messages were successfully received it returns true,
even if a message contains an error. To detect the error, see the
C<nlerr_error> accessor.

=cut

sub recv_nlmsgs
{
   my $self = shift;
   my ( $msgs, $maxlen ) = @_;

   my $buffer;
   my $message;

   do {
      defined $self->recv( $buffer, $maxlen ) or return;

      $message = $self->unpack_message( $buffer );
      # Ignore NLMSG_NOOP and try again
   } while( $message->nlmsg_type == NLMSG_NOOP );

   push @$msgs, $message;
   return scalar @$msgs unless $message->nlmsg_flags & NLM_F_MULTI;

   # We may still have to make more recv calls:
   while(1) {
      while( defined $buffer ) {
         $message = $self->message_class->unpack( $buffer );

         return scalar @$msgs if $message->nlmsg_type == NLMSG_DONE;

         push @$msgs, $message if $message->nlmsg_type != NLMSG_NOOP;
      }

      defined $self->recv( $buffer, $maxlen ) or return;
   }
}

package IO::Socket::Netlink::_Message;

use Carp;

use Socket::Netlink qw(
   :DEFAULT
   pack_nlmsghdr unpack_nlmsghdr pack_nlattrs unpack_nlattrs
);

# Don't hard-depend on Sub::Name or Sub::Util since it's only a niceness for stack traces
BEGIN {
   if( eval { require Sub::Name } ) {
      *subname = \&Sub::Name::subname;
   }
   elsif( eval { require Sub::Util } ) {
      *subname = \&Sub::Util::set_subname;
   }
   else {
      # Ignore the name, return the CODEref
      *subname = sub { return $_[1] };
   }
}

=head1 MESSAGE OBJECTS

Netlink messages are passed in to C<send_nlmsg> and returned by C<recv_nlmsg>
and C<recv_nlmsgs> in the form of objects, which wrap the protocol headers.
These objects are not directly constructed; instead you should use the
C<new_message> method on the socket to build a new message to send.

These objects exist also to wrap higher-level protocol fields, for messages in
some particular netlink protocol. A subclass of C<IO::Socket::Netlink> would
likely use its own subclass of message object; extra fields may exist on these
objects.

The following accessors may be used to set or obtain the fields in the
toplevel C<nlmsghdr> structure:

=cut

sub new
{
   my $class = shift;

   my $self = bless {}, $class;

   # Important that these happen in order
   for ( my $i=0; $i<@_; $i+=2 ) {
      my $method = $_[$i];
      $self->$method( $_[$i+1] );
   }

   return $self;
}

sub pack : method
{
   my $self = shift;

   return pack_nlmsghdr(
      $self->nlmsg_type  || 0,
      $self->nlmsg_flags || 0,
      $self->nlmsg_seq   || 0,
      $self->nlmsg_pid   || 0,
      $self->nlmsg
   );
}

sub unpack : method
{
   my $class = shift;

   ( my ( $type, $flags, $seq, $pid, $body ), $_[0] ) = unpack_nlmsghdr( $_[0] );

   return $class->new(
      nlmsg_type  => $type,
      nlmsg_flags => $flags,
      nlmsg_seq   => $seq,
      nlmsg_pid   => $pid,

      nlmsg => $body,
   );
}

=over 4

=item * $message->nlmsg_type

=item * $message->nlmsg_flags

=item * $message->nlmsg_seq

=item * $message->nlmsg_pid

Set or obtain the fields in the C<nlmsghdr> structure.

=item * $message->nlmsg

Set or obtain the packed message body. This method is intended to be
overridden by specific protocol implementations, to pack or unpack their own
structure type.

=back

Many Netlink-based protocols use standard message headers with attribute
bodies. Messages may start with structure layouts containing standard fields,
optionally followed by a sequence of one or more attributes in a standard
format. Each attribute is an ID number and a value.

Because this class is intended to be subclassed by specific Netlink protocol
implementations, a number of class methods exist to declare metadata about the
protocol to assist generating the code required to support it. A message class
can declare its header format, which defines what extra accessor fields will be
created, and functions to pack and unpack the fields to or from the message
body. It can also declare its mapping of attribute names, ID numbers, and data
types. The message class will then support automatic encoding and decoding of
named attributes to or from the buffer.

=cut

sub nlmsg_type
{
   my $self = shift;
   $self->{nlmsg_type} = $_[0] if @_;
   if( @_ and $self->{nlmsg_type} == NLMSG_ERROR ) {
      bless $self, "IO::Socket::Netlink::_ErrorMessage";
   }
   $self->{nlmsg_type} || 0;
}

__PACKAGE__->is_header(
   no_data => 1,
   fields => [
      [ nlmsg_type  => "decimal", no_accessor => 1 ],
      [ nlmsg_flags => "hex" ],
      [ nlmsg_seq   => "decimal" ],
      [ nlmsg_pid   => "decimal" ],
      [ nlmsg       => "bytes" ],
   ],
);

sub nlerr_error { 0 }

=head2 $messageclass->is_header( %args )

Called by a subclass of the message class, this class method declares that
messages of this particular type contain a message header. The four required
fields of C<%args> define how this behaves:

=over 4

=item * data => STRING

Gives the name of the accessor method on its parent class which contains the
data buffer for the header. Normally this would be C<nlmsg> for direct
subclasses of the base message class, but further subclasses would need to use
the trailing data buffer accessor of their parent class.

=item * fields => ARRAY

Reference to an array of definitions for the fields, in the order returned by
the pack function or expected by the unpack function. A new accessor method
will be created for each.

Each field item should either be an ARRAY reference containing the following
structure, or a plain scalar denoting simply its name

 [ $name, $type, %opts ]

The C<$type> defines the default value of the attribute, and determines how
it will be printed by the C<STRING> method:

=over 4

=item * decimal

Default 0, printed with printf "%d"

=item * hex

Default 0, printed with printf "%x"

=item * bytes

Default "", printed with printf "%v02x"

=item * string

Default "", printed with printf "%s"

=back

The following options are recognised:

=over 8

=item default => SCALAR

A value to set for the field when the message header is packed, if no other
value has been provided.

=back

Fields defined simply by name are given the type of C<decimal> with a default
value of 0, and no other options.

=item * pack => CODE

=item * unpack => CODE

References to code that, respectively, packs a list of field values into a
packed string value, or unpacks a packed string value back out into a list of
values.

=back

When the header is declared, the base class's method named by C<data> will be
overridden by generated code. This overridden method unpacks the values of the
fields into accessors when it is set, or packs the accessors into a value when
queried.

This arrangement can be continued by further subclasses which implement
further levels of wrapping, if the pack and unpack functions implement a data
tail area; that is, the pack function takes an extra string buffer and the
unpack function returns one, for extra bytes after the header itself. The last
named field will then contain this buffer.

=cut

sub is_header
{
   my $class = shift;
   my %args = @_;

   # This function is also used internally to bootstrap the bottom layer. It
   # contains a number of undocumented features.

   my $no_data = $args{no_data};

   my $datafield = $args{data} or $no_data or croak "Expected 'data'";

   ref( my $fields = $args{fields} ) eq "ARRAY" or croak "Expected 'fields' as ARRAY ref";

   $no_data or ref( my $packfunc   = $args{pack}   ) eq "CODE" or croak "Expected 'pack' as CODE ref";
   $no_data or ref( my $unpackfunc = $args{unpack} ) eq "CODE" or croak "Expected 'unpack' as CODE ref";

   my @fieldnames;
   my @formats;

   foreach my $f ( @$fields ) {
      my ( $name, $type, %opts ) = ref $f eq "ARRAY" ? @$f
                                                     : ( $f, "decimal" );
      push @fieldnames, $name;

      my $default;
      my $format;
      if( $type eq "decimal" ) {
         $default = 0;
         $format = "%d";
      }
      elsif( $type eq "hex" ) {
         $default = 0;
         $format = "%x";
      }
      elsif( $type eq "bytes" ) {
         $default = "";
         $format = "%v02x";
      }
      elsif( $type eq "string" ) {
         $default = "";
         $format = "%s";
      }
      else {
         croak "Unrecognised field type '$type'";
      }

      $default = $opts{default} if defined $opts{default};

      no strict 'refs';

      *{"${class}::$name"} = subname $name => sub {
         my $self = shift;
         $self->{$name} = shift if @_;
         defined $self->{$name} ? $self->{$name} : $default;
      } unless $opts{no_accessor};

      push @formats, "$name=$format";
   }

   no strict 'refs';
   *{"${class}::$datafield"} = subname $datafield => sub {
      my $self = shift;
      if( @_ ) {
         my @values = $unpackfunc->( shift );
         $self->${ \$fieldnames[$_] }( $values[$_] ) for 0 .. $#fieldnames;
      }

      return $packfunc->( map { $self->${ \$fieldnames[$_] }() } 0 .. $#fieldnames );
   } unless $no_data;

   # Debugging support
   if( defined $datafield and !defined &{"${class}::${datafield}_string"} ) {
      my $formatstring = join ",", @formats;
      *{"${class}::${datafield}_string"} = subname "${datafield}_string" => sub {
         my $self = shift;
         sprintf "${datafield}={$formatstring}", map $self->$_, @fieldnames;
      };
   }
}

=head2 $messageclass->is_subclassed_by_type

Called by a subclass of the message class, this class method declares that
messages are further subclassed according to the value of their C<nlmsg_type>.
This will override the C<nlmsg_type> accessor to re-C<bless> the object into
its declared subclass according to the types declared to the generated
C<register_nlmsg_type> method.

For example

 package IO::Socket::Netlink::SomeProto::_Message;
 use base qw( IO::Socket::Netlink::_Message );

 __PACKAGE__->is_subclassed_by_type;

 package IO::Socket::Netlink::SomeProto::_InfoMessage;

 __PACKAGE__->register_nlmsg_type( 123 );

 ...

At this point, if a message is constructed with this type number, either by
code calling C<new_message>, or received from the socket, it will be
automatically reblessed to the appropriate class.

This feature is intended for use by netlink protocols where different message
types have different stucture types.

=cut

sub is_subclassed_by_type
{
   my $class = shift;

   my %type2pkg;

   no strict 'refs';

   *{"${class}::register_nlmsg_type"} = subname "register_nlmsg_type" => sub {
      my $pkg = shift;
      my ( $type ) = @_;

      $type2pkg{$type} = $pkg;
   };

   # SUPER:: happens in the context of the current package. So we need some
   # massive hackery to make this work
   my $SUPER_nlmsg_type = eval "
      package $class;
      sub { shift->SUPER::nlmsg_type( \@_ ) }
   ";

   *{"${class}::nlmsg_type"} = subname "nlmsg_type" => sub {
      my $self = shift;
      my $nlmsg_type = $SUPER_nlmsg_type->( $self, @_ );

      return $nlmsg_type unless @_;
      return unless defined $nlmsg_type;

      my $pkg = $type2pkg{$nlmsg_type} or return; # no known type
      return if ref $self eq $pkg; # already right type

      # Only rebless upwards or downwards, not sideways
      if( ref $self eq $class or $pkg eq $class ) {
         bless $self, $pkg;
      }
   };
}

=head2 $messageclass->has_nlattrs( $fieldname, %attrs )

Called by a subclass of the message class, this class method is intended to be
used by subclass authors to declare the attributes the message protocol
understands. The data declared here is used by the C<nlattrs> method.

C<$fieldname> should be the name of an existing method on the object class;
this method will be used to obtain or set the data field containing the
attributes (typically this will be the trailing message body). C<%attrs>
should be a hash, mapping symbolic names of fields into their typeid and
data format. Each entry should be of the form

 $name => [ $typeid, $datatype ]

When the C<attrs> method is packing attributes into the message body, it will
read attributes by C<$name> and encode them using the given C<$datatype> to
store in the body by C<$typeid>. When it is unpacking attributes from the
body, it will use the C<$typeid> to decode the data, and return it in a hash
key of the given C<$name>.

=cut

my %attr_bytype; # typeid => [ name,   unpacker ]
my %attr_byname; # name   => [ typeid, packer ]

sub has_nlattrs
{
   my $class = shift;
   my ( $fieldname, %attrs ) = @_;

   my $fieldfunc = $class->can( $fieldname )
      or croak "$class cannot $fieldname";

   {
      no strict 'refs';
      *{"${class}::nlattrdata"} = $fieldfunc;
   }

   foreach my $name ( keys %attrs ) {
      my ( $typeid, $datatype ) = @{ $attrs{$name} };

      my $packer = $class->can( "pack_nlattr_$datatype" ) or
         croak "$class cannot pack_nlattr_$datatype";
      my $unpacker = $class->can( "unpack_nlattr_$datatype" ) or
         croak "$class cannot unpack_nlattr_$datatype";

      $attr_bytype{$class}{$typeid} = [ $name,   $unpacker ];
      $attr_byname{$class}{$name}   = [ $typeid, $packer ];
   }
}

=pod

The following standard definitions exist for C<$datatype>:

=over 4

=cut

=item * u8

An unsigned 8-bit number

=cut

sub   pack_nlattr_u8 {   pack "C", $_[1] }
sub unpack_nlattr_u8 { unpack "C", $_[1] }

=item * u16

An unsigned 16-bit number

=cut

sub   pack_nlattr_u16 {   pack "S", $_[1] }
sub unpack_nlattr_u16 { unpack "S", $_[1] }

=item * u32

An unsigned 32-bit number

=cut

sub   pack_nlattr_u32 {   pack "L", $_[1] }
sub unpack_nlattr_u32 { unpack "L", $_[1] }

=item * u64

An unsigned 64-bit number

=cut

sub   pack_nlattr_u64   { pack "Q", $_[1] }
sub unpack_nlattr_u64 { unpack "Q", $_[1] }

=item * asciiz

A NULL-terminated string of ASCII text

=cut

sub   pack_nlattr_asciiz {   pack "Z*", $_[1] }
sub unpack_nlattr_asciiz { unpack "Z*", $_[1] }

=item * raw

No encoding or decoding will take place; the value contains the raw byte
buffer

=cut

sub   pack_nlattr_raw { $_[1] }
sub unpack_nlattr_raw { $_[1] }

=item * nested

The buffer itself contains more attributes in the same schema. These will be
taken or returned in a HASH reference.

=cut

sub   pack_nlattr_nested { $_[0]->_pack_nlattrs( $_[1] ) }
sub unpack_nlattr_nested { $_[0]->_unpack_nlattrs( $_[1] ) }

=back

A subclass can define new data types by providing methods called
C<pack_nlattr_$datatype> and C<unpack_nlattr_$datatype> which will be used to
encode or decode the attribute value into a string buffer.

=cut

=head2 $message->nlattrs( \%newattrs )

Sets the message body field by encoding the attributes given by C<%newattrs>,
keyed by name, into Netlink attribute values, by using the definitions
declared by the subclass's C<has_nlattrs> method.

=head2 \%attrs = $message->nlattrs

Returns the decoded attributes from the message body field.

=cut

sub _pack_nlattrs
{
   my $self = shift;
   my $class = ref $self;
   my ( $values ) = @_;

   my $attrmap = $attr_byname{$class} or
      croak "No attribute defintions for $class have been declared";

   my %attrs;
   foreach my $name ( keys %$values ) {
      $attrmap->{$name} or croak "Unknown netlink message attribute $name";
      my ( $typeid, $packer ) = @{ $attrmap->{$name} };
      $attrs{$typeid} = $packer->( $self, $values->{$name} );
   }

   return pack_nlattrs( %attrs );
}

sub _unpack_nlattrs
{
   my $self = shift;
   my $class = ref $self;
   my ( $data ) = @_;

   my $attrmap = $attr_bytype{$class} or
      croak "No attribute definitions for $class have been declared";

   my %attrs = unpack_nlattrs( $data );

   my %values;
   foreach my $typeid ( keys %attrs ) {
      $attrmap->{$typeid} or next;
      my ( $name, $unpacker ) = @{ $attrmap->{$typeid} };
      $values{$name} = $unpacker->( $self, $attrs{$typeid} );
   }

   return \%values;
}

sub nlattrs
{
   my $self = shift;

   if( @_ ) {
      $self->nlattrdata( $self->_pack_nlattrs( @_ ) );
   }
   else {
      return $self->_unpack_nlattrs( $self->nlattrdata );
   }
}

=head2 $value = $message->get_nlattr( $name )

Returns the decoded value of a single attribute from the message body field.
Similar to

 $value = $message->nlattrs->{$name}

except it does not incur the extra cost of decoding the other attribute values
that remain unused.

=cut

sub get_nlattr
{
   my $self = shift;
   my $class = ref $self;
   my ( $wantname ) = @_;

   my $attrmap = $attr_bytype{$class} or
      croak "No attribute definitions for $class have been declared";

   my %attrs = unpack_nlattrs( $self->nlattrdata );

   foreach my $typeid ( keys %attrs ) {
      $attrmap->{$typeid} or next;
      my ( $name, $unpacker ) = @{ $attrmap->{$typeid} };
      return $unpacker->( $self, $attrs{$typeid} ) if $name eq $wantname;
   }

   return undef;
}

=head2 $message->change_nlattrs( %newvalues )

Changes the stored values of the given attributes in the message body field.
Similar to

 $message->nlattrs( { %{ $message->nlattrs }, %newvalues } );

except it does not incur the extra cost of decoding and reencoding the
unmodified attribute values.

A value of C<undef> may be assigned to delete an attribute.

=cut

sub change_nlattrs
{
   my $self = shift;
   my $class = ref $self;
   my %newvalues = @_;

   my $attrmap = $attr_byname{$class} or
      croak "No attribute definitions for $class have been declared";

   my %attrs = unpack_nlattrs( $self->nlattrdata );

   foreach my $name ( keys %newvalues ) {
      $attrmap->{$name} or croak "Unknown netlink message attribute $name";
      my ( $typeid, $packer ) = @{ $attrmap->{$name} };
      if( defined( my $value = $newvalues{$name} ) ) {
         $attrs{$typeid} = $packer->( $self, $newvalues{$name} );
      }
      else {
         delete $attrs{$typeid};
      }
   }

   $self->nlattrdata( pack_nlattrs( %attrs ) );
}

=pod

The following accessors are provided for debugging purposes

=cut

=head2 $str = $message->nlmsg_type_string

Renders the message type into a readable string form. Subclasses may wish to
override this method to return other strings they recognise, or call to
C<SUPER> if they don't.

=cut

# Some useful debugging accessors
sub nlmsg_type_string
{
   my $self = shift;
   my $type = $self->nlmsg_type || 0;
   return $type == NLMSG_NOOP  ? "NLMSG_NOOP" :
          $type == NLMSG_DONE  ? "NLMSG_DONE" :
          $type == NLMSG_ERROR ? "NLMSG_ERROR" :
                                 "$type";
}

=head2 $str = $message->nlmsg_flags_string

Renders the flags into a readable string form. Each flag present is named,
joined by C<|> characters.

=cut

sub nlmsg_flags_string
{
   my $self = shift;
   my $flags = $self->nlmsg_flags || 0;
   my @flags;

   foreach my $f (qw(
         NLM_F_REQUEST NLM_F_MULTI NLM_F_ACK    NLM_F_ECHO
         NLM_F_ROOT    NLM_F_MATCH NLM_F_ATOMIC NLM_F_DUMP
         NLM_F_REPLACE NLM_F_EXCL  NLM_F_CREATE NLM_F_APPEND
      )) {
      my $val = __PACKAGE__->$f;
      push @flags, $f if $flags & $val;
      $flags &= ~$val;

      last unless $flags;
   }

   push @flags, sprintf "0x%x", $flags if $flags;

   return @flags ? join "|", @flags : "0";
}

=head2 $str = $message->nlmsg_string

Intended for subclasses to override, to include more of their own information
about nested headers.

=cut

sub nlmsg_string
{
   my $self = shift;
   return sprintf "nlmsg={%d bytes}", length $self->nlmsg;
}

=head2 $str = $message->STRING

=head2 $str = "$message"

Returns a human-readable string form of the message, giving details of the
values of the fields. Provided primarily for debugging purposes.

=cut

use overload '""' => "STRING";
sub STRING
{
   my $self = shift;
   return sprintf "%s(type=%s,flags=%s,seq=%d,pid=%d,%s)",
      ref $self,
      $self->nlmsg_type_string,
      $self->nlmsg_flags_string,
      $self->nlmsg_seq || 0,
      $self->nlmsg_pid || 0,
      $self->nlmsg_string;
}

package IO::Socket::Netlink::_ErrorMessage;

use base qw( IO::Socket::Netlink::_Message );
use Socket::Netlink qw(
   pack_nlmsgerr unpack_nlmsgerr
);

=head1 ERROR MESSAGE OBJECTS

If a message object has its C<nlmsg_type> field set to C<NLMSG_ERROR> then the
object will be reblessed into a subclass that encapsulates the error message.

=head2 $message->nlerr_error

Accessor for the error value from the kernel. This will be a system error
value such used by C<$!>. This accessor also exists on non-error messages, but
returns false. This makes it easy to test for an error after C<recv_nlmsg>:

 $sock->recv_nlmsg( my $message, 2**15 ) or die "Cannot recv - $!";
 ( $! = $message->nlerr_error ) and die "Received NLMSG_ERROR - $!";

=head2 $message->nlerr_msg

Accessor for the original netlink message header that invoked the error. This
value may be unpacked using C<unpack_nlmsghdr>.

=cut

__PACKAGE__->is_header(
   data   => "nlmsg",
   fields => [ 
      [ nlerr_error => "decimal" ],
      [ nlerr_msg   => "bytes" ],
   ],
   pack   => \&pack_nlmsgerr,
   unpack => \&unpack_nlmsgerr,
);

=head1 SEE ALSO

=over 4

=item *

L<Socket::Netlink> - interface to Linux's C<PF_NETLINK> socket family

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
