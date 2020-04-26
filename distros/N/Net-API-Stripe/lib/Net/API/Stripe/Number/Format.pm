##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Number/Format.pm
## Version 0.2
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/04/24
## Modified 2020/04/25
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Number::Format;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use POSIX qw( localeconv );
    our $VERSION = '0.2';
};

{
    our $DEFAULT_LOCALE =
    {
    currency_symbol   => '$',
    decimal_digits    => '2',
    decimal_fill      => '0',
    decimal_point     => '.',
    frac_digits       => '2',
    gibi_suffix       => 'GiB',
    giga_suffix       => 'G',
    grouping          => undef(),
    int_curr_symbol   => 'USD',
    int_frac_digits   => '2',
    kibi_suffix       => 'KiB',
    kilo_suffix       => 'K',
    mebi_suffix       => 'MiB',
    mega_suffix       => 'M',
    mon_decimal_point => '.',
    mon_grouping      => undef(),
    mon_thousands_sep => ',',
    n_cs_precedes     => '1',
    n_sep_by_space    => '1',
    n_sign_posn       => '1',
    neg_format        => '-x',
    negative_sign     => '-',
    p_cs_precedes     => '1',
    p_sep_by_space    => '1',
    p_sign_posn       => '1',
    positive_sign     => '',
    thousands_sep     => ',',
    };
    # On Windows, the POSIX localeconv() call returns illegal negative
    # numbers for some values, seemingly attempting to indicate null.  The
    # following list indicates the values for which this has been
    # observed, and for which the values should be stripped out of
    # localeconv().
    #
    our @IGNORE_NEGATIVE = qw( frac_digits int_frac_digits
                               n_cs_precedes n_sep_by_space n_sign_posn
                               p_xs_precedes p_sep_by_space p_sign_posn );

    # Largest integer a 32-bit Perl can handle is based on the mantissa
    # size of a double float, which is up to 53 bits.  While we may be
    # able to support larger values on 64-bit systems, some Perl integer
    # operations on 64-bit integer systems still use the 53-bit-mantissa
    # double floats.  To be safe, we cap at 2**53; use Math::BigFloat
    # instead for larger numbers.
    #
    use constant MAX_INT => 2**53;
}

sub init
{
    my $self = shift( @_ );
    $self->{debug} = 3;
    my $opts = {};
    if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
    {
        $opts = shift( @_ );
    }
    elsif( !( @_ % 2 ) )
    {
        $opts = { @_ };
    }
    else
    {
        my @args = @_;
        return( $self->error( "Unknown parameters set provided to create a number format object: ", sub{ $self->dumper( \@args ) } ) );
    }
    
    my @keys = keys( %$DEFAULT_LOCALE );
    ## Copy default values
    @$self{ @keys } = @$DEFAULT_LOCALE{ @keys };
    
    my $locale_values = POSIX::localeconv();
    # Strip out illegal negative values from the current locale
    foreach( @IGNORE_NEGATIVE )
    {
        if( defined( $locale_values->{ $_ } ) && $locale_values->{ $_ } eq '-1' )
        {
            delete( $locale_values->{ $_ } );
        }
    }
    my @locales = keys( %$locale_values );
    for( @locales )
    {
        delete( $locale_values->{ $_ } ) if( !exists( $DEFAULT_LOCALE->{ $_ } ) );
    }
    # Some broken locales define the decimal_point but not the
    # thousands_sep.  If decimal_point is set to "," the default
    # thousands_sep will be a conflict.  In that case, set
    # thousands_sep to empty string.  Suggested by Moritz Onken.
    foreach my $prefix ( '', 'mon_' )
    {
        if( $locale_values->{ "${prefix}decimal_point" } eq $locale_values->{ "${prefix}thousands_sep" } )
        {
            $locale_values->{ "${prefix}thousands_sep" } = '';
        }
    }
    
    foreach my $k ( keys( %$opts ) )
    {
        if( !exists( $self->{ $k } ) )
        {
            warn( "Warning only: unknown parameter '$k' to create a number format\n" );
            delete( $opts->{ $k } );
        }
    }
    ## Override default values with locales
    @$self{ @locales } = @$locale_values{ @locales };
    
    ## Only use parameters that are pre-defined in the object
    $self->{_init_strict} = 1;
    ## We use an hash rather than hash reference so we can see parameters passed in debugging stack trace
    $self->SUPER::init( %$opts );
    return( $self );
}

