=head1 NAME

Net::FCP - http://freenet.sf.net client protocol

=head1 SYNOPSIS

 use Net::FCP;

 my $fcp = new Net::FCP;

 my $ni = $fcp->txn_node_info->result;
 my $ni = $fcp->node_info;

=head1 DESCRIPTION

This module implements the first version of the freenet client protocol,
for use with freenet versions 0.5. For freenet protocol version 2.0
support (as used by freenet 0.7), see the L<AnyEvent::FCP> module.

See L<http://freenet.sourceforge.net/index.php?page=fcp> for a description
of what the messages do.

The module uses L<AnyEvent> to find a suitable Event module.

=head2 IMPORT TAGS

Nothing much can be "imported" from this module right now.

=head2 FREENET BASICS

Ok, this section will not explain any freenet basics to you, just some
problems I found that you might want to avoid:

=over 4

=item freenet URIs are _NOT_ URIs

Whenever a "uri" is required by the protocol, freenet expects a kind of
URI prefixed with the "freenet:" scheme, e.g. "freenet:CHK...". However,
these are not URIs, as freeent fails to parse them correctly, that is, you
must unescape an escaped characters ("%2c" => ",") yourself. Maybe in the
future this library will do it for you, so watch out for this incompatible
change.

=item Numbers are in HEX

Virtually every number in the FCP protocol is in hex. Be sure to use
C<hex()> on all such numbers, as the module (currently) does nothing to
convert these for you.

=back

=head2 THE Net::FCP CLASS

=over 4

=cut

package Net::FCP;

use Carp;

$VERSION = '1.2';

no warnings;

use AnyEvent;

use Net::FCP::Metadata;
use Net::FCP::Util qw(tolc touc xeh);

=item $fcp = new Net::FCP [host => $host][, port => $port][, progress => \&cb]

Create a new virtual FCP connection to the given host and port (default
127.0.0.1:8481, or the environment variables C<FREDHOST> and C<FREDPORT>).

Connections are virtual because no persistent physical connection is
established.

You can install a progress callback that is being called with the Net::FCP
object, a txn object, the type of the transaction and the attributes. Use
it like this:

   sub progress_cb {
      my ($self, $txn, $type, $attr) = @_;

      warn "progress<$txn,$type," . (join ":", %$attr) . ">\n";
   }

=cut

sub new {
   my $class = shift;
   my $self = bless { @_ }, $class;

   $self->{host} ||= $ENV{FREDHOST} || "127.0.0.1";
   $self->{port} ||= $ENV{FREDPORT} || 8481;

   $self;
}

sub progress {
   my ($self, $txn, $type, $attr) = @_;

   $self->{progress}->($self, $txn, $type, $attr)
      if $self->{progress};
}

=item $txn = $fcp->txn (type => attr => val,...)

The low-level interface to transactions. Don't use it unless you have
"special needs". Instead, use predefiend transactions like this:

The blocking case, no (visible) transactions involved:

   my $nodehello = $fcp->client_hello;

A transaction used in a blocking fashion:
   
   my $txn = $fcp->txn_client_hello;
   ...
   my $nodehello = $txn->result;

Or shorter:

   my $nodehello = $fcp->txn_client_hello->result;

Setting callbacks:

   $fcp->txn_client_hello->cb(
      sub { my $nodehello => $_[0]->result }
   );

=cut

sub txn {
   my ($self, $type, %attr) = @_;

   $type = touc $type;

   my $txn = "Net::FCP::Txn::$type"->new (fcp => $self, type => tolc $type, attr => \%attr);

   $txn;
}

