#!/usr/bin/perl

package Net::BGP::ASPath::AS;
use bytes;

use strict;
use Carp;
use Exporter;
use vars qw(
  $VERSION @ISA
);

use overload
  '<=>'      => \&compare,
  '""'       => \&as_string,
  'fallback' => 1;

# DO NOT OVERLOAD @{} - it's an array - we need this!

$VERSION = '0.17';

use Net::BGP::Notification qw( :errors );

@Net::BGP::ASPath::AS_SEQUENCE::ISA = qw( Exporter );

## BGP AS_PATH Path Attribute Type Classes ##

my @BGP_PATH_ATTR_CLASS = (
    undef,                                    # unused
    'Net::BGP::ASPath::AS_SET',               # BGP_PATH_ATTR_AS_SET
    'Net::BGP::ASPath::AS_SEQUENCE',          # BGP_PATH_ATTR_AS_SEQUENCE
    'Net::BGP::ASPath::AS_CONFED_SEQUENCE',   # BGP_PATH_ATTR_AS_CONFED_SEQUENCE
    'Net::BGP::ASPath::AS_CONFED_SET'         # BGP_PATH_ATTR_AS_CONFED_SET
);

## Public Class Methods ##

sub new {
    my ($class, $value) = (shift, shift);

    return $value->clone if (ref $value) =~ /^Net::BGP::ASPath::AS_/;

    my ($this, $realclass);

    $value = '' unless defined($value);

    if (ref $value eq 'HASH') {

        # Construct SET from HASH
        croak "Hash argument given for a non-set AS_PATH element"
          unless $class =~ /_SET$/;
        $this->{ keys %{$value} } = values(%{$value});
        bless($this, $class);
        return $this;
    }

    if (ref $value eq 'ARRAY') {

        # Construct SET from HASH
        if ($class =~ /_SEQUENCE$/) {
            push(@{$this}, @{$value});
        } else {
            $this = {};
            foreach my $a (@{$value}) { $this->{$a} = 1; }
        }
        bless($this, $class);
        return $this;
    }

    croak "Unknown argument type ("
      . (ref $value)
      . ") parsed as argument to AS_PATH construtor."
      if (ref $value);

    # Only a scalar left - Parse string!
    my $confed = '';
    if (   ($value =~ /^\((.*)\)$/)
        || ($value eq '' && $class =~ /_CONFED_/))
    {
        $value = $1 if defined($1);
        $confed = '_CONFED';
    }
    if (   ($value =~ /^\{([0-9,]*)\}$/)
        || ($value eq '' && $class =~ /_SET$/))
    {
        my $set = defined $1 ? $1 : $value;
        $realclass = 'Net::BGP::ASPath::AS' . $confed . '_SET';
        $this      = {};
        foreach my $a (split(/,/, $set)) { $this->{$a} = 1; }
    } elsif ($value =~ /^[0-9 ]*$/) {
        $realclass = 'Net::BGP::ASPath::AS' . $confed . '_SEQUENCE';
        $this = [ split(' ', $value) ];
    } else {
        croak "$value is not a valid AS_PATH segment";
    }

    croak "AS_PATH segment is a $realclass but was constructed as $class"
      if $class !~ /::AS$/ && $class ne $realclass;

    bless($this, $realclass);
    return ($this);
}

sub _new_from_msg

  # Constructor - returns object AND buffer with data removed
{
    my ($class, $buffer, $args) = @_;

    if (!defined($args)) { $args = {}; }
    $args->{as4} ||= 0;

    my $size = $args->{as4} ? 4 : 2;

    my ($type, $len) = unpack('CC', $buffer);

    if ( ($len * $size + 2) > length($buffer)) {
        Net::BGP::Notification->throw(
            ErrorCode    => BGP_ERROR_CODE_UPDATE_MESSAGE,
            ErrorSubCode => BGP_ERROR_SUBCODE_BAD_AS_PATH
        );
    }

    my @list;
    if ($args->{as4}) {
        @list = unpack('N*', substr($buffer,2,(4*$len)) );
    } else {
        @list = unpack('n*', substr($buffer,2,(2*$len)) );
    }
    $class = $BGP_PATH_ATTR_CLASS[$type];

    if (length($buffer) > 2+($size*$len)) {
        $buffer = substr($buffer, 2+($size*$len));
    } else {
        $buffer = '';
    }
    return ($class->new(\@list), $buffer);
}

# This encodes the standard AS Path
# TODO: Note that if AS4 != True, then there is an issue with this code.
# In particular, it will stick 23456 into the confederation types.  In
# theory, no confederation using AS4 should be transmitting confed types
# to any node that is NOT using AS4, per RFC4893.
#
# But when this breaks the internet, it's not my fault.
sub _encode {
    my ($this, $args) = @_;
    if (!defined($args)) { $args = {}; }
    $args->{as4} ||= 0;

    my $list = $this->asarray;
    my $len  = scalar @{$list};
    my $type = $this->type;

    my $msg;
    if (!($args->{as4})) {
        $msg = pack('CC', $type, $len);
        foreach my $as ( @{$list} ) {
            $msg .= ($as <= 65535) ? pack('n', $as) : pack('n', 23456);
        }
    } else {
        $msg = pack('CCN*', $type, $len, @{$list});
    }

    return $msg;
}

# Determines if the path element has any ASNs > 23456
sub _has_as4 {
    my ($this) = @_;
    
    if ( ref($this) =~ /_CONFED_/) {
        # No confeds in AS4_ paths
        return 0;
    }

    my $list = $this->asarray;
    foreach my $as ( @{$list} ) {
        if ($as > 65535) { return 1; }
    }

    return 0;
}

sub compare {
    my ($this, $other) = @_;
    return undef unless defined($other);
    return $this->length <=> $other->length;
}

sub clone {
    my $proto = shift;
    my $class = ref $proto || $proto;
    $proto = shift unless ref $proto;

    my $clone;
    if ($class =~ /_SET$/) {
        return $class->new([ keys %{$proto} ]);
    } else {
        return $class->new([ @{$proto} ]);    # Unblessed!
    }
}

sub asstring {
    my $this = shift;
    return $this->as_string(@_);
}

sub as_string {
    my $this = shift;
    croak 'Instance of ASPath::AS should not exist!'
      if (ref $this eq 'Net::BGP::ASPath::AS');
    return $this->as_string;
}

sub asarray {
    my $this = shift;
    croak 'Instance of ASPath::AS should not exist!'
      if (ref $this eq 'Net::BGP::ASPath::AS');
    return $this->asarray;
}

1;
