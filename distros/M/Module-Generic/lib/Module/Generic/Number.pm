##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Number.pm
## Version v2.5.1
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2026/07/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Number;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    warnings::register_categories( 'Module::Generic' );
    use parent qw( Module::Generic );
    use vars qw( $SUPPORTED_LOCALES $DEFAULT $NUMBER_RE $LOCALE_LOCK );
    use Config;
    require POSIX;
    if( $] >= 5.022 )
    {
        POSIX->import( qw( cbrt isfinite isinf isnan isnormal signbit ) );
    }
    else
    {
        my $POS_INF = 9**9**9;
        my $NEG_INF = -$POS_INF;
        *isinf = sub
        {
            return(0) if( !defined( $_[0] ) );
            no warnings 'numeric';
            return( $_[0] == $POS_INF || $_[0] == $NEG_INF );
        };
        *isnan = sub
        {
            return(0) if( !defined( $_[0] ) );
            no warnings 'numeric';
            return( $_[0] != $_[0] );
        };
        *isfinite = sub { my $n = $_[0]; return( $n == $n && $n != $POS_INF && $n != $NEG_INF ? 1 : 0 ); };
        *isnormal = sub
        {
            my $n = $_[0];
            return(0) if( $n != $n );
            return(0) if( $n == 0 );
            return(0) if( $n == $POS_INF || $n == $NEG_INF );
            my $abs = $n < 0 ? -$n : $n;
            return( $abs >= 2.2250738585072014e-308 ? 1 : 0 );
        };
        # signbit: returns non-zero for negative numbers (including -0.0)
        *signbit = sub
        {
            my $n = $_[0];
            return(1) if( $n < 0 );
            return(0) if( $n > 0 );
            # zero or NaN: check string representation for -0
            return( sprintf( "%g", $n ) =~ /^-/ ? 1 : 0 );
        };
        # cbrt: handle negatives correctly (real cube root)
        *cbrt = sub
        {
            my $n = $_[0];
            return( $n < 0 ? -( ( -$n ) ** ( 1/3 ) ) : $n ** ( 1/3 ) );
        };
    }

    # 2026-05-17: Regexp::Common does not install under perl v5.10.1 because of an error in its test t/test_comments.t
    # use Regexp::Common qw( number );
    # $NUMBER_RE = $RE{num}{real};
    $NUMBER_RE = qr/(?:(?i)(?:[-+]?)(?:(?=[.]?[0123456789])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[-+]?)(?:[0123456789]+))|))/;
    use Scalar::Util ();
    use overload (
        # I know there is the nomethod feature, but I need to provide return_object set to true or false
        # And I do not necessarily want to catch all the operation.
        '""' => sub { return( shift->{_number} ); },
        # numeric context
        '0+' => \&as_number,
        '-' => sub { return( shift->compute( @_, { op => '-', return_object => 1 }) ); },
        '+' => sub { return( shift->compute( @_, { op => '+', return_object => 1 }) ); },
        '*' => sub { return( shift->compute( @_, { op => '*', return_object => 1 }) ); },
        '/' => sub { return( shift->compute( @_, { op => '/', return_object => 1 }) ); },
        '%' => sub { return( shift->compute( @_, { op => '%', return_object => 1 }) ); },
        # Exponent
        '**' => sub { return( shift->compute( @_, { op => '**', return_object => 1 }) ); },
        # Bitwise AND
        '&' => sub { return( shift->compute( @_, { op => '&', return_object => 1 }) ); },
        # Bitwise OR
        '|' => sub { return( shift->compute( @_, { op => '|', return_object => 1 }) ); },
        # Bitwise XOR
        '^' => sub { return( shift->compute( @_, { op => '^', return_object => 1 }) ); },
        # Bitwise shift left
        '<<' => sub { return( shift->compute( @_, { op => '<<', return_object => 1 }) ); },
        # Bitwise shift right
        '>>' => sub { return( shift->compute( @_, { op => '>>', return_object => 1 }) ); },
        'x' => sub { return( shift->compute( @_, { op => 'x', return_object => 1, type => 'scalar' }) ); },
        '+=' => sub { return( shift->compute( @_, { op => '+=', return_object => 1 }) ); },
        '-=' => sub { return( shift->compute( @_, { op => '-=', return_object => 1 }) ); },
        '*=' => sub { return( shift->compute( @_, { op => '*=', return_object => 1 }) ); },
        '/=' => sub { return( shift->compute( @_, { op => '/=', return_object => 1 }) ); },
        '%=' => sub { return( shift->compute( @_, { op => '%=', return_object => 1 }) ); },
        '**=' => sub { return( shift->compute( @_, { op => '**=', return_object => 1 }) ); },
        '<<=' => sub { return( shift->compute( @_, { op => '<<=', return_object => 1 }) ); },
        '>>=' => sub { return( shift->compute( @_, { op => '>>=', return_object => 1 }) ); },
        'x=' => sub { return( shift->compute( @_, { op => 'x=', return_object => 1 }) ); },
        # '.=' => sub { return( shift->compute( @_, { op => '.=', return_object => 1 }) ); },
        '.=' => sub
        {
            my( $self, $other, $swap ) = @_;
            my $op = '.=';
            no strict;
            my $operation = $swap ? "${other} ${op} \$self->{_number}" : "\$self->{_number} ${op} ${other}";
            my $res = eval( $operation );
            warn( "Error with formula \"$operation\": $@" ) if( $@ && $self->_warnings_is_enabled( 'Module::Generic' ) );
            return if( $@ );
            # Concatenated something. If it still look like a number, we return it as an object
            if( $res =~ /^$NUMBER_RE$/ )
            {
                return( $self->clone( $res ) );
            }
            # Otherwise we pass it to the scalar module
            else
            {
                return( Module::Generic::Scalar->new( "$res" ) );
            }
        },
        '<' => sub { return( shift->compute( @_, { op => '<', boolean => 1 }) ); },
        '<=' => sub { return( shift->compute( @_, { op => '<=', boolean => 1 }) ); },
        '>' => sub { return( shift->compute( @_, { op => '>', boolean => 1 }) ); },
        '>=' => sub { return( shift->compute( @_, { op => '>=', boolean => 1 }) ); },
        '<=>' => sub { return( shift->compute( @_, { op => '<=>', return_object => 0 }) ); },
        '==' => sub { return( shift->compute( @_, { op => '==', boolean => 1 }) ); },
        '!=' => sub { return( shift->compute( @_, { op => '!=', boolean => 1 }) ); },
        'eq' => sub { return( shift->compute( @_, { op => 'eq', boolean => 1 }) ); },
        'ne' => sub { return( shift->compute( @_, { op => 'ne', boolean => 1 }) ); },
        '++' => sub
        {
            my( $self ) = @_;
            return( ++$self->{_number} );
        },
        '--' => sub
        {
            my( $self ) = @_;
            return( --$self->{_number} );
        },
        'fallback' => 1,
    );
    use constant HAS_THREADS => $Config{useithreads};
    if( HAS_THREADS )
    {
        require threads;
        require threads::shared;
        threads->import();
        threads::shared->import();
        our $LOCALE_LOCK :shared;
    }
    our( $VERSION ) = 'v2.5.1';
};

