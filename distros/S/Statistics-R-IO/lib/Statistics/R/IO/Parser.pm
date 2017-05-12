package Statistics::R::IO::Parser;
# ABSTRACT: Functions for parsing R data files
$Statistics::R::IO::Parser::VERSION = '1.0001';
use 5.010;
use strict;
use warnings FATAL => 'all';

use Exporter 'import';

our @EXPORT = qw( );
our @EXPORT_OK = qw( endianness any_char char string
                     any_uint8 any_uint16 any_uint24 any_uint32 any_real32 any_real64 any_real64_na
                     uint8 uint16 uint24 uint32
                     any_int8 any_int16 any_int24 any_int32 any_int32_na
                     int8 int16 int24 int32
                     count with_count many_till seq choose mreturn error add_singleton get_singleton reserve_singleton bind );

our %EXPORT_TAGS = ( all => [ @EXPORT_OK ],
                     num => [ qw( any_uint8 any_uint16 any_uint24 any_uint32 any_int32_na any_real32 any_real64 any_real64_na uint8 uint16 uint24 uint32 ) ],
                     char => [ qw( any_char char string ) ],
                     combinator => [ qw( count with_count many_till seq choose mreturn bind ) ] );


use Scalar::Util qw(looks_like_number);
use Carp;

sub endianness {
    state $endianness = '>';
    my $new_value = shift if @_ or return $endianness;
    $endianness = $new_value =~ /^[<>]$/ && $new_value || $endianness;
}


sub any_char {
    my $state = shift;

    return undef if !$state || $state->eof;
    
    [$state->at, $state->next]
}


sub char {
    my $arg = shift;
    die 'Must be a single-char argument: ' . $arg unless length($arg) == 1;
    
    sub {
        my $state = shift or return;
        return if $state->eof || $arg ne $state->at;
        
        [ $arg, $state->next ]
    }
}


sub string {
    my $arg = shift;
    die 'Must be a scalar argument: ' . $arg unless $arg && !ref($arg);
    my $chars = count(length($arg), \&any_char);

    sub {
        my ($char_values, $state) = @{$chars->(@_) or return};
        return unless join('', @{$char_values}) eq $arg;
        [ $arg, $state ]
    }
}


sub any_uint8 {
    my ($value, $state) = @{any_char @_ or return};
    
    [ unpack('C', $value), $state ]
}


sub any_uint16 {
    my ($value, $state) = @{count(2, \&any_uint8)->(@_) or return};
    
    [ unpack("S" . endianness, pack 'C2' => @{$value}),
      $state ]
}


sub any_uint24 {
    my ($value, $state) = @{count(3, \&any_uint8)->(@_) or return};
    
    [ unpack("L" . endianness,
             pack(endianness eq '>' ? 'xC3' : 'C3x', @{$value})),
      $state ]
}


sub any_uint32 {
    my ($value, $state) = @{count(4, \&any_uint8)->(@_) or return};
    
    [ unpack("L" . endianness, pack 'C4' => @{$value}),
      $state ]
}


sub uint8 {
    my $arg = shift;
    die 'Argument must be a number 0-255: ' . $arg
        unless looks_like_number($arg) && $arg <= 0x000000FF && $arg >= 0;
    
    sub {
        my ($value, $state) = @{any_uint8 @_ or return};
        return unless $arg == $value;
        
        [ $arg, $state ]
    }
}


sub uint16 {
    my $arg = shift;
    die 'Argument must be a number 0-65535: ' . $arg
        unless looks_like_number($arg) && $arg <= 0x0000FFFF && $arg >= 0;
    
    sub {
        my ($value, $state) = @{any_uint16 @_ or return};
        return unless $arg == $value;
        
        [ $arg, $state ]
    }
}


