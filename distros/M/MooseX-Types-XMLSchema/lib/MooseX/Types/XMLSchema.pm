package MooseX::Types::XMLSchema;
BEGIN {
  $MooseX::Types::XMLSchema::AUTHORITY = 'cpan:AJGB';
}
{
  $MooseX::Types::XMLSchema::VERSION = '0.06';
}
#ABSTRACT: XMLSchema compatible Moose types library

use warnings;
use strict;

use MooseX::Types -declare => [qw(
    xs:string
    xs:integer
    xs:positiveInteger
    xs:nonPositiveInteger
    xs:negativeInteger
    xs:nonNegativeInteger
    xs:long
    xs:unsignedLong
    xs:int
    xs:unsignedInt
    xs:short
    xs:unsignedShort
    xs:byte
    xs:unsignedByte
    xs:boolean
    xs:float
    xs:double
    xs:decimal
    xs:duration
    xs:dateTime
    xs:time
    xs:date
    xs:gYearMonth
    xs:gYear
    xs:gMonthDay
    xs:gDay
    xs:gMonth
    xs:base64Binary
    xs:anyURI
)];
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(
    Str
    Int
    Num
    Bool
    ArrayRef
);

use Regexp::Common qw( number );
use MIME::Base64 qw( encode_base64 );
use Encode qw( encode );
use DateTime::Duration;
use DateTime::TimeZone;
use DateTime;
use IO::Handle;
use URI;
use Math::BigInt;
use Math::BigFloat;


class_type 'Math::BigInt';
class_type 'Math::BigFloat';
class_type 'DateTime::Duration';
class_type 'DateTime';
class_type 'IO::Handle';
class_type 'URI';


subtype 'xs:string' =>
    as 'Str';



subtype 'xs:integer' =>
    as 'Math::BigInt',
    where { ! $_->is_nan && ! $_->is_inf };

coerce 'xs:integer'
    => from 'Int', via { Math::BigInt->new($_) }
    => from 'Str', via { Math::BigInt->new($_) };


subtype 'xs:positiveInteger' => as 'Math::BigInt', where { $_ > 0 };
coerce 'xs:positiveInteger'
    => from 'Int', via { Math::BigInt->new($_) }
    => from 'Str', via { Math::BigInt->new($_) };


subtype 'xs:nonPositiveInteger' => as 'Math::BigInt', where { $_ <= 0 };
coerce 'xs:nonPositiveInteger'
    => from 'Int', via { Math::BigInt->new($_) }
    => from 'Str', via { Math::BigInt->new($_) };


subtype 'xs:negativeInteger' => as 'Math::BigInt', where { $_ < 0 };
coerce 'xs:negativeInteger'
    => from 'Int', via { Math::BigInt->new($_) }
    => from 'Str', via { Math::BigInt->new($_) };


subtype 'xs:nonNegativeInteger' =>
    as 'Math::BigInt',
        where { $_ >= 0 };
coerce 'xs:nonNegativeInteger'
    => from 'Int', via { Math::BigInt->new($_) }
    => from 'Str', via { Math::BigInt->new($_) };


{
    my $min = Math::BigInt->new('-9223372036854775808');
    my $max = Math::BigInt->new('9223372036854775807');

    subtype 'xs:long' =>
        as 'Math::BigInt',
            where { $_ <= $max && $_ >= $min };
    coerce 'xs:long'
        => from 'Int', via { Math::BigInt->new($_) }
        => from 'Str', via { Math::BigInt->new($_) };
}


{
    my $max = Math::BigInt->new('18446744073709551615');

    subtype 'xs:unsignedLong' =>
        as 'Math::BigInt',
            where { $_ >= 0 && $_ <= $max };
    coerce 'xs:unsignedLong'
        => from 'Int', via { Math::BigInt->new($_) }
        => from 'Str', via { Math::BigInt->new($_) };
}


subtype 'xs:int' =>
    as 'Int',
        where { $_ <= 2147483647 && $_ >= -2147483648 };


subtype 'xs:unsignedInt' =>
    as 'Int',
        where { $_ <= 4294967295 && $_ >= 0};


