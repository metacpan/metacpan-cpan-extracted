package Net::Radius::PacketOrdered;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $VSA);
@ISA       = qw(Exporter);
@EXPORT    = qw(auth_resp acct_request_auth acct_response_auth);
@EXPORT_OK = qw( );

$VERSION = '1.53';

$VSA = 26;			# Type assigned in RFC2138 to the
				# Vendor-Specific Attributes

# Be shure our dictionaries are current
use Net::Radius::Dictionary 1.1;
use Carp;
use Socket;
use Digest::MD5;

=head1 NAME

Net::Radius::PacketOrdered - interface to RADIUS packets with proxy states

=head1 SYNOPSIS

  use Net::Radius::PacketOrdered;
  use Net::Radius::Dictionary;

  my $d = new Net::Radius::Dictionary "/etc/radius/dictionary";

  my $p = new Net::Radius::PacketOrdered $d, $data;
  $p->dump;

  if ($p->attr('User-Name' eq "lwall") {
    my $resp = new Net::Radius::PacketOrdered $d;
    $resp->set_code('Access-Accept');
    $resp->set_identifier($p->identifier);
    $resp->set_authenticator($p->authenticator);
    $resp->set_attr('Reply-Message' => "Welcome, Larry!\r\n");
    my $respdat = auth_resp($resp->pack, "mysecret");
    ...

=head1 DESCRIPTION

RADIUS (RFC2865) specifies a binary packet format which contains
various values and attributes.  Net::Radius::PacketOrdered provides an
interface to turn RADIUS packets into Perl data structures and
vice-versa.

Net::Radius::PacketOrdered does not provide functions for obtaining
RADIUS packets from the network.  A simple network RADIUS server is
provided as an example at the end of this document.

=head2 Proxy-State, RFC specification

from RFC 2865 - ftp://ftp.rfc-editor.org/in-notes/rfc2865.txt

2. Operation

If any Proxy-State attributes were present in the Access-Request,
they MUST be copied unmodified and in order into the response packet.
Other Attributes can be placed before, after, or even between the
Proxy-State attributes.

2.3 Proxy

The forwarding server MUST treat any Proxy-State attributes already
in the packet as opaque data.  Its operation MUST NOT depend on the
content of Proxy-State attributes added by previous servers.

If there are any Proxy-State attributes in the request received from
the client, the forwarding server MUST include those Proxy-State
attributes in its reply to the client.  The forwarding server MAY
include the Proxy-State attributes in the access-request when it
forwards the request, or MAY omit them in the forwarded request.  If
the forwarding server omits the Proxy-State attributes in the
forwarded access-request, it MUST attach them to the response before
sending it to the client.

=head2 Proxy-State, Implementation

Proxy-State attributes are stored in an array, and when copied from
one Net::Radius::PacketOrdered to another - using method I<new> with
packet data as attribute - they retain their order.

I<attr> method always returns last attribute inserted.

I<set_attr> method pushed name attribute onto the Attributes stack, or
overwrites it in specific circumnstances, as described in method
documentation.

=head2 PACKAGE METHODS

=over 4

=item I<new> Net::Radius::PacketOrdered $dictionary, $data

Returns a new Net::Radius::PacketOrdered object.  $dictionary is an
optional reference to a Net::Radius::Dictionary object.  If not
supplied, you must call B<set_dict>.  If $data is supplied, B<unpack>
will be called for you to initialize the object.

=back

=cut

my (%unkvprinted,%unkgprinted);
sub new {
  my ($class, $dict, $data) = @_;
  my $self = { unknown_entries => 1 };
  bless $self, $class;
  $self->set_dict($dict) if defined($dict);
  $self->unpack($data) if defined($data);
  return $self;
}

=head2 OBJECT METHODS

There are actually two families of object methods. The ones described
below deal with standard RADIUS attributes. An additional set of methods
handle the Vendor-Specific attributes as defined in the RADIUS protocol.
Those methods behave in much the same way as the ones below with the
exception that the prefix I<vs> must be applied before the I<attr> in most
of the names. The vendor code must also be included as the first parameter
of the call.

The I<vsattr> and I<set_vsattr> methods, used to query and set
Vendor-Specific attributes return an array reference with the values
of each instance of the particular attribute in the packet. This
difference is required to support multiple VSAs with different
parameters in the same packet.

=over 4

=item -E<gt>I<set_dict>($dictionary)

Net::Radius::PacketOrdered needs access to a Net::Radius::Dictionary object to do
packing and unpacking.  set_dict must be called with an appropriate
dictionary reference (see L<Net::Radius::Dictionary>) before you can
use ->B<pack> or ->B<unpack>.

=cut

sub set_dict {
  my ($self, $dict) = @_;
  $self->{Dict} = $dict;
}

=item -E<gt>I<code>

Returns the Code field as a string.  As of this writing, the following
codes are defined:

        Access-Request          Access-Accept
        Access-Reject           Accounting-Request
        Accounting-Response     Access-Challenge
        Status-Server           Status-Client

=item -><set_code>($code)

Sets the Code field to the string supplied.

=item -E<gt>I<identifier>

Returns the one-byte Identifier used to match requests with responses,
as a character value.

=item -E<gt>I<set_identifier>

Sets the Identifier byte to the character supplied.

=item -E<gt>I<authenticator>

Returns the 16-byte Authenticator field as a character string.

=item -E<gt>I<set_authenticator>

Sets the Authenticator field to the character string supplied.

=cut

# Functions for accessing data structures
sub code          { $_[0]->{Code};          }
sub identifier    { $_[0]->{Identifier};    }
sub authenticator { $_[0]->{Authenticator}; }

sub set_code          { $_[0]->{Code} = $_[1];          }
sub set_identifier    { $_[0]->{Identifier} = $_[1];    }
sub set_authenticator { $_[0]->{Authenticator} = $_[1]; }

=item -E<gt>I<set_attr>($name, $val, $rewrite_flag)

Sets the named Attributes to the given value. Values should be
supplied as they would be returned from the B<attr> method. If
rewrite_flag is set, and a single attribute with such name already
exists on the Attributes stack, its value will be overwriten with the
supplied one. In all other cases (if there are more than one
attributes with such name already on the stack, there are no
attributes with such name, rewrite_flag is omitted) name/pair array
will be pushed onto the stack.

=cut

sub set_attr {
    my ($self, $name, $value, $rewrite_flag ) = @_;
    my ( $push, $pos );

    $push = 1 unless $rewrite_flag;

    if ($rewrite_flag) {
        my $found = 0;
        my @attr = $self->_attributes;

        for (my $i = 0; $i <= $#attr; $i++ ) {
            if ($attr[$i][0] eq $name) {
                $found++;
                $pos = $i;
            }
        }

        if ($found > 1) {
            $push = 1;
        } elsif ($found) {
            $attr[$pos][0] = $name;
            $attr[$pos][1] = $value;
            $self->_set_attributes( \@attr );
            return;
        } else {
            $push = 1;
        }
    }

    $self->_push_attr( $name, $value ) if $push;

}

=item -E<gt>I<attributes>

Retrieves a list of attribute names present within the packet.

=cut

sub attributes {
    my ($self) = @_;

    my @attr = $self->_attributes;
    my @attriblist = ();
    for (my $i = $#attr; $i >= 0; $i-- ) {
        push @attriblist, $attr[$i][0];
    }
    return @attriblist;
}

=item -E<gt>I<attr>($name)

Retrieves the value of the named Attribute. If there are multiple
values for the Attribute, last one inserted will be returned. This is
behaviour is crucial for correct implementation of Proxy-State.

=cut

sub attr       {
    my ($self, $name ) = @_;

    my @attr = $self->_attributes;

    for (my $i = $#attr; $i >= 0; $i-- ) {
        return $attr[$i][1] if $attr[$i][0] eq $name;
    }
    return;
}

=item -E<gt>I<unset_attr>($name,$value)

Removes given Attribute with given value from the Attributes stack.

=cut

sub unset_attr {
    my ($self, $name, $value ) = @_;

    my $found;
    my @attr = $self->_attributes;

    for (my $i = 0; $i <= $#attr; $i++ ) {
        if ( $name eq $attr[$i][0] && $value eq pclean(pdef($attr[$i][1]))) {
            $found = 1;
	    if ( $#attr == 0 ) {
		# no more attributes left on the stack
		$self->_set_attributes( [ ] );
	    } else {
		splice @attr, $i, 1;
		$self->_set_attributes( \@attr );
	    }
            return 1;
        }
    }

    return 0;
}

=item -E<gt>I<attr_slot>($integer)

Retrieves the attribute value of the given slot number from the
Attributes stack.

=cut

sub attr_slot       { ($_[0]->_attributes)[ $_[1] ]->[1];      }


=item -E<gt>I<unset_attr_slot>($integer)

Removes given stack position from the Attributes stack.

=cut

sub unset_attr_slot {
    my ($self, $position ) = @_;

    my @attr = $self->_attributes;

    if ( not $position > $#attr ) {
        splice @attr, $position, 1;
        $self->_set_attributes( \@attr );
        return 1;
    } else {
        return;
    }

}

=item -E<gt>I<password>($secret)

The RADIUS User-Password attribute is encoded with a shared secret.
Use this method to return the decoded version. This also works when
the attribute name is 'Password' for compatibility reasons.

=item -E<gt>I<set_password>($passwd, $secret)

The RADIUS User-Password attribute is encoded with a shared secret.
Use this method to prepare the encoded version. Note that this method
always stores the encrypted password in the 'User-Password'
attribute. Some servers have been reported on insisting on this
attribute to be 'Password' instead.

=item -E<gt>I<show_unknown_entries($bool)>

Controls the generation of a C<warn()> whenever an unknown tuple is seen.

=cut

sub vendors      { keys %{$_[0]->{VSAttributes}};                          }
sub vsattributes { keys %{$_[0]->{VSAttributes}->{$_[1]}};                 }
sub vsattr       { $_[0]->{VSAttributes}->{$_[1]}->{$_[2]};                }
sub set_vsattr   { push @{$_[0]->{VSAttributes}->{$_[1]}->{$_[2]}}, $_[3]; }

sub show_unknown_entries { $_[0]->{unknown_entries} = $_[1]; }

# Decode the password
sub password {
  my ($self, $secret) = @_;
  my $lastround = $self->authenticator;
  my $pwdin = $self->attr("User-Password") || $self->attr("Password");
  my $pwdout = ""; # avoid possible undef warning
  for (my $i = 0; $i < length($pwdin); $i += 16) {
    $pwdout .= substr($pwdin, $i, 16) ^ Digest::MD5::md5($secret . $lastround);
    $lastround = substr($pwdin, $i, 16);
  }
  $pwdout =~ s/\000*$// if $pwdout;
    substr($pwdout,length($pwdin)) = "" 
	unless length($pwdout) <= length($pwdin);
  return $pwdout;
}

# Encode the password
sub set_password {
  my ($self, $pwdin, $secret) = @_;
  my $lastround = $self->authenticator;
  my $pwdout = ""; # avoid possible undef warning
  $pwdin .= "\000" x (15-(15 + length $pwdin)%16);     # pad to 16n bytes

  for (my $i = 0; $i < length($pwdin); $i += 16) {
    $lastround = substr($pwdin, $i, 16) 
      ^ Digest::MD5::md5($secret . $lastround);
    $pwdout .= $lastround;
  }
  $self->set_attr("User-Password", $pwdout, 1);
}

=item -E<gt>I<acct_request_auth>($packet, $secret)

Set request authenticator in binary packet, for accounting request
authentication.

=cut

sub acct_request_auth {
    my $new = $_[0];
    substr($new, 4, 16) = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";
    substr($new, 4, 16) = Digest::MD5::md5($new . $_[1]);
    return $new;
}

=item -E<gt>I<acct_response_auth>($packet, $secret, request-auth)

Set reponse authenticator in binary packet, for accounting response
authentication.

=cut

sub acct_response_auth {
    my $new = $_[0];
    substr($new, 4, 16) = $_[2];
    substr($new, 4, 16) = Digest::MD5::md5($new . $_[1]);
    return $new;
}

# Set response authenticator in binary packet
sub auth_resp {
  my $new = $_[0];
  substr($new, 4, 16) = Digest::MD5::md5($_[0] . $_[1]);
  return $new;
}

# Utility functions for printing/debugging
sub pdef { defined $_[0] ? $_[0] : "UNDEF"; }
sub pclean {
  my $str = $_[0];
  $str =~ s/([\000-\037\177-\377])/<${\ord($1)}>/g;
  return $str;
}

=item -E<gt>I<dump>

Prints the content of the packet to STDOUT.

=cut

sub dump {
    print _str_dump(@_);
}

=item -E<gt>I<pack>

Returns a raw RADIUS packet suitable for sending to a RADIUS client
or server.

=cut

sub pack {
  my $self = shift;
  my $hdrlen = 1 + 1 + 2 + 16;    # Size of packet header
  my $p_hdr  = "C C n a16 a*";    # Pack template for header
  my $p_attr = "C C a*";          # Pack template for attribute
  my $p_vsa  = "C C N C C a*";

  # XXX - The spec says that a
  # 'Vendor-Type' must be included
  # but there are no documented definitions
  # for this! We'll simply skip this value

  my $p_vsa_3com  = "C C N N a*"; 

  my %codes  = ('Access-Request'      => 1,  'Access-Accept'      => 2,
		'Access-Reject'       => 3,  'Accounting-Request' => 4,
		'Accounting-Response' => 5,  'Access-Challenge'   => 11,
		'Status-Server'       => 12, 'Status-Client'      => 13);
  my $attstr = "";                # To hold attribute structure
  # Define a hash of subroutine references to pack the various data types
  my %packer = (
                "string" => sub {
                    return $_[0];
                },
                "integer" => sub {
                    return pack "N", $self->{Dict}->attr_has_val($_[1]) ?
                        $self->{Dict}->val_num(@_[1, 0]) : $_[0];
                },
                "ipaddr" => sub {
                    return inet_aton($_[0]);
                },
                "time" => sub {
                    return pack "N", $_[0];
                },
                "date" => sub {
                    return pack "N", $_[0];
                });

  my %vsapacker = ("string" => sub { return $_[0]; },
    	     "integer" => sub {
    		 return pack "N", 
    		 $self->{Dict}->vsattr_has_val($_[2], $_[1]) ?
    		     $self->{Dict}->vsaval_num(@_[2, 1, 0]) : $_[0];
    	     },
    	     "ipaddr" => sub {
    		 return inet_aton($_[0]);
             },
             "time" => sub {
        	 return pack "N", $_[0];
             },
             "date" => sub {
        	 return pack "N", $_[0];
             });

  # Pack the attributes
  foreach my $attr ($self->_attributes) {

      my $attr_name  = $attr->[0];
      my $attr_value = $attr->[1];

      if (! defined $self->{Dict}->attr_num($attr_name))
      {
	  carp("Unknown RADIUS tuple $attr_name\n")
	      if ($self->{unknown_entries});
	  next;
      }

      next unless ref($packer{$self->{Dict}->attr_type($attr_name)}) eq 'CODE';

      my $val = &{$packer{ $self->{Dict}->attr_type($attr_name) } }
      ($attr_value, $self->{Dict} ->attr_num($attr_name));

      $attstr .= pack $p_attr, $self->{Dict}->attr_num($attr_name),
      length($val)+2, $val;
  }

  # Pack the Vendor-Specific Attributes

  foreach my $vendor ($self->vendors) {
    foreach my $attr ($self->vsattributes($vendor)) {
      next unless ref($vsapacker{$self->{Dict}->vsattr_type($vendor, $attr)}) 
            eq 'CODE';
      foreach my $datum (@{$self->vsattr($vendor, $attr)}) {
        my $vval = &{$vsapacker{$self->{'Dict'}
        			->vsattr_type($vendor, $attr)}}
        ($datum, $self->{'Dict'}->vsattr_num($vendor, $attr), $vendor);

        if ($vendor == 429) {

      		# XXX - As pointed out by Quan Choi,
      		# we need special code to handle the
      		# 3Com case

          $attstr .= pack $p_vsa_3com, 26,
          length($vval) + 10, $vendor,
          $self->{'Dict'}->vsattr_num($vendor, $attr),
          $vval;
        } else {
          $attstr .= pack $p_vsa, 26, length($vval) + 8, $vendor,
          $self->{'Dict'}->vsattr_num($vendor, $attr),
          length($vval) + 2, $vval;
        }
      }
    }
  }

  # Prepend the header and return the complete binary packet
  return pack $p_hdr, $codes{$self->code}, $self->identifier,
  length($attstr) + $hdrlen, $self->authenticator,
  $attstr;
}

=item -E<gt>I<unpack>($data)

Given a raw RADIUS packet $data, unpacks its contents so that they
can be retrieved with the other methods (B<code>, B<attr>, etc.).

=back

=cut

sub unpack {
  my ($self, $data) = @_;
  my $dict = $self->{Dict};
  my $p_hdr  = "C C n a16 a*";    # Pack template for header
  my $p_attr = "C C a*";          # Pack template for attribute
  my %rcodes = (1  => 'Access-Request',      2  => 'Access-Accept',
		3  => 'Access-Reject',       4  => 'Accounting-Request',
		5  => 'Accounting-Response', 11 => 'Access-Challenge',
		12 => 'Status-Server',       13 => 'Status-Client');

  # Decode the header
  my ($code, $id, $len, $auth, $attrdat) = unpack $p_hdr, $data;

  # Generate a skeleton data structure to be filled in
  $self->set_code($rcodes{$code});
  $self->set_identifier($id);
  $self->set_authenticator($auth);

  # Functions for the various data types
  my %unpacker =
	(
	 "string" => sub {
	     return $_[0];
	 },
	 "integer" => sub {
	     return $dict->val_has_name($_[1]) ?
		 $dict->val_name($_[1], 
				 unpack("N", $_[0]))
		     : unpack("N", $_[0]);
	 },
	 "ipaddr" => sub {
	     return inet_ntoa($_[0]);
	 },
	 "time" => sub {
	     return unpack "N", $_[0];
	 },
	 "date" => sub {
	     return unpack "N", $_[0];
	 });

  my %vsaunpacker = 
	( "string" => sub {
	    return $_[0];
	},
	  "integer" => sub {
		  $dict->vsaval_has_name($_[2], $_[1]) 
		      ? $dict->vsaval_name($_[2], $_[1], unpack("N", $_[0]))
			  : unpack("N", $_[0]);
	  },
	  "ipaddr" => sub {
	      return inet_ntoa($_[0]);
	  },
	  "time" => sub {
	      return unpack "N", $_[0];
	  },
	  "date" => sub {
	      return unpack "N", $_[0];
	  });


  my $i = 0;
  # Unpack the attributes
  while (length($attrdat)) {
    my $length = unpack "x C", $attrdat;
    my ($type, $value) = unpack "C x a${\($length-2)}", $attrdat;
    if ($type == $VSA) {    # Vendor-Specific Attribute
      my ($vid, $vtype, $vlength) = unpack "N C C", $value;

      # XXX - How do we calculate the length
      # of the VSA? It's not defined!

      # XXX - 3COM seems to do things a bit differently.
      # The IF below takes care of that. This was contributed by
      # Ian Smith. Check the file CHANGES on this distribution for
      # more information.

      my $vvalue;
      if ($vid == 429) {
        ($vid, $vtype) = unpack "N N", $value;
        $vvalue = unpack "xxxx xxxx a${\($length-10)}", $value;
      } else {
        $vvalue = unpack "xxxx x x a${\($vlength-2)}", $value;
      }

      if ((not defined $dict->vsattr_numtype($vid, $vtype)) or 
          (ref $vsaunpacker{$dict->vsattr_numtype($vid, $vtype)} ne 'CODE')) {
        my $whicherr = (defined $dict->vsattr_numtype($vid, $vtype)) ?
            "Garbled":"Unknown";
        warn "$whicherr vendor attribute $vid/$vtype for unpack()\n"
          unless $unkvprinted{"$vid/$vtype"};
        $unkvprinted{"$vid/$vtype"} = 1;
        substr($attrdat, 0, $length) = ""; # Skip this section
        next;
      }
      my $val =
          &{$vsaunpacker{$dict->vsattr_numtype($vid, $vtype)}}($vvalue,
                                   $vtype,
                                   $vid);
      $self->set_vsattr($vid,
                $dict->vsattr_name($vid, $vtype),
                $val);
    } else {            # Normal attribute
      if ((not defined $dict->attr_numtype($type)) or
          (ref ($unpacker{$dict->attr_numtype($type)}) ne 'CODE')) {
        my $whicherr = (defined $dict->attr_numtype($type)) ?
            "Garbled":"Unknown";
        warn "$whicherr general attribute $type for unpack()\n"
          unless $unkgprinted{$type};
        $unkgprinted{$type} = 1;
        substr($attrdat, 0, $length) = ""; # Skip this section
          next;
      }
      my $val = &{$unpacker{$dict->attr_numtype($type)}}($value, $type);
      $self->set_attr($dict->attr_name($type), $val);

    }
    substr($attrdat, 0, $length) = ""; # Skip this section
  }
}

#================================================================
#               ***   PRIVATE METHODS   ***
#================================================================

# 'Attributes' is now array of arrays, so that we can have multiple
# Proxy-State values in the order in which they were added,
# as specified in RFC 2865
sub _attributes     { @{ $_[0]->{Attributes} };             }
sub _set_attributes { $_[0]->{Attributes} = $_[1];          }
sub _push_attr      { push @{ $_[0]->{Attributes} }, [ $_[1], $_[2] ]; }

sub _str_dump {
    my $self = shift;
    my $ret = '';
    my $i = 0;

    $ret .= "--- DUMP OF RADIUS PACKET ($self) ---\n";
    $ret .= "Code:       ". pdef($self->{Code}). "\n";
    $ret .= "Identifier: ". pdef($self->{Identifier}). "\n";
    $ret .= "Authentic:  ". pclean(pdef($self->{Authenticator})). "\n";
    $ret .= "Attributes stack:\n";

    foreach my $attr ( $self->_attributes ) {
        $ret .= sprintf("  %s %-20s %s\n", "[$i]", $attr->[0] . ":" ,
                        pclean( pdef($attr->[1]) )
                       );
        $i++;
    }
    foreach my $vendor ($self->vendors) {
        $ret .= "VSA for vendor $vendor\n";
        foreach my $attr ($self->vsattributes($vendor)) {
            $ret .= sprintf("    %-20s %s\n", $attr . ":" ,
                            pclean(join("|", @{$self->vsattr($vendor, $attr)})));
        }
    }
    $ret .= "--- END DUMP -------------------------\n";
    return $ret;
}

1;

__END__

=head2 EXPORTED SUBROUTINES

=over 4

=item I<auth_resp>($packed_packet, $secret)

Given a (packed) RADIUS packet and a shared secret, returns a new
packet with the Authenticator field changed in accordace with RADIUS
protocol requirements.

=back

=head1 NOTES

This document is (not yet) intended to be a complete description of
how to implement a RADIUS server.  Please see the RFCs (at
ftp://ftp.livingston.com/pub/radius/) for that.  The following is
a brief description of the procedure:

  1. Receive a RADIUS request from the network.
  2. Unpack it using this package.
  3. Examine the attributes to determine the appropriate response.
  4. Construct a response packet using this package.
     Copy the Identifier and Authenticator fields from the request,
     set the Code as appropriate, and fill in whatever Attributes
     you wish to convey in to the server.
  5. Call the pack method and use the auth_resp function to
     authenticate it with your shared secret.
  6. Send the response back over the network.
  7. Lather, rinse, repeat.

=head1 EXAMPLE

    #!/usr/local/bin/perl -w

    use Net::Radius::Dictionary;
    use Net::Radius::PacketOrdered;
    use Net::Inet;
    use Net::UDP;
    use Fcntl;
    use strict;

    # This is a VERY simple RADIUS authentication server which responds
    # to Access-Request packets with Access-Accept.  This allows anyone
    # to log in.

    my $secret = "mysecret";  # Shared secret on the term server

    # Parse the RADIUS dictionary file (must have dictionary in current dir)
    my $dict = new Net::Radius::Dictionary "dictionary"
      or die "Couldn't read dictionary: $!";

    # Set up the network socket (must have radius in /etc/services)
    my $s = new Net::UDP { thisservice => "radius" } or die $!;
    $s->bind or die "Couldn't bind: $!";
    $s->fcntl(F_SETFL, $s->fcntl(F_GETFL,0) | O_NONBLOCK)
      or die "Couldn't make socket non-blocking: $!";

    # Loop forever, recieving packets and replying to them
    while (1) {
      my ($rec, $whence);
      # Wait for a packet
      my $nfound = $s->select(1, 0, 1, undef);
      if ($nfound > 0) {
	# Get the data
	$rec = $s->recv(undef, undef, $whence);
	# Unpack it
	my $p = new Net::Radius::PacketOrdered $dict, $rec;
	if ($p->code eq 'Access-Request') {
	  # Print some details about the incoming request (try ->dump here)
	  print $p->attr('User-Name'), " logging in with password ",
		$p->password($secret), "\n";
	  # Create a response packet
	  my $rp = new Net::Radius::PacketOrdered $dict;
	  $rp->set_code('Access-Accept');
	  $rp->set_identifier($p->identifier);
	  $rp->set_authenticator($p->authenticator);
	  # (No attributes are needed.. but you could set IP addr, etc. here)
	  # Authenticate with the secret and send to the server.
	  $s->sendto(auth_resp($rp->pack, $secret), $whence);
	}
	else {
	  # It's not an Access-Request
	  print "Unexpected packet type recieved.";
	  $p->dump;
	}
      }
    }

=head1 RADIUS PROXY EXAMPLE

See README.proxy for how to setup a test consisting of radius client,
server and multiple proxies inbetween, all using this module and
FreeRadius. Scripts for all components (client/server/proxies) in the
test setup are provided in the CPAN distribution of the module.

About the stability, this code has been in very active use since early
2004 on a network with 8000+ edge devices without a single problem
encountered so far. It has been succesfully used under FreeBSD and
Linux.

=head1 AUTHOR

Christopher Masto, <chris@netmonger.net>. VSA support by Luis
E. Muñoz, <luismunoz@cpan.org>. Fix for unpacking 3COM VSAs
contributed by Ian Smith <iansmith@ncinter.net>. Information for
packing of 3Com VSAs provided by Quan Choi <Quan_Choi@3com.com>. Some
functions contributed by Tony Mountifield <tony@mountifield.org>.

Extension of Net:Radius::Packet into Net:Radius::PacketOrdered to
include the ability to implement correctly Proxy-State by Toni Prug,
<toni@irational.org>, idea by Bill Hulley.

=head1 COPYRIGHT

Original work (c) Christopher Masto. Changes (c) 2002,2003 Luis
E. Muñoz <luismunoz@cpan.org>. PacketOrdered additions/changes (c)
2004 Toni Prug. All rights reserved.

This package is free software and is provided "as is" without
expressed or implied warranty. It may be used, redistributed and/or
modified under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

Net::Radius::Dictionary Net::Radius::Packet

=cut