{ # transactions

my $txn = sub {
   my ($name, $sub) = @_;
   *{"txn_$name"} = $sub;
   *{$name} = sub { $sub->(@_)->result };
};

=item $txn = $fcp->txn_client_hello

=item $nodehello = $fcp->client_hello

Executes a ClientHello request and returns it's results.

   {
     max_file_size => "5f5e100",
     node => "Fred,0.6,1.46,7050"
     protocol => "1.2",
   }

=cut

$txn->(client_hello => sub {
   my ($self) = @_;

   $self->txn ("client_hello");
});

=item $txn = $fcp->txn_client_info

=item $nodeinfo = $fcp->client_info

Executes a ClientInfo request and returns it's results.

   {
     active_jobs => "1f",
     allocated_memory => "bde0000",
     architecture => "i386",
     available_threads => 17,
     datastore_free => "5ce03400",
     datastore_max => "2540be400",
     datastore_used => "1f72bb000",
     estimated_load => 52,
     free_memory => "5cc0148",
     is_transient => "false",
     java_name => "Java HotSpot(_T_M) Server VM",
     java_vendor => "http://www.blackdown.org/",
     java_version => "Blackdown-1.4.1-01",
     least_recent_timestamp => "f41538b878",
     max_file_size => "5f5e100",
     most_recent_timestamp => "f77e2cc520"
     node_address => "1.2.3.4",
     node_port => 369,
     operating_system => "Linux",
     operating_system_version => "2.4.20",
     routing_time => "a5",
   }

=cut

$txn->(client_info => sub {
   my ($self) = @_;

   $self->txn ("client_info");
});

=item $txn = $fcp->txn_generate_chk ($metadata, $data[, $cipher])

=item $uri = $fcp->generate_chk ($metadata, $data[, $cipher])

Calculates a CHK, given the metadata and data. C<$cipher> is either
C<Rijndael> or C<Twofish>, with the latter being the default.

=cut

$txn->(generate_chk => sub {
   my ($self, $metadata, $data, $cipher) = @_;

   $metadata = Net::FCP::Metadata::build_metadata $metadata;

   $self->txn (generate_chk =>
               data => "$metadata$data",
               metadata_length => xeh length $metadata,
               cipher => $cipher || "Twofish");
});

=item $txn = $fcp->txn_generate_svk_pair

=item ($public, $private, $crypto) = @{ $fcp->generate_svk_pair }

Creates a new SVK pair. Returns an arrayref with the public key, the
private key and a crypto key, which is just additional entropy.

   [
     "acLx4dux9fvvABH15Gk6~d3I-yw",
     "cPoDkDMXDGSMM32plaPZDhJDxSs",
     "BH7LXCov0w51-y9i~BoB3g",
   ]

A private key (for inserting) can be constructed like this:

   SSK@<private_key>,<crypto_key>/<name>

It can be used to insert data. The corresponding public key looks like this:

   SSK@<public_key>PAgM,<crypto_key>/<name>

Watch out for the C<PAgM>-part!

=cut

$txn->(generate_svk_pair => sub {
   my ($self) = @_;

   $self->txn ("generate_svk_pair");
});

=item $txn = $fcp->txn_invert_private_key ($private)

=item $public = $fcp->invert_private_key ($private)

Inverts a private key (returns the public key). C<$private> can be either
an insert URI (must start with C<freenet:SSK@>) or a raw private key (i.e.
the private value you get back from C<generate_svk_pair>).

Returns the public key.

=cut

$txn->(invert_private_key => sub {
   my ($self, $privkey) = @_;

   $self->txn (invert_private_key => private => $privkey);
});

=item $txn = $fcp->txn_get_size ($uri)

=item $length = $fcp->get_size ($uri)

Finds and returns the size (rounded up to the nearest power of two) of the
given document.

=cut

$txn->(get_size => sub {
   my ($self, $uri) = @_;

   $self->txn (get_size => URI => $uri);
});

=item $txn = $fcp->txn_client_get ($uri [, $htl = 15 [, $removelocal = 0]])

=item ($metadata, $data) = @{ $fcp->client_get ($uri, $htl, $removelocal)

Fetches a (small, as it should fit into memory) key content block from
freenet. C<$meta> is a C<Net::FCP::Metadata> object or C<undef>).

The C<$uri> should begin with C<freenet:>, but the scheme is currently
added, if missing.

  my ($meta, $data) = @{
     $fcp->client_get (
        "freenet:CHK@hdXaxkwZ9rA8-SidT0AN-bniQlgPAwI,XdCDmBuGsd-ulqbLnZ8v~w"
     )
  };

=cut

$txn->(client_get => sub {
   my ($self, $uri, $htl, $removelocal) = @_;

   $uri =~ s/^freenet://; $uri = "freenet:$uri";

   $self->txn (client_get => URI => $uri, hops_to_live => xeh (defined $htl ? $htl : 15),
               remove_local_key => $removelocal ? "true" : "false");
});

=item $txn = $fcp->txn_client_put ($uri, $metadata, $data, $htl, $removelocal)

=item my $uri = $fcp->client_put ($uri, $metadata, $data, $htl, $removelocal);

Insert a new key. If the client is inserting a CHK, the URI may be
abbreviated as just CHK@. In this case, the node will calculate the
CHK. If the key is a private SSK key, the node will calculcate the public
key and the resulting public URI.

C<$meta> can be a hash reference (same format as returned by
C<Net::FCP::parse_metadata>) or a string.

The result is an arrayref with the keys C<uri>, C<public_key> and C<private_key>.

=cut

$txn->(client_put => sub {
   my ($self, $uri, $metadata, $data, $htl, $removelocal) = @_;

   $metadata = Net::FCP::Metadata::build_metadata $metadata;
   $uri =~ s/^freenet://; $uri = "freenet:$uri";

   $self->txn (client_put => URI => $uri,
               hops_to_live => xeh (defined $htl ? $htl : 15),
               remove_local_key => $removelocal ? "true" : "false",
               data => "$metadata$data", metadata_length => xeh length $metadata);
});

} # transactions

