package Net::Radius::Dictionary;

use strict;
use warnings;
use vars qw($VERSION);

# $Id: Dictionary.pm 80 2007-04-26 20:20:02Z lem $

$VERSION = '1.55';

sub new {
  my $class = shift;
  my $self = { 
      rvsattr	=> {},
      vsattr	=> {},
      vsaval	=> {},
      rvsaval	=> {},
      attr	=> {},
      rattr	=> {},
      val	=> {},
      rval	=> {},
      vendors	=> {},
      packet    => undef,  # Fall back to default
      rpacket   => undef,  # Fall back to default
  };
  bless $self, $class;
  $self->readfile($_) for @_; # Read all given dictionaries
  return $self;
}

sub readfile {
  my ($self, $filename) = @_;

  open DICT, "<$filename";

  while (defined(my $l = <DICT>)) {
    next if $l =~ /^\#/;
    next unless my @l = split /\s+/, $l;

    if ($l[0] =~ m/^vendor$/i) 
    {
	if (defined $l[1] and defined $l[2] and $l[2] =~ /^[xo0-9]+$/)
	{
	    if (substr($l[2],0,1) eq "0") { #allow hex or octal
		my $num = lc($l[2]);
		$num =~ s/^0b//;
		$l[2] = oct($num);
	    }   
	    $self->{vendors}->{$l[1]} = $l[2];
	}
	else
	{
	    warn "Garbled VENDOR line $l\n";
	}
    }
    elsif ($l[0] =~ m/^attribute$/i) 
    {
	if (@l == 4)
	{
	    $self->{attr}->{$l[1]}  = [@l[2,3]];
	    $self->{rattr}->{$l[2]} = [@l[1,3]];
	}
	elsif (@l == 5)		# VENDORATTR
	{
	    if (substr($l[2],0,1) eq "0") { #allow hex or octal
		my $num = lc($l[2]);
		$num =~ s/^0b//;
		$l[2] = oct($num);
	    }   
	    if (exists $self->{vendors}->{$l[4]})
	    {
		$self->{vsattr}->{$self->{vendors}->{$l[4]}}->{$l[1]} 
		= [@l[2, 3]];
		$self->{rvsattr}->{$self->{vendors}->{$l[4]}}->{$l[2]} 
		= [@l[1, 3]];
	    }
	    elsif ($l[4] =~ m/^\d+$/)
	    {
		$self->{vsattr}->{$l[4]}->{$l[1]}	= [@l[2, 3]];
		$self->{rvsattr}->{$l[4]}->{$l[2]}	= [@l[1, 3]];
	    }
	    else
	    {
		warn "Warning: Unknown vendor $l[4]\n";
	    }
	}
    }
    elsif ($l[0] =~ m/^value$/i) {
      if (exists $self->{attr}->{$l[1]}) {
	  $self->{val}->{$self->{attr}->{$l[1]}->[0]}->{$l[2]}  = $l[3];
	  $self->{rval}->{$self->{attr}->{$l[1]}->[0]}->{$l[3]} = $l[2];
      }
      else {
	  for my $v (keys %{$self->{vsattr}})
	  {
	      if (defined $self->{vsattr}->{$v}->{$l[1]})
	      {
		  $self->{vsaval}->{$v}->{$self->{vsattr}->{$v}
					      ->{$l[1]}->[0]}->{$l[2]} 
		  = $l[3];
		  $self->{rvsaval}->{$v}->{$self->{vsattr}->{$v}
					   ->{$l[1]}->[0]}->{$l[3]} 
		  = $l[2];
	      }
	  }
      }
    }
    elsif ($l[0] =~ m/^vendorattr$/i) {
	if (substr($l[3],0,1) eq "0") { #allow hex or octal
          my $num = lc($l[3]);
          $num =~ s/^0b//;
          $l[3] = oct($num);
	}   
	if (exists $self->{vendors}->{$l[1]})
	{
	    $self->{vsattr}->{$self->{vendors}->{$l[1]}}->{$l[2]} 
	    = [@l[3, 4]];
	    $self->{rvsattr}->{$self->{vendors}->{$l[1]}}->{$l[3]} 
	    = [@l[2, 4]];
	}
	elsif ($l[1] =~ m/^\d+$/)
	{
	    $self->{vsattr}->{$l[1]}->{$l[2]} = [@l[3, 4]];
	    $self->{rvsattr}->{$l[1]}->{$l[3]} = [@l[2, 4]];
	}
	else
	{
	    warn "Warning: Unknown vendor $l[1]\n";
	}
    }
    elsif ($l[0] =~ m/^vendorvalue$/i) {
	if (substr($l[4],0,1) eq "0") 
	{ #allow hex or octal 
          my $num = lc($l[4]);
          $num =~ s/^0b//;
          $l[4] = oct($num);
	}
	if (exists $self->{vendors}->{$l[1]})
	{
	    $self->{vsaval}->{$self->{vendors}->{$l[1]}}
	    ->{$self->{vsattr}->{$self->{vendors}->{$l[1]}}
	       ->{$l[2]}->[0]}->{$l[3]} = $l[4];
	    $self->{rvsaval}->{$self->{vendors}->{$l[1]}}
	    ->{$self->{vsattr}->{$self->{vendors}->{$l[1]}}
	       ->{$l[2]}->[0]}->{$l[4]} = $l[3];
	}
	elsif ($l[1] =~ m/^\d+$/)
	{
	    $self->{vsaval}->{$l[1]}->{$self->{vsattr}->{$l[1]}->{$l[2]}
				       ->[0]}->{$l[3]} = $l[4];
	    $self->{rvsaval}->{$l[1]}->{$self->{vsattr}->{$l[1]}->{$l[2]}
					->[0]}->{$l[4]} = $l[3];
	}
	else {
	    warn "Warning: $filename contains vendor value for ",
	    "unknown vendor attribute - ignored ",
	    "\"$l[1]\"\n  $l";
	}
    }
    elsif (lc($l[0]) eq 'packet') {
        my ($name, $value) = @l[1,2];
        $self->{packet}{$name} = $value;
        $self->{rpacket}{$value} = $name;
    }
    else {
      warn "Warning: Weird dictionary line: $l\n";
    }
  }
  close DICT;
}

