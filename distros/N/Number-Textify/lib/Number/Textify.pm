package Number::Textify;
$Number::Textify::VERSION = '20200511';

use strict;
use utf8;
use warnings;

=encoding utf8

=head1 NAME

Number::Textify - turn number into some string.

=head1 VERSION

version 20200511

=head1 SYNOPSIS

  use Number::Textify ();

  my $time_converter = Number::Textify
    -> new( [ [ 60 * 60, 'hour' ],
              [ 60, 'minute' ],
              [ 0, 'second' ],
            ],

            skip_zeroes => 1,
          );

  print $time_converter -> textify( 7274 ); # 2 hours 1 minute 14 seconds


  my $time_converter_digital_neat = Number::Textify
    -> new( [ [ 24 * 60 * 60, '%dd ' ],
              [ 60 * 60, '%02d:' ],
              [ 60, '%02d:' ],
              [ 0, '%02d' ],
            ],

            joiner => '',
            formatter => sub { my $format = $_[ 1 ] // '%02d';
                               sprintf $format,
                                 $_[ 0 ];
                             },
            post_process => sub {
              $_[ 0 ] =~ s/^0+//;
              $_[ 0 ];
            },
          );

  print $time_converter_digital_neat -> textify( 10_000_000 ); # 115d 17:46:40


  my $size_converter = Number::Textify
    -> new( [ [ 1_024 * 1_024 * 1_024, '%.2f GiB' ],
              [ 1_024 * 1_024, '%.2f MiB' ],
              [ 1_024, '%.2f KiB' ],
              [ 0, '%d B' ],
            ],

            rounding => 1,
            formatter => sub { sprintf $_[ 1 ],
                                 $_[ 0 ];
                             },
          );

  print $size_converter -> textify( 10_000_000 ); # 9.54 MiB

=head1 DESCRIPTION

Number::Textify helps you to build and use converter of number to some text representation of it.

For example 10_000_000 can be represented as '115 days 17 hours 46 minutes 40 seconds', '115.7 days', '115d 17:46:40', '9.54 MiB' or '10.00 MB'.  You can see some examples in t/02-examples.t

This module uses object oriented approach and doesn't export anything.

=head1 OBJECT CREATION

=head2 new

Expects one required parameter and a hash of optional ones.  If some incorrectness detected, it dies.

First (and only required) parameter is an arrayref to arrayrefs.  First element in the nested arrayref is a positive number, which is a threshold for the range.  The rest of elements are passed to the formatter.  Arrayrefs should be sorted by the first element in descending order.

Range representation figured using the threshold is passed to the formatter along with the rest of elements in the nested arrayref.

Default formatter joins the range representation with the first of the rest of elements in the arrayref.  Unless range representation equals 1, adds 's' to the result.

If you need something else instead of that, you can pass a pair:

  formatter => sub { my ( $range_representation, @tail_of_nested_arrayref ) = @_; .. },

Then those formatted range representations are joined with the default joiner, which is ' ' (a space).  If you want to use another joiner, you can provide it as:

  joiner => ':',

Then the joined result is passed through the post_process sub, which by default doesn't change anything.  If you want to do some processing though, you can replace it:

  post_process => sub { my $result = shift; .. },

If you prefer to avoid zero values in the middle of result ( like '2 hours 0 minutes 14 seconds' ), you can use the option:

  skip_zeroes => 1,

If you don't want the exact representation, but only some rounding, there's an option for that:

  rounding => 1,

though in this case it usually has sense to provide a custom formatter too.

=cut

sub new {
  ref( my $class = shift )
    and die "I'm only a class method!";

  die 'Constructor expects at least one argument'
    unless @_ > 0;

  my $ranges = shift;

  die 'Incorrect number of additional parameters (hash expected)'
    if @_ % 2;

  my %arg = @_;

  # let's check that ranges are in the way we expect (as structure)
  die 'Ranges should be defined as array of arrays'
    unless $ranges
    && 'ARRAY' eq ref $ranges
    && @$ranges
    && ! grep( ! ( $_
                   && 'ARRAY' eq ref $_
                   && @$_ >= 1  # range cutoff, additional parameters (e. g. description string) for formatter
                   && $_ -> [ 0 ] >= 0 # range cutoff should be positive
                 ),
               @$ranges
             )
    ;

  # now let's check that ranges are in descending order
  my $prev_range = $ranges -> [ 0 ][ 0 ];
  for my $range
    ( @$ranges[ 1 .. $#$ranges ]
    ) {
    die 'Ranges should be defined in descending order'
      unless $prev_range > $range -> [ 0 ];

    $prev_range = $range -> [ 0 ];
  }

  my %self =
    ( ranges => $ranges,
      joiner => exists $arg{joiner} ? $arg{joiner} : ' ',
      skip_zeroes => exists $arg{skip_zeroes} ? !! $arg{skip_zeroes} : '',
      rounding => exists $arg{rounding} ? !! $arg{rounding} : '',

      map {
        exists $arg{ $_ }
          && $arg{ $_ }
          && 'CODE' eq ref $arg{ $_ } ?
          ( $_ => $arg{ $_ } )
          : ();
      }
      qw/ formatter
          post_process
        /,
    );

  bless \ %self, $class;
}

=head1 OBJECT METHODS

=head2 textify

Returns text presentation of the only one passed numeric parameter.

=cut

sub textify {
  ref( my $self = shift )
    or die "I'm only an object method!";

  my $value = shift;
  my $sign = '';
  if ( $value < 0
     ) {
    $sign = '-';
    $value *= -1;
  }

  my @result;

  for my $range
    ( @{ $self -> {ranges} }
    ) {
    my $t;
    ( $t, $value ) = $self -> _range_value( $value, $range -> [ 0 ] );
    if ( $t
         || ( @result
              && ! $self -> {skip_zeroes}
            )
       ) {
      push @result,
        $self -> _formatter( $t, @$range[ 1 .. $#$range ] );
    }

    last
      unless defined $value;
  }

  $self
    -> _post_process( ( $sign ? $sign : '' )
                      . join $self -> {joiner},
                      @result
                    );
}

sub _range_value { # returns numeric value for current range, value for the next range (undef if not needed to process further)
  my $self = shift;
  my $value = shift;
  my $range = shift;

  if ( $value >= $range
     ) {                        # there's something in this range
    my $value_for_range = $range ?
      $value / $range
      : $value;

    if ( $self -> {rounding}
       ) {                      # range value is rounded.  no need to continue
      ( $value_for_range, undef );
    } else {                    # range value is whole
      $value_for_range = int( $value_for_range );

      my $for_next_range = $range ?
        $value % $range
        : undef;

      ( $value_for_range, $for_next_range );
    }
  } else {                      # pass to the next range
    ( 0, $value );
  }
}

sub _formatter {
  my $self = shift;

  if ( $self -> {formatter}
     ) {
    $self -> {formatter} -> ( @_ );
  } else {
    my $value = shift;
    my $string = shift;

    sprintf '%s %s%s',
      $value,
      $string // '',
      $value == 1 ? '' : 's',
      ;
  }
}

sub _post_process {
  my $self = shift;

  if ( $self -> {post_process}
     ) {
    $self -> {post_process} -> ( @_ );
  } else {
    $_[ 0 ];
  }
}

=head1 AUTHOR

Valery Kalesnik, C<< <valkoles at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Valery Kalesnik.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