=back

=head2 THE Net::FCP::Txn CLASS

All requests (or transactions) are executed in a asynchronous way. For
each request, a C<Net::FCP::Txn> object is created (worse: a tcp
connection is created, too).

For each request there is actually a different subclass (and it's possible
to subclass these, although of course not documented).

The most interesting method is C<result>.

=over 4

=cut

package Net::FCP::Txn;

use Fcntl;
use Socket;

=item new arg => val,...

Creates a new C<Net::FCP::Txn> object. Not normally used.

=cut

sub new {
   my $class = shift;
   my $self = bless { @_ }, $class;

   $self->{signal} = AnyEvent->condvar;

   $self->{fcp}{txn}{$self} = $self;

   my $attr = "";
   my $data = delete $self->{attr}{data};

   while (my ($k, $v) = each %{$self->{attr}}) {
      $attr .= (Net::FCP::touc $k) . "=$v\012"
   }

   if (defined $data) {
      $attr .= sprintf "DataLength=%x\012", length $data;
      $data = "Data\012$data";
   } else {
      $data = "EndMessage\012";
   }

   socket my $fh, PF_INET, SOCK_STREAM, 0
      or Carp::croak "unable to create new tcp socket: $!";
   binmode $fh, ":raw";
   fcntl $fh, F_SETFL, O_NONBLOCK;
   connect $fh, (sockaddr_in $self->{fcp}{port}, inet_aton $self->{fcp}{host});
#      and Carp::croak "FCP::txn: unable to connect to $self->{fcp}{host}:$self->{fcp}{port}: $!\n";

   $self->{sbuf} = 
      "\x00\x00\x00\x02"
      . (Net::FCP::touc $self->{type})
      . "\012$attr$data";

   #shutdown $fh, 1; # freenet buggy?, well, it's java...
   
   $self->{fh} = $fh;
   
   $self->{w} = AnyEvent->io (fh => $fh, poll => 'w', cb => sub { $self->fh_ready_w });
   
   $self;
}

=item $txn = $txn->cb ($coderef)

Sets a callback to be called when the request is finished. The coderef
will be called with the txn as it's sole argument, so it has to call
C<result> itself.

Returns the txn object, useful for chaining.

Example:

   $fcp->txn_client_get ("freenet:CHK....")
      ->userdata ("ehrm")
      ->cb(sub {
         my $data = shift->result;
      });

=cut

sub cb($$) {
   my ($self, $cb) = @_;
   $self->{cb} = $cb;
   $self;
}

=item $txn = $txn->userdata ([$userdata])

Set user-specific data. This is useful in progress callbacks. The data can be accessed
using C<< $txn->{userdata} >>.

Returns the txn object, useful for chaining.

=cut

sub userdata($$) {
   my ($self, $data) = @_;
   $self->{userdata} = $data;
   $self;
}

=item $txn->cancel (%attr)

Cancels the operation with a C<cancel> exception and the given attributes
(consider at least giving the attribute C<reason>).

UNTESTED.

=cut

sub cancel {
   my ($self, %attr) = @_;
   $self->throw (Net::FCP::Exception->new (cancel => { %attr }));
   $self->set_result;
   $self->eof;
}

