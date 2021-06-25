##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Datetime.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2021/03/20
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Datetime;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use overload (
        q{""}   => sub { $_[0]->{dt}->stringify },
        bool    => sub () { 1 },
        q{>}    => sub { &op( @_, '>' ) },
        q{>=}   => sub { &op( @_, '>=' ) },
        q{<}    => sub { &op( @_, '<' ) },
        q{<=}   => sub { &op( @_, '<=' ) },
        q{==}   => sub { &op( @_, '==' ) },
        q{!=}   => sub { &op( @_, '!=' ) },
        q{-}    => sub { &op_minus_plus( @_, '-' ) },
        q{+}    => sub { &op_minus_plus( @_, '+' ) },
        fallback => 1,
    );
    use DateTime;
    use DateTime::Format::Strptime;
    use Nice::Try dont_want => 1;
    use Regexp::Common;
    use Scalar::Util ();
    our( $ERROR );
    our $VERSION = 'v0.1.0';
    our $TS_RE = qr/
    (?<year>\d{4})
    -
    (?<month>\d{1,2})
    -
    (?<day>\d{1,2})
    (?:
        ([[:blank:]]+|T)
        (?<hour>\d{1,2})
        \:
        (?<minute>\d{1,2})
        \:
        (?<second>\d{1,2})
        (?<tz_offset>
            (?:
                (?<tz_sign>[-+])
                (?<tz_offset1>\d{1,2})(?<tz_offset2>\d{2})
            )
        )?
    )?
    /x;
};

sub new
{
    my $this = shift( @_ );
    my $dt   = shift( @_ ) || return;
    return( bless( { dt => $dt->clone } => ( ref( $this ) || $this ) )->init( @_ ) );
}

sub op
{
    no overloading;
    my( $self, $other, $swap, $op ) = @_;
    my $dt1 = $self->{dt};
    my $dt2;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'DateTime' ) )
    {
        $dt2 = $other;
    }
    elsif( Scalar::Util::blessed( $other ) && ref( $other ) eq ref( $self ) )
    {
        $dt2 = $other->{dt};
    }
    ## Might trigger an error if this does not work with DateTime, but that's the developer's problem
    elsif( Scalar::Util::blessed( $other ) )
    {
        $dt2 = $other;
    }
    ## Unix time
    elsif( $other =~ /^\d{10}$/ )
    {
        $dt2 = DateTime->from_epoch( epoch => $other, time_zone => 'local' );
        $dt2->set_formatter( $self->formatter );
    }
    elsif( $other =~ /^$TS_RE$/ )
    {
        my $hash = {};
        my $re = { %+ };
        my $offset;
        @$hash{ qw( year month day hour minute second ) } = @$re{ qw( year month day hour minute second ) };
        for( keys( %$hash ) )
        {
            $hash->{ $_ } = int( $hash->{ $_ } );
        }
        
        if( $re->{tz_offset1} )
        {
            $offset = 3600 * $re->{tz_offset1};
            $offset += 60 * $re->{tz_offset2} if( length( $re->{tz_offset2} ) );
            $offset *= -1 if( $re->{tz_sign} && $re->{tz_sign} ne '-' );
            $re->{tz_offset} = $re->{tz_sign} . $re->{tz_offset1} . $re->{tz_offset2};
        }
        
        try
        {
            $dt2 = DateTime->new( %$hash );
            $dt2->set_time_zone( $re->{tz_offset} ) if( length( $re->{tz_offset} ) );
            my $dt3 = $dt2->clone;
            $dt3->set_time_zone( 'UTC' );
        }
        catch( $e )
        {
            warn( "Unable to create DateTime object from parsing '$other': $e\n" );
        }
    }
    use overloading;
    my $eval = $swap ? "\$dt2 $op \$dt1" : "\$dt1 $op \$dt2";
    my $res = eval( $eval );
    return( $res );
}