sub format_bytes
{
    my( $self, $number, @options ) = @_;

    unless( defined( $number ) )
    {
        my $bitmask = ( caller(0) )[9];
        my $offset = $warnings::Offsets{uninitialized};
        warn( "No number was provided to format\n" ) if( vec( $bitmask, $offset, 1 ) );
        $number = 0;
    }

    return( $self->error( 'Negative number not allowed in format_bytes' ) ) if( $number < 0 );

    # If a single scalar is given instead of key/value pairs for
    # @options, treat that as the value of the precision option.
    my %options;
    if( @options == 1 )
    {
        # To be changed to 'croak' in a future release:
        warn( "format_bytes: number instead of options is deprecated\n" );
        %options = ( precision => $options[0] );
    }
    else
    {
        %options = @options;
    }

    # Set default for precision.  Test using defined because it may be 0.
    $options{precision} = $self->{decimal_digits} unless( defined( $options{precision} ) );
    # default
    $options{precision} = 2 unless( defined( $options{precision} ) );

    $options{mode} ||= 'traditional';
    my( $ksuff, $msuff, $gsuff );
    if( $options{mode} =~ /^iec(60027)?$/i )
    {
        ( $ksuff, $msuff, $gsuff ) = @$self{ qw( kibi_suffix mebi_suffix gibi_suffix ) };
        return( $self->error( 'base option not allowed in iec60027 mode' ) ) if( exists( $options{base} ) );
    }
    elsif( $options{mode} =~ /^trad(itional)?$/i )
    {
        ( $ksuff, $msuff, $gsuff ) = @$self{ qw( kilo_suffix mega_suffix giga_suffix ) };
    }
    else
    {
        return( $self->error( 'Invalid mode' ) );
    }

    # Set default for "base" option.  Calculate threshold values for
    # kilo, mega, and giga values.  On 32-bit systems tera would cause
    # overflows so it is not supported.  Useful values of "base" are
    # 1024 or 1000, but any number can be used.  Larger numbers may
    # cause overflows for giga or even mega, however.
    ## $self->message( 3, "Getting base values for '$options{base}'" );
    my $mult = $self->_get_multipliers( $options{base} ) || return;
    ## $self->message( 3, "Data received from _get_multipliers is ", sub{ $self->dumper( \%mult ) } );

    # Process "unit" option.  Set default, then take first character
    # and convert to upper case.
    $options{unit} = 'auto' unless( defined( $options{unit} ) );
    my $unit = uc( substr( $options{unit}, 0, 1 ) );

    # Process "auto" first (default).  Based on size of number,
    # automatically determine which unit to use.
    if( $unit eq 'A' )
    {
        if( $number >= $mult->{giga} )
        {
            $unit = 'G';
        }
        elsif( $number >= $mult->{mega} )
        {
            $unit = 'M';
        }
        elsif( $number >= $mult->{kilo} )
        {
            $unit = 'K';
        }
        else
        {
            $unit = 'N';
        }
    }

    # Based on unit, whether specified or determined above, divide the
    # number and determine what suffix to use.
    my $suffix = '';
    if( $unit eq 'G' )
    {
        $number /= $mult->{giga};
        $suffix = $gsuff;
    }
    elsif( $unit eq 'M' )
    {
        $number /= $mult->{mega};
        $suffix = $msuff;
    }
    elsif( $unit eq 'K' )
    {
        $number /= $mult->{kilo};
        $suffix = $ksuff;
    }
    elsif( $unit ne 'N' )
    {
        return( $self->error( 'Invalid unit option' ) );
    }

    # Format the number and add the suffix.
    return( $self->format_number( $number, $options{precision} ) . $suffix );
}

sub format_negative
{
    my( $self, $number, $format ) = @_;

    unless( defined( $number ) )
    {
        my $bitmask = ( caller(0) )[9];
        my $offset = $warnings::Offsets{uninitialized};
        warn( "No number was provided to format\n" ) if( vec( $bitmask, $offset, 1 ) );
        $number = 0;
    }

    $format = $self->{neg_format} unless( defined( $format ) );
    return( $self->error( 'Letter x must be present in picture in format_negative()' ) ) unless( $format =~ /x/ );
    $number =~ s/^-//;
    $format =~ s/x/$number/;
    return( $format );
}

sub format_number
{
    my( $self, $number, $precision, $trailing_zeroes, $mon ) = @_;
    unless( defined( $number ) )
    {
        my $bitmask = ( caller(0) )[9];
        my $offset = $warnings::Offsets{uninitialized};
        ## $self->message( 3, "Undefined number provided." );
        ## $self->message( 3, "Caller's bitmask is '$bitmask', warnings offset is '$offset' and vector is '", vec( $bitmask, $offset, 1 ), "'." );
        warn( "No number was provided to format\n" ) if( vec( $bitmask, $offset, 1 ) );
        $number = 0;
    }

    return( $self->error( 'thousands_sep is not set' ) ) if( !length( $self->{thousands_sep} ) );
    return( $self->error( 'thousands_sep may not be numeric' ) ) if( $self->{thousands_sep} =~ /\d/ );
    return( $self->error( 'decimal_point may not be numeric' ) ) if( $self->{decimal_point} =~ /\d/ );
    return( $self->error( 'thousands_sep and decimal_point may not be equal' ) ) if( $self->{decimal_point} eq $self->{thousands_sep} );

    my( $thousands_sep, $decimal_point ) = @$self{ qw( thousands_sep decimal_point ) };

    # Set defaults and standardize number
    $precision = $self->{decimal_digits}     unless( defined( $precision ) );
    $trailing_zeroes = $self->{decimal_fill} unless( defined( $trailing_zeroes ) );

    # Handle negative numbers
    my $sign = $number <=> 0;
    $number = abs( $number ) if( $sign < 0 );
    # round off $number
    $number = $self->round( $number, $precision );

    # detect scientific notation
    my $exponent = 0;
    if( $number =~ /^(-?[\d.]+)e([+-]\d+)$/ )
    {
        # Don't attempt to format numbers that require scientific notation.
        return( $number );
    }

    # Split integer and decimal parts of the number and add commas
    my $integer = int( $number );
    my $decimal;

    # Note: In perl 5.6 and up, string representation of a number
    # automagically includes the locale decimal point.  This way we
    # will detect the decimal part correctly as long as the decimal
    # point is 1 character.
    $decimal = substr( $number, length( $integer ) + 1 ) if( length( $integer ) < length( $number ) );
    $decimal = '' unless( defined( $decimal ) );

    # Add trailing 0's if $trailing_zeroes is set.
    $decimal .= '0' x ( $precision - length( $decimal ) ) if( $trailing_zeroes && $precision > length( $decimal ) );

    # Add the commas (or whatever is in thousands_sep). If thousands_sep is the empty string, do nothing.
    if( $thousands_sep )
    {
        # Add leading 0's so length($integer) is divisible by 3
        $integer = '0' x ( 3 - ( length( $integer ) % 3 ) ) . $integer;

        # Split $integer into groups of 3 characters and insert commas
        $integer = join( $thousands_sep, grep { $_ ne '' } split( /(...)/, $integer ) );

        # Strip off leading zeroes and optional thousands separator
        $integer =~ s/^0+(?:\Q$thousands_sep\E)?//;
    }
    $integer = '0' if( $integer eq '' );

    # Combine integer and decimal parts and return the result.
    my $result = ( ( defined( $decimal ) && length( $decimal ) ) 
        ? join( $decimal_point, $integer, $decimal ) 
        : $integer );

    return( ( $sign < 0 ) ? $self->format_negative( $result ) : $result );
}

