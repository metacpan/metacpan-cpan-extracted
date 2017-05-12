package SimpleDB::Class::Types;
BEGIN {
  $SimpleDB::Class::Types::VERSION = '1.0503';
}

=head1 NAME

SimpleDB::Class::Types - Attribute types.

=head1 VERSION

version 1.0503

=head1 DESCRIPTION

The allowable value types for L<SimpleDB::Class::Item> attributes.

=head1 SYNOPSIS

 Type                   | Default        | Range
 -----------------------+----------------+-----------------------------------------------
 Str                    | ''             | 0 to 1024 characters 
 MediumStr              | ''             | 0 to 259,080 chracters
 ArrayRefOfStr          | []             | 254 Str elements
 Int                    | 0              | -999,999,999 to 99,999,999,999,999 (no commas)
 ArrayRefOfInt          | []             | 254 Int elements
 DateTime               | now()          | Any DateTime object
 ArrayRefOfDateTime     | []             | 254 DateTime elements
 HashRef                | {}             | Less than 259,080 characters when converted to JSON

=head1 TYPES

The following types may be used to define attributes in L<SimpleDB::Class::Item>s.

=head2 Str

A string of less than 1024 characters. Defaults to C<''>. The basic working unit of SimpleDB. This is the fastest type as it needs no coercion, and is the native storage unit for SimpleDB. When in dobut, use this.

=head2 ArrayRefOfStr

An array reference of strings which can have up to 254 elements. Each string follows the rules of C<Str>. This is your basic multi-value workhorse, as it is the fastest multi-value type. See B<Attribute Limits> for special considerations about this type.

=head2 MediumStr

A string of up to 259,080 characters. Defaults to C<''>. Use this B<only> if you need to store text larger than C<Str> will allow. Much slower than C<Str> and not reliably searchable or sortable. See B<Attribute Limits> for special considerations about this type.

=head2 Int

An integer between -999,999,999 and 99,999,999,999,999 (without the commas). Defaults to C<0>. Is completely searchable and sortable.

=head2 ArrayRefOfInt

An array reference of integers which can have up to 254 elements. Each integer follows the rules of C<Int>. If you need a multi-value integer type, this is the way to go. See B<Attribute Limits> for special considerations about this type.

=head2 DateTime

A L<DateTime> object. Defaults to:

 DateTime->now();

Store a precise date in the database. Is searchable and sortable. 

=head2 ArrayRefOfDateTime

An array reference of dates which can have up to 254 elements. Each date follows the rules of C<DateTime>. Use this if you need a multi-value date. See B<Attribute Limits> for special considerations about this type.

=head2 HashRef

A hash reference. For storage this is serialized into JSON and stored as a C<MediumStr>, therefore it cannot exceed 259,080 characters after serialization. You B<cannot> use it to store a blessed hash reference. It is not searchable, not sortable, and is the slowest field type available. However, it can be quite useful if you need to persist a hash reference. See B<Attribute Limits> for special considerations about this type.

=head1 Attribute Limits

SimpleDB Items are limited to 256 attributes each. This means that they can have no more than any combination of names, values, or multi values. So you can have 256 name/value pairs, or you could have one multi-valued attribute with 256 elements, or anything in between. For that reason, be careful when adding ArrayRefOfDateTime, ArrayRefOfInt, ArrayRefOfStr, MediumStr, and HashRef elements to your items. 

=cut

use warnings;
use strict;
use DateTime;
use DateTime::Format::Strptime;
use JSON;

use MooseX::Types 
    -declare => [qw(SdbArrayRefOfDateTime SdbDateTime
        SdbArrayRefOfStr SdbStr SdbMediumStr
        SdbArrayRefOfInt SdbInt SdbIntAsStr SdbArrayRefOfIntAsStr
        SdbHashRef
    )];

use MooseX::Types::Moose qw/Int HashRef ArrayRef Str Undef/;

## Types

subtype SdbStr,
    as Str,
    where { length $_ <= 1024 };

subtype SdbMediumStr,
    as Str,
    where { length $_ <= 1020 * 254 };

subtype SdbArrayRefOfStr,
    as ArrayRef[SdbStr];

class_type 'DateTime';

subtype SdbDateTime,
    as 'DateTime';