subtype 'xs:short' =>
    as 'Int',
        where { $_ <= 32767 && $_ >= -32768 };


subtype 'xs:unsignedShort' =>
    as 'Int',
        where { $_ <= 65535 && $_ >= 0 };


subtype 'xs:byte' =>
    as 'Int',
        where { $_ <= 127 && $_ >= -128 };


subtype 'xs:unsignedByte' =>
    as 'Int',
        where { $_ <= 255 && $_ >= 0 };


subtype 'xs:boolean' =>
    as 'Bool';



{
    my $m = Math::BigFloat->new(2 ** 24);
    my $min = $m * Math::BigFloat->new(2 ** -149);
    my $max = $m * Math::BigFloat->new(2 ** 104);

    subtype 'xs:float' =>
        as 'Math::BigFloat',
            where { $_->is_nan || $_->is_inf || ( $_ <= $max && $_ >= $min ) };
    coerce 'xs:float'
        => from 'Num', via { Math::BigFloat->new($_) }
        => from 'Str', via { Math::BigFloat->new($_) };
}


{
    my $m = Math::BigFloat->new(2 ** 53);
    my $min = $m * Math::BigFloat->new(2 ** -1075);
    my $max = $m * Math::BigFloat->new(2 ** 970);

    subtype 'xs:double' =>
        as 'Math::BigFloat',
            where { $_->is_nan || $_->is_inf || ( $_ < $max && $_ > $min ) };
    coerce 'xs:double'
        => from 'Num', via { Math::BigFloat->new($_) }
        => from 'Str', via { Math::BigFloat->new($_) };
}


subtype 'xs:decimal' =>
    as 'Math::BigFloat',
    where { ! $_->is_nan && ! $_->is_inf };
coerce 'xs:decimal'
    => from 'Num', via { Math::BigFloat->new($_) }
    => from 'Str', via { Math::BigFloat->new($_) };



subtype 'xs:duration' =>
    as 'Str' =>
        where { /^\-?P\d+Y\d+M\d+DT\d+H\d+M\d+(?:\.\d+)?S$/ };

coerce 'xs:duration'
    => from 'DateTime::Duration' =>
        via {
            my $is_negative;
            if ($_->is_negative) {
                $is_negative = 1;
                $_ = $_->inverse;
            }
            my ($s, $ns) = $_->in_units(qw(
                seconds
                nanoseconds
            ));
            if ( int($ns) ) {
                $s = sprintf("%d.%09d", $s, $ns);
                $s =~ s/0+$//;
            }
            return sprintf('%sP%dY%dM%dDT%dH%dM%sS',
                $is_negative ? '-' : '',
                $_->in_units(qw(
                    years
                    months
                    days
                    hours
                    minutes
                )),
                $s
            );
        };



subtype 'xs:dateTime' =>
    as 'Str' =>
        where { /^\-?\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?(?:[\-\+]\d{2}:?\d{2})?$/ };

coerce 'xs:dateTime'
    => from 'DateTime' =>
        via {
            my $datetime = $_->strftime( $_->nanosecond ? "%FT%T.%N" : "%FT%T");
            $datetime =~ s/0+$// if $_->nanosecond;
            my $tz = $_->time_zone;

            return $datetime if $tz->is_floating;
            return $datetime .'Z' if $tz->is_utc;

            if ( DateTime::TimeZone->offset_as_string($_->offset) =~
                /^([\+\-]\d{2})(\d{2})/ ) {
                return "$datetime$1:$2";
            }
            return $datetime;
        };



subtype 'xs:time' =>
    as 'Str' =>
        where { /^\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?(?:[\-\+]\d{2}:?\d{2})?$/ };

coerce 'xs:time'
    => from 'DateTime' =>
        via {
            my $time = $_->strftime( $_->nanosecond ? "%T.%N" : "%T");
            $time =~ s/0+$// if $_->nanosecond;
            my $tz = $_->time_zone;

            return $time if $tz->is_floating;
            return $time .'Z' if $tz->is_utc;

            if ( DateTime::TimeZone->offset_as_string($_->offset) =~
                /^([\+\-]\d{2})(\d{2})/ ) {
                return "$time$1:$2";
            }
            return $time;
        };



