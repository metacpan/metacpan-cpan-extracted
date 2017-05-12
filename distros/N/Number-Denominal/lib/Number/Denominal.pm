package Number::Denominal;

use strict;
use warnings;
use List::ToHumanString 1.002;
use Carp;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(denominal  denominal_hashref  denominal_list);

our $VERSION = '2.001001'; # VERSION

sub denominal {
    my ( $num, @den ) = @_;
    return _denominal( $num, \@den, 'string' );
}

sub denominal_list {
    my ( $num, @den ) = @_;
    return _denominal( $num, \@den, 'list' );
}

sub denominal_hashref {
    my ( $num, @den ) = @_;
    return _denominal( $num, \@den, 'hashref' );
}

sub _denominal {
    my ( $num, $den, $mode ) = @_;

    $num     =  abs $num;
    my $args = _prepare_extra_args( $den );
    $den     = _process_den( $mode, $den );

    my @bits;
    my $step = 1; # steps for precision, if enabled
    my $pre_bit;  # a "pre" bit, again for precision to handle rounding.
    my @ordered_bit_names; # need this for missing bits in denominal_list
    for my $bit ( _get_bits( @$den ) ) {
        push @ordered_bit_names, $bit->{name}[0];

        $bit->{num} = sprintf '%d', $num / $bit->{divisor};
        $num = $num - $bit->{num} * $bit->{divisor};

        if ( @bits
            and $args->{precision} and ++$step > $args->{precision}
        ) {
            last unless $bit->{num};

            # add current element and pre bit, for sake of calculations
            # I should really really refactor this crap to something sane
            unshift @bits, $pre_bit if defined $pre_bit;
            push @bits, +{ %$bit };

            for ( reverse 0 .. $#bits ) {
                # increase the previous number if we have to round
                $bits[$_-1]{num}++
                    if $bits[$_]{num} * $bits[$_]{divisor}
                        / $bits[$_-1]{divisor} >= 0.5;

                $bits[$_]{num} = 0
                    if $bits[$_]{num} * $bits[$_]{divisor}
                        / $bits[$_-1]{divisor} == 1;

                # stop checking previous numbers if we ran out of them
                # or they haven't reached their limit (divisor) yet.
                last if $_ == 0
                    or $bits[$_-1]{num} * $bits[$_-1]{divisor}
                        < $bits[$_-2]{divisor};
            }

            # pop last element off, since it was temporary
            pop @bits;

            # get rid of els with zero nums (including pre bit)
            @bits = grep $_->{num}, @bits;
            last;
        }

        $pre_bit = $bit unless $bit->{num};
        $bit->{num} or next; # don't insert the bit, if it's zero
        push @bits, +{ %$bit };
    }

    my @result;
    # process the bits into output format, depending on what type
    # ... of output is wanted
    for ( @bits ) {
        push @result, $mode eq 'hashref' ? ( $_->{name}[0] => $_->{num} )
            : $mode eq 'list' ? { num => $_->{num}, name => $_->{name}[0] }
                : $_->{num} . ' ' . $_->{name}[ $_->{num} == 1 ? 0 : 1 ];
    }

    if ( $mode eq 'list' ) {
        my @temp_result = @result;
        @result = ();
        my %bits_in_result;
        @bits_in_result{ map $_->{name}, @temp_result }
        = map $_->{num}, @temp_result;

        for ( @ordered_bit_names ) {
            push @result, exists $bits_in_result{ $_ }
                ? $bits_in_result{ $_ } : 0;
        }
    }

    return $mode eq 'hashref'
        ? +{@result} :
            $mode eq 'list'
                ? @result : to_human_string '|list|', @result;
}

sub _get_bits {
    my @den = @_;

    my @bits;
    my $divisor = 1;
    for ( grep !($_%2), 0..$#den ) {
        if ( not ref $den[ $_ ] ) {
            $den[ $_ ] = [
                $den[ $_ ],
                $den[ $_ ] . 's',
            ];
        }

        push @bits, {
            name    => $den[ $_ ],
            divisor => $divisor,
        };

        $divisor *= $den[ $_+1 ] || 1;
    }

    return reverse @bits;
}