# use strict;
no warnings 'redefine';
use utf8;

sub init
{
    my $self = shift( @_ );
    return( $self->error( "No number was provided." ) ) if( !scalar( @_ ) );
    my $num  = shift( @_ );
    return( $self->error( "Number provided is undefined" ) ) if( !defined( $num ) );
    my $opts = $self->_get_args_as_hash( @_ );
    # Trigger overloading to string operation
    $num = "$num" if( ref( $num ) );
    return( $self->error( "Number value provided is empty" ) ) if( !CORE::length( $num ) );
    {
        no warnings;
        return( Module::Generic::Infinity->new( $num ) ) if( isinf( $num ) );
        return( Module::Generic::Nan->new( $num ) ) if( isnan( $num ) );
    }
    if( !exists( $opts->{locale} ) &&
        exists( $opts->{lang} ) )
    {
        $opts->{locale} = CORE::delete( $opts->{lang} );
    }
    $self->{locale} = exists( $opts->{locale} ) ? CORE::delete( $opts->{locale} ) : '';
    $self->debug( CORE::delete( $opts->{debug} ) ) if( exists( $opts->{debug} ) );
    # Convert Japanese double bytes numbers to regular digits.
    $num =~ tr/[\x{FF10}-\x{FF19}]＋ー/[0-9]+-/;
    if( $num !~ /^$NUMBER_RE$/ )
    {
        $self->_load_class( 'Module::Generic::Number::Format' ) || return( $self->pass_error );
        my $locale = $self->{locale};
        my $fmt = Module::Generic::Number::Format->new( "$num", ( $locale ? ( locale => $locale ) : () ) ) ||
            return( $self->pass_error( Module::Generic::Number::Format->error ) );
        $self->{_number} = $fmt->as_string;
    }
    else
    {
        $self->{_number} = $num;
    }
    $self->{_init_strict_use_sub} = 1;
    # $self->SUPER::init( %$opts ) || return( $self->pass_error );
    my $rv = $self->SUPER::init( %$opts );
    return( $self->pass_error ) if( !defined( $rv ) );
    $self->{_original} = $num;
    $self->{_fields} = [qw( locale _number )];
    return( $self->error( "Invalid number: $num (", overload::StrVal( $num ), ")" ) ) if( !defined( $self->{_number} ) );
    return( $self );
}

sub abs { return( shift->_func( 'abs' ) ); }

# sub asin { return( shift->_func( 'asin', { posix => 1 } ) ); }