sub fh_ready_w {
   my ($self) = @_;

   my $len = syswrite $self->{fh}, $self->{sbuf};

   if ($len > 0) {
      substr $self->{sbuf}, 0, $len, "";
      unless (length $self->{sbuf}) {
         fcntl $self->{fh}, F_SETFL, 0;
         $self->{w} = AnyEvent->io (fh => $self->{fh}, poll => 'r', cb => sub { $self->fh_ready_r });
      }
   } elsif (defined $len) {
      $self->throw (Net::FCP::Exception->new (network_error => { reason => "unexpected end of file while writing" }));
   } else {
      $self->throw (Net::FCP::Exception->new (network_error => { reason => "$!" }));
   }
}

sub fh_ready_r {
   my ($self) = @_;

   if (sysread $self->{fh}, $self->{buf}, 16384 + 1024, length $self->{buf}) {
      for (;;) {
         if ($self->{datalen}) {
            #warn "expecting new datachunk $self->{datalen}, got ".(length $self->{buf})."\n";#d#
            if (length $self->{buf} >= $self->{datalen}) {
               $self->rcv_data (substr $self->{buf}, 0, delete $self->{datalen}, "");
            } else {
               last;
            }
         } elsif ($self->{buf} =~ s/^DataChunk\015?\012Length=([0-9a-fA-F]+)\015?\012Data\015?\012//) {
            $self->{datalen} = hex $1;
            #warn "expecting new datachunk $self->{datalen}\n";#d#
         } elsif ($self->{buf} =~ s/^([a-zA-Z]+)\015?\012(?:(.+?)\015?\012)?EndMessage\015?\012//s) {
            $self->rcv ($1, {
                  map { my ($a, $b) = split /=/, $_, 2; ((Net::FCP::tolc $a), $b) }
                      split /\015?\012/, $2
            });
         } else {
            last;
         }
      }
   } else {
      $self->eof;
   }
}

sub rcv {
   my ($self, $type, $attr) = @_;

   $type = Net::FCP::tolc $type;

   #use PApp::Util; warn PApp::Util::dumpval [$type, $attr];

   if (my $method = $self->can("rcv_$type")) {
      $method->($self, $attr, $type);
   } else {
      warn "received unexpected reply type '$type' for '$self->{type}', ignoring\n";
   }
}

# used as a default exception thrower
sub rcv_throw_exception {
   my ($self, $attr, $type) = @_;
   $self->throw (Net::FCP::Exception->new ($type, $attr));
}

*rcv_failed       = \&Net::FCP::Txn::rcv_throw_exception;
*rcv_format_error = \&Net::FCP::Txn::rcv_throw_exception;

sub throw {
   my ($self, $exc) = @_;

   $self->{exception} = $exc;
   $self->set_result;
   $self->eof; # must be last to avoid loops
}

sub set_result {
   my ($self, $result) = @_;

   unless (exists $self->{result}) {
      $self->{result} = $result;
      $self->{cb}->($self) if exists $self->{cb};
      $self->{signal}->broadcast;
   }
}

sub eof {
   my ($self) = @_;

   delete $self->{w};
   delete $self->{fh};

   delete $self->{fcp}{txn}{$self};

   unless (exists $self->{result}) {
      $self->throw (Net::FCP::Exception->new (short_data => {
         reason   => "unexpected eof or internal node error",
      }));
   }
}

sub progress {
   my ($self, $type, $attr) = @_;

   $self->{fcp}->progress ($self, $type, $attr);
}

=item $result = $txn->result

Waits until a result is available and then returns it.

This waiting is (depending on your event model) not very efficient, as it
is done outside the "mainloop". The biggest problem, however, is that it's
blocking one thread of execution. Try to use the callback mechanism, if
possible, and call result from within the callback (or after is has been
run), as then no waiting is necessary.

=cut

sub result {
   my ($self) = @_;

   $self->{signal}->wait while !exists $self->{result};

   die $self->{exception} if $self->{exception};

   return $self->{result};
}

package Net::FCP::Txn::ClientHello;

use base Net::FCP::Txn;

sub rcv_node_hello {
   my ($self, $attr) = @_;

   $self->set_result ($attr);
}

package Net::FCP::Txn::ClientInfo;

use base Net::FCP::Txn;

