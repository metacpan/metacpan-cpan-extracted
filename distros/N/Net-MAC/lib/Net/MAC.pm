# Net::MAC - Perl extension for representing and manipulating MAC addresses
# Copyright (C) 2005-2008 Karl Ward <karlward@cpan.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

package Net::MAC;
BEGIN {
  $Net::MAC::VERSION = '2.103622';
}

use 5.006000;
use strict;
use Carp;
use warnings;
use overload
    '""' => sub { return $_[0]->get_mac(); },
    '==' => \&_compare_value,
    '!=' => \&_compare_value_ne,
    'eq' => \&_compare_string,
    'ne' => \&_compare_string_ne;

our $AUTOLOAD;

# Constructor.
sub new {
    my ( $class, %arg ) = @_;
    my ($self) = {};    # Anonymous hash
    bless( $self, $class );    # Now the hash is an object
    if (%arg) {
        $self->_init(%arg);
    }
    $self->_discover();
    return ($self);
}

{                              # Closure for class data and class methods

    #
    # CLASS DATA
    #
    # These are the valid private attributes of the object, with their
    # default values, if applicable.
    my %_attrs = (
        '_mac'          => undef,
        '_base'         => 16,
        '_delimiter'    => ':',
        '_bit_group'    => 48,
        '_zero_padded'  => 1,
        '_case'         => 'upper',    # FIXME: does IEEE specify upper?
        '_groups'       => undef,
        '_internal_mac' => undef,
        '_die'          => 1,          # die() on invalid MAC address format
        '_error'        => undef,
        '_verbose'      => 0
    );

    # new formats supplied by the user are stored here
    my %_user_format_for = ();

    # Preset formats we will accept for use by ->convert, via ->as_foo
    my %_format_for = (
        Cisco => {
            base => 16,
            bit_group => 16,
            delimiter => '.',
        },
        IEEE  => {
            base        => 16,
            bit_group   => 8,
            delimiter   => ':',
            zero_padded => 1,
            case        => 'upper',
        },
        Microsoft => {
            base => 16,
            bit_group => 8,
            delimiter => '-',
            case => 'upper',
        },
        Sun => {
            base        => 16,
            bit_group   => 8,
            delimiter   => ':',
            zero_padded => 0,
            case        => 'lower'
        }
    );

    #
    # CLASS METHODS
    #
    # Returns a copy of the instance.
    sub _clone {
        my ($self)  = @_;
        my ($clone) = {%$self};        # No need for deep copying here.
        bless( $clone, ref $self );
        return ($clone);
    }

    # Verify that an attribute is valid (called by the AUTOLOAD sub)
    sub _accessible {
        my ( $self, $name ) = @_;
        if ( exists $_attrs{$name} ) {

            #$self->verbose("attribute $name is valid");
            return 1;
        }
        else { return 0; }
    }

    # Initialize the object (only called by the constructor)
    sub _init {
        my ( $self, %arg ) = @_;
        if ( defined $arg{'verbose'} ) {
            $self->{'_verbose'} = $arg{'verbose'};
            delete $arg{'verbose'};
        }

        # Set the '_die' attribute to default at the first
        $self->_default('die');

        # passed a "format" as shorthand for the specific vars
        if (exists $arg{'format'}) {
            my $f;

            $f = $_format_for{$arg{'format'}}
                if exists $_format_for{$arg{'format'}};
            $f = $_user_format_for{$arg{'format'}}
                if exists $_user_format_for{$arg{'format'}};

            %arg = (%arg, %$f)
                if (defined $f and ref $f eq 'HASH');

            delete $arg{'format'};
        }

        foreach my $key ( keys %_attrs ) {
            $key =~ s/^_+//;
            if ( ( defined $arg{$key} ) && ( $self->_accessible("_$key") ) ) {
                $self->verbose("setting \"$key\" to \"$arg{$key}\"");
                $self->{"_$key"} = $arg{$key};
            }
        }
        my ($mesg) = "initialized object into class " . ref($self);
        $self->verbose($mesg);
        return (1);
    }

    # Set an attribute to its default value
    sub _default {
        my ( $self, $key ) = @_;
        if ( $self->_accessible("_$key") && $_attrs{"_$key"} ) {
            $self->verbose( "setting \"$key\" to default value \""
                    . $_attrs{"_$key"}
                    . "\"" );
            $self->{"_$key"} = $_attrs{"_$key"};
            return (1);
        }
        else {
            $self->verbose("no default value for attribute \"$key\"");
            return (0);    # FIXME: die() here?
        }
    }

    sub _format {
        my ( $self, $identifier ) = @_;

        # built-ins first
        if (exists $_format_for{$identifier}
            and ref $_format_for{$identifier} eq 'HASH') {
            return %{$_format_for{$identifier}};
        }

        # then user-supplied
        if (exists $_user_format_for{$identifier}
            and ref $_user_format_for{$identifier} eq 'HASH') {
            return %{$_user_format_for{$identifier}};
        }

        return (undef);
    }

    # program in a new custom MAC address format supplied by the user
    sub _set_format_for {
        my ($self, $identifier, $format) = @_;
        croak "missing identifier for custom format\n"
            unless defined $identifier and length $identifier;
        croak "missing HASH ref custom format\n"
            unless defined $format and ref $format eq 'HASH';

        $_user_format_for{$identifier} = $format;
    }

}    # End closure