sub format_picture
{
    my( $self, $number, $picture ) = @_;

    unless( defined( $number ) )
    {
        my $bitmask = ( caller(0) )[9];
        my $offset = $warnings::Offsets{uninitialized};
        warn( "No number was provided to format\n" ) if( vec( $bitmask, $offset, 1 ) );
        $number = 0;
    }

    return( $self->error( "Picture not defined" ) ) unless( defined( $picture ) );

    return( $self->error( 'thousands_sep is not set' ) ) if( !length( $self->{thousands_sep} ) );
    return( $self->error( 'thousands_sep may not be numeric' ) ) if( $self->{thousands_sep} =~ /\d/ );
    return( $self->error( 'decimal_point may not be numeric' ) ) if( $self->{decimal_point} =~ /\d/ );
    return( $self->error( 'thousands_sep and decimal_point may not be equal' ) ) if( $self->{decimal_point} eq $self->{thousands_sep} );

    # Handle negative numbers
    my( $neg_prefix ) = $self->{neg_format} =~ /^([^x]+)/;
    my( $pic_prefix ) = $picture            =~ /^([^\#]+)/;
    my $neg_pic = $self->{neg_format};
    ( my $pos_pic = $self->{neg_format} ) =~ s/[^x\s]/ /g;
    ( my $pos_prefix = $neg_prefix ) =~ s/[^x\s]/ /g;
    $neg_pic =~ s/x/$picture/;
    $pos_pic =~ s/x/$picture/;
    my $sign = $number <=> 0;
    $number = abs( $number ) if( $sign < 0 );
    $picture = $sign < 0 ? $neg_pic : $pos_pic;
    my $sign_prefix = $sign < 0 ? $neg_prefix : $pos_prefix;

    # Split up the picture and die if there is more than one $DECIMAL_POINT
    my( $pic_int, $pic_dec, @cruft ) =
        split( /\Q$self->{decimal_point}\E/, $picture );
    $pic_int = '' unless( defined( $pic_int ) );
    $pic_dec = '' unless( defined( $pic_dec ) );

    return( $self->error( 'Only one decimal separator permitted in picture' ) ) if( @cruft );

    # Obtain precision from the length of the decimal part...
    my $precision = $pic_dec;          # start with copying it
    $precision =~ s/[^\#]//g;          # eliminate all non-# characters
    $precision = length( $precision ); # take the length of the result

    # Format the number
    $number = $self->round( $number, $precision );

    # Obtain the length of the integer portion just like we did for $precision
    my $intsize = $pic_int;        # start with copying it
    $intsize =~ s/[^\#]//g;        # eliminate all non-# characters
    $intsize = length( $intsize ); # take the length of the result

    # Split up $number same as we did for $picture earlier
    my( $num_int, $num_dec ) = split( /\./, $number, 2 );
    $num_int = '' unless( defined( $num_int ) );
    $num_dec = '' unless( defined( $num_dec ) );

    # Check if the integer part will fit in the picture
    if( length( $num_int ) > $intsize )
    {
        # convert # to * and return it
        $picture =~ s/\#/\*/g;
        $pic_prefix = '' unless( defined( $pic_prefix ) );
        $picture =~ s/^(\Q$sign_prefix\E)(\Q$pic_prefix\E)(\s*)/$2$3$1/;
        return( $picture );
    }

    # Split each portion of number and picture into arrays of characters
    my @num_int = split( //, $num_int );
    my @num_dec = split( //, $num_dec );
    my @pic_int = split( //, $pic_int );
    my @pic_dec = split( //, $pic_dec );

    # Now we copy those characters into @result.
    my @result;
    @result = ( $self->{decimal_point} ) if( $picture =~ /\Q$self->{decimal_point}\E/ );
    # For each characture in the decimal part of the picture, replace '#'
    # signs with digits from the number.
    my $char;
    foreach $char ( @pic_dec )
    {
        $char = ( shift( @num_dec ) || 0 ) if( $char eq '#' );
        push( @result, $char );
    }

    # For each character in the integer part of the picture (moving right
    # to left this time), replace '#' signs with digits from the number,
    # or spaces if we've run out of numbers.
    while( $char = pop( @pic_int ) )
    {
        $char = pop( @num_int ) if( $char eq '#' );
        $char = ' ' if( !defined( $char ) ||
                        $char eq $self->{thousands_sep} && $#num_int < 0 );
        unshift( @result, $char );
    }

    # Combine @result into a string and return it.
    my $result = join( '', @result );
    $sign_prefix = '' unless( defined( $sign_prefix ) );
    $pic_prefix  = '' unless( defined( $pic_prefix ) );
    $result =~ s/^(\Q$sign_prefix\E)(\Q$pic_prefix\E)(\s*)/$2$3$1/;
    return( $result );
}

sub format_price
{
    my( $self, $number, $precision, $curr_symbol ) = @_;

    unless( defined( $number ) )
    {
        my $bitmask = ( caller(0) )[9];
        my $offset = $warnings::Offsets{uninitialized};
        warn( "No number was provided to format\n" ) if( vec( $bitmask, $offset, 1 ) );
        $number = 0;
    }

    # Determine what the monetary symbol should be
    $curr_symbol = $self->{int_curr_symbol} if( !defined( $curr_symbol ) || lc( $curr_symbol ) eq 'int_curr_symbol' );
    $curr_symbol = $self->{currency_symbol} if( !defined( $curr_symbol ) || lc( $curr_symbol ) eq 'currency_symbol' );
    $curr_symbol = '' unless( defined( $curr_symbol ) );

    # Determine which value to use for frac digits
    my $frac_digits = ( $curr_symbol eq $self->{int_curr_symbol} ?
                       $self->{int_frac_digits} : $self->{frac_digits} );

    # Determine precision for decimal portion
    $precision = $frac_digits            unless( defined( $precision ) );
    $precision = $self->{decimal_digits} unless( defined( $precision ) ); # fallback
    $precision = 2                       unless( defined( $precision ) ); # default

    # Determine sign and absolute value
    my $sign = $number <=> 0;
    $number = abs( $number ) if( $sign < 0 );

    # format it first
    $number = $self->format_number( $number, $precision, undef, 1 );

    # Now we make sure the decimal part has enough zeroes
    my( $integer, $decimal ) =
        split( /\Q$self->{mon_decimal_point}\E/, $number, 2 );
    $decimal = '0' x $precision unless( $decimal );
    $decimal .= '0' x ( $precision - length( $decimal ) );

    # Extract positive or negative values
    my( $sep_by_space, $cs_precedes, $sign_posn, $sign_symbol );
    if( $sign < 0 )
    {
        $sep_by_space = $self->{n_sep_by_space};
        $cs_precedes  = $self->{n_cs_precedes};
        $sign_posn    = $self->{n_sign_posn};
        $sign_symbol  = $self->{negative_sign};
    }
    else
    {
        $sep_by_space = $self->{p_sep_by_space};
        $cs_precedes  = $self->{p_cs_precedes};
        $sign_posn    = $self->{p_sign_posn};
        $sign_symbol  = $self->{positive_sign};
    }

    # Combine it all back together.
    my $result = ( $precision ?
                  join( $self->{mon_decimal_point}, $integer, $decimal ) :
                  $integer );

    # Determine where spaces go, if any
    my( $sign_sep, $curr_sep );
    if( $sep_by_space == 0 )
    {
        $sign_sep = $curr_sep = "";
    }
    elsif( $sep_by_space == 1 )
    {
        $sign_sep = "";
        $curr_sep = " ";
    }
    elsif( $sep_by_space == 2 )
    {
        $sign_sep = " ";
        $curr_sep = "";
    }
    else
    {
        return( $self->error( 'Invalid sep_by_space value' ) );
    }

    # Add sign, if any
    if( $sign_posn >= 0 && $sign_posn <= 2 )
    {
        # Combine with currency symbol and return
        if( $curr_symbol ne '' )
        {
            if( $cs_precedes )
            {
                $result = $curr_symbol . $curr_sep . $result;
            }
            else
            {
                $result = $result . $curr_sep . $curr_symbol;
            }
        }

        if( $sign_posn == 0 )
        {
            return( "($result)" );
        }
        elsif( $sign_posn == 1 )
        {
            return( $sign_symbol . $sign_sep . $result );
        }
        # $sign_posn == 2
        else
        {
            return( $result . $sign_sep . $sign_symbol );
        }
    }
    elsif( $sign_posn == 3 || $sign_posn == 4 )
    {
        if( $sign_posn == 3 )
        {
            $curr_symbol = $sign_symbol . $sign_sep . $curr_symbol;
        }
        # $sign_posn == 4
        else
        {
            $curr_symbol = $curr_symbol . $sign_sep . $sign_symbol;
        }

        # Combine with currency symbol and return
        if( $cs_precedes )
        {
            return( $curr_symbol. $curr_sep. $result );
        }
        else
        {
            return( $result . $curr_sep . $curr_symbol );
        }
    }

    else
    {
        return( $self->error( 'Invalid *_sign_posn value' ) );
    }
}

sub round
{
    my( $self, $number, $precision ) = @_;

    unless( defined( $number ) )
    {
        my $bitmask = ( caller(0) )[9];
        my $offset = $warnings::Offsets{uninitialized};
        warn( "No number was provided to format\n" ) if( vec( $bitmask, $offset, 1 ) );
        $number = 0;
    }

    $precision = $self->{decimal_digits} unless defined $precision;
    $precision = 2 unless defined $precision;

    return( $self->error( "precision must be integer. Value provided was '$precision'." ) )
        unless( int( $precision ) == $precision );

    if( ref( $number ) && $number->isa( 'Math::BigFloat' ) )
    {
        my $rounded = $number->copy();
        $rounded->precision( -$precision );
        return( $rounded );
    }

    my $sign       = $number <=> 0;
    my $multiplier = ( 10 ** $precision );
    my $result     = abs( $number );
    my $product    = $result * $multiplier;

    return( $self->error( "round() overflow for '$product'. Try smaller precision or use Math::BigFloat" ) ) if( $product > MAX_INT );

    # We need to add 1e-14 to avoid some rounding errors due to the
    # way floating point numbers work - see string-eq test in t/round.t
    $result = int( $product + .5 + 1e-14 ) / $multiplier;
    $result = -$result if( $sign < 0 );
    return( $result );
}

sub unformat_number
{
    my( $self, $formatted, %options ) = @_;

    unless( defined( $formatted ) )
    {
        my $bitmask = ( caller(0) )[9];
        my $offset = $warnings::Offsets{uninitialized};
        return( $self->error( "No format was provided to format number" ) ) if( vec( $bitmask, $offset, 1 ) );
        # $formatted = '';
    }

    return( $self->error( 'thousands_sep is not set' ) ) if( !length( $self->{thousands_sep} ) );
    return( $self->error( 'thousands_sep may not be numeric' ) ) if( $self->{thousands_sep} =~ /\d/ );
    return( $self->error( 'decimal_point may not be numeric' ) ) if( $self->{decimal_point} =~ /\d/ );
    return( $self->error( 'thousands_sep and decimal_point may not be equal' ) ) if( $self->{decimal_point} eq $self->{thousands_sep} );
    # require at least one digit
    return( $self->error( 'require at least one digit' ) ) unless( $formatted =~ /\d/ );

    # Regular expression for detecting decimal point
    my $pt = qr/\Q$self->{decimal_point}\E/;

    # ru_RU locale has comma for decimal_point, but period for
    # mon_decimal_point!  But as long as thousands_sep is different
    # from either, we can allow either decimal point.
    if( $self->{mon_decimal_point} &&
        $self->{decimal_point} ne $self->{mon_decimal_point} &&
        $self->{decimal_point} ne $self->{mon_thousands_sep} &&
        $self->{mon_decimal_point} ne $self->{thousands_sep} )
    {
        $pt = qr/(?:\Q$self->{decimal_point}\E|
                    \Q$self->{mon_decimal_point}\E)/x;
    }

    # Detect if it ends with one of the kilo / mega / giga suffixes.
    my $kp = ( $formatted =~ s/\s*($self->{kilo_suffix}|$self->{kibi_suffix})\s*$// );
    my $mp = ( $formatted =~ s/\s*($self->{mega_suffix}|$self->{mebi_suffix})\s*$// );
    my $gp = ( $formatted =~ s/\s*($self->{giga_suffix}|$self->{gibi_suffix})\s*$// );
    my $mult = $self->_get_multipliers( $options{base} ) || return;

    # Split number into integer and decimal parts
    my( $integer, $decimal, @cruft ) = split( $pt, $formatted );
    return( $self->error( 'Only one decimal separator permitted' ) ) if( @cruft );

    # It's negative if the first non-digit character is a -
    my $sign = $formatted =~ /^\D*-/ ? -1 : 1;
    my( $before_re, $after_re ) = split( /x/, $self->{neg_format}, 2 );
    $sign = -1 if( $formatted =~ /\Q$before_re\E(.+)\Q$after_re\E/ );

    # Strip out all non-digits from integer and decimal parts
    $integer = '' unless( defined( $integer ) );
    $decimal = '' unless( defined( $decimal ) );
    $integer =~ s/\D//g;
    $decimal =~ s/\D//g;

    # Join back up, using period, and add 0 to make Perl think it's a number
    my $number = join( '.', $integer, $decimal ) + 0;
    $number = -$number if( $sign < 0 );

    # Scale the number if it ended in kilo or mega suffix.
    $number *= $mult->{kilo} if( $kp );
    $number *= $mult->{mega} if( $mp );
    $number *= $mult->{giga} if( $gp );
    return( $number );
}

# _get_multipliers returns the multipliers to be used for kilo, mega,
# and giga (un-)formatting.  Used in format_bytes and unformat_number.
# For internal use only.
sub _get_multipliers
{
    my $self = shift( @_ );
    my $base = shift( @_ );
    # $self->message( 3, "Returning data for base '$base'." );
    if( !defined( $base ) || $base == 1024 )
    {
        return({
            kilo => 0x00000400,
            mega => 0x00100000,
            giga => 0x40000000
        });
    }
    elsif( $base == 1000 )
    {
        return({
            kilo => 1_000,
            mega => 1_000_000,
            giga => 1_000_000_000
        });
    }
    else
    {
        return( $self->error( 'base overflow' ) ) if( $base **3 > MAX_INT );
        return( $self->error( 'base must be a positive integer' ) ) unless( $base > 0 && $base == int( $base ) );
        return({
            kilo => $base,
            mega => $base ** 2,
            giga => $base ** 3
        });
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Number::Format - Number Formatting

=head1 SYNOPSIS

    use Net::API::Stripe::Number::Format;
    my $x = Net::API::Stripe::Number::Format->new( %args );
    $formatted = $x->round( $number, $precision );
    $formatted = $x->format_number( $number, $precision, $trailing_zeroes );
    $formatted = $x->format_negative( $number, $picture );
    $formatted = $x->format_picture( $number, $picture );
    $formatted = $x->format_price( $number, $precision, $symbol );
    $formatted = $x->format_bytes( $number, $precision );
    $number    = $x->unformat_number( $formatted );

=head1 VERSION

    0.2

=head1 DESCRIPTION

These functions provide an easy means of formatting numbers in a manner suitable for displaying to the user.

You can declare an object of type Number::Format, which you can think of as a formatting engine. The various functions defined here are provided as object methods. The constructor C<new()> can be used to set the parameters of the formatting engine. Valid parameters are:

=over 4

=item I<thousands_sep>

character inserted between groups of 3 digits

=item I<decimal_point>

character separating integer and fractional parts

=item I<mon_thousands_sep>

like THOUSANDS_SEP, but used for format_price

=item I<mon_decimal_point>

like DECIMAL_POINT, but used for format_price

=item I<int_curr_symbol>

character(s) denoting currency (see format_price())

=item I<decimal_digits>

number of digits to the right of dec point (def 2)

=item I<decimal_fill>

boolean; whether to add zeroes to fill out decimal

=item I<neg_format>

format to display negative numbers (def ``-x'')

=item I<kilo_suffix>

suffix to add when format_bytes formats kilobytes (trad)

=item I<mega_suffix>

suffix to add when format_bytes formats megabytes (trad)

=item I<giga_suffix>

suffix to add when format_bytes formats gigabytes (trad)

=item I<kibi_suffix>

suffix to add when format_bytes formats kibibytes (iec)

=item I<mebi_suffix>

suffix to add when format_bytes formats mebibytes (iec)

=item I<gibi_suffix>

suffix to add when format_bytes formats gibibytes (iec)

They may be specified in upper or lower case, with or without a leading hyphen ( - ).

If I<thousands_sep> is set to the empty string, format_number will not insert any separators.

The defaults for I<thousands_sep>, I<decimal_point>, I<mon_thousands_sep>, I<mon_decimal_point>, and I<int_curr_symbol> come from the POSIX locale information (see L<perllocale>). If your L<POSIX> locale does not provide I<mon_thousands_sep> and/or I<mon_decimal_point> fields, then the I<thousands_sep> and/or I<decimal_point> values are used for those parameters.

The default object values for all the parameters are:

  thousands_sep     = ','
  decimal_point     = '.'
  mon_thousands_sep = ','
  mon_decimal_point = '.'
  int_curr_symbol   = 'USD'
  decimal_digits    = 2
  decimal_fill      = 0
  neg_format        = '-x'
  kilo_suffix       = 'K'
  mega_suffix       = 'M'
  giga_suffix       = 'G'
  kibi_suffix       = 'KiB'
  mebi_suffix       = 'MiB'
  gibi_suffix       = 'GiB'

The I<decimal_fill> and I<decimal_digits> values are not set by the Locale system, but are definable by the user.  They affect the output of L</"format_number">. Setting I<decimal_digits> is like giving that value as the C<$precision> argument to that function. Setting I<decimal_fill> to a true value causes L</"format_number"> to append
zeroes to the right of the decimal digits until the length is the specified number of digits.

I<neg_format> is only used by L</"format_negative"> and is a string containing the letter 'x', where that letter will be replaced by a positive representation of the number being passed to that function.
L</"format_number"> and L</"format_price"> utilise this feature by calling L</"format_negative"> if the number was less than 0.

I<kilo_suffix>, I<mega_suffix>, and I<giga_suffix> are used by L</"format_bytes"> when the value is over 1024, 1024*1024, or 1024*1024*1024, respectively. The default values are "K", "M", and "G".  These apply in the default "traditional" mode only. Note: TERA or higher are not implemented because of integer overflows on 32-bit
systems.

I<kibi_suffix>, I<mebi_suffix>, and I<gibi_suffix> are used by L</"format_bytes"> when the value is over 1024, 1024*1024, or 1024*1024*1024, respectively. The default values are "KiB", "MiB", and "GiB". These apply in the "iso60027"" mode only. Note: TEBI or higher are not implemented because of integer overflows on 32-bit
systems.

The only restrictions on I<decimal_point> and I<thousands_sep> are that they must not be digits and must not be identical. There are no restrictions on I<int_curr_symbol>.

For example, a German user might include this in their code:

  use Net::API::Stripe::Number::Format;
  my $de = new Net::API::Stripe::Number::Format(
      thousands_sep   => '.',
      decimal_point   => ',',
      int_curr_symbol => 'DEM'
  );
  my $formatted = $de->format_number( $number );

=head1 REQUIRES

Perl, version 5.8 or higher.

L<POSIX> to determine locale settings.

=head1 ERROR HANDLING

This module never dies, or at least not voluntarily. It does not use carp, or croak.

When an error occurs, it returns undef, or an empty list depending on the context, after having set an error which can be retrieved with the L<Module::Generic/"error"> this module inherits

=head1 METHODS

=over 4

=item new

Provided a hash or hash reference of parameters, this creates a new L<Net::API::Stripe::Number::Format> object. Valid keys for %args are any of the parameters described above. Keys must be in lowercase.
Example:

  my $de = new Net::API::Stripe::Number::Format(
      thousands_sep   => '.',
      decimal_point   => ',',
      int_curr_symbol => 'DEM'
  );

=item round

This takes 2 parameters: C<$number> and C<$precision>

Rounds the number to the specified precision. If C<$precision> is omitted, the value of the I<decimal_digits> parameter is used (default value 2). Both input and output are numeric (the function uses math operators rather than string manipulation to do its job), The value of C<$precision> may be any integer, positive or negative. Examples:

  round( 3.14159 )       yields    3.14
  round( 3.14159, 4 )    yields    3.1416
  round( 42.00, 4 )      yields    42
  round( 1234, -2 )      yields    1200

Since this is a mathematical rather than string oriented function, there will be no trailing zeroes to the right of the decimal point, and the I<decimal_point> and I<thousands_sep> variables are ignored. To format your number using the I<decimal_point> and I<thousands_sep> variables, use L</"format_number"> instead.

=item format_number

This takes 3 parameters: C<$number>, C<$precision> and C<trailing_zeroes>

Formats a number by adding C<thousands_sep> between each set of 3 digits to the left of the decimal point, substituting I<decimal_point> for the decimal point, and rounding to the specified precision using L</"round">. Note that C<$precision> is a I<maximum> precision specifier; trailing zeroes will only appear in the output if C<$trailing_zeroes> is provided, or the parameter I<decimal_fill> is set, with a value that is true (not zero, undef, or the empty string). If C<$precision> is omitted, the value of the object I<decimal_digits> parameter (default value of 2) is used.

If the value is too large or great to work with as a regular number, but instead must be shown in scientific notation, returns that number in scientific notation without further formatting.

Examples:

  format_number( 12345.6789 )             yields   '12,345.68'
  format_number( 123456.789, 2 )          yields   '123,456.79'
  format_number( 1234567.89, 2 )          yields   '1,234,567.89'
  format_number( 1234567.8, 2 )           yields   '1,234,567.8'
  format_number( 1234567.8, 2, 1 )        yields   '1,234,567.80'
  format_number( 1.23456789, 6 )          yields   '1.234568'
  format_number( "0.000020000E+00", 7 );' yields   '2e-05'

Of course the output would have your values of C<THOUSANDS_SEP> and C<DECIMAL_POINT> instead of ',' and '.' respectively.

=item format_negative

This takes 2 parameters: C<$number> and C<$picture>

Formats a negative number. Picture should be a string that contains the letter C<x> where the number should be inserted. For example, for standard negative numbers you might use ``C<-x>'', while for accounting purposes you might use ``C<(x)>''. If the specified number begins with a ``-'' character, that will be removed before formatting, but formatting will occur whether or not the number is negative.

=item format_picture

This takes 2 parameters: C<$number> and C<$picture>

Returns a string based on C<$picture> with the C<#> characters replaced by digits from C<$number>. If the length of the integer part of $number is too large to fit, the C<#> characters are replaced with asterisks (C<*>) instead.  Examples:

  format_picture( 100.023, 'USD ##,###.##' )   yields   'USD    100.02'
  format_picture( 1000.23, 'USD ##,###.##' )   yields   'USD  1,000.23'
  format_picture( 10002.3, 'USD ##,###.##' )   yields   'USD 10,002.30'
  format_picture( 100023,  'USD ##,###.##' )   yields   'USD **,***.**'
  format_picture( 1.00023, 'USD #.###,###' )   yields   'USD 1.002,300'

The comma (,) and period (.) you see in the picture examples should match the values of I<thousands_sep> and I<decimal_point>, respectively, for proper operation. However, the I<thousands_sep> characters in C<$picture> need not occur every three digits; the I<only> use of that variable by this function is to remove leading commas (see the first example above). There may not be more than one instance of I<decimal_point> in C<$picture>.

The value of I<neg_format> is used to determine how negative numbers are displayed. The result of this is that the output of this function my have unexpected spaces before and/or after the number. This is necessary so that positive and negative numbers are formatted into a space the same size. If you are only using positive numbers and want to avoid this problem, set I<neg_format> to "x".

=item format_price( $number, $precision, $symbol )

This takes 3 parameters: C<$number>, C<$precision> and C<$symbol>

Returns a string containing C<$number> formatted similarly to L</"format_number">, except that the decimal portion may have trailing zeroes added to make it be exactly C<$precision> characters long, and the currency string will be prefixed.

The C<$symbol> attribute may be one of I<int_curr_symbol> or I<currency_symbol> (case insensitive) to use the value of that attribute of the object, or a string containing the symbol to be used. The default is I<int_curr_symbol> if this argument is undefined or not given; if set to the empty string, or if set to undef and the I<int_curr_symbol> attribute of the object is the empty string, no currency will be added.

If C<$precision> is not provided, the default of 2 will be used.
Examples:

  format_price( 12.95 )   yields   'USD 12.95'
  format_price( 12 )      yields   'USD 12.00'
  format_price( 12, 3 )   yields   '12.000'

The third example assumes that C<int_curr_symbol> is the empty string.

=item format_bytes( $number, %options )

This takes 2 or more parameters: C<$number> and C<%options>

Returns a string containing C<$number> formatted similarly to L</"format_number">, except that large numbers may be abbreviated by adding a suffix to indicate 1024, 1,048,576, or 1,073,741,824 bytes. Suffix may be the traditional K, M, or G (default); or the IEC standard 60027 "KiB," "MiB," or "GiB" depending on the "mode" option.

Negative values will result in an error.

The second parameter is a hash that sets the following possible options:

=over 4

=item precision

Set the precision for displaying numbers. If not provided, a default of 2 will be used.  Examples:

  format_bytes( 12.95 )                   yields   '12.95'
  format_bytes( 12.95, precision => 0 )   yields   '13'
  format_bytes( 2048 )                    yields   '2K'
  format_bytes( 2048, mode => "iec" )     yields   '2KiB'
  format_bytes( 9999999 )                 yields   '9.54M'
  format_bytes( 9999999, precision => 1 ) yields   '9.5M'

=item unit

Sets the default units used for the results. The default is to determine this automatically in order to minimize the length of the string. In other words, numbers greater than or equal to 1024 (or other number given by the 'base' option, q.v.) will be divided by 1024 and I<kilo_suffix> or I<kibi_suffix> added; if greater than or equal to 1048576 (1024*1024), it will be divided by 1048576 and I<mega_suffix> or I<mebi_suffix> appended to the end; etc.

However if a value is given for C<unit> it will use that value instead. The first letter (case-insensitive) of the value given indicates the threshhold for conversion; acceptable values are G (for giga/gibi), M (for mega/mebi), K (for kilo/kibi), or A (for automatic, the default). For example:

  format_bytes( 1048576, unit => 'K' ) yields     '1,024K'
                                       instead of '1M'

Note that the valid values to this option do not vary even when the suffix configuration variables have been changed.

=item base

Sets the number at which the I<kilo_suffix> is added. Default is 1024. Set to any value; the only other useful value is probably 1000, as hard disk manufacturers use that number to make their disks sound bigger than they really are.

If the mode (see below) is set to "iec" or "iec60027" then setting the base option results in an error.

=item mode

Traditionally, bytes have been given in SI (metric) units such as "kilo" and "mega" even though they represent powers of 2 (1024, etc.) rather than powers of 10 (1000, etc.) This "binary prefix" causes much confusion in consumer products where "GB" may mean either 1,048,576 or 1,000,000, for example. The International Electrotechnical Commission has created standard IEC 60027 to introduce prefixes Ki, Mi, Gi, etc. ("kibibytes," "mebibytes," "gibibytes," etc.) to remove this confusion.  Specify a mode option with either "traditional" or "iec60027" (or abbreviate as "trad" or "iec") to indicate which type of binary prefix you want format_bytes to use.  For backward compatibility, "traditional" is the default.
See L<http://en.wikipedia.org/wiki/Binary_prefix> for more information.

=back

=item unformat_number

This takes 1 parameter: C<$formatted>

Converts a string as returned by L</"format_number">, L</"format_price">, or L</"format_picture">, and returns the
corresponding value as a numeric scalar.  Returns C<undef> if the number does not contain any digits.  Examples:

  unformat_number( 'USD 12.95' )   yields   12.95
  unformat_number( 'USD 12.00' )   yields   12
  unformat_number( 'foobar' )      yields   undef
  unformat_number( '1234-567@.8' ) yields   1234567.8

The value of I<decimal_point> is used to determine where to separate the integer and decimal portions of the input.  All other non-digit characters, including but not limited to I<int_curr_symbol> and I<thousands_sep>, are removed.

If the number matches the pattern of I<neg_format> I<or> there is a ``-'' character before any of the digits, then a negative number is returned.

If the number ends with the I<kilo_suffix>, I<kibi_suffix>, I<mega_suffix>, I<mebi_suffix>, I<giga_suffix>, or I<gibi_suffix> characters, then the number returned will be multiplied by the appropriate multiple of 1024 (or if the base option is given, by the multiple of that value) as appropriate.  Examples:

  unformat_number( "4K", base => 1024 )   yields  4096
  unformat_number( "4K", base => 1000 )   yields  4000
  unformat_number( "4KiB", base => 1024 ) yields  4096
  unformat_number( "4G" )                 yields  4294967296

=back

=head1 CAVEATS

Some systems, notably OpenBSD, may have incomplete locale support.
Using this module together with L<setlocale(3)> in OpenBSD may therefore not produce the intended results.

=head1 CREDITS

Adapted from the original work by William R. Ward

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::Stripe::Number>, L<Number::Format>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