sub _process_den {
    my ( $mode, $den ) = @_;

    if ( @$den == 1 and ref $den->[0] eq 'ARRAY' ) {
        my $idx = 0;
        @$den = map +( 'el' . $idx++ => $_ ), @{ $den->[0] };
        push @$den, 'el', $idx;
        $mode = 'list';
    }
    elsif ( @$den == 1 and ref $den->[0] eq 'SCALAR' ) {
        my $unit_shortcut = ${ $den->[0] };
        my $values_for_unit = _get_units()->{ $unit_shortcut };

        croak qq{Unknown unit shortcut ``$unit_shortcut''}
            unless $values_for_unit;
        $den = $values_for_unit;
    }

    return $den;
}

sub _prepare_extra_args {
    my $den = shift;

    return unless ref $den->[-1] eq 'HASH';

    my %extra_args = %{ delete $den->[-1] };

    if ( exists $extra_args{precision} ) {
        my $p = $extra_args{precision};
        croak q{precision argument takes positive integers only,}
            . q{ but its value is } . (defined $p ? $p : '[undefined]')
            unless $p and $p =~ /\A\d+\z/;
    }

    return \%extra_args;
}

sub _get_units {
    return {
        time    => [
            second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
        ],
        weight  => [
            gram => 1000 => kilogram => 1000 => 'tonne',
        ],
        weight_imperial => [
           ounce => 16 => pound => 14 => stone => 160 => 'ton',
        ],
        length  => [
           meter => 1000 => kilometer => 9_460_730_472.5808 => 'light year',
        ],
        length_mm  => [
           millimeter => 10 => centimeter => 100 => meter => 1000
                => kilometer => 9_460_730_472.5808 => 'light year',
        ],
        length_imperial => [
            [qw/inch  inches/] => 12 =>
                [qw/foot  feet/] => 3 => yard => 1760
                    => [qw/mile  miles/],
        ],
        volume => [
           milliliter => 1000 => 'Liter',
        ],
        volume_imperial => [
           'fluid ounce' => 20 => pint => 2 => quart => 4 => 'gallon',
        ],
        info => [
            bit => 8 => byte => 1000 => kilobyte => 1000 => megabyte => 1000
                => gigabyte => 1000 => terabyte => 1000 => petabyte => 1000
                    => exabyte => 1000 => zettabyte => 1000 => 'yottabyte',
        ],
        info_1024  => [
            bit => 8 => byte => 1024 => kibibyte => 1024 => mebibyte => 1024
                => gibibyte => 1024 => tebibyte => 1024 => pebibyte => 1024
                    => exbibyte => 1024 => zebibyte => 1024 => 'yobibyte',
        ],
    };
}

q|
  Q: how many programmers does it take to change a light bulb?
  A: none, that's a hardware problem
|;

__END__

=encoding utf8

=for stopwords LeoNerd scalarref

=head1 NAME

Number::Denominal - break up numbers into arbitrary denominations

=head1 SYNOPSIS


    use Number::Denominal;

    my ( $sec, $min, $hr ) = (localtime)[0..2];
    my $seconds = $hr*3600 + $min*60 + $sec;

    print 'So far today you lived for ',
        denominal($seconds,
            [ qw/second seconds/ ] =>
                60 => [ qw/minute minutes/ ] =>
                    60 => [ qw/hour hours/ ]
        ) . "\n";
    ## Prints: So far today you lived for 23 hours,
    ## 48 minutes, and 23 seconds

    # Same thing but with a 'time' unit set shortcut:
    print 'So far today you lived for ', denominal($seconds, \'time');

    print 'If there were 100 seconds in a minute, and 100 minutes in an hour,',
        ' then you would have lived today for ',
        denominal(
            # This is a shortcut for units that pluralize by adding "s"
            $seconds, second => 100 => minute => 100 => 'hour',
        ) . "\n";
    ## Prints: If there were 100 seconds in a minute, and 100 minutes
    ## in an hour, then you would have lived today for 8 hours, 57 minutes,
    ## and 3 seconds

    print 'And if we called seconds "foos," minutes "bars," and hours "bers"',
        ' then you would have lived today for ',
        denominal(
            $seconds, foo => 100 => bar => 100 => 'ber',
        ) . "\n";
    ## Prints: And if we called seconds "foos," minutes "bars," and hours
    ## "bers" then you would have lived today for 8 bers, 57 bars, and 3 foos

    ## You can get the denominalized data as a list:
    my @data = denominal_list(
        $seconds, foo => 100 => bar => 100 => 'ber',
    );

    ## Or same thing as a shorthand:
    my @data = denominal_list(  $seconds, [ 100, 100 ], );

    ## Or get the data as a hashref:
    my $data = denominal_hashref(
        $seconds, foo => 100 => bar => 100 => 'ber',
    );

    # We can also handle precision (with rounding):
    print denominal( 3*3600 + 31*60 + 40, \'time', { precision => 2 } );
    # Prints '3 hours and 32 minutes'