sub uint24 {
    my $arg = shift;
    die 'Argument must be a number 0-16777215: ' . $arg
        unless looks_like_number($arg) && $arg <= 0x00FFFFFF && $arg >= 0;
    
    sub {
        my ($value, $state) = @{any_uint24 @_ or return};
        return unless $arg == $value;
        
        [ $arg, $state ]
    }
}


sub uint32 {
    my $arg = shift;
    die 'Argument must be a number 0-4294967295: ' . $arg
        unless looks_like_number($arg) && $arg <= 0xFFFFFFFF && $arg >= 0;
    
    sub {
        my ($value, $state) = @{any_uint32 @_ or return};
        return unless $arg == $value;
        
        [ $arg, $state ]
    }
}


sub any_int8 {
    my ($value, $state) = @{any_char @_ or return};
    
    [ unpack('c', $value), $state ]
}


sub any_int16 {
    my ($value, $state) = @{any_uint16 @_ or return};
    
    $value |= 0x8000 if ($value >= 1<<15);
    [ unpack('s', pack 's' => $value),
      $state ]
}


sub any_int24 {
    my ($value, $state) = @{any_uint24 @_ or return};
    
    $value |= 0xff800000 if ($value >= 1<<23);
    [ unpack('l', pack 'l' => $value),
      $state ]
}


sub any_int32 {
    my ($value, $state) = @{any_uint32 @_ or return};
    
    $value |= 0x80000000 if ($value >= 1<<31);
    [ unpack('l', pack 'l' => $value),
      $state ]
}


sub int8 {
    my $arg = shift;
    die 'Argument must be a number -128-127: ' . $arg
        unless looks_like_number($arg) && $arg < 1<<7 && $arg >= -(1<<7);
    
    sub {
        my ($value, $state) = @{any_int8 @_ or return};
        return unless $arg == $value;
        
        [ $arg, $state ]
    }
}


sub int16 {
    my $arg = shift;
    die 'Argument must be a number -32768-32767: ' . $arg
        unless looks_like_number($arg) && $arg < 1<<15 && $arg >= -(1<<15);
    
    sub {
        my ($value, $state) = @{any_int16 @_ or return};
        return unless $arg == $value;
        
        [ $arg, $state ]
    }
}


sub int24 {
    my $arg = shift;
    die 'Argument must be a number 0-16777215: ' . $arg
        unless looks_like_number($arg) && $arg < 1<<23 && $arg >= -(1<<23);
    
    sub {
        my ($value, $state) = @{any_int24 @_ or return};
        return unless $arg == $value;
        
        [ $arg, $state ]
    }
}


sub int32 {
    my $arg = shift;
    die 'Argument must be a number -2147483648-2147483647: ' . $arg
        unless looks_like_number($arg) && $arg < 1<<31 && $arg >= -(1<<31);
    
    sub {
        my ($value, $state) = @{any_int32 @_ or return};
        return unless $arg == $value;
        
        [ $arg, $state ]
    }
}


sub any_int32_na {
    choose(&bind(int32(-2147483648),
                 sub {
                     mreturn(undef);
                 }),
           \&any_int32)
}

my %na_real = ( '>' => [ uint32(0x7ff00000),
                         uint32(0x7a2) ],
                '<' => [ uint32(0x7a2),
                         uint32(0x7ff00000) ]);

sub any_real64_na {
    choose(&bind(seq(@{$na_real{endianness()}}),
                 sub {
                     mreturn(undef);
                 }),
           \&any_real64)
}


sub any_real32 {
    my ($value, $state) = @{count(4, \&any_uint8)->(@_) or return};
    
    [ unpack("f" . endianness, pack 'C4' => @{$value}),
      $state ]
}


sub any_real64 {
    my ($value, $state) = @{count(8, \&any_uint8)->(@_) or return};
    
    [ unpack("d" . endianness, pack 'C8' => @{$value}),
      $state ]
}