sub op_minus_plus
{
    no overloading;
    my( $self, $other, $swap, $op ) = @_;
    my $dt1 = $self->{dt};
    $other = $self->_get_other( $other );
    use overloading;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'DateTime::Duration' ) )
    {
        ## Duration [+-] DateTime => update the datetime object in place
        if( $swap )
        {
            if( $op eq '-' )
            {
                $dt1->subtract_duration( $other );
            }
            else
            {
                $dt1->add_duration( $other );
            }
            return( $self );
        }
        else
        {
            my $clone = !defined( $swap ) ? $dt1 : $dt1->clone;
            if( $op eq '-' )
            {
                $clone->subtract_duration( $other );
            }
            else
            {
                $clone->add_duration( $other );
            }
            return( !defined( $swap ) ? $self : $self->_make_my_own( $clone ) );
        }
    }
    elsif( Scalar::Util::blessed( $other ) && $other->isa( 'DateTime' ) )
    {
        if( $op eq '-' )
        {
            # return( $swap ? $other->subtract( $dt1 ) : $dt1->subtract( $other ) );
            return( $self->_make_my_own( $swap ? ( $other - $dt1 ) : ( $dt1 - $other ) ) );
        }
        else
        {
            return( $self->_make_my_own( $swap ? ( $other + $dt1 ) : ( $dt1 + $other ) ) );
        }
    }
    
    my $v = "$other" unless( ref( $other ) );
    die( "\$other ($other) is not a number, a DateTime, or a DateTime::Duration object!\n" ) if( $v !~ /^(?:$RE{num}{real}|$RE{num}{int})$/ );
    try
    {
        my $new_dt;
        if( $op eq '-' )
        {
            if( $swap )
            {
                my $clone = $dt1->clone;
                my $ts = $clone->epoch;
                $clone->set_time_zone( 'local' );
                my $new_ts = $v - $ts;
                $new_dt = DateTime->from_epoch( epoch => $new_ts, time_zone => $dt1->time_zone );
                my $strp = DateTime::Format::Strptime->new(
                    pattern => '%s',
                    locale => 'en_GB',
                    time_zone => $new_dt->time_zone,
                );
                $new_dt->set_formatter( $strp );
            }
            else
            {
                my $clone = !defined( $swap ) ? $dt1 : $dt1->clone;
                $new_dt = $clone->subtract( seconds => $v );
                ## If $swap is undefined, this is an assignment operation such as -=
                return( $self ) if( !defined( $swap ) );
            }
        }
        ## +
        else
        {
            if( $swap )
            {
                $new_dt = $dt1->add( seconds => $v );
            }
            else
            {
                my $clone = !defined( $swap ) ? $dt1 : $dt1->clone;
                $new_dt = $clone->add( seconds => $v );
                return( $self ) if( !defined( $swap ) );
            }
        }
        return( $self->_make_my_own( $new_dt ) );
    }
    catch( $e )
    {
        use overloading;
        if( $op eq '-' )
        {
            die( "Failed to subtract ", ( $swap ? $self : $v ), " from ", ( $swap ? $v : $self ), ": $e\n" );
        }
        else
        {
            die( "Failed to add ", ( $swap ? $self : $v ), " to ", ( $swap ? $v : $self ), ": $e\n" );
        }
    }
}

sub _get_other
{
    my( $self, $other ) = @_;
    if( Scalar::Util::blessed( $other ) )
    {
        if( $other->isa( 'Module::Generic::Datetime' ) )
        {
            $other = $other->{dt};
        }
        elsif( $other->isa( 'Module::Generic::Datetime::Interval' ) )
        {
            $other = $other->{interval};
        }
    }
    return( $other );
}

sub _make_my_own
{
    my( $self, $res ) = @_;
    if( Scalar::Util::blessed( $res ) && 
        $res->isa( 'DateTime::Duration' ) )
    {
        return( Module::Generic::Datetime::Interval->new( $res ) );
    }
    elsif( Scalar::Util::blessed( $res ) && 
           $res->isa( 'DateTime' ) )
    {
        return( $self->new( $res ) );
    }
    else
    {
        return( $res );
    }
}

