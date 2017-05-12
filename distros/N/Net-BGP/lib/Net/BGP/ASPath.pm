#!/usr/bin/perl

package Net::BGP::ASPath;

use strict;
use vars qw(
  $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @PATHTYPES
  @BGP_PATH_ATTR_COUNTS
);

## Inheritance and Versioning ##

@ISA     = qw( Exporter );
$VERSION = '0.16';

## Module Imports ##

use Carp;
use IO::Socket;
use overload
  '<=>'      => \&len_compare,
  '<'        => \&len_lessthen,
  '>'        => \&len_greaterthen,
  '=='       => \&len_equal,
  '!='       => \&len_notequal,
  '""'       => \&as_string,
  '+'        => sub { my $x = shift->clone; $x->prepend(shift); },
  '+='       => \&prepend,
  'eq'       => \&equal,
  'ne'       => \&notequal,
  '@{}'      => \&asarray,
  'fallback' => 1;

use Net::BGP::ASPath::AS;
use Net::BGP::ASPath::AS_CONFED_SEQUENCE;
use Net::BGP::ASPath::AS_CONFED_SET;
use Net::BGP::ASPath::AS_SEQUENCE;
use Net::BGP::ASPath::AS_SET;

## Public Class Methods ##

sub new {
    my $class = shift;
    my $value = shift;
    my $options = shift;

    if (!defined($options)) { $options = {}; }
    $options->{as4} ||= 0;

    return clone Net::BGP::ASPath($value) if (ref $value eq 'Net::BGP::ASPath');

    my $this = {
        _as_path => [],
        _as4 => $options->{as4}
    };

    bless($this, $class);

    if (defined($value)) {
        if (ref $value) {
            if (ref $value eq 'ARRAY') {
                $this->_setfromstring(join ' ', @$value);
            } else {
                croak "Unknown ASPath constructor argument type: " . ref $value
            }
        } else {
            # Scalar/string
            $this->_setfromstring($value);
        }
    }

    return ($this);
}

sub _setfromstring {
    my ($this, $value) = @_;
    $this->{_as_path} = [];

    # Normalize string
    $value =~ s/\s+/ /g;
    $value =~ s/^\s//;
    $value =~ s/\s$//;
    $value =~ s/\s?,\s?/,/g;

    while ($value ne '') {

       # Note that the AS_SEQUENCE can't be > 255 path elements.  The entire len
       # of the AS_PATH can be > 255 octets, true, but not an individual AS_SET
       # segment.
       # TODO: We should do the same for other path types and also take care to
       # not allow ourselves to overflow the 65535 byte length limit if this is
       # converted back to a usable path.
       # TODO: It would be better to put the short AS PATH at end of the path,
       # not the beginning of the path, so that it is easier for other routers
       # to process.
        confess 'Invalid path segments for path object: >>' . $value . '<<'
          unless (
            ($value =~ /^(\([^\)]*\))( (.*))?$/) ||     # AS_CONFED_* segment
            ($value =~ /^(\{[^\}]*\})( (.*))?$/) ||     # AS_SET segment
            ($value =~ /^(([0-9]+\s*){1,255})(.*)?$/)
          );                                            # AS_SEQUENCE seqment

        $value = $3 || '';
        my $segment = Net::BGP::ASPath::AS->new($1);

        push(@{ $this->{_as_path} }, $segment);
    }
    return $this;
}

sub clone {
    my $proto = shift;
    my $class = ref $proto || $proto;
    $proto = shift unless ref $proto;

    my $clone = { _as_path => [] };

    foreach my $p (@{ $proto->{_as_path} }) {
        push(@{ $clone->{_as_path} }, $p->clone);
    }

    return (bless($clone, $class));
}