sub rcv_node_info {
   my ($self, $attr) = @_;

   $self->set_result ($attr);
}

package Net::FCP::Txn::GenerateCHK;

use base Net::FCP::Txn;

sub rcv_success {
   my ($self, $attr) = @_;

   $self->set_result ($attr->{uri});
}

package Net::FCP::Txn::GenerateSVKPair;

use base Net::FCP::Txn;

sub rcv_success {
   my ($self, $attr) = @_;
   $self->set_result ([$attr->{public_key}, $attr->{private_key}, $attr->{crypto_key}]);
}

package Net::FCP::Txn::InvertPrivateKey;

use base Net::FCP::Txn;

sub rcv_success {
   my ($self, $attr) = @_;
   $self->set_result ($attr->{public_key});
}

package Net::FCP::Txn::GetSize;

use base Net::FCP::Txn;

sub rcv_success {
   my ($self, $attr) = @_;
   $self->set_result (hex $attr->{length});
}

package Net::FCP::Txn::GetPut;

# base class for get and put

use base Net::FCP::Txn;

*rcv_uri_error       = \&Net::FCP::Txn::rcv_throw_exception;
*rcv_route_not_found = \&Net::FCP::Txn::rcv_throw_exception;

sub rcv_restarted {
   my ($self, $attr, $type) = @_;

   delete $self->{datalength};
   delete $self->{metalength};
   delete $self->{data};

   $self->progress ($type, $attr);
}

package Net::FCP::Txn::ClientGet;

use base Net::FCP::Txn::GetPut;

*rcv_data_not_found = \&Net::FCP::Txn::rcv_throw_exception;

sub rcv_data {
   my ($self, $chunk) = @_;

   $self->{data} .= $chunk;

   $self->progress ("data", { chunk => length $chunk, received => length $self->{data}, total => $self->{datalength} });

   if ($self->{datalength} == length $self->{data}) {
      my $data = delete $self->{data};
      my $meta = new Net::FCP::Metadata (substr $data, 0, $self->{metalength}, "");

      $self->set_result ([$meta, $data]);
      $self->eof;
   }
}

sub rcv_data_found {
   my ($self, $attr, $type) = @_;

   $self->progress ($type, $attr);

   $self->{datalength} = hex $attr->{data_length};
   $self->{metalength} = hex $attr->{metadata_length};
}

package Net::FCP::Txn::ClientPut;

use base Net::FCP::Txn::GetPut;

*rcv_size_error    = \&Net::FCP::Txn::rcv_throw_exception;

sub rcv_pending {
   my ($self, $attr, $type) = @_;
   $self->progress ($type, $attr);
}

sub rcv_success {
   my ($self, $attr, $type) = @_;
   $self->set_result ($attr);
}

sub rcv_key_collision {
   my ($self, $attr, $type) = @_;
   $self->set_result ({ key_collision => 1, %$attr });
}

=back

=head2 The Net::FCP::Exception CLASS

Any unexpected (non-standard) responses that make it impossible to return
the advertised result will result in an exception being thrown when the
C<result> method is called.

These exceptions are represented by objects of this class.

=over 4

=cut

package Net::FCP::Exception;

use overload
   '""' => sub {
      "Net::FCP::Exception<<$_[0][0]," . (join ":", %{$_[0][1]}) . ">>";
   };

=item $exc = new Net::FCP::Exception $type, \%attr

Create a new exception object of the given type (a string like
C<route_not_found>), and a hashref containing additional attributes
(usually the attributes of the message causing the exception).

=cut

sub new {
   my ($class, $type, $attr) = @_;

   bless [Net::FCP::tolc $type, { %$attr }], $class;
}

=item $exc->type([$type])

With no arguments, returns the exception type. Otherwise a boolean
indicating wether the exception is of the given type is returned.

=cut

sub type {
   my ($self, $type) = @_;

   @_ >= 2
      ? $self->[0] eq $type
      : $self->[0];
}

=item $exc->attr([$attr])

With no arguments, returns the attributes. Otherwise the named attribute
value is returned.

=cut

sub attr {
   my ($self, $attr) = @_;

   @_ >= 2
      ? $self->[1]{$attr}
      : $self->[1];
}

=back

=head1 SEE ALSO

L<http://freenet.sf.net>.

=head1 BUGS

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