=head1 DESCRIPTION

Define arbitrary set of units and split up a number into those units.

This module arose from a discussion in IRC, regarding splitting
a number of seconds into minutes, hours, days...
L<Paul 'LeoNerd' Evans|https://metacpan.org/author/PEVANS> brought up
the idea for L<Number::Denominal> that would split up a number into any
arbitrarily defined arbitrary units and I am the code monkey that
released it.

=head1 EXPORTS

=head2 C<denominal>

    ## All these are equivalent:

    my $string = denominal( $number, \'time' );

    my $string = denominal(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/hour hours/ ] =>
                    24 => day => 7 => 'week',
    );


    # Specify precision:
    my $string = denominal( $number, \'time', { precision => 2 } );

Breaks up the number into given denominations and B<returns> it as a
human-readable string (e.g. C<"5 hours, 22 minutes, and 4 seconds">.
If the value for any unit ends up being zero, that unit will be omitted
(an empty string will be returned if the given number is zero).

B<The first argument> is the number that needs to be broken up into units.
Negative numbers will be C<abs()'ed>.

B<The other arguments> are given as a list and
define unit denominations. The list of denominations should start
with a unit name and end with a unit name, and each unit name must be
separated by a number that represents how many left-side units fit into the
right-side unit. B<Unit name> can be an arrayref, a simple string,
or a scalarref. The meaning is as follows:

B<The last argument> is optional and, if present, is given as a
hashref. It specifies various options. See C<OPTIONS HASHREF> section
below for possible values.

=head3 an arrayref

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/foo bar/ ]
    );

The arrayref must have two elements. The first element is a string
that is the singular name of the unit. The second element is a string
that is the plural name of the unit Arrayref unit names can be mixed
with simple-string unit names.

=head3 a simple string

    # These are the same:

    my $string = denominal( $number, second => 60 => 'minute' );

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] => 60 => [ qw/minute minutes/ ]
    );

When a unit name is a simple string, it's taken as a shortcut for
an arrayref unit name with this simple string as the first element
in that arrayref and the string with letter "s" added at the end as the
second element. (Basically a shortcut for typing units that pluralize
by adding "s" to the end).