subtype SdbArrayRefOfDateTime,
    as ArrayRef[SdbDateTime];

subtype SdbInt,
    as Int,
    where { $_ =~ m/^[-]?\d+$/ };

subtype SdbIntAsStr,
    as Str,
    where { $_ =~ m/^int\d{15}/ };

subtype SdbArrayRefOfInt,
    as ArrayRef[SdbInt];

subtype SdbArrayRefOfIntAsStr,
    as ArrayRef[SdbIntAsStr];

subtype SdbHashRef,
    as HashRef;




## Coercions

sub slice_string {
    my $string = shift;
    my @array;
    my $i = 1;
    my @parts;
    push @parts, substr $string, 0, 1020, '' while length $string;
    foreach my $part (@parts) {
        push @array, sprintf "%03d|%s", $i, $part;
        $i++;
    }
    return \@array;
}

sub mend_string {
    my $array_ref = shift;
    my $string;
    foreach my $part (sort @{$array_ref}) {
        $part =~ m/^\d{3}\|(.*)/xms;
        $string .= $1;
    }
    return $string;
}

coerce SdbStr,
    from SdbDateTime, via { DateTime::Format::Strptime::strftime('%Y-%m-%d %H:%M:%S %N %z', $_) },
    from SdbArrayRefOfDateTime, via { $_->[0] },
    from SdbMediumStr, via { substr(0,1024,$_) },
    from SdbArrayRefOfStr, via { $_->[0] },
    from Undef, via { '' };

coerce SdbIntAsStr,
    from SdbInt, via { sprintf("int%015d", ($_ + 1000000000)) };

coerce SdbArrayRefOfStr,
    from SdbArrayRefOfDateTime, via { [ map { to_SdbStr($_) } @{$_} ] },
    from SdbMediumStr, via { slice_string($_) },
    from SdbStr, via { [ $_ ] },
    from SdbHashRef, via { slice_string(JSON::to_json($_)) };
    from Undef, via { [''] };

coerce SdbMediumStr,
    from SdbStr, via { $_ },
    from SdbArrayRefOfStr, via { mend_string($_) },
    from Undef, via { '' };

coerce SdbArrayRefOfDateTime,
    from SdbArrayRefOfStr, via { [ map { to_SdbDateTime($_) } @{$_} ] },
    from SdbDateTime, via { [ $_ ] };

coerce SdbDateTime,
    from SdbStr, via { 
        if ($_ =~ m/\d{4}-\d\d-\d\d \d\d:\d\d:\d\d \d+ \+\d{4}/ ) {
            return DateTime::Format::Strptime::strptime('%Y-%m-%d %H:%M:%S %N %z', $_);
        }
        else {
            return DateTime->now; 
        }
    },
    from SdbArrayRefOfStr, via { to_SdbDateTime($_->[0]) },
    from SdbArrayRefOfDateTime, via { $_->[0] },
    from Undef, via { DateTime->now };

coerce SdbArrayRefOfInt,
    from SdbArrayRefOfStr, via { [ map { to_SdbInt($_) } @{$_} ] },
    from SdbInt, via { [ $_ ] };

coerce SdbArrayRefOfIntAsStr,
    from SdbArrayRefOfInt, via { [ map { to_SdbIntAsStr($_) } @{$_} ] };

coerce SdbInt,
    from SdbStr, via { 
        if ($_ =~ m/^int(\d{15})$/) {
            return $1 - 1000000000;
        }
        else {
            return 0;
        }
    },
    from SdbArrayRefOfStr, via { to_SdbInt($_->[0]) },
    from SdbArrayRefOfInt, via { $_->[0] },
    from Undef, via { 0 };

coerce SdbHashRef,
    from Undef, via { {} },
    from SdbArrayRefOfStr, via { 
        my $hash_ref = eval{ JSON::from_json(to_SdbMediumStr($_)) };
        if ($@) {
            warn "Got $@ coercing json into hash ref";
            return {};
        }
        else {
            return $hash_ref;
        }
    },
    from SdbStr, via { {} };


=head1 LEGAL

SimpleDB::Class is Copyright 2009-2010 Plain Black Corporation (L<http://www.plainblack.com/>) and is licensed under the same terms as Perl itself.

=cut


1;