# Accessors for standard attributes

sub vendor_num	 { $_[0]->{vendors}->{$_[1]};		}
sub attr_num     { $_[0]->{attr}->{$_[1]}->[0];		}
sub attr_type    { $_[0]->{attr}->{$_[1]}->[1];		}
sub attr_name    { $_[0]->{rattr}->{$_[1]}->[0];	}
sub attr_numtype { $_[0]->{rattr}->{$_[1]}->[1];	}
sub attr_has_val { $_[0]->{val}->{$_[1]};		}
sub val_has_name { $_[0]->{rval}->{$_[1]};		}
sub val_num      { $_[0]->{val}->{$_[1]}->{$_[2]};	}
sub val_name     { $_[0]->{rval}->{$_[1]}->{$_[2]};	}
sub val_tag      { $_[0]->{val}->{$_[1]}->{$_[3]}; 	}

# Accessors for Vendor-Specific Attributes

sub vsattr_num      { $_[0]->{vsattr}->{$_[1]}->{$_[2]}->[0];		}
sub vsattr_type     { $_[0]->{vsattr}->{$_[1]}->{$_[2]}->[1];		}
sub vsattr_name     { $_[0]->{rvsattr}->{$_[1]}->{$_[2]}->[0];		}
sub vsattr_numtype  { $_[0]->{rvsattr}->{$_[1]}->{$_[2]}->[1];		}
sub vsattr_has_val  { $_[0]->{vsaval}->{$_[1]}->{$_[2]};		}
sub vsaval_has_name { $_[0]->{rvsaval}->{$_[1]}->{$_[2]};		}
sub vsaval_has_tval { $_[0]->{vsaval}->{$_[1]}->{$_[2]}->[0];		}
sub vsaval_has_tag  { $_[0]->{vsaval}->{$_[1]}->{$_[2]}->[1];		}
sub vsaval_num      { $_[0]->{vsaval}->{$_[1]}->{$_[2]}->{$_[3]};	}
sub vsaval_name     { $_[0]->{rvsaval}->{$_[1]}->{$_[2]}->{$_[3]};	}

# Accessors for packet types. Fall-back to defaults if the case.

# Defaults taken from http://www.iana.org/assignments/radius-types
# as of Oct 21, 2006
my %default_packets = (
    'Access-Request'      => 1, # [RFC2865]
    'Access-Accept'       => 2, # [RFC2865]
    'Access-Reject'       => 3, # [RFC2865]
    'Accounting-Request'  => 4, # [RFC2865]
    'Accounting-Response' => 5, # [RFC2865]
    'Accounting-Status'   => 6, # [RFC2882] (now Interim Accounting)
    'Interim-Accounting'  => 6, # see previous note
    'Password-Request'    => 7, # [RFC2882]
    'Password-Ack'        => 8, # [RFC2882]
    'Password-Reject'     => 9, # [RFC2882]
    'Accounting-Message'  => 10, # [RFC2882]
    'Access-Challenge'    => 11, # [RFC2865]
    'Status-Server'       => 12, # (experimental) [RFC2865]
    'Status-Client'       => 13, # (experimental) [RFC2865]
    'Resource-Free-Request'   => 21, # [RFC2882]
    'Resource-Free-Response'  => 22, # [RFC2882]
    'Resource-Query-Request'  => 23, # [RFC2882]
    'Resource-Query-Response' => 24, # [RFC2882]
    'Alternate-Resource-Reclaim-Request' => 25, # [RFC2882]
    'NAS-Reboot-Request'  => 26, # [RFC2882]
    'NAS-Reboot-Response' => 27, # [RFC2882]
    # 28       Reserved
    'Next-Passcode'       => 29, # [RFC2882]
    'New-Pin'             => 30, # [RFC2882]
    'Terminate-Session'   => 31, # [RFC2882]
    'Password-Expired'    => 32, # [RFC2882]
    'Event-Request'       => 33, # [RFC2882]
    'Event-Response'      => 34, # [RFC2882]
    'Disconnect-Request'  => 40, # [RFC3575]
    'Disconnect-ACK'      => 41, # [RFC3575]
    'Disconnect-NAK'      => 42, # [RFC3575]
    'CoA-Request'         => 43, # [RFC3575]
    'CoA-ACK'             => 44, # [RFC3575]
    'CoA-NAK'             => 45, # [RFC3575]
    'IP-Address-Allocate' => 50, # [RFC2882]
    'IP-Address-Release'  => 51, # [RFC2882]
    # 250-253  Experimental Use
    # 254      Reserved
    # 255      Reserved  [RFC2865]
);