sub count {
    my ($n, $parser) = (shift, shift);
    sub {
        my $state = shift;
        my @value;

        for (1..$n) {
            my $result = $parser->($state) or return;

            push @value, shift @$result;
            $state = shift @$result;
        }

        return [ [ @value ], $state ];
    }
}


sub seq {
    my @parsers = @_;
    
    sub {
        my $state = shift;
        my @value;

        foreach my $parser (@parsers) {
            my $result = $parser->($state) or return;

            push @value, shift @$result;
            $state = shift @$result;
        }

        return [ [ @value ], $state ];
    }
}


sub many_till {
    my ($p, $end) = (shift, shift);
    die "'bind' expects two arguments" unless $p && $end;
    
    sub {
        my $state = shift or return;
        my @value;

        until ($end->($state)) {
            my $result = $p->($state) or return;
            
            push @value, shift @$result;
            $state = shift @$result;
        }
        
        return [ [ @value ], $state ]
    }
}


sub choose {
    my @parsers = @_;
    
    sub {
        my $state = shift or return;
        
        foreach my $parser (@parsers) {
            my $result = $parser->($state);
            return $result if $result;
        }
        
        return;
    }
}


sub mreturn {
    my $arg = shift;
    sub {
        [ $arg, shift ]
    }
}


sub error {
    my $message = shift;
    sub {
        my $state = shift;
        croak $message . " (at " . $state->position . ")";
    }
}


sub add_singleton {
    my $singleton = shift;
    sub {
        [ $singleton, shift->add_singleton($singleton) ]
    }
}


sub get_singleton {
    my $ref_id = shift;
    sub {
        my $state = shift;
        [ $state->get_singleton($ref_id), $state ]
    }
}


## Preallocates a space for a singleton before running a given parser,
## and then assigns the parser's value to the singleton.
sub reserve_singleton {

    my $p = shift;
    &bind(
        seq(
            sub {
                my $state = shift;
                my $ref_id = scalar(@{$state->singletons});
                my $new_state = $state->add_singleton(undef);
                [ $ref_id, $new_state ]
            },
            $p),
        sub {
            my ($ref_id, $value) = @{shift()};
            sub {
                my $state = shift;
                $state->singletons->[$ref_id] = $value;
                [ $value, $state ]
            }
        })
}


sub bind {
    my ($p1, $fp2) = (shift, shift);
    die "'bind' expects two arguments" unless $p1 && $fp2;
    
    sub {
        my $v1 = $p1->(shift or return);
        my ($value, $state) = @{$v1 or return};
        $fp2->($value)->($state)
    }
}