DESTROY
{
};

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    die( "DateTime object is gone !\n" ) if( !ref( $self->{dt} ) );
    no overloading;
    my $dt = $self->{dt};
    try
    {
        if( $dt->can( $method ) )
        {
            return( $dt->$method( @_ ) );
        }
        else
        {
            return( $self->error( "No method \"$method\" available in DateTime" ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error trying to call DateTime::$method with arguments: '", join( "', '", @_ ), "': $e" ) );
    }
};

# XXX package Module::Generic::Datetime::Interval
package Module::Generic::Datetime::Interval;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use overload (
        '+'      => '__add_overload',
        '-'      => '__subtract_overload',
        '*'      => '__multiply_overload',
        '<=>'    => '__compare_overload',
        'cmp'    => '__compare_overload',
        fallback => 1,
    );
    use DateTime;
    use Nice::Try;
    use Scalar::Util ();
    use Want;
};

sub new
{
    my $this = shift( @_ );
    my $dur  = shift( @_ ) || return;
    return( bless( { interval => $dur->clone } => ( ref( $this ) || $this ) )->init( @_ ) );
}

sub dump
{
    my $self = shift( @_ );
    my @info = $self->{interval}->in_units( qw( years months weeks days hours minutes seconds nanoseconds ) );
    return( sprintf( <<EOT, @info ) );
Years ... %d
Months .. %d
Weeks ... %d
Days .... %d
Hours ... %d
Minutes . %d
Seconds . %d
EOT
}

sub days : lvalue { return( shift->__set_get_unit( 'days', @_ ) ); }

sub hours : lvalue { return( shift->__set_get_unit( 'hours', @_ ) ); }

sub minutes : lvalue { return( shift->__set_get_unit( 'minutes', @_ ) ); }

sub months : lvalue { return( shift->__set_get_unit( 'months', @_ ) ); }

sub nanoseconds : lvalue { return( shift->__set_get_unit( 'nanoseconds', @_ ) ); }

sub seconds : lvalue { return( shift->__set_get_unit( 'seconds', @_ ) ); }

sub weeks : lvalue { return( shift->__set_get_unit( 'weeks', @_ ) ); }

sub years : lvalue { return( shift->__set_get_unit( 'years', @_ ) ); }

sub __add_overload
{
    my( $self, $other, $swap ) = @_;
    my $dur1 = $self->{interval};
    $other = $self->_get_other( $other );
    my $res;
    if( !defined( $swap ) )
    {
        $dur1 += $other;
        return( $self );
    }
    else
    {
        $res = $swap ? ( $other + $dur1 ) : ( $dur1 + $other );
        return( $self->_make_my_own( $res ) );
    }
}

sub __compare_overload
{
    my( $self, $other, $swap ) = @_;
    my $d1 = $self->{interval};
    my $d2 = $self->_get_other( $other );
    my $dt = DateTime->now;
    ( $d1, $d2 ) = ( $d2, $d1 ) if( $swap );
 
    return( DateTime->compare(
        $dt->clone->add_duration( $d1 ),
        $dt->clone->add_duration( $d2 )
    ) );
}

sub __multiply_overload
{
    my( $self, $num, $swap ) = @_;
    my @units = qw( months days minutes seconds nanoseconds );
    if( "$num" =~ /^\d+$/ )
    {
        $num = int( "$num" );
        ## If $swap is undefined, it means an assignment operation like *=
        my $clone = !defined( $swap ) ? $self->{interval} : $self->{interval}->clone;
        $clone->multiply( $num );
        return( !defined( $swap ) ? $self : $self->_make_my_own( $clone ) );
    }
    elsif( Scalar::Util::blessed( $num ) && $num->isa( 'Module::Generic::Datetime::Interval' ) )
    {
        my $clone = !defined( $swap ) ? $self->{interval} : $self->{interval}->clone;
        foreach my $t ( @units )
        {
            $clone->{ $t } *= $num->{ $t };
        }
        $clone->_normalize_nanoseconds if( $clone->{nanoseconds} );
        return( !defined( $swap ) ? $self : $self->_make_my_own( $clone ) );
    }
    else
    {
        return( $self );
    }
}

sub __set_get_unit : lvalue
{
    my $self = shift( @_ );
    my $unit = shift( @_ );
    my $dur  = $self->{interval};
    my $coderef = $dur->can( $unit );
    
    local $update_value = sub
    {
        my $v = shift( @_ );

        if( $unit eq 'years' )
        {
            $dur->{years} = $v;
            my $p_months = $dur->{months};
            if( $p_months > 12 )
            {
                my $n_years = int( $p_months / 12 );
                $p_months -= ( 12 * $n_years );
                $dur->{months} = ( $dur->{years} * 12 ) + $p_months;
            }
        }
        elsif( $unit eq 'months' )
        {
            $dur->{months} = $v;
        }
        elsif( $unit eq 'weeks' )
        {
            $dur->{weeks} = $v;
            if( $dur->{days} > 7 )
            {
                my $p_days = $dur->{days};
                my $n_weeks = int( $p_days / 7 );
                $p_days -= ( 7 * $n_weeks );
                $dur->{days} = ( $dur->{weeks} * 7 ) + $p_days;
            }
        }
        elsif( $unit eq 'days' )
        {
            $dur->{days} = ( $dur->{weeks} * 7 ) + $v;
        }
        elsif( $unit eq 'hours' )
        {
            $dur->{hours} = $v;
            if( $dur->{minutes} > 60 )
            {
                my $p_minutes = $dur->{minutes};
                my $n_hours = int( $p_minutes / 60 );
                $p_minutes -= ( 60 * $n_hours );
                $dur->{minutes} = ( $dur->{hours} * 60 ) + $p_minutes;
            }
        }
        elsif( $unit eq 'minutes' )
        {
            $dur->{minutes} = ( $dur->{hours} * 60 ) + $v;
        }
        elsif( $unit eq 'seconds' )
        {
            $dur->{seconds} = $v;
        }
        elsif( $unit eq 'nanoseconds' )
        {
            $dur->{nanoseconds} = $v;
            $self->_normalize_nanoseconds;
        }
    };
    
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        my( $v ) = want( 'ASSIGN' );
        $update_value->( $v );
        $coderef->( $dur );
        return( $dur->{ $unit } );
    }
    else
    {
        if( @_ )
        {
            my $v = shift( @_ );
            $update_value->( $v );
        }
        my $curr_v = $coderef->( $dur );
        return( $curr_v ) if( want( 'LVALUE' ) );
        rreturn( $curr_v );
    }
    return;
}