# This takes two buffers.  The first buffer is the standard AS_PATH buffer and
# should always be defined.
#
# The second buffer is the AS4_PATH buffer.
#
# The third parameter is true if AS4 is natively supported, false if AS4 is not
sub _new_from_msg {
    my ($class, $buffer, $buffer2, $options) = @_;
    my $this = $class->new;

    if (!defined($options)) { $options = {}; }
    $options->{as4} ||= 0;

    my $size = $options->{as4} ? 4 : 2;

    if (!defined($buffer2)) { $buffer2 = ''; }

    my $segment;
    while ($buffer ne '') {

        ($segment, $buffer)
            = Net::BGP::ASPath::AS->_new_from_msg($buffer, $options);

        # Error handling
        if ( !(defined $segment) ) {
            return undef;
        }
        if ( length($buffer) && ( ( length($buffer) - 2 ) % $size) ) {
            return undef;
        }

        push(@{ $this->{_as_path} }, $segment);
    }

    # We ignore AS4_PATHs on native AS4 speaker sessions
    # So we stop here.
    if ($options->{as4}) {
        return $this;
    }

    my @as4_path;

    while ($buffer2 ne '') {

        ($segment, $buffer2)
            = Net::BGP::ASPath::AS->_new_from_msg(
                $buffer2,
                { as4 => 1 }
              );

        # TODO: Should make sure type is only AS_SEQUENCE or AS_SET!

        if ( !(defined $segment) ) {
            return undef;
        }
        if ( length($buffer2) && ( ( length($buffer2) - 2 ) % 4) ) {
            return undef;
        }

        push (@as4_path, $segment);
    }

    my $as_count = $this->_length_helper( $this->{_as_path} );
    my $as4_count = $this->_length_helper( \@as4_path );

    if ($as_count < $as4_count) {
        # We ignroe the AS4 stuff per RFC4893 in this case
        return $this;
    }

    my $remove = $as4_count;

    while ($remove > 0) {
        my $ele = pop @{ $this->{_as_path} };
        if ($ele->length <= $remove) {
            $remove -= $ele->length;
        } else {
            push @{ $this->{_as_path} }, $ele->remove_tail($remove);
            $remove = 0;
        }
    }

    push @{ $this->{_as_path} }, @as4_path;

    return $this;
}

## Public Object Methods ##

# This encodes the AS_PATH and AS4_PATH elements (both are returned)
#
# If the AS4_PATH element is undef, that indicates an AS4_PATH is not
# needed - either we're encoding in 32-bit clear format, or all
# elements have only 16 bit ASNs.
sub _encode {
    my ($this, $args) = @_;

    if (!defined($args)) { $args = {}; }
    $args->{as4} ||= 0;

    my $has_as4;
    my $msg  = '';
    foreach my $segment (@{ $this->{_as_path} }) {
        $msg .= $segment->_encode($args);

        if ($segment->_has_as4()) { $has_as4 = 1; }
    }

    my $as4;
    if ( ( !($args->{as4} ) ) && ($has_as4) ) {
        $as4 = '';

        foreach my $segment (@{ $this->{_as_path} }) {
            if ( !(ref($segment) =~ /_CONFED_/) ) {
                $as4 .= $segment->_encode( { as4 => 1 } );
            }
        }
    }

    return ($msg, $as4);
}

