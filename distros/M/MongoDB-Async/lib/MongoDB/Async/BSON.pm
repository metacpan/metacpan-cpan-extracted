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

package MongoDB::Async::BSON;
{
  $MongoDB::Async::BSON::VERSION = '0.702.3';
}


# ABSTRACT: Tools for serializing and deserializing data in BSON form

tie $MongoDB::Async::BSON::looks_like_number, 'MongoDB::Async::BSON::FlagsCacheRefresher';
$MongoDB::Async::BSON::looks_like_number = 0;

tie $MongoDB::Async::BSON::char, 'MongoDB::Async::BSON::FlagsCacheRefresher';
$MongoDB::Async::BSON::char = '$';

tie $MongoDB::Async::BSON::utf8_flag_on, 'MongoDB::Async::BSON::FlagsCacheRefresher';
$MongoDB::Async::BSON::utf8_flag_on = 1;

tie $MongoDB::Async::BSON::use_boolean, 'MongoDB::Async::BSON::FlagsCacheRefresher';
$MongoDB::Async::BSON::use_boolean = 0;

tie $MongoDB::Async::BSON::use_binary, 'MongoDB::Async::BSON::FlagsCacheRefresher';
$MongoDB::Async::BSON::use_binary = 0;


tie $MongoDB::Async::BSON::dt_type, 'MongoDB::Async::BSON::FlagsCacheRefresher';
$MongoDB::Async::BSON::dt_type = "DateTime";


tie $MongoDB::Async::Cursor::inflate_dbrefs , 'MongoDB::Async::BSON::FlagsCacheRefresher';
$MongoDB::Async::Cursor::inflate_dbrefs = 1;

{
package  MongoDB::Async::BSON::FlagsCacheRefresher;
no warnings; # Use of uninitialized value in subroutine entry

	sub TIESCALAR { bless \my($scalar) }

	sub FETCH { ${ $_[0] } }

	sub STORE {
		MongoDB::Async::BSON::read_flags();
		
		${ $_[0] } = $_[1];
	}

	sub DESTROY {}
	sub UNTIE {}

}

1;

__END__

=pod

=head1 NAME

MongoDB::Async::BSON - Tools for serializing and deserializing data in BSON form

=head1 VERSION

version 0.702.3

=head1 NAME

MongoDB::Async::BSON - Encoding and decoding utilities (more to come)

=head1 ATTRIBUTES

=head2 C<looks_like_number>

    $MongoDB::Async::BSON::looks_like_number = 1;
    $collection->insert({age => "4"}); # stores 4 as an int

If this is set, the driver will be more aggressive about converting strings into
numbers.  Anything that L<Scalar::Util>'s looks_like_number would approve as a
number will be sent to MongoDB as its numeric value.

Defaults to 0 (for backwards compatibility).

If you do not set this, you may be using strings more often than you intend to.
See the L<MongoDB::Async::DataTypes> section for more info on the behavior of strings
vs. numbers.

=head2 char

    $MongoDB::Async::BSON::char = ":";
    $collection->query({"x" => {":gt" => 4}});

Can be used to set a character other than "$" to use for special operators.

=head2 Turn on/off UTF8 flag when return strings

    # turn off utf8 flag on strings
    $MongoDB::Async::BSON::utf8_flag_on = 0;

Default is turn on, that compatible with version before 0.34.

If set to 0, will turn of utf8 flag on string attribute and return on bytes mode, meant same as :

    utf8::encode($str)

Currently MongoDB return string with utf8 flag, on character mode , some people
wish to turn off utf8 flag and return string on byte mode, it maybe help to display "pretty" strings.

NOTE:

If you turn off utf8 flag, the string  length will compute as bytes, and is_utf8 will return false.

=head2 Return boolean values as booleans instead of integers

    $MongoDB::Async::BSON::use_boolean = 1

By default, booleans are deserialized as integers.  If you would like them to be
deserialized as L<boolean/true> and L<boolean/false>, set
C<$MongoDB::Async::BSON::use_boolean> to 1.

=head2 Return binary data as instances of L<MongoDB::Async::BSON::Binary> instead of
string refs.

    $MongoDB::Async::BSON::use_binary = 1

For backwards compatibility, binary data is deserialized as a string ref.  If
you would like to have it deserialized as instances of L<MongoDB::Async::BSON::Binary>
(to, say, preserve the subtype), set C<$MongoDB::Async::BSON::use_binary> to 1.

    $MongoDB::Async::BSON:dt_type = "DateTime"

Sets the type of object which is returned for DateTime fields. The default is L<DateTime>. Other
acceptable values are L<DateTime::Tiny> and C<undef>. The latter will give you the raw epoch value
rather than an object.

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
