#
#  Copyright 2009 10gen, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

package MongoDB::Async::OID;
{
  $MongoDB::Async::OID::VERSION = '0.702.3';
}

# ABSTRACT: A Mongo Object ID
use bytes; # length in bytes
use Carp qw/croak/;

sub new {
	my $self = shift;
	$self = bless( ( (ref($_[0]) eq 'HASH')	?  $_[0]  :  { (int(@_) == 1) ? ( 'value' => @_ ) : @_ }	), $self);
	
	unless ( $self->{value} ){
		$self->{value} = _generate_oid; 
	}elsif(length($self->{value}) != 24){
		croak("OIDs need to have a length of 24 bytes")
	}
	
	$self;
}

sub value {$_[0]->{value}}
*to_string = \&value;



sub get_time {
    return hex(substr($_[0]->{value}, 0, 8));
}


sub TO_JSON { {'$oid' => $_[0]->{value}} }

use overload
    '""' => \&to_string,
    'fallback' => 1;


1;

__END__

=pod

=head1 NAME

MongoDB::Async::OID - A Mongo Object ID

=head1 VERSION

version 0.702.3

=head1 SYNOPSIS

If no C<_id> field is provided when a document is inserted into the database, an 
C<_id> field will be added with a new C<MongoDB::Async::OID> as its value.

    my $id = $collection->insert({'name' => 'Alice', age => 20});

C<$id> will be a C<MongoDB::Async::OID> that can be used to retreive or update the 
saved document:

    $collection->update({_id => $id}, {'age' => {'$inc' => 1}});
    # now Alice is 21

To create a copy of an existing OID, you must set the value attribute in the
constructor.  For example:

    my $id1 = MongoDB::Async::OID->new;
    my $id2 = MongoDB::Async::OID->new(value => $id1->value);
	my $id3 = MongoDB::Async::OID->new({value => $id1->value});

Now C<$id1> and C<$id2> will have the same value.

OID generation is thread safe.

=head1 NAME

MongoDB::Async::OID - A Mongo ObjectId

=head1 SEE ALSO

Core documentation on object ids: L<http://dochub.mongodb.org/core/objectids>.

=head1 ATTRIBUTES

=head2 value

The OID value. A random value will be generated if none exists already.
It is a 24-character hexidecimal string (12 bytes).  

Its string representation is the 24-character string.

=head1 METHODS

=head2 to_string

    my $hex = $oid->to_string;

Gets the value of this OID as a 24-digit hexidecimal string.

=head2 get_time

    my $date = DateTime->from_epoch(epoch => $id->get_time);

Each OID contains a 4 bytes timestamp from when it was created.  This method
extracts the timestamp.  

=head2 TO_JSON

    my $json = JSON->new;
    $json->allow_blessed;
    $json->convert_blessed;

    $json->encode(MongoDB::Async::OID->new);

Returns a JSON string for this OID.  This is compatible with the strict JSON
representation used by MongoDB, that is, an OID with the value 
"012345678901234567890123" will be represented as 
C<{"$oid" : "012345678901234567890123"}>.

=head1 AUTHOR

  Kristina Chodorow <kristina@mongodb.org>

=head1 AUTHORS

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Kristina Chodorow <kristina@mongodb.org>

=item *

Mike Friedman <mike.friedman@10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by 10gen, Inc..

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