sub with_count {
    die "'bind' expects one or two arguments"
        unless @_ and scalar(@_) <= 2;

    unshift(@_, \&any_uint32) if (scalar(@_) == 1);
    my ($counter, $content) = (shift, shift);

    &bind($counter,
          sub {
              my $n = shift;
              count($n, $content)
          })
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::IO::Parser - Functions for parsing R data files

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::IO::ParserState;
    use Statistics::R::IO::Parser;
    
    my $state = Statistics::R::IO::ParserState->new(
        data => 'file.rds'
    );
    say $state->at
    say $state->next->at;

=head1 DESCRIPTION

You shouldn't create instances of this class, it exists mainly to
handle deserialization of R data files by the C<IO> classes.

=head1 FUNCTIONS

This library is inspired by monadic parser frameworks from the
Haskell world, like L<Packrat|http://bford.info/packrat/> or
L<Parsec|http://hackage.haskell.org/package/parsec>. What this means
is that I<parsers> are constructed by combining simpler parsers.

The library offers a selection of basic parsers and combinators.
Each of these is a function (think of it as a factory) that returns
another function (the actual parser) which receives the current
parsing state (L<Statistics::R::IO::ParserState>) as the argument
and returns a two-element array reference (called for brevity "a
pair" in the following text) with the result of the parser in the
first element and the new parser state in the second element. If the
I<parser> fails, say if the current state is "a" where a number is
expected, it returns C<undef> to signal failure.

The descriptions of individual functions below use a shorthand
because the above mechanism is implied. Thus, when C<any_char> is
described as "parses any character", it really means that calling
C<any_char> will return a function that when called with the current
state will return "a pair of the character...", etc.

=head2 CHARACTER PARSERS

=over

=item any_char

Parses any character, returning a pair of the character at the current
State's position and the new state, advanced by one from the starting
state. If the state is at the end (C<$state->eof> is true), returns
undef to signal failure.

=item char $c

Parses the given character C<$c>, returning a pair of the character at
the current State's position if it is equal to C<$c> and the new
state, advanced by one from the starting state. If the state is at the
end (C<$state->eof> is true) or the character at the current position
is not C<$c>, returns undef to signal failure.

=item string $s

Parses the given string C<$s>, returning a pair of the sequence of
characters starting at the current State's position if it is equal to
C<$s> and the new state, advanced by C<length($s)> from the starting
state. If the state is at the end (C<$state->eof> is true) or the
string starting at the current position is not C<$s>, returns undef to
signal failure.

=back

=head2 NUMBER PARSERS

=over

=item endianness [$end]

When the C<$end> argument is given, this functions sets the byte
order used by parsers in the module to be little- (when C<$end> is
"E<lt>") or big-endian (C<$end> is "E<gt>"). This function changes
the B<module's> state and remains in effect until the next change.

When called with no arguments, C<endianness> returns the current
byte order in effect. The starting byte order is big-endian.

=item any_uint8, any_uint16, any_uint24, any_uint32

Parses an 8-, 16-, 24-, and 32-bit I<unsigned> integer, returning a
pair of the integer starting at the current State's position and the
new state, advanced by 1, 2, 3, or 4 bytes from the starting state,
depending on the parser. The integer value is determined by the
current value of C<endianness>. If there are not enough elements left
in the data from the current position, returns undef to signal
failure.

=item uint8 $n, uint16 $n, uint24 $n, uint32 $n

Parses the specified 8-, 16-, 24-, and 32-bit I<unsigned> integer
C<$n>, returning a pair of the integer at the current State's
position if it is equal C<$n> and the new state. The new state is
advanced by 1, 2, 3, or 4 bytes from the starting state, depending
on the parser. The integer value is determined by the current value
of C<endianness>. If there are not enough elements left in the data
from the current position or the current position is not C<$n>,
returns undef to signal failure.

=item any_int8, any_int16, any_int24, any_int32

Parses an 8-, 16-, 24-, and 32-bit I<signed> integer, returning a pair
of the integer starting at the current State's position and the new
state, advanced by 1, 2, 3, or 4 bytes from the starting state,
depending on the parser. The integer value is determined by the
current value of C<endianness>. If there are not enough elements left
in the data from the current position, returns undef to signal
failure.

=item int8 $n, int16 $n, int24 $n, int32 $n

Parses the specified 8-, 16-, 24-, and 32-bit I<signed> integer
C<$n>, returning a pair of the integer at the current State's
position if it is equal C<$n> and the new state. The new state is
advanced by 1, 2, 3, or 4 bytes from the starting state, depending
on the parser. The integer value is determined by the current value
of C<endianness>. If there are not enough elements left in the data
from the current position or the current position is not C<$n>,
returns undef to signal failure.

=item any_real32, any_real64

Parses an 32- or 64-bit real number, returning a pair of the number
starting at the current State's position and the new state, advanced
by 4 or 8 bytes from the starting state, depending on the parser. The
real value is determined by the current value of C<endianness>. If
there are not enough elements left in the data from the current
position, returns undef to signal failure.

=item any_int32_na, any_real64_na

Parses a 32-bit I<signed> integer or 64-bit real number, respectively,
but recognizing R-style missing values (NAs): INT_MIN for integers and
a special NaN bit pattern for reals. Returns a pair of the number
value (C<undef> if a NA) and the new state, advanced by 4 or 8 bytes
from the starting state, depending on the parser. If there are not
enough elements left in the data from the current position, returns
undef to signal failure.

=back

=head2 SEQUENCING

=over

=item seq $p1, ...

This combinator applies parsers C<$p1>, ... in sequence, using the
returned parse state of C<$p1> as the input parse state to C<$p2>,
etc.  Returns a pair of the concatenation of all the parsers'
results and the parsing state returned by the final parser. If any
of the parsers returns undef, C<seq> will return it immediately
without attempting to apply any further parsers.

=item many_till $p, $end

This combinator applies a parser C<$p> until parser C<$end> succeeds.
It does this by alternating applications of C<$end> and C<$p>; once
C<$end> succeeds, the function returns the concatenation of results of
preceding applications of C<$p>. (Thus, if C<$end> succeeds
immediately, the 'result' is an empty list.) Otherwise, C<$p> is
applied and must succeed, and the procedure repeats. Returns a pair of
the concatenation of all the C<$p>'s results and the parsing state
returned by the final parser. If any applications of C<$p> returns
undef, C<many_till> will return it immediately.

=item count $n, $p

This combinator applies the parser C<$p> exactly C<$n> times in
sequence, threading the parse state through each call.  Returns a
pair of the concatenation of all the parsers' results and the
parsing state returned by the final application. If any application
of C<$p> returns undef, C<count> will return it immediately without
attempting any more applications.

=item with_count [$num_p = any_uint32], $p

This combinator first applies parser C<$num_p> to get the number of
times that C<$p> should be applied in sequence. If only one argument
is given, C<any_uint32> is used as the default value of C<$num_p>.
(So C<with_count> works by getting a number I<$n> by applying
C<$num_p> and then calling C<count $n, $p>.) Returns a pair of the
concatenation of all the parsers' results and the parsing state
returned by the final application. If the initial application of
C<$num_p> or any application of C<$p> returns undef, C<with_count>
will return it immediately without attempting any more applications.

=item choose $p1, ...

This combinator applies parsers C<$p1>, ... in sequence, until one
of them succeeds, when it immediately returns the parser's result.
If all of the parsers fail, C<choose> fails and returns undef

=back

=head2 COMBINATORS

=over

=item bind $p1, $f

This combinator applies parser C<$p1> and, if it succeeds, calls
function C<$f> using the first element of C<$p1>'s result as the
argument. The call to C<$f> needs to return a parser, which C<bind>
applies to the parsing state after C<$p1>'s application.

The C<bind> combinator is an essential building block for most
combinators described so far. For instance, C<with_count> can be
written as:

    bind($num_p,
         sub {
             my $n = shift;
             count $n, $p;
         })

=item mreturn $value

Returns a parser that when applied returns C<$value> without
changing the parsing state.

=item error $message

Returns a parser that when applied croaks with the C<$message> and
the current parsing state.

=back

=head2 SINGLETONS

These functions are an interface to L<ParseState>'s
singleton-related functions, L<ParseState/add_singleton> and
L<ParseState/get_singleton>. They exist because certain types of
objects in R data files, for instance environments, have to exist as
unique instances, and any subsequent objects that include them refer
to them by a "reference id".

=over

=item add_singleton $singleton

Adds the C<$singleton> to the current parsing state.  Returns a pair
of C<$singleton> and the new parsing state.

=item get_singleton $ref_id

Retrieves from the current parse state the singleton identified by
C<$ref_id>, returning a pair of the singleton and the (unchanged)
state.

=item reserve_singleton $p

Preallocates a space for a singleton before running a given parser,
and then assigns the parser's value to the singleton. Returns a pair
of the singleton and the new parse state.

=back

=head1 BUGS AND LIMITATIONS

Instances of this class are intended to be immutable. Please do not
try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