subtype 'xs:date' =>
    as 'Str' =>
        where { /^\-?\d{4}\-\d{2}\-\d{2}Z?(?:[\-\+]\d{2}:?\d{2})?$/ };

coerce 'xs:date'
    => from 'DateTime' =>
        via {
            my $date = $_->strftime("%F");
            my $tz = $_->time_zone;

            return $date if $tz->is_floating;
            return $date .'Z' if $tz->is_utc;

            if ( DateTime::TimeZone->offset_as_string($_->offset) =~
                /^([\+\-]\d{2})(\d{2})/ ) {
                return "$date$1:$2";
            }
            return $date;

        };



subtype '__xs:IntPair' =>
    as 'ArrayRef[Int]' =>
        where { @$_ == 2 };


subtype 'xs:gYearMonth' =>
    as 'Str' =>
        where { /^\d{4}\-\d{2}$/ };

coerce 'xs:gYearMonth'
    => from '__xs:IntPair' =>
        via {
            return sprintf("%02d-%02d", @$_);
        }
    => from 'DateTime' =>
        via {
            return $_->strftime("%Y-%m");
        };



subtype 'xs:gYear' =>
    as 'Str' =>
        where { /^\d{4}$/ };

coerce 'xs:gYear'
    => from 'DateTime' =>
        via {
            return $_->strftime("%Y");
        };



subtype 'xs:gMonthDay' =>
    as 'Str' =>
        where { /^\-\-\d{2}\-\d{2}$/ };

coerce 'xs:gMonthDay'
    => from '__xs:IntPair' =>
        via {
            return sprintf("--%02d-%02d", @$_);
        }
    => from 'DateTime' =>
        via {
            return $_->strftime("--%m-%d");
        };



subtype 'xs:gDay' =>
    as 'Str' =>
        where { /^\-\-\-\d{2}$/ };

coerce 'xs:gDay'
    => from 'Int' =>
        via {
            return sprintf("---%02d", $_);
        }
    => from 'DateTime' =>
        via {
            return $_->strftime("---%d");
        };



subtype 'xs:gMonth' =>
    as 'Str' =>
        where { $_ => /^\-\-\d{2}$/ };

coerce 'xs:gMonth'
    => from 'Int' =>
        via {
            return sprintf("--%02d", $_);
        }
    => from 'DateTime' =>
        via {
            return $_->strftime("--%m");
        };



subtype 'xs:base64Binary' =>
    as 'Str' =>
        where { $_ =~ /^[a-zA-Z0-9=\+\/]+$/m };

coerce 'xs:base64Binary'
    => from 'IO::Handle' =>
        via {
            local $/;
            my $content = <$_>;
            return encode_base64(encode("UTF-8", $content));
        };



subtype 'xs:anyURI' =>
    as 'Str' =>
        where { $_ =~ /^\w+:\/\/.*$/ };

coerce 'xs:anyURI'
    => from 'URI' =>
        via {
            return $_->as_string;
        };

no Moose::Util::TypeConstraints;
no Moose;



1; # End of MooseX::Types::XMLSchema

__END__
=pod

=encoding utf-8

=head1 NAME