=head3 a scalarref

    ## All these are the same:

    my $string = denominal( $number, \'time' );

    my $string = denominal(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

Instead of giving a list of unit names and their denominations, you
can pass a scalarref as the second argument to C<denominal()>. The
value of the scalar that scalarref references is the name of a unit
set shortcut. Currently available unit sets and their definitions are as
follows:

=head4 C<time>

    time    => [
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    ],

=head4 C<weight>

    weight  => [
        gram => 1000 => kilogram => 1000 => 'tonne',
    ],

=head4 C<weight_imperial>

    weight_imperial => [
       ounce => 16 => pound => 14 => stone => 160 => 'ton',
    ],

=head4 C<length>

    length  => [
       meter => 1000 => kilometer => 9_460_730_472.5808 => 'light year',
    ],

=head4 C<length_mm>

    length_mm  => [
       millimeter => 10 => centimeter => 100 => meter => 1000
            => kilometer => 9_460_730_472.5808 => 'light year',
    ],

=head4 C<length_imperial>

    length_imperial => [
        [qw/inch  inches/] => 12 =>
            [qw/foot  feet/] => 3 => yard => 1760
                => [qw/mile  miles/],
    ],

=head4 C<volume>

    volume => [
       milliliter => 1000 => 'Liter',
    ],

=head4 C<volume_imperial>

    volume_imperial => [
       'fluid ounce' => 20 => pint => 2 => quart => 4 => 'gallon',
    ],

=head4 C<info>

    info => [
        bit => 8 => byte => 1000 => kilobyte => 1000 => megabyte => 1000
            => gigabyte => 1000 => terabyte => 1000 => petabyte => 1000
                => exabyte => 1000 => zettabyte => 1000 => 'yottabyte',
    ],

=head4 C<info_1024>

    info_1024  => [
        bit => 8 => byte => 1024 => kibibyte => 1024 => mebibyte => 1024
            => gibibyte => 1024 => tebibyte => 1024 => pebibyte => 1024
                => exbibyte => 1024 => zebibyte => 1024 => 'yobibyte',
    ],

=head3 OPTIONS HASHREF

    my $string = denominal( $number, \'time', { precision => 2 } );

    my $string = denominal(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
        { precision => 2 },
    );

    my $string = denominal(
        $number,
        [ qw/second seconds/ ] =>
            60 => [ qw/minute minutes/ ] =>
                60 => [ qw/hour hours/ ] =>
                    24 => day => 7 => 'week',
        { precision => 2 },
    );

If the last argument to C<denominal()> (or C<denominal_hashref()>
or C<denominal_list()>) is a hashref, its contents will be interpreted
as various options, dictating specifics of how the number should be
denominated. Currently supported values are as follows:

=head4 C<precision>

    my $string = denominal( $number, \'time', { precision => 2 } );

B<Takes> a positive integer as a value. Specifies precision of output.
This means the output will have at most C<precision> number of different
units. B<Rounding> is in place for units smaller than C<precision>.

For example,

    denominal( 3*3600 + 31*60 + 1, \'time', );

will output C<3 hours, 31 minutes, and 1 second>. If we set C<precision>to
C<2> units:

    denominal( 3*3600 + 31*60 + 40, \'time', { precision => 2 } );

The output will be C<3 hours and 32 minutes> (note how the minutes got
rounded, because 40 seconds is more than half a minute). Further, if
we set C<precision> to C<1> unit:

    denominal( 3*3600 + 31*60 + 1, \'time', { precision => 1} );

We'll get C<4 hours> as output.

It is possible to get fewer than C<precision> units in the output, even
if without precision you'd get more than 1. For example,

    denominal( 23*3600 + 59*60 + 59, \'time', );

Would output C<23 hours, 59 minutes, and 59 seconds>. Now, if we set
C<precision> to C<2> units:

    denominal( 23*3600 + 59*60 + 59, \'time', { precision => 2 } );

The output will be C<1 day>. What happens is a 2-unit precision rounds
off to C<23 hours and 60 seconds>, which rounds off to C<24 hours>, and
we have a larger unit that is equal to 24 hours: C<1 day>.

For C<denominal_list>, C<precision> affects how many units can have
values other than zero. Units outside C<precision> will have their values
as zero.

=head2 C<denominal_list>

    ## These two are equivalent

    my @bits = denominal_list(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );
    ## @bits will always contain 5 elements, some of which might be 0


    my @bits = denominal_list(
        $number,
        [ qw/60  60  24  7/ ],
    );

Functions the same as C<denominal()>, except it B<returns> a list of unit
values, instead of a string. (e.g. when C<denominal()> would return
"8 hours, 23 minutes, and 5 seconds", C<denominal_list()> would return
a list of numbers—C<8, 23, 5>—for hours, minutes, seconds, and
C<0> B<for all the remaining units>).

Another shortcut is possible with C<denominal_list()>. Instead of giving
each unit a name, you can call C<denominal_list()> with just
B<two arguments> and pass an arrayref as the second
argument, containing a list of numbers defining unit denominations.

B<Note on precision:> if you're using C<precision> argument to specify
the precision of units (see its description in L<OPTIONS HASHREF>
section above), then it will affect how many units will have values
other than zeros; i.e. you'll still have the same number of elements
as without C<precision>.

=head2 C<denominal_hashref>

    ## These two are equivalent

    my $data = denominal_hashref(
        $number,
        second => 60 => minute => 60 => hour => 24 => day => 7 => 'week'
    );

    say "The number has $data->{second} seconds and $data->{week} weeks!";

Functions the same as C<denominal()>, except it B<returns> a hashref
where the keys are the B<singular> names of the units and values are
the numerical values of each unit. If a unit's value is zero, its key
will be absent from the hashref.

=head1 AUTHORS

=over 4

=item * B<Idea:> Paul Evans, C<< <pevans at cpan.org> >>

=item * B<Code:> Zoffix Znet, C<< <zoffix at cpan.org> >>

=back

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Number-Denominal>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Number-Denominal/issues>

If you can't access GitHub, you can email your request
to C<bug-Number-Denominal at rt.cpan.org>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