sub __subtract_overload
{
    my( $self, $other, $swap ) = @_;
    my $dur1 = $self->{interval};
    $other = $self->_get_other( $other );
    my $res;
    if( !defined( $swap ) )
    {
        $dur1 -= $other;
        return( $self );
    }
    else
    {
        $res = $swap ? ( $other - $dur1 ) : ( $dur1 - $other );
        return( $self->_make_my_own( $res ) );
    }
}

sub _get_other
{
    my( $self, $other ) = @_;
    if( Scalar::Util::blessed( $other ) )
    {
        if( $other->isa( 'Module::Generic::Datetime' ) )
        {
            $other = $other->{dt};
        }
        elsif( $d2->isa( 'Module::Generic::Datetime::Interval' ) )
        {
            $other = $other->{interval};
        }
    }
    return( $other );
}

sub _make_my_own
{
    my( $self, $res ) = @_;
    if( Scalar::Util::blessed( $res ) && 
        $res->isa( 'DateTime::Duration' ) )
    {
        return( $self->new( $res ) );
    }
    elsif( Scalar::Util::blessed( $res ) && 
           $res->isa( 'DateTime' ) )
    {
        return( Module::Generic::Datetime->new( $res ) );
    }
    else
    {
        return( $res );
    }
}

DESTROY
{
};

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    die( "DateTime::Duration object is gone !\n" ) if( !ref( $self->{interval} ) );
    no overloading;
    my $dur = $self->{interval};
    try
    {
        if( $dur->can( $method ) )
        {
            return( $dur->$method( @_ ) );
        }
        else
        {
            return( $self->error( "No method \"$method\" available in DateTime::Duration" ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error trying to call DateTime::Duration::$method with arguments: '", join( "', '", @_ ), "': $e" ) );
    }
};

1;

__END__

=encoding utf8

=head1 NAME

Module::Generic::Datetime - A DateTime wrapper for enhanced features

=head1 SYNOPSIS

    use Module::Generic::Datetime;
    my $dt = DateTime->new;
    my $gdt = Module::Generic::Datetime->new( $dt );
    # No you can do operations that are not normally possible with DateTime
    # Compare a dt object with a unix timestamp
    if( $gdt > time() )
    {
        # do something
    }
    elsif( $gdt < '2020-03-01 07:12:10+0900' )
    {
        # do something
    }
    # and of course, comparison with other dt works as before
    elsif( $gdt >= $dt )
    {
        # do something
    }

    # Remove 10 seconds from time object
    $gdt -= 10;
    # Add 5 seconds and get a new object
    my $dt2 = $gdt + 5;

    # Get the difference as an interval between two objects
    my $interval = $dt1 - $dt2;
    # DateTime::Duration are represented by Module::Generic::Datetime::Interval
    # and extra manipulations are possible
    # Add 7 seconds
    $int += 7;
    # Change the days
    $int->days( 5 );
    # or using lvalue
    $int->days = 5;
    # or multiply everything (years, months, weeks, days, hours, minutes, seconds and nanoseconds) in the interval by 2
    $int *= 2
    # Multiply one interval by another:
    my $new_interval = $int1 * $int2;
    # or multiply with assignment
    $int1 *= $int2;
    # Then add the interval to the datetime object
    $dt += $int;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION


=encoding utf-8

=head1 NAME - Module::Generic::Datetime

=cut