MooseX::Types::XMLSchema - XMLSchema compatible Moose types library

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    package My::Class;
    use Moose;
    use MooseX::Types::XMLSchema qw( :all );

    has 'string'       => ( is => 'rw', isa => 'xs:string' );

    has 'boolean'      => ( is => 'rw', isa => 'xs:boolean' );

    has 'byte'         => ( is => 'rw', isa => 'xs:byte' );
    has 'short'        => ( is => 'rw', isa => 'xs:short' );
    has 'int'          => ( is => 'rw', isa => 'xs:int' );
    has 'long'         => ( is => 'rw', isa => 'xs:long', coerce => 1 );
    has 'integer'      => ( is => 'rw', isa => 'xs:integer', coerce => 1 );
    has 'float'        => ( is => 'rw', isa => 'xs:float', coerce => 1 );
    has 'double'       => ( is => 'rw', isa => 'xs:double', coerce => 1 );
    has 'decimal'      => ( is => 'rw', isa => 'xs:decimal', coerce => 1 );

    has 'duration'     => ( is => 'rw', isa => 'xs:duration', coerce => 1 );
    has 'datetime'     => ( is => 'rw', isa => 'xs:dateTime', coerce => 1 );
    has 'time'         => ( is => 'rw', isa => 'xs:time', coerce => 1 );
    has 'date'         => ( is => 'rw', isa => 'xs:date', coerce => 1 );
    has 'gYearMonth'   => ( is => 'rw', isa => 'xs:gYearMonth', coerce => 1 );
    has 'gYear'        => ( is => 'rw', isa => 'xs:gYear', coerce => 1 );
    has 'gMonthDay'    => ( is => 'rw', isa => 'xs:gMonthDay', coerce => 1 );
    has 'gDay'         => ( is => 'rw', isa => 'xs:gDay', coerce => 1 );
    has 'gMonth'       => ( is => 'rw', isa => 'xs:gMonth', coerce => 1 );

    has 'base64Binary' => ( is => 'rw', isa => 'xs:base64Binary', coerce => 1 );

    has 'anyURI'            => ( is => 'rw', isa => 'xs:anyURI', coerce => 1 );

    has 'nonPositiveInteger' => ( is => 'rw', isa => 'xs:nonPositiveInteger', coerce => 1 );
    has 'positiveInteger'    => ( is => 'rw', isa => 'xs:positiveInteger', coerce => 1 );
    has 'nonNegativeInteger' => ( is => 'rw', isa => 'xs:nonNegativeInteger', coerce => 1 );
    has 'negativeInteger'    => ( is => 'rw', isa => 'xs:negativeInteger', coerce => 1 );

    has 'unsignedByte'    => ( is => 'rw', isa => 'xs:unsignedByte' );
    has 'unsignedShort'   => ( is => 'rw', isa => 'xs:unsignedShort' );
    has 'unsignedInt'     => ( is => 'rw', isa => 'xs:unsignedInt' );
    has 'unsignedLong'    => ( is => 'rw', isa => 'xs:unsignedLong', coerce => 1 );

Then, elsewhere:

    my $object = My::Class->new(
        string          => 'string',
        decimal         => Math::BigFloat->new(20.12),
        duration        => DateTime->now - DateTime->(year => 1990),
        base64Binary    => IO::File->new($0),
    );

=head1 DESCRIPTION

This class provides a number of XMLSchema compatible types for your Moose
classes.

=head1 TYPES

=head2 xs:string

    has 'string'       => (
        is => 'rw',
        isa => 'xs:string'
    );

A wrapper around built-in Str.