# program in a new custom MAC address format supplied by the user
sub set_format_for { goto &_set_format_for }

# Automatic accessor methods via AUTOLOAD
# See Object Oriented Perl, 3.3, Damian Conway
sub Net::MAC::AUTOLOAD {
    no strict 'refs';
    my ( $self, $value ) = @_;
    if ( ( $AUTOLOAD =~ /.*::get(_\w+)/ ) && ( $self->_accessible($1) ) ) {

        #$self->verbose("get$1 method");
        my $attr_name = $1;
        *{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
        return ( $self->{$attr_name} );
    }
    if ( $AUTOLOAD =~ /.*::set(_\w+)/ && $self->_accessible($1) ) {
        my $attr_name = $1;
        *{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return; };
        $self->{$1} = $value;
        return;
    }
    if ( $AUTOLOAD =~ /.*::as_(\w+)/ && $_[0]->_format($1) ) {
        my $fmt = $1;
        *{$AUTOLOAD} = sub { return $_[0]->convert( $_[0]->_format($fmt) ) };
        return ( $self->convert( $_[0]->_format($fmt) ) );
    }
    croak "No such method: $AUTOLOAD";
}

# Just for kicks, report an error if we know of one.
sub DESTROY {
    my ($self) = @_;
    my $error = $self->get_error();
    if ($error) {
        $self->verbose("Net::MAC detected an error: $error");
        return (1);
    }
}

# Discover the metadata for this MAC, using hints if necessary
sub _discover {
    my ($self) = @_;
    my $mac = $self->get_mac();

    # Check for undefined MAC or invalid characters
    if ( !( defined $mac ) ) {
        $self->error(
            "discovery of MAC address metadata failed, no MAC address supplied"
        );
    }
    elsif ( !( $mac =~ /[a-fA-F0-9]/ ) ) {    # Doesn't have hex/dec numbers
        $self->error(
            "discovery of MAC address metadata failed, no meaningful characters in $mac"
        );
    }
    # XXX: this isn't a very effective check for anything
    elsif ( $mac =~ /[g-z]/i ) {
        $self->error(
            "discovery of MAC address metadata failed, invalid characters in MAC address \"$mac\""
        );
    }

    unless ( $self->get_delimiter() )   { $self->_find_delimiter(); }
    unless ( $self->get_base() )        { $self->_find_base(); }
    unless ( $self->get_bit_group() )   { $self->_find_bit_group(); }
    unless ( $self->get_zero_padded() ) { $self->_find_zero_padded(); }
    $self->_write_internal_mac();
    $self->_check_internal_mac();
    return (1);
}

# Find the delimiter for this MAC address
sub _find_delimiter {
    my ($self) = @_;
    my $mac = $self->get_mac();
    # XXX: why not just look for any non hexadec char?
    if ( $mac =~ m/([^a-zA-Z0-9]+)/ ) {    # Found a delimiter
        $self->set_delimiter($1);
        $self->verbose("setting attribute \"delimiter\" to \"$1\"");
        return (1);
    }
    else {
        $self->set_delimiter(undef);
        $self->verbose("setting attribute \"delimiter\" to undef");
        return (1);
    }
    $self->error("internal Net::MAC failure for MAC \"$mac\"");
    return (0);    # Bizarre failure if we get to this line.
}

# Find the numeric base for this MAC address
sub _find_base {
    my ($self) = @_;
    my $mac = $self->get_mac();
    # XXX this will fail for 00:00:00:00:00:00 ??
    if ( $mac =~ /[a-fA-F]/ ) {
        # It's hexadecimal
        $self->set_base(16);
        return (1);
    }
    my @groups = split( /[^a-zA-Z0-9]+/, $mac );
    my $is_decimal = 0;
    foreach my $group (@groups) {
        if ( length($group) == 3 ) {

            # It's decimal, sanity check it
            $is_decimal = 1;
            if ( $group > 255 ) {
                $self->error("invalid decimal MAC \"$mac\"");
                return (0);
            }
        }
    }
    if ($is_decimal) {
        $self->set_base(10);
        return (1);
    }

    # There are no obvious indicators, so we'll default the value
    $self->_default('base');
    return (1);
}

# Find the bit grouping for this MAC address
sub _find_bit_group {
    my ($self) = @_;
    my $mac = $self->get_mac();
    if ( $mac =~ m/([^a-zA-Z0-9]+)/ ) {    # Found a delimiter
        my $delimiter = ($1 eq ' ' ? '\s' : '\\'. $1);
        my @groups = split( /$delimiter/, $mac );
        if ( ( @groups > 3 ) && ( @groups % 2 ) ) {
            $self->error("invalid MAC address format: $mac");
        }
        elsif (@groups) {
            use integer;
            my $n    = @groups;
            my $t_bg = 48 / $n;
            if ( ( $t_bg == 8 ) || ( $t_bg == 16 ) ) {
                $self->set_bit_group($t_bg);
                $self->verbose(
                    "setting attribute \"bit_group\" to \"$t_bg\"");
                return (1);
            }
            else {
                $self->error("invalid MAC address format: $mac");
                return (0);
            }
        }
    }
    else {    # No delimiter, bit grouping is 48 bits
              # Sanity check the length of the MAC address in characters
        if ( length($mac) != 12 ) {
            $self->error(
                "invalid MAC format, not 12 characters in hexadecimal MAC \"$mac\""
            );
            return (0);
        }
        else {
            $self->_default('bit_group');
            return (1);
        }
    }

    # If we get here the MAC is invalid or there's a bug in Net::MAC
    $self->error("invalid MAC address format \"$mac\"");
}

# FIXME: untested
# Find whether this MAC address has zero-padded bit groups
sub _find_zero_padded {
    my ($self) = @_;

    # Zero-padding is only allowed for 8 bit grouping
    unless ( $self->get_bit_group() && ( $self->get_bit_group() == 8 ) ) {
        return (0);    # False
    }
    my $delimiter = $self->get_delimiter();
    if ( $delimiter eq ' ' ) { $delimiter = '\s'; }
    my @groups = split( /\Q$delimiter\E/, $self->get_mac() );
    foreach my $group (@groups) {
        if ( $group =~ /^0./ ) {
            $self->set_zero_padded(1);
            return (1);    # True, zero-padded group.
        }
    }
    $self->set_zero_padded(0);
    return (0);            # False, if we got this far.
}

# Write an internal representation of the MAC address.
# This is mainly useful for conversion between formats.
sub _write_internal_mac {
    my ($self) = @_;
    my $mac = $self->get_mac();
    $mac =~ s/(\w)/\l$1/g;

    #my @groups = $self->get_groups();
    my @groups;
    my $delimiter = $self->get_delimiter();
    if ($delimiter) {
        $delimiter = ($delimiter eq ' ' ? '\s' : '\\'. $delimiter);
        @groups = split( /$delimiter/, $mac );
    }
    else { @groups = $mac; }

    # Hex base
    if ( ( defined $self->get_base() ) && ( $self->get_base() == 16 ) ) {
        my $bit_group;
        if ( defined $self->get_bit_group() ) {
            $bit_group = $self->get_bit_group();
        }
        else { $bit_group = 48; }
        my ($chars) = $bit_group / 4;
        my ($internal_mac);
        foreach my $element (@groups) {
            my $format = '%0' . $chars . 's';
            $internal_mac .= sprintf( $format, $element );
        }
        $self->set_internal_mac($internal_mac);
        return (1);
    }
    else {    # Decimal base
        if ( @groups == 6 ) { # Decimal addresses can only have octet grouping
            my @hex_groups;
            foreach my $group (@groups) {
                my $hex = sprintf( "%02x", $group );
                push( @hex_groups, $hex );
            }
            my $imac = join( '', @hex_groups );
            $self->set_internal_mac($imac);
            return (1);
        }
        else {
            $self->error("unsupported MAC address format \"$mac\"");
            return (0);
        }
    }
    $self->error("internal Net::MAC failure for MAC \"$mac\"");
    return (0);    # FIXME: die() here?
}

# Check the internal MAC address for errors (last check)
sub _check_internal_mac {
    my ($self) = @_;
    if ( !defined( $self->get_internal_mac() ) ) {
        my $mac = $self->get_mac();
        $self->error("invalid MAC address \"$mac\"");
        return (0);
    }
    elsif ( length( $self->get_internal_mac() ) != 12 ) {
        my $mac = $self->get_mac();
        $self->error("invalid MAC address \"$mac\"");
        return (0);
    }
    else { return (1) }
}

# Convert a MAC address object into a different format
sub convert {
    my ( $self, %arg ) = @_;
    my $imac = $self->get_internal_mac();
    my @groups;
    my $bit_group = $arg{'bit_group'} || 8; # not _default value
    my $offset = 0;
    use integer;
    my $size = $bit_group / 4;
    no integer;

    while ( $offset < length($imac) ) {
        my $group = substr( $imac, $offset, $size );
        if (   ( $bit_group == 8 )
            && ( exists $arg{zero_padded} )
            && ( $arg{zero_padded} == 0 ) )
        {
            $group =~ s/^0//;
        }
        push( @groups, $group );
        $offset += $size;
    }

    # Convert to base 10 if necessary
    if ( ( exists $arg{'base'} ) && ( $arg{'base'} == 10 ) )
    {    # Convert to decimal base
        my @dec_groups;
        foreach my $group (@groups) {
            my $dec_group = hex($group);
            push( @dec_groups, $dec_group );
        }
        @groups = @dec_groups;
    }
    my $mac_string;
    if ( exists $arg{delimiter} ) {

        #warn "\nconvert delimiter $arg{'delimiter'}\n";
        #my $delimiter = $arg{'delimiter'};
        #$delimiter =~ s/(:|\-|\.)/\\$1/;
        $mac_string = join( $arg{'delimiter'}, @groups );

        #warn "\nconvert groups @groups\n";
    }
    elsif ($bit_group != 48) {
        # use default delimiter
        $mac_string = join( ':', @groups );
    } 
    else {
        $mac_string = join( '', @groups );
    }

    if ( exists $arg{case} && $arg{case} =~ /^(upper|lower)$/ ) {
        for ($mac_string) {
            $_ = $arg{case} eq 'upper' ? uc : lc;
        }
    }

    # Construct the argument list for the new Net::MAC object
    $arg{'mac'} = $mac_string;

    #    foreach my $test (keys %arg) {
    #        warn "\nconvert arg $test is $arg{$test}\n";
    #    }
    my $new_mac = Net::MAC->new(%arg);
    return ($new_mac);
}

# Overloading the == operator (numerical comparison)
sub _compare_value {
    my ( $arg_1, $arg_2, $reversed ) = @_;
    my ( $mac_1, $mac_2 );
    if ( UNIVERSAL::isa( $arg_2, 'Net::MAC' ) ) {
        $mac_2 = $arg_2->get_internal_mac();
    }
    else {
        my $temp = Net::MAC->new( mac => $arg_2 );
        $mac_2 = $temp->get_internal_mac();
    }
    $mac_1 = $arg_1->get_internal_mac();
    if   ( $mac_1 eq $mac_2 ) { return (1); }
    else                      { return (0); }
}

# Overloading the != operator (numeric comparison)
sub _compare_value_ne {
    my ( $arg_1, $arg_2 ) = @_;
    if   ( $arg_1 == $arg_2 ) { return (0); }
    else                      { return (1); }
}

# Overloading the eq operator (string comparison)
sub _compare_string {
    my ( $arg_1, $arg_2, $reversed ) = @_;
    my ( $mac_1, $mac_2 );
    if ( UNIVERSAL::isa( $arg_2, 'Net::MAC' ) ) {
        $mac_2 = $arg_2->get_mac();
    }
    else {
        my $temp = Net::MAC->new( mac => $arg_2 );
        $mac_2 = $temp->get_mac();
    }
    $mac_1 = $arg_1->get_mac();
    if   ( $mac_1 eq $mac_2 ) { return (1); }
    else                      { return (0); }
}

# Overloading the ne operator (string comparison)
sub _compare_string_ne {
    my ( $arg_1, $arg_2 ) = @_;
    if   ( $arg_1 eq $arg_2 ) { return (0); }
    else                      { return (1); }
}

# Print verbose messages about internal workings of this class
sub verbose {
    my ( $self, $message ) = @_;
    if ( ( defined($message) ) && ( $self->{'_verbose'} ) ) {
        chomp($message);
        print "$message\n";
    }
}

# carp(), croak(), or ignore errors, depending on the attributes of the object.
# If the object is configured to stay alive despite errors, this method will
# store the error message in the '_error' attribute of the object, accessible
# via the get_error() method.
sub error {
    my ( $self, $message ) = @_;
    if ( $self->get_die() ) {    # die attribute is set to 1
        croak $message;
    }
    elsif ( $self->get_verbose() ) {    # die attribute is set to 0
        $self->set_error($message);
        carp $message;                  # Be verbose, carp() the message
    }
    else {    # die attribute is set to 0, verbose is set to 0
        $self->set_error($message);    # Just store the error
    }
    return (1);
}

1;                                     # Necessary for usage statement

# ABSTRACT: Perl extension for representing and manipulating MAC addresses 


__END__
=pod

=head1 NAME

Net::MAC - Perl extension for representing and manipulating MAC addresses 

=head1 VERSION

version 2.103622

=head1 SYNOPSIS

  use Net::MAC;
  my $mac = Net::MAC->new('mac' => '08:20:00:AB:CD:EF'); 

  # Example: convert to a different MAC address format (dotted-decimal)
  my $dec_mac = $mac->convert(
      'base' => 10,         # convert from base 16 to base 10
      'bit_group' => 8,     # octet grouping
      'delimiter' => '.'    # dot-delimited
  ); 

  print "$dec_mac\n"; # Should print 8.32.0.171.205.239

  # Example: find out whether a MAC is base 16 or base 10
  my $base = $mac->get_base();
  if ($base == 16) { 
      print "$mac is in hexadecimal format\n"; 
  } 
  elsif ($base == 10) { 
      print "$mac is in decimal format\n"; 
  }
  else { die "This MAC is neither base 10 nor base 16"; } 

=head1 DESCRIPTION

This is a module that allows you to 

  - store a MAC address in a Perl object
  - find out information about a stored MAC address
  - convert a MAC address into a specified format
  - easily compare two MAC addresses for string or numeric equality

There are quite a few different ways that MAC addresses may be represented 
in textual form.  The most common is arguably colon-delimited octets in 
hexadecimal form.  When working with Cisco devices, however, you are more 
likely to encounter addresses that are dot-delimited 16-bit groups in 
hexadecimal form.  In the Windows world, addresses are usually 
dash-delimited octets in hexadecimal form.  MAC addresses in a Sun ethers 
file are usually non-zero-padded, colon-delimited hexadecimal octets.  And 
sometimes, you come across dot-delimited octets in decimal form (certain 
Cisco SNMP MIBS actually use this). Hence the need for a common way to 
represent and manipulate MAC addresses in Perl.  

There is a surprising amount of complexity involved in converting MAC 
addresses between types.  This module does not attempt to understand all 
possible ways of representing a MAC address in a string, though most of the 
common ways of representing MAC addresses are supported.  

=head1 METHODS 

=head2 new() method (constructor)

The new() method creates a new Net::MAC object.  Possible arguments are 

  mac           a string representing a MAC address
  base          a number corresponding to the numeric base of the MAC 
                possible values: 10 16
  delimiter     the delimiter in the MAC address string from above 
                possible values: : - . space
  bit_group     the number of bits between each delimiter 
                possible values: 8 16 48
  zero_padded   whether bit groups have leading zero characters
                (Net::MAC only allows zero-padding for bit groups of 8 bits)
                possible values: 0 1 
  format        the name of a MAC address format specification which takes
                the place of the base,delimiter,bit_group and zero_padded
                options above
  verbose       write informational messages (useful for debugging)
                possible values: 0 1
  die           die() on invalid MAC address (default is to die on invalid MAC) 
                possible values: 0 1 (default is 1)

When the new() method is called with a 'mac' argument and nothing else, the 
object will attempt to auto-discover metadata like bit grouping, number base, 
delimiter, etc.  If the MAC is in an invalid or unknown format, the object 
will call the croak() function.  If you don't want the object to croak(), 
you can give the new() method a die argument, such as: 

  my $m_obj = Net::MAC->new('mac' => '000adf012345', 'die' => 0); 

There are cases where the auto-discovery will not be able to guess the 
numeric base of a MAC.  If this happens, try giving the new() method 
a hint, like so: 

  # Example: this MAC is actually in decimal-dotted notation, not hex
  my $mac = Net::MAC->new('mac' => '10.0.0.12.14.8', 'base' => 10); 

This is necessary for cases like the one above, where the class has no way 
of knowing that an address is decimal instead of hexadecimal.  

If you have installed a custom MAC address format into the class (see below)
then you can also pass the C<format> option as a hint:

  my $mac = Net::MAC->new('mac' => 'ab01~ab01~ab01', 'format' => 'My_Format');

=head2 class methods

=head3 set_format_for()

When discovering MAC address formats, and converting between different
formats (using C<convert> or C<as_*>) the module can use predefined common
formats or you can install your own for local circumstances.

For example consider a fictional device which uses MAC addresses formatted
like C<ab01~ab01~ab01>, which would otherwise not be understood. You can
install a new Format for this address style:

  Net::MAC->set_format_for( 'My_Format_Name' => {
      base => 16,
      bit_group => 16,
      delimiter => '~',
  });

Now when using either the C<format> option to C<new()>, or the C<convert()> or
C<as_*> methods, the module will recognise this new format C<My_Format_Name>.
The Hashref supplied can include any of the standard options for formats as
listed elsewhere in this documentation.

  my $mac = Net::MAC->new('mac' => 'ab01~ab01~ab01', 'format' => 'My_Format_Name');

Custom formats sharing the same name as one shipping with the module (such as
C<Cisco>) will override that built-in format.

=head2 accessor methods

=head3 get_mac() method 

Returns the MAC address stored in the object.    

=head3 get_base() method 

Returns the numeric base of the MAC address.  There are two possible return 
values: 

  16    hexadecimal (common)
  10    decimal (uncommon)

=head3 get_delimiter() method 

Returns the delimiter, if any, in the specified MAC address.  A valid 
delimiter matches the following regular expression:  

  /\:|\-|\.|\s/

In other words, either a colon, a dash, a dot, or a space.  If there is no 
delimiter, this method will return the undefined value (undef).  If an 
invalid delimiter is found (like an asterisk or something), the object will 
call the croak() function.  

=head3 get_bit_group() method

Returns the number of bits between the delimiters.  A MAC address is a 48 bit 
address, usually delimited into 8 bit groupings (called octets), i.e. 

  08:20:00:AB:CD:EF

Sometimes, MAC addresses are specified with fewer than 5 delimiters, or even 
no delimiters at all: 

  0820.00ab.cdef    # get_bit_group() returns 16
  082000abcdef      # get_bit_group() returns 48, no delimiters at all

=head3 get_zero_padded() method

Returns a boolean value indicating whether or not the bit groups are 
zero-padded.  A return value of 0 (false) means that the bit groups are not 
zero-padded, and a return value of 1 (true) means that they are zero-padded: 

  00.80.02.ac.4f.ff     # get_zero_padded() returns 1
  0:80:2:ac:4f:ff       # get zero_padded() returns 0
  0.125.85.122.155.64   # get_zero_padded() returns 0 

Net::MAC only allows bit groups of 8 bits to be zero-padded.  

=head2 convert() method 

Convert an already-defined Net::MAC object into a different MAC address 
format.  With this function you can change the delimiter, the bit grouping, 
or the numeric base.  

  # Example: convert to a different MAC address format (dotted-decimal)
  my $new_mac_obj = $existing_mac_obj->convert(
          'base' => 16,         # convert to base 16, if necessary
          'bit_group' => 16,    # 16 bit grouping
          'delimiter' => '.'    # dot-delimited
  );

Note that if any of the above arguments are not provided, they will be set to
the following default values:

 base       16
 bit_group  8  (i.e. a delimiter will be used)
 delimiter  :

=head2 Conversion to common formats

The most common formats have shortcut conversion methods that can be used 
instead of the convert() method with its many options.  

=head3 as_Cisco() method 

Cisco routers seem to usually represent MAC addresses in hexadecimal, 
dot-delimited, 16 bit groups.  

  my $mac = Net::MAC->new(mac => '00-02-03-AA-AB-FF'); 
  my $cisco_mac = $mac->as_Cisco(); 
  print "$cisco_mac"; 
  # should print 0002.03aa.abff

=head3 as_IEEE() method

The IEEE 802 2001 specification represents MAC addresses in hexadecimal, 
colon-delimited, upper case, 8 bit groups.  

  my $mac = Net::MAC->new(mac => '00-02-03-AA-AB-FF'); 
  my $IEEE_mac = Net::MAC->as_IEEE(); 
  print "$IEEE_mac"; 
  # should print 00:02:03:AA:AB:FF

=head3 as_Microsoft() method 

Microsoft usually represents MAC addresses in hexadecimal, dash delimited, 
upper case, 8 bit groups. 

  my $mac = Net::MAC->new(mac => '00:02:03:AA:AB:FF'); 
  my $microsoft_mac = $mac->as_Microsoft(); 
  print "$microsoft_mac"; 
  # should print 00-02-03-AA-AB-FF

=head3 as_Sun() method

Sun represents MAC addresses in hexadecimal, colon-delimited, 
non-zero-padded, lower case, 8 bit groups.  

  my $mac = Net::MAC->new(mac => '00-02-03-AA-AB-FF'); 
  my $sun_mac = $mac->as_Sun(); 
  print "$sun_mac"; 
  # should print 0:2:3:aa:ab:ff

=head2 Stringification

The stringification operator "" has been overloaded to allow for the 
meaningful use of the instance variable in a string.  

  my $mac = Net::MAC->new(mac => '00:0a:23:4f:ff:ef'); 
  print "object created for MAC address $mac"; 
  # Should print:
  # object created for MAC address 00:0a:23:4f:ff:ef

=head2 MAC address comparison

The Perl operators 'eq' and 'ne' (string comparison) and '==' '!=' (numeric 
comparison) have been overloaded to allow simple, meaningful comparisons of 
two MAC addresses.  

Example (two MAC addresses numerically identical but in different formats): 

  my $d = Net::MAC->new(mac => '0.8.1.9.16.16', base => 10); 
  my $h = Net::MAC->new(mac => '00:08:01:0A:10:10', base => 16); 
  if ($d == $h) { print "$d and $h are numerically equal"; } 
  if ($d ne $h) { print " but $d and $h are not the same string"; } 

=head1 BUGS 

=head2 Malformed MAC addresses 

Net::MAC can't handle MAC addresses where whole leading zero octets are 
omitted.  Example: 

  7.122.32.41.5 (should be 0.7.122.32.41.5)

Arguably, that's their problem and not mine, but maybe someday I'll get 
around to supporting that case as well. 

=head2 Case is not preserved 

Net::MAC doesn't reliably preserve case in a MAC address.  I might add a 
flag to the new() and convert() methods to do this.  I might not.

Case is however altered when using the as_foo() formatted output methods.

=head1 SEE ALSO

Net::MacMap
Net::MAC::Vendor

=head1 MAINTAINER

Oliver Gorwits <oliver@cpan.org>

=head1 CONTRIBUTORS 

Oliver Gorwits, Robin Crook, Kevin Brintnall

=head1 AUTHOR

Karl Ward <karlward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Karl Ward <karlward@cpan.org>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