sub prepend {
    my $this  = shift;
    my $value = shift;
    return $this->prepend_confed($value) if ($value =~ /^\(/);
    $this->strip;

    my @list = ($value);
    @list = @{$value} if (ref $value eq 'ARRAY');
    @list = split(' ', $list[0]) if $list[0] =~ / /;

    # Ugly - slow - but simple! Should be improved later!
    return $this->_setfromstring(join(' ', @list) . ' ' . $this)->cleanup;
}

sub prepend_confed {
    my $this = shift;

    my $value = shift;
    $value =~ s/^\((.*)\)$/$1/ unless ref $value;

    my @list = ($value);
    @list = @{$value} if (ref $value eq 'ARRAY');
    @list = split(' ', $list[0]) if $list[0] =~ / /;

    # Ugly - slow - but simple! Should be improved later!
    return $this->_setfromstring('(' . join(' ', @list) . ') ' . $this)
      ->cleanup;
}

sub cleanup {
    my $this = shift;

    # Ugly - slow - but simple! Should be improved later!
    my $str = $this->as_string;
    $str =~ s/\{\}//g;
    $str =~ s/\(\)//g;
    $str =~ s/(\d)\) +\((\d)/$1 $2/g;
    return $this->_setfromstring($str);
}

sub _confed {
    my $this = shift->clone;
    @{ $this->{_as_path} } =
      grep { (ref $_) =~ /_CONFED_/ } @{ $this->{_as_path} };
    return $this;
}

sub strip {
    my $this = shift;
    @{ $this->{_as_path} } =
      grep { (ref $_) !~ /_CONFED_/ } @{ $this->{_as_path} };
    return $this;
}

sub striped {
    return shift->clone->strip(@_);
}

sub aggregate {
    my @olist = @_;
    shift(@olist) unless ref $olist[0];

    # Sets
    my $cset = Net::BGP::ASPath::AS_CONFED_SET->new;
    my $nset = Net::BGP::ASPath::AS_SET->new;

    # Lists of confed / normal part of paths
    my @clist = map { $_->_confed } @olist;
    my @nlist = map { $_->striped } @olist;

    my $res = '';
    foreach my $pair ([ \@clist, $cset ], [ \@nlist, $nset ]) {
        my ($list, $set) = @{$pair};

        # Find common head
        my $head = $list->[0]->_head;
        foreach my $obj (@{$list}[ 1 .. @{$list} - 1 ]) {
            my $s = $obj->_head;
            $head = _longest_common_head($head, $s);
        }

        # Find tail set
        foreach my $obj (@{$list}) {
            my $tail = $obj->_tail($head);
            $tail = '(' . $tail if $tail =~ /^[^\(]*\).*$/;    # Fix tail
            $obj = Net::BGP::ASPath->new($tail);
            $set->merge($obj);
        }
        $head .= ')' if $head =~ /^\([^\)]+$/;                 # Fix head
        $res .= "$head $set ";
    }

    # Construct result
    return Net::BGP::ASPath->new($res)->cleanup;
}

## Utility functions (not methods!) ##
sub _longest_common_head {
    my ($s1, $s2) = @_;
    my $pos = 0;
    $s1 .= ' ';
    $s2 .= ' ';
    for my $i (0 .. length($s1) - 1) {
        last unless substr($s1, $i, 1) eq substr($s2, $i, 1);
        $pos = $i if substr($s1, $i, 1) eq ' ';
    }
    return substr($s1, 0, $pos);
}

sub _head

  # Head means the leading non-set part of the path
{
    my $this = shift->clone;
    my $ok   = 1;
    $this->{_as_path} =
      [ grep { $ok &&= (ref $_) =~ /_SEQUENCE$/; $_ = undef unless $ok; }
          @{ $this->{_as_path} } ];
    return $this;
}

sub _tail

  # Tail means everything after the "head" given as argument.
  # The tail is returned as a string. Returns undef if "head" is invalid.
{
    my $thisstr = shift() . " ";
    my $head    = shift() . " ";
    $head =~ s/\(/\\(/g;
    $head =~ s/\)/\\)/g;
    return undef unless $thisstr =~ s/^$head//;
    $thisstr =~ s/ $//;
    return $thisstr;
}

# For compatability
sub asstring { 
    my $this = shift;
    return $this->as_string(@_);
}

sub as_string {
    my $this = shift;

    return $this->_as_string_helper($this->{_as_path});
}

sub _as_string_helper {
    my ($this, $path) = @_;

    return join(' ', map { $_->as_string; } @{ $path });
}


sub asarray {
    my $this = shift;
    my @res;
    foreach my $s (@{ $this->{_as_path} }) {
        push(@res, @{ $s->asarray });
    }
    return \@res;
}

sub len_equal {
    my ($this, $other) = @_;
    return 0 unless defined($other);
    return ($this->length == $other->length) ? 1 : 0;
}

sub len_notequal {
    my ($this, $other) = @_;
    return 1 unless defined($other);
    return ($this->length != $other->length) ? 1 : 0;
}

sub len_lessthen {
    my ($this, $other) = @_;
    return 0 unless defined($other);
    return ($this->length < $other->length) ? 1 : 0;
}

sub len_greaterthen {
    my ($this, $other) = @_;
    return 1 unless defined($other);
    return ($this->length > $other->length) ? 1 : 0;
}

sub len_compare {
    my ($this, $other) = @_;
    return 1 unless defined($other);
    return $this->length <=> $other->length;
}

sub equal {
    my ($this, $other) = @_;
    return 0 unless defined($other);
    confess "Cannot compare " . (ref $this) . " with a " . (ref $other) . "\n"
      unless ref $other eq ref $this;
    return $this->as_string eq $other->as_string ? 1 : 0;
}

sub notequal {
    my ($this, $other) = @_;
    return 1 unless defined($other);
    return $this->as_string ne $other->as_string ? 1 : 0;
}

sub length {
    my ($this) = @_;

    return $this->_length_helper($this->{_as_path});
}

sub _length_helper {
    my ($this, $path) = @_;

    my $res = 0;
    foreach my $p (@{ $path }) {
        $res += $p->length;
    }
    return $res;
}

## POD ##

=pod

=head1 NAME

Net::BGP::ASPath - Class encapsulating BGP-4 AS Path information

=head1 SYNOPSIS

    use Net::BGP::ASPath;

    # Constructor
    $aspath  = Net::BGP::ASPath->new(undef, { as4 => 1 });
    $aspath2 = Net::BGP::ASPath->new([65001,65002]);
    $aspath3 = Net::BGP::ASPath->new("(65001 65002) 65010");
    $aspath4 = Net::BGP::ASPath->new("65001 {65011,65010}");

    # Object Copy
    $clone   = $aspath->clone();

    # Modifiers;
    $aspath  = $aspath->prepend(64999);
    $aspath  = $aspath->prepend("64999 65998");
    $aspath  = $aspath->prepend([64999,65998]);

    $aspath  = $aspath->prepend("(64999 65998)");
    $aspath  = $aspath->prepend_confed("64999 65998");

    $aspath += "65001 65002";    # Same as $aspath->prepend("65001 65002")

    $aspath5 = $aspath->striped; # New object
    $aspath  = $aspath->strip;   # Same modified

    $aspath  = $aspath->cleanup  # Same modified

    # Aggregation
    $aspath  = $aspath1->aggregate($aspath2,$aspath3);
    $aspath  = Net::BGP::ASPath->aggregate($aspath1,$aspath2,$aspath3);


    # Accessor Methods
    $length    = $aspath->length;
    $string    = $aspath->as_string;
    $array_ref = $aspath->asarray

    # In context
    $string    = "The AS path is: " . $aspath;
    $firstas   = $aspath[0];

    # Length comparisons
    if ($aspath < $aspath2) { ... };
    if ($aspath > $aspath2) { ... };
    if ($aspath == $aspath2) { ... };
    if ($aspath != $aspath2) { ... };
    @sorted = sort { $a <=> $b } ($aspath, $aspath2, $aspath3, $aspath4);

    # Path comparisons
    if ($aspath eq $aspath2) { ... };
    if ($aspath ne $aspath2) { ... };

=head1 DESCRIPTION

This module encapsulates the data contained in a BGP-4 AS_PATH, inluding
confederation extentions.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::BGP::ASPath object

    $aspath = Net::BGP::ASPath->new( PATHDATA, OPTIONS );

This is the constructor for Net::BGP::ASPath objects. It returns a
reference to the newly created object. The first parameter may be either:

=over 4

=item ARRAY_REF

An array ref containing AS numbers inteperted as an AS_PATH_SEQUENCE.

=item SCALAR

A string with AS numbers seperated by spaces (AS_PATH_SEQUANCE).
AS_PATH_SETs is written using "{}" with "," to seperate AS numbers. 
AS_PATH_CONFED_* is writen equally, but encapsulated in "()".

=item Net::BGP::ASPath

Another ASPath object, in which case a clone is constructed.

=item C<undef>

This will create the ASPath object with empty contents

=back

Following the PATHDATA, the OPTIONS may be specified.  Currently the
only valid option is c<as4>, which, if true, builds ASPath objects
usable for talking to an peer that supports 32 bit ASNs.  False, or
the default value, assumes that the peer does not support 32 bit ASNs,
which affects the decode routines.  Note that the encode routines
are not dependent upon this option.

Basically, if as4 is true, AS_PATH is populated from messages assuming
4 byte ASNs and AS4_PATH is not used.  Encoded AS_PATH attributes also
assume a 4 byte ASN.

If as4 is false, AS_PATH is populated from messages assuming 2 byte ASNs,
and, if available, AS4_PATH is used to replace occurences of 23456
when possible when outputing to user-readable formats.  Encoding routines
will also allow output of AS4_PATH objects when appropriate.

=back

=head1 OBJECT COPY

=over 4

=item clone() - clone a Net::BGP::ASPath object

    $clone = $aspath->clone();

This method creates an exact copy of the Net::BGP::ASPath object.

=back

=head1 ACCESSOR METHODS

=over 4

=item length()

Return the path-length used in BGP path selection. This is the sum
of the lengths of all AS_PATH elements. This does however not include
AS_PATH_CONFED_* elements and AS_SEGMENTS count as one BGP hop.

=item as_string()

Returns the path as a string in same notation as the constructor accept.

=item cleanup()

Reduce the path by removing meaningless AS_PATH elements (empty sets or
sequences) and joining neighbour elements of same _SET type.

=item strip()

Strips AS_CONFED_* segments from the path.

=item striped()

Returns a strip() 'ed clone() of the path.

=item prepend(ARRAY)

=item prepend(SCALAR)

Strips AS_CONFED_* segments from the path and prepends one or more AS numbers
to the path as given as arguments, either as an array of AS numbers or as a
string with space seperated AS numbers. If string has "()" arround, prepend_confed
will be used instead.

=item prepend_confed(ARRAY)

=item prepend_confed(SCALAR)

Prepends one or more confederation AS numbers to the path as given as
arguments, either as an array of AS numbers or as a string with space
seperated AS numbers. "()" arround the string is ignored.

=item aggregate(ASPath)

=item aggregate(ARRAY)

Aggregates the current ASPath with the ASPath(s) given as argument.
If invoked as class method, aggregate all ASPaths given as argument.

To aggregate means to find the longest common substring (of the paths of all
objects that should be aggregated) and keep them, but
replacing the non-common substrings with AS_SET segments. Currently only
the longest common normal and confederation head will be found and the remaing
will be left as an AS_SET and AS_CONFED_SET.

Returns the aggregated object. The objects self are not modified.

=back

=head1 SEE ALSO

B<RFC 1771>, B<RFC 1997>, Net::BGP, Net::BGP::Process, Net::BGP::Peer,
Net::BGP::Notification, Net::BGP::NLRI, Net::BGP::Update

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::BGP::ASPath ##