=head2 xs:integer

    has 'integer'      => (
        is => 'rw',
        isa => 'xs:integer',
        coerce => 1
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer.

=head2 xs:positiveInteger

    has 'positiveInteger' => (
        is => 'rw',
        isa => 'xs:positiveInteger',
        coerce => 1,
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer greater than zero.

=head2 xs:nonPositiveInteger

    has 'nonPositiveInteger' => (
        is => 'rw',
        isa => 'xs:nonPositiveInteger',
        coerce => 1,
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer less than or equal
to zero.

=head2 xs:negativeInteger

    has 'negativeInteger' => (
        is => 'rw',
        isa => 'xs:negativeInteger',
        coerce => 1,
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer less than zero.

=head2 xs:nonNegativeInteger

    has 'nonPositiveInteger' => (
        is => 'rw',
        isa => 'xs:nonNegativeInteger',
        coerce => 1,
    );

A L<Math::BigInt> object. Set to coerce from Int/Str.

This is defined in XSchema to be an arbitrary size integer greater than or
equal to zero.

=head2 xs:long

    has 'long' => (
        is => 'rw',
        isa => 'xs:long',
        coerce => 1,
    );

A 64-bit Integer. Represented as a L<Math::Bigint> object, but limited to the
64-bit (signed) range. Set to coerce from Int/Str.

=head2 xs:unsignedLong

    has 'unsignedLong' => (
        is => 'rw',
        isa => 'xs:unsignedLong',
        coerce => 1,
    );

A 64-bit Integer. Represented as a L<Math::Bigint> object, but limited to the
64-bit (unsigned) range. Set to coerce from Int/Str.

=head2 xs:int

    has 'int' => (
        is => 'rw',
        isa => 'xs:int'
    );

A 32-bit integer. Represented natively.

=head2 xs:unsignedInt

    has 'unsignedInt' => (
        is => 'rw',
        isa => 'xs:unsignedInt'
    );

A 32-bit integer. Represented natively.

=head2 xs:short

    has 'short' => (
        is => 'rw',
        isa => 'xs:short'
    );

A 16-bit integer. Represented natively.

=head2 xs:unsignedShort

    has 'unsignedShort' => (
        is => 'rw',
        isa => 'xs:unsignedShort'
    );

A 16-bit integer. Represented natively.

=head2 xs:byte

    has 'byte' => (
        is => 'rw',
        isa => 'xs:byte'
    );

An 8-bit integer. Represented natively.

=head2 xs:unsignedByte

    has 'unsignedByte' => (
        is => 'rw',
        isa => 'xs:unsignedByte'
    );

An 8-bit integer. Represented natively.

=head2 xs:boolean

    has 'boolean' => (
        is => 'rw',
        isa => 'xs:boolean'
    );

A wrapper around built-in Bool.

=head2 xs:float

    has 'float' => (
        is => 'rw',
        isa => 'xs:float',
        coerce => 1,
    );

A single-precision 32-bit Float. Represented as a L<Math::BigFloat> object, but limited to the
32-bit range. Set to coerce from Num/Str.

=head2 xs:double

    has 'double' => (
        is => 'rw',
        isa => 'xs:double',
        coerce => 1,
    );

A double-precision 64-bit Float. Represented as a L<Math::BigFloat> object, but limited to the
64-bit range. Set to coerce from Num/Str.

=head2 xs:decimal

    has 'decimal' => (
        is => 'rw',
        isa => 'xs:decimal',
        coerce => 1,
    );

Any base-10 fixed-point number. Represented as a L<Math::BigFloat> object. Set to coerce from Num/Str.

=head2 xs:duration

    has 'duration' => (
        is => 'rw',
        isa => 'xs:duration',
        coerce => 1,
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime::Duration object.

=head2 xs:dateTime

    has 'datetime' => (
        is => 'rw',
        isa => 'xs:dateTime',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object.

=head2 xs:time

    has 'time' => (
        is => 'rw',
        isa => 'xs:time',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object.

=head2 xs:date

    has 'date'  => (
        is => 'rw',
        isa => 'xs:date',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object.

=head2 xs:gYearMonth

    has 'gYearMonth' => (
        is => 'rw',
        isa => 'xs:gYearMonth',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object or a ArrayRef of two
integers.

=head2 xs:gYear

    has 'gYear' => (
        is => 'rw',
        isa => 'xs:gYear',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object.

=head2 xs:gMonthDay

    has 'gMonthDay' => (
        is => 'rw',
        isa => 'xs:gMonthDay',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object or a ArrayRef of two
integers.

=head2 xs:gDay

    has 'gDay' => (
        is => 'rw',
        isa => 'xs:gDay',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object or Int eg. 24.

=head2 xs:gMonth

    has 'gMonth' => (
        is => 'rw',
        isa => 'xs:gMonth',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a DateTime object or Int eg. 10.

=head2 xs:base64Binary

    has 'base64Binary' => (
        is => 'rw',
        isa => 'xs:base64Binary',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a IO::Handle object - the content of the
file will be encoded to UTF-8 before encoding with base64.

=head2 xs:anyURI

    has 'anyURI' => (
        is => 'rw',
        isa => 'xs:anyURI',
        coerce => 1
    );

A wrapper around Str.
If you enable coerce you can pass a URI object.

=head1 SEE ALSO

=over 4

=item * Enable attributes coercion automatically with

L<MooseX::AlwaysCoerce>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