# This class does not convert to an HASH, but the TO_JSON method will convert to a string
sub as_hash { return( $_[0] ); }

sub atan { return( shift->_func( 'atan', { posix => 1 } ) ); }

sub atan2 { return( shift->_func( 'atan2', @_ ) ); }

sub as_array
{
    my $self = shift( @_ );
    return( $self->error( 'as_array() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    $self->_load_class( 'Module::Generic::Array' ) || return( $self->pass_error );
    return( Module::Generic::Array->new( [ $self->{_number} ] ) );
}

sub as_boolean
{
    my $self = shift( @_ );
    return( $self->error( 'as_boolean() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    $self->_load_class( 'Module::Generic::Boolean' ) || return( $self->pass_error );
    return( Module::Generic::Boolean->new( $self->{_number} ? 1 : 0 ) );
}

sub as_number
{
    my $self = shift( @_ );
    return( $self->error( 'as_number() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    return( $self->{_number} + 0 );
}

sub as_scalar
{
    my $self = shift( @_ );
    return( $self->error( 'as_scalar() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    return( Module::Generic::Scalar->new( $self->{_number} ) );
}

sub as_string { return( shift->{_number} ) }

sub cbrt
{
    my $self = shift( @_ );
    return( $self->error( 'cbrt() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    if( $] >= 5.022 )
    {
        return( $self->_func( 'cbrt', { posix => 1 } ) );
    }
    else
    {
        my $n = $self->{_number};
        # Handle negative numbers properly: cbrt(-x) = -cbrt(x)
        my $res = $n < 0 ? -( ( -$n ) ** ( 1/3 ) ) : $n ** ( 1/3 );
        return if( !defined( $res ) );
        return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
        return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
        # No need to explicitly clear errors here, because clone() does it for us.
        return( $self->clone( $res ) );
    }
}

sub ceil { return( shift->_func( 'ceil', { posix => 1 } ) ); }

sub chr
{
    my $self = shift( @_ );
    return( $self->error( 'chr() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    return( Module::Generic::Scalar->new( CORE::chr( $self->{_number} ) ) );
}

sub clone
{
    my $self = shift( @_ );
    return( $self->error( 'clone() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    my $new;
    # Called as a class function
    if( !$self->_is_object( $self ) )
    {
        my $num = shift( @_ ) // 0;
        $new = $self->new( $num );
        return( $self->pass_error ) if( !defined( $new ) );
    }
    else
    {
        my $num = @_ ? shift( @_ ) : $self->{_number};
        my $actual_num = $self->_is_a( $num => 'Module::Generic::Number' ) ? $num->{_number} : $num;
        return( Module::Generic::Infinity->new( $actual_num ) ) if( isinf( $actual_num ) );
        return( Module::Generic::Nan->new( $actual_num ) ) if( isnan( $actual_num ) );
        $new = $self->SUPER::clone;
        return( $self->pass_error ) if( !defined( $new ) );
        $new->{_number} = $actual_num;
        my $old_fmt = CORE::delete( $new->{_formatter} );
        if( $old_fmt )
        {
            my $fmt = $old_fmt->clone( $actual_num );
            $new->{_formatter} = $fmt;
        }
        $new->clear_error;
    }
    return( $new );
}

sub compute
{
    my $self = shift( @_ );
    my $opts = pop( @_ );
    my( $other, $swap, $nomethod, $bitwise ) = @_;
    return( $self->error( 'compute() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    if( !defined( $opts ) || 
        ref( $opts ) ne 'HASH' || 
        !exists( $opts->{op} ) || 
        !defined( $opts->{op} ) || 
        !length( $opts->{op} ) )
    {
        die( "No argument 'op' provided" );
    }
    my $op = $opts->{op};

    my $allowed =
    {
        '+'   => 1, '-'   => 1, '*'   => 1, '/'   => 1, '%'   => 1, '**'  => 1,
        '&'   => 1, '|'   => 1, '^'   => 1, '<<'  => 1, '>>'  => 1, 'x'   => 1,
        '+='  => 1, '-='  => 1, '*='  => 1, '/='  => 1, '%='  => 1, '**=' => 1,
        '<<=' => 1, '>>=' => 1, 'x='  => 1,
        '<'   => 1, '<='  => 1, '>'   => 1, '>='  => 1, '<=>' => 1,
        '=='  => 1, '!='  => 1, 'eq'  => 1, 'ne'  => 1,
    };
    die( "Unsupported operator '$op'" ) if( !$allowed->{ $op } );

    # my $other_val = Scalar::Util::blessed( $other ) ? $other : "\"$other\"";
    # my $operation = $swap ? ( defined( $other_val ) ? $other_val : 'undef' ) . " ${op} \$self->{_number}" : "\$self->{_number} ${op} " . ( defined( $other_val ) ? $other_val : 'undef' );
    my $left  = $self->{_number};
    my $right = $other;
    if( Scalar::Util::blessed( $right ) &&
        ref( $right ) &&
        exists( $right->{_number} ) )
    {
        $right = $right->{_number};
    }

    my $operation = $swap ? "\$right ${op} \$left" : "\$left ${op} \$right";

    no warnings 'uninitialized';
    no strict;
    local $@;
    my $res = eval( $operation );
    if( $@ )
    {
        warn( "Error with formula \"$operation\" using object $self having number '$self->{_number}': $@" )
            if( $self->_warnings_is_enabled( 'Module::Generic' ) );
        return;
    }

    if( $opts->{return_object} )
    {
        # Here we need to die, because we are inside 'compute', which is call in overloading. We simply cannot return an error object.
        $self->_load_class( 'Module::Generic::Scalar' ) ||
            die( "Unable to load Module::Generic::Scalar" );
        return( Module::Generic::Scalar->new( $res ) ) if( $opts->{type} eq 'scalar' );
        return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
        return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
        # undef may be returned for example on platform supporting NaN when using <=>
        return if( !defined( $res ) );
        # If the operator is a self-assignent, then we modifie our own object, and return it
        # 1) because there is no need to create a new object; and
        # 2) because the user might expect the returned object to be the same (i.e. same even using Scalar::Util::refaddr) as the one before the operation
        if( $op =~ /=$/ )
        {
            $self->{_number} = $res;
            return( $self );
        }
        else
        {
            return( $self->clone( $res ) );
        }
    }
    elsif( $opts->{boolean} )
    {
        # return( $res ? $self->true : $self->false );
        return( $res );
    }
    else
    {
        return( $res );
    }
}

sub cos { return( shift->_func( 'cos' ) ); }

sub currency { return( shift->_call_formatter( 'currency', @_ ) ); }

sub decimal { return( shift->_call_formatter( 'decimal', @_ ) ); }

sub decimal_fill { return( shift->_call_formatter( 'decimal_fill', @_ ) ); }

sub default { return( shift->_call_formatter( 'default', @_ ) ); }

sub encoding { return( shift->_call_formatter( 'encoding', @_ ) ); }

sub exp { return( shift->_func( 'exp' ) ); }

sub floor { return( shift->_func( 'floor', { posix => 1 } ) ); }

sub format { return( shift->_call_formatter( 'format', @_ ) ); }

sub format_binary { return( shift->_call_formatter( 'format_binary', @_ ) ); }

sub format_bytes { return( shift->_call_formatter( 'format_bytes', @_ ) ); }

sub format_hex { return( shift->_call_formatter( 'format_hex', @_ ) ); }

sub format_money { return( shift->_call_formatter( 'format_money', @_ ) ); }

sub format_negative { return( shift->_call_formatter( 'format_negative', @_ ) ); }

sub format_picture { return( shift->_call_formatter( 'format_picture', @_ ) ); }

# <https://stackoverflow.com/a/483708/4814971>
sub from_binary
{
    my $self = shift( @_ );
    my $binary = shift( @_ );
    return( $self->error( 'from_binary() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    return( $self->error( "No binary value was provided to instantiate a new number object." ) ) if( !defined( $binary ) || !CORE::length( $binary ) );
    # Nice trick to convert from binary to decimal. See perlfunc -> oct
    my $res = CORE::oct( "0b${binary}" );
    return if( !defined( $res ) );
    # try-catch
    local $@;
    my $rv = eval
    {
        $self->clone( $res );
    };
    if( $@ )
    {
        return( $self->error( "Error while getting number from binary value \"$binary\": $@" ) );
    }
    elsif( !defined( $rv ) && $self->error )
    {
        return( $self->pass_error );
    }
    return( $rv );
}

sub from_hex
{
    my $self = shift( @_ );
    my $hex = shift( @_ );
    return( $self->error( 'from_hex() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    return( $self->error( "No hex value was provided to instantiate a new number object." ) ) if( !defined( $hex ) || !CORE::length( $hex ) );
    my $res = CORE::hex( $hex );
    # hex() actually does not return undef
    return( $self->error( "Error while getting number from hexadecimal value \"$hex\": $!" ) ) if( !defined( $res ) );
    # No need to explicitly call clear_error() here, because clone() does it for us.
    return( $self->clone( $res ) );
}

sub gibi_suffix { return( shift->_call_formatter( 'gibi_suffix', @_ ) ); }

sub giga_suffix { return( shift->_call_formatter( 'giga_suffix', @_ ) ); }

sub grouping { return( shift->_call_formatter( 'grouping', @_ ) ); }

sub int { return( shift->_func( 'int' ) ); }

{
    no warnings 'once';
    *is_decimal = \&is_float;
}

sub is_decimal { return( ( shift->{_number} % 1 ) != 0 ); }

sub is_empty { return( CORE::length( shift->{_number} ) == 0 ); }

sub is_even { return( !( shift->{_number} % 2 ) ); }

sub is_finite { return( isfinite( shift->{_number} ) ? 1 : 0 ); }

sub is_float { return( (POSIX::modf( shift->{_number} ))[0] != 0 ); }

sub is_infinite { return( isinf( shift->{_number} ) ? 1 : 0 ); }

sub is_int { return( (POSIX::modf( shift->{_number} ))[0] == 0 ); }

sub is_nan { return( isnan( shift->{_number} ) ); }

{
    no warnings 'once';
    *is_neg = \&is_negative;
}

sub is_negative { return( signbit( shift->{_number} ) != 0 ? 1 : 0 ); }

sub is_normal { return( isnormal( shift->{_number} ) ? 1 : 0 ); }

sub is_odd { return( shift->{_number} % 2 ); }

{
    no warnings 'once';
    *is_pos = \&is_positive;
}

sub is_positive { return( signbit( shift->{_number} ) == 0 ? 1 : 0 ); }

sub kibi_suffix { return( shift->_call_formatter( 'kibi_suffix', @_ ) ); }

sub kilo_suffix { return( shift->_call_formatter( 'kilo_suffix', @_ ) ); }

sub lang { return( shift->locale( @_ ) ); }

sub length { return( $_[0]->clone( CORE::length( $_[0]->{_number} ) ) ); }

sub locale { return( shift->_set_get_scalar_as_object(
{
    field => 'locale',
    callbacks =>
    {
        get => sub
        {
            my( $self ) = @_;
            if( $self->{_formatter} )
            {
                return( $self->{_formatter}->locale );
            }
            return( $self->{locale} );
        },
        set => sub
        {
            my( $self, $locale ) = @_;
            # If we have a formatter, we pass along the locale value.
            if( defined( $locale ) && $self->{_formatter} )
            {
                $self->{_formatter}->set_locale( $locale );
            }
            return( $locale );
        },
    }
}, @_ ) ); }

sub log { return( shift->_func( 'log' ) ); }

sub log2
{
    my $self = shift( @_ );
    return( $self->error( 'log2() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    if( $] >= 5.022 )
    {
        return( $self->_func( 'log2', { posix => 1 } ) );
    }
    else
    {
        my $n = $self->{_number};
        my $res = ( CORE::log( $n ) / CORE::log(2) );
        return if( !defined( $res ) );
        return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
        return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
        return( $self->clone( $res ) );
    }
}

sub log10 { return( shift->_func( 'log10', { posix => 1 } ) ); }

sub max
{
    my $self = shift( @_ );
    my $other = shift( @_ );
    return( $self->error( 'max() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    if( $] >= 5.022 )
    {
        return( $self->_func( 'fmax', $other, { posix => 1 } ) );
    }
    else
    {
        my $n = $self->{_number};
        # fmax: if one is NaN, return the other; otherwise the larger.
        # We don't fully replicate IEEE NaN semantics here, just the common case.
        my $res;
        if( isnan( $n ) ) { $res = $other; }
        elsif( isnan( $other ) ) { $res = $n; }
        else { $res = $n > $other ? $n : $other; }
        return if( !defined( $res ) );
        return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
        return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
        # No need to explicitly call clear_error() here, because clone() does it for us.
        return( $self->clone( $res ) );
    }
}

sub mebi_suffix { return( shift->_call_formatter( 'mebi_suffix', @_ ) ); }

sub mega_suffix { return( shift->_call_formatter( 'mega_suffix', @_ ) ); }

sub min
{
    my $self = shift( @_ );
    my $other = shift( @_ );
    return( $self->error( 'min() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    if( $] >= 5.022 )
    {
        return( $self->_func( 'fmin', $other, { posix => 1 } ) );
    }
    else
    {
        my $n = $self->{_number};
        my $res;
        if( isnan( $n ) ) { $res = $other; }
        elsif( isnan( $other ) ) { $res = $n; }
        else { $res = $n < $other ? $n : $other; }
        return if( !defined( $res ) );
        return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
        return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
        # No need to explicitly call clear_error() here, because clone() does it for us.
        return( $self->clone( $res ) );
    }
}

sub mod { return( shift->_func( 'fmod', @_, { posix => 1 } ) ); }

sub mon_decimal { return( shift->_call_formatter( 'mon_decimal', @_ ) ); }

sub mon_grouping { return( shift->_call_formatter( 'mon_grouping', @_ ) ); }

sub mon_thousand { return( shift->_call_formatter( 'mon_thousand', @_ ) ); }

sub neg_format { return( shift->_call_formatter( 'neg_format', @_ ) ); }

sub oct { return( shift->_func( 'oct' ) ); }

sub posix_strict { return( shift->_call_formatter( 'posix_strict', @_ ) ); }

sub position_neg { return( shift->_call_formatter( 'position_neg', @_ ) ); }

sub position_pos { return( shift->_call_formatter( 'position_pos', @_ ) ); }

sub pow { return( shift->_func( 'pow', @_, { posix => 1 } ) ); }

sub precede { return( shift->_call_formatter( 'precede', @_ ) ); }

sub precede_neg { return( shift->_call_formatter( 'precede_neg', @_ ) ); }

sub precede_pos { return( shift->_call_formatter( 'precede_pos', @_ ) ); }

sub precision { return( shift->_call_formatter( 'precision', @_ ) ); }

sub rand { return( shift->_func( 'rand' ) ); }

sub real { return( shift->{_number} ); }

sub round { return( shift->_call_formatter_and_replace( 'round', @_ ) ); }

sub round_zero { return( shift->_call_formatter_and_replace( 'round_zero', @_ ) ); }

sub round2 { return( shift->_call_formatter_and_replace( 'round2', @_ ) ); }

sub scalar { return( shift->as_string ); }

sub sign_neg { return( shift->_call_formatter( 'sign_neg', @_ ) ); }

sub sign_pos { return( shift->_call_formatter( 'sign_pos', @_ ) ); }

sub space_neg { return( shift->_call_formatter( 'space_neg', @_ ) ); }

sub space_pos { return( shift->_call_formatter( 'space_pos', @_ ) ); }

sub sin { return( shift->_func( 'sin' ) ); }

{
    no warnings 'once';
    *space = \&space_pos;
}

sub sqrt { return( shift->_func( 'sqrt' ) ); }

sub symbol { return( shift->_call_formatter( 'symbol', @_ ) ); }

sub tan { return( shift->_func( 'tan', { posix => 1 } ) ); }

sub thousand { return( shift->_call_formatter( 'thousand', @_ ) ); }

sub unformat
{
    my $self = shift( @_ );
    my $num  = shift( @_ );
    return( $self->error( 'unformat() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    my $fmt  = $self->_get_formatter || return( $self->pass_error );
    # Module::Generic::Number::Format->unformat returns a raw number
    my $num2 = $fmt->unformat( $num );
    if( !defined( $num2 ) && $fmt->error )
    {
        return( $self->pass_error( $fmt->error ) );
    }
    my $clone = $self->clone;
    $clone->{_original}  = $num;
    $clone->{_number}    = $num2;
    # We keep whatever parameters we have for the previous value, we clone the formatter with the new value.
    $clone->{_formatter} = $fmt->clone( $num2 );
    $clone->debug( $self->debug );
    $clone->clear_error;
    return( $clone );
}

# Returns a scalar
sub _call_formatter
{
    my $self = shift( @_ );
    my $meth = shift( @_ ) ||
        return( $self->error( "No Module::Generic::Number::Format method name was provided." ) );
    my @args = @_;
    my $fmt = $self->_get_formatter || return( $self->pass_error );
    my $code = $fmt->can( $meth );
    unless( defined( $code ) && ref( $code ) eq 'CODE' )
    {
        return( $self->error( "The method \"$meth\" is not supported by Module::Generic::Number::Format" ) );
    }
    my @rv;
    if( wantarray() )
    {
        # @rv = $fmt->$meth( scalar( @args ) ? @args : () );
        @rv = $code->( $fmt, scalar( @args ) ? @args : () );
        if( !scalar( @rv ) && $fmt->error )
        {
            return( $self->pass_error( $fmt->error ) );
        }
        $self->clear_error;
        return( @rv );
    }
    else
    {
        # $rv[0] = $fmt->$meth( scalar( @args ) ? @args : () );
        $rv[0] = $code->( $fmt, scalar( @args ) ? @args : () );
        if( !defined( $rv[0] ) && $fmt->error )
        {
            return( $self->pass_error( $fmt->error ) );
        }
        $self->clear_error;
        # Whether we are called in void context or not, this is the same.
        return( $rv[0] );
    }
}

# Same as _call_formatter, except we clone ourself and use the output as the new number value.
sub _call_formatter_and_replace
{
    my $self = shift( @_ );
    # Module::Generic::Number::Format returns a scalar, always.
    my $rv   = $self->_call_formatter( @_ );
    return( $self->pass_error ) if( !defined( $rv ) && $self->error );
    # Keep the formatter, but with the new value.
    my $fmt = $self->_get_formatter->clone( $rv );
    my $clone = $self->clone( $rv );
    $clone->{_formatter} = $fmt;
    return( $clone );
}

sub _func
{
    my $self = shift( @_ );
    my $func = shift( @_ ) || return( $self->error( "No function was provided." ) );
    return( $self->error( '_func() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    my $opts = {};
    no strict;
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $namespace = $opts->{posix} ? 'POSIX' : 'CORE';
    my $val  = @_ ? shift( @_ ) : undef;
    my $expr = defined( $val ) ? "${namespace}::${func}( \$self->{_number}, $val )" : "${namespace}::${func}( \$self->{_number} )";
    local $@;
    my $res = eval( $expr );
    return( $self->error( $@ ) ) if( $@ );
    $self->clear_error;
    return if( !defined( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
    return( $self->clone( $res ) );
}

sub _get_formatter
{
    my $self = shift( @_ );
    my $fmt  = $self->{_formatter};
    if( $self->_is_a( $fmt => 'Module::Generic::Number::Format' ) )
    {
        # We already have a formatter object set
    }
    else
    {
        $fmt = $self->_instantiate_format;
        return( $self->pass_error ) if( !defined( $fmt ) && $self->error );
        $self->{_formatter} = $fmt;
    }
    return( $fmt );
}

sub _instantiate_format
{
    my $self = shift( @_ );
    if( !ref( $self ) )
    {
        return( $self->error( "_instantiate_format() must be called on an object." ) );
    }
    my $opts   = $self->_get_args_as_hash( @_ );
    # effectively same as $self->{_number}
    # my $num    = $self->as_number;
    my $num    = $self->{_number};
    my $locale = $self->locale;
    my $debug  = $self->debug;
    $opts->{debug} = $debug if( $debug && !CORE::exists( $opts->{debug} ) );
    # The option 'locale' or 'lang' are interchangeable, because they point to the same method
    if( !CORE::exists( $opts->{locale} ) &&
        !CORE::exists( $opts->{lang} ) &&
        defined( $locale ) &&
        CORE::length( $locale // '' ) )
    {
        $opts->{locale} = $locale;
    }
    if( !defined( $num ) || !CORE::length( $num // '' ) )
    {
        return( $self->error( "No number is currently defined on our instance. A number is required to instantiate a number formatter." ) );
    }
    $self->_load_class( 'Module::Generic::Number::Format' ) ||
        return( $self->pass_error );
    my $fmt = Module::Generic::Number::Format->new( $num, %$opts ) ||
        return( $self->pass_error( Module::Generic::Number::Format->error ) );
    return( $fmt );
}

sub FREEZE
{
    my $self       = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class      = CORE::ref( $self );

    # We keep a strict allow-list to avoid accidentally freezing DBI handles or other
    # process-local state.
    my @props = ( @{$self->{_fields}} );

    my $hash = {};
    foreach my $prop ( @props )
    {
        if( CORE::exists( $self->{ $prop } ) &&
            defined( $self->{ $prop } ) &&
            CORE::ref( $self->{ $prop } ) ne 'CODE' )
        {
            $hash->{ $prop } = $self->{ $prop };
        }
    }

    # Return an array reference rather than a list so this works with Sereal and CBOR.
    # On or before Sereal version 4.023, Sereal did not support multiple values returned.
    if( $serialiser eq 'Sereal' )
    {
        require Sereal::Encoder;
        require version;

        if( version->parse( Sereal::Encoder->VERSION ) <= version->parse( '4.023' ) )
        {
            CORE::return( [$class, $hash] );
        }
    }

    # But Storable wants a list with the first element being the serialised element
    CORE::return( $class, $hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON { return( shift->as_number ); }

# NOTE: package Module::Generic::NumberSpecial
package Module::Generic::NumberSpecial;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::Number );
    use vars qw( $POS_INF $NEG_INF );
    use overload ('""'      => sub{ $_[0]->{_number} },
                  '+='      => sub{ &_catchall( @_[0..2], '+' ) },
                  '-='      => sub{ &_catchall( @_[0..2], '-' ) },
                  '*='      => sub{ &_catchall( @_[0..2], '*' ) },
                  '/='      => sub{ &_catchall( @_[0..2], '/' ) },
                  '%='      => sub{ &_catchall( @_[0..2], '%' ) },
                  '**='     => sub{ &_catchall( @_[0..2], '**' ) },
                  '<<='     => sub{ &_catchall( @_[0..2], '<<' ) },
                  '>>='     => sub{ &_catchall( @_[0..2], '>>' ) },
                  'x='      => sub{ &_catchall( @_[0..2], 'x' ) },
                  '.='      => sub{ &_catchall( @_[0..2], '.' ) },
                  nomethod  => \&_catchall,
                  fallback  => 1,
                 );
    $POS_INF = 9**9**9;
    $NEG_INF = -$POS_INF;
    if( $] >= 5.022 )
    {
        require POSIX;
        POSIX->import( qw( isinf isnan ) );
    }
    else
    {
        *isinf = sub
        {
            return(0) if( !defined( $_[0] ) );
            no warnings 'numeric';
            return( $_[0] == $POS_INF || $_[0] == $NEG_INF );
        };
        *isnan = sub
        {
            return(0) if( !defined( $_[0] ) );
            no warnings 'numeric';
            return( $_[0] != $_[0] );
        };
    }
    use Wanted;
    our( $VERSION ) = '0.1.0';
};

sub new
{
    my $this = CORE::shift( @_ );
    my $val  = CORE::shift( @_ );
    if( $] < 5.022 )
    {
        my $str = "$val";
        my $is_nan;
        {
            # Suppress numeric comparison warnings: on perl < 5.22, IEEE special values
            # may carry a non-numeric string representation depending on the C library,
            # and the standard NaN-detection idiom ($val != $val) will warn if $val
            # happens to be a plain non-numeric string. The check is still semantically
            # correct.
            no warnings 'numeric';
            $is_nan = ( $val != $val );
        }
        # Fallback to string pattern matching (covers libc variants like:
        # "nan", "-nan", "nan(0x...)", "1.#QNAN", "1.#IND", "nanq", etc.)
        $is_nan ||= ( $str =~ /^[+-]?(?:nan|1\.\#(?:ind|qnan|snan))/i );
        if( $is_nan )
        {
            $val = 'NaN';
        }
        else
        {
            no warnings 'numeric';
            if( $val == $POS_INF )
            {
                $val = 'Inf';
            }
            elsif( $val == -$POS_INF )
            {
                $val = '-Inf';
            }
            elsif( $str =~ /^([+-]?)(?:inf(?:inity)?|1\.\#inf)/i )
            {
                $val = ( $1 eq '-' ) ? '-Inf' : 'Inf';
            }
        }
    }
    return( bless( { _number => $val } => ( ref( $this ) || $this ) ) );
}

sub clone { return( shift->new( @_ ) ); }

sub is_finite { return(0); }

sub is_float { return(0); }

sub is_infinite { return(0); }

sub is_int { return(0); }

sub is_nan { return(0); }

sub is_normal { return(0); }

sub length { return( CORE::length( shift->{_number} ) ); }

sub round_zero
{
    my $self = shift( @_ );
    my @args = @_;
    if( $] >= 5.022 )
    {
        return( $self->_func( 'round', @args, { posix => 1 } ) );
    }
    else
    {
        my $n = $self->{_number};
        # round to nearest, ties away from zero (same semantics as C99 round())
        my $res;
        if( $n >= 0 )
        {
            $res = CORE::int( $n + 0.5 );
        }
        else
        {
            $res = -CORE::int( -$n + 0.5 );
        }
        return if( !defined( $res ) );
        return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
        return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
        return( $self->clone( $res ) );
    }
}

sub _catchall
{
    my( $self, $other, $swap, $op ) = @_;
    no strict;
    my $expr = $swap ? "$other $op $self->{_number}" : "$self->{_number} $op $other";
    local $@;
    my $res = eval( $expr );
    CORE::warn( "Error evaluating expression \"$expr\": $@" ) if( $@ );
    return if( $@ );
    return( Module::Generic::Number->new( $res ) ) if( isnormal( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
    return( $res );
}

sub _func
{
    my $self = shift( @_ );
    my $func = shift( @_ ) || return( $self->error( "No function was provided." ) );
    my $opts = {};
    no strict;
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $namespace = $opts->{posix} ? 'POSIX' : 'CORE';
    my $val  = @_ ? shift( @_ ) : undef;
    my $expr = defined( $val ) ? "${namespace}::${func}( $self->{_number}, $val )" : "${namespace}::${func}( $self->{_number} )";
    local $@;
    my $res = eval( $expr );
    CORE::warn( $@ ) if( $@ );
    return if( !defined( $res ) );
    # return( Module::Generic::Number->new( $res ) ) if( isnormal( $res ) );
    return( $self->clone( $res ) ) if( isnormal( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( isnan( $res ) );
    return( $res );
}

# NOTE: AUTOLOAD
AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # If we are chained, return our null object, so the chain continues to work
    if( want( 'OBJECT' ) )
    {
        # No, this is NOT a typo. rreturn() is a function of module Wanted
        rreturn( $_[0] );
    }
    # Otherwise, we return infinity, whether positive or negative or NaN depending on what was set
    return( $_[0]->{_number} );
};

# NOTE: DESTROY
DESTROY {};

# NOTE: package Module::Generic::Infinity
# Purpose is to allow chaining of methods when infinity is returned
# At the end of the chain, Inf or -Inf is returned
package Module::Generic::Infinity;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::NumberSpecial );
    use overload (
        '""' => sub { return( $_[0]->{_number} ); },
        fallback => 1,
    );

    our( $VERSION ) = '0.1.0';
};

sub is_infinite { return(1); }

# NOTE: package Module::Generic::Nan
package Module::Generic::Nan;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::NumberSpecial );
    use overload (
        '""' => sub { 'NaN' },
        fallback => 1,
    );
    our( $VERSION ) = '0.1.0';
};

sub is_nan { return(1); }

1;

__END__