# Reverse defaults. Remember that code #6 has a double mapping, force
# to Interim-Accouting
my %default_rpackets 
    = map { $default_packets{$_} => $_ } keys %default_packets;
$default_rpackets{6} = 'Interim-Accounting';

# Get full hashes
sub packet_numbers { %{ $_[0]->{packet}  || \%default_packets  }  }
sub packet_names   { %{ $_[0]->{rpacket} || \%default_rpackets }; }

# Single resolution, I'm taking care of avoiding auto-vivification
sub packet_hasname {
    my $href = $_[0]->{packet} || \%default_packets;
    my $ok = exists $href->{$_[1]};
    return $ok unless wantarray;
    # return both answer and the resolution
    return ($ok, $ok ? $href->{$_[1]} : undef);
}

sub packet_hasnum {
    my $href = $_[0]->{rpacket} || \%default_rpackets;
    my $ok = exists $href->{$_[1]};
    return $ok unless wantarray;
    # return both answer and the resolution
    return ($ok, $ok ? $href->{$_[1]} : undef);
}

# Note: crossed, as it might not be immediately evident
sub packet_num  { ($_[0]->packet_hasname($_[1]))[1]; }
sub packet_name { ($_[0]->packet_hasnum($_[1]))[1];  }

1;
__END__

=head1 NAME

Net::Radius::Dictionary - RADIUS dictionary parser

=head1 SYNOPSIS

  use Net::Radius::Dictionary;

  my $dict = new Net::Radius::Dictionary "/etc/radius/dictionary";
  $dict->readfile("/some/other/file");
  my $num = $dict->attr_num('User-Name');
  my $name = $dict->attr_name(1);
  my $vsa_num = $dict->vsattr_num(9, 'cisco-avpair');
  my $vsa_name = $dict->vsattr_name(9, 1);

=head1 DESCRIPTION

This is a simple module that reads a RADIUS dictionary file and
parses it, allowing conversion between dictionary names and numbers.
Vendor-Specific attributes are supported in a way consistent to the
standards.

A few earlier versions of this module attempted to make dictionaries
case-insensitive. This proved to be a very bad decision. From this
version on, this tendency is reverted: Dictionaries and its contents
are to be case-sensitive to prevent random, hard to debug failures in
production code.

=head2 METHODS

=over

=item B<new($dict_file, ...)>

Returns a new instance of a Net::Radius::Dictionary object. This
object will have no attributes defined, as expected.

If given an (optional) list of filenames, it calls I<readfile> for you
for all of them, in the given order.

=item B<-E<gt>readfile($dict_file)>

Parses a dictionary file and learns the mappings to use. It can be
called multiple times for the same object. The result will be that new
entries will override older ones, thus you could load a default
dictionary and then have a smaller dictionary that override specific
entries.

=item B<-E<gt>vendor_num($vendorname)>

Return the vendor number for the given vendor name.

=item B<-E<gt>attr_num($attrname)>

Returns the number of the named attribute.

=item B<-E<gt>attr_type($attrname)>

Returns the type (I<string>, I<integer>, I<ipaddr>, or I<time>) of the
named attribute.

=item B<-E<gt>attr_name($attrnum)>

Returns the name of the attribute with the given number.

=item B<-E<gt>attr_numtype($attrnum)>

Returns the type of the attribute with the given number.

=item B<-E<gt>attr_has_val($attrnum)>

Returns a true or false value, depending on whether or not the numbered
attribute has any known value constants.

=item B<-E<gt>val_has_name($attrnum)>

Alternate (bad) name for I<attr_has_val>.

=item B<-E<gt>val_num($attrnum, $valname)>

Returns the number of the named value for the attribute number supplied.

=item B<-E<gt>val_name($attrnum, $valnumber)>

Returns the name of the numbered value for the attribute number supplied.

=back

There is an equivalent family of accessor methods for Vendor-Specific
attributes and its values. Those methods are identical to their standard
attributes counterparts with two exceptions. Their names have a
I<vsa> prepended to the accessor name and the first argument to each one
is the vendor code on which they apply.

=head1 CAVEATS

This module is mostly for the internal use of Net::Radius::Packet, and
may otherwise cause insanity and/or blindness if studied.

=head1 AUTHOR

Christopher Masto <chris@netmonger.net>, 
Luis E. Muñoz <luismunoz@cpan.org> contributed the VSA code.

=head1 SEE ALSO

Net::Radius::Packet

=cut
