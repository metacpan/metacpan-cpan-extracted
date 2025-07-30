##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/DateTime.pm
## Version v0.6.2
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2025/04/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::DateTime;
BEGIN
{
    use v5.26.1;
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $ERROR $TS_RE $VERSION );
    use DateTime 1.57;
    use DateTime::Format::Strptime 1.79;
    use DateTime::TimeZone 2.51;
    use Module::Generic::Global ':const';
    use Regexp::Common;
    use Scalar::Util ();
    use overload (
        q{""}   => sub{ $_[0]->{dt}->stringify },
        bool    => sub{1},
        q{>}    => sub{ &op( @_, '>' ) },
        q{>=}   => sub{ &op( @_, '>=' ) },
        q{<}    => sub{ &op( @_, '<' ) },
        q{<=}   => sub{ &op( @_, '<=' ) },
        q{==}   => sub{ &op( @_, '==' ) },
        q{!=}   => sub{ &op( @_, '!=' ) },
        q{-}    => sub{ &op_minus_plus( @_, '-' ) },
        q{+}    => sub{ &op_minus_plus( @_, '+' ) },
        fallback => 1,
    );
    $TS_RE = qr/
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
    our $VERSION = 'v0.6.2';
};

BEGIN
{
    unless( defined( &DateTime::FREEZE ) )
    {
        *DateTime::FREEZE = sub
        {
            my $self = shift( @_ );
            my $class = ref( $self );
            my $params = {};
            for( qw( utc_rd_days utc_rd_secs rd_nanosecs locale tz formatter ) )
            {
                $params->{ $_ } = $self->{ $_ };
            }
            # not used yet, but may be handy in the future.
            $params->{version} = ( $DateTime::VERSION || 'git' );
            return( [$class, $params] );
        };
    }
    unless( defined( &DateTime::THAW ) )
    {
        *DateTime::THAW = sub
        {
            my( $this, $serialiser, $ref ) = @_;
            my( $class, $params ) = @$ref;
            my( $locale, $tz, $formatter ) = @$params{qw( locale tz formatter )};
            delete( $params->{version} );
            if( ref( $locale ) eq 'ARRAY' )
            {
                $locale = $locale->[0] if( ref( $locale->[0] ) eq 'ARRAY' );
                my $locale_class = $locale->[0];
                $locale = &{"${locale_class}\::THAW"}( $locale_class, $serialiser, $locale );
            }
            if( ref( $tz ) eq 'ARRAY' )
            {
                $tz = $tz->[0] if( ref( $tz->[0] ) eq 'ARRAY' );
                my $tz_class = $tz->[0];
                $tz = &{"${tz_class}\::THAW"}( $tz_class, $serialiser, $tz );
            }

            my $object = bless({
                utc_vals => [ @$params{qw(utc_rd_days utc_rd_secs rd_nanosecs)} ],
                tz => $tz,
            }, 'DateTime::_Thawed' );

            my %formatter = defined( $params->{formatter} ) ? ( formatter => $params->{formatter} ) : ();
            my $new       = $class->from_object(
                object => $object,
                locale => $locale,
                %formatter,
            );
            return( $new );
        };
    }
    unless( defined( &DateTime::TimeZone::FREEZE ) )
    {
        *DateTime::TimeZone::FREEZE = sub
        {
            my $self = shift;
            my $class = ref( $self ) || $self;
            return( [ $class, $self->name ] );
        };
    }
    unless( defined( &DateTime::TimeZone::THAW ) )
    {
        *DateTime::TimeZone::THAW = sub
        {
            my( $this, $serialiser, $serial ) = @_;
            my( $class, $tzone ) = @$serial;
            my $self = $class->new( name => $tzone );
            return( $self );
        };
    }

    unless( defined( &DateTime::TimeZone::OffsetOnly::FREEZE ) )
    {
        *DateTime::TimeZone::OffsetOnly::FREEZE = sub
        {
            my( $self, undef ) = @_;
            my $class = ref( $self );
            return( [$class, $self->name] );
        };
    }
    unless( defined( &DateTime::TimeZone::OffsetOnly::THAW ) )
    {
        *DateTime::TimeZone::OffsetOnly::THAW = sub
        {
            my( $this, $serialiser, $serial ) = @_;
            my( $class, $name ) = @$serial;
            my $self = $class->new( offset => $name );
            return( $self );
        };
    }

    unless( defined( &DateTime::Locale::FromData::FREEZE ) )
    {
        *DateTime::Locale::FromData::FREEZE = sub
        {
            my( $self, undef ) = @_;
            my $class = ref( $self );
            return( [$class, $self->code] );
        };
    }
    unless( defined( &DateTime::Locale::FromData::THAW ) )
    {
        *DateTime::Locale::FromData::THAW = sub
        {
            my( $self, undef, $ref ) = @_;
            my( $class, $code ) = @$ref;
            require DateTime::Locale;
            my $new = DateTime::Locale->load( $code );
            return( $new );
        };
    }

    unless( defined( &DateTime::Locale::Base::FREEZE ) )
    {
        *DateTime::Locale::Base::FREEZE = sub
        {
            my( $self, undef ) = @_;
            my $class = ref( $self );
            return( [$class, $self->id] );
        };
    }
    unless( defined( &DateTime::Locale::Base::THAW ) )
    {
        *DateTime::Locale::Base::THAW = sub
        {
            my( $self, undef, $ref ) = @_;
            my( $class, $id ) = @$ref;
            require DateTime::Locale;
            my $new = DateTime::Locale->load( $id );
            return( $new );
        };
    }
    Module::Generic->_implement_freeze_thaw( qw( DateTime::TimeZone::UTC ) );
};

use v5.26.1;
# use strict;
no warnings 'redefine';

sub new
{
    my $this = shift( @_ );
    my $dt;
    # Module::Generic::DateTime->new( $datetime_object );
    # Module::Generic::DateTime->new( $datetime_object, $hash_ref_of_options );
    # Module::Generic::DateTime->new( $datetime_object, %hash_of_options );
    # Module::Generic::DateTime->new( $datetime_object, %hash_of_options );
    # Module::Generic::DateTime->new( $hash_ref_of_options );
    # Module::Generic::DateTime->new( %hash_of_options );
    if( scalar( @_ ) &&
        $this->_is_a( $_[0] => 'DateTime' ) )
    {
        $dt = shift( @_ );
    }
    my $opts = $this->_get_args_as_hash( @_ );

    if( !defined( $dt ) )
    {
        # try-catch
        local $@;
        my @params = qw( year month day hour minute second nanosecond );
        my $args = {};
        for( @params )
        {
            $args->{ $_ } = $opts->{ $_ } if( CORE::exists( $opts->{ $_ } ) && CORE::length( $opts->{ $_ } ) );
        }

        if( scalar( keys( %$args ) ) )
        {
            $dt = eval
            {
                DateTime->new( %$opts );
            };
            if( $@ )
            {
                return( $this->error( $@ ) );
            }
        }

        unless( defined( $dt ) )
        {
            eval
            {
                if( !exists( $opts->{formatter} ) )
                {
                    $opts->{formatter} = DateTime::Format::Strptime->new(
                        pattern => "%FT%T%z",
                        locale => "en_GB",
                    );
                }
                $dt = DateTime->now( %$opts );
            };
            if( $@ )
            {
                if( $@ =~ /Cannot[[:blank:]\h]+determine[[:blank:]\h]+local[[:blank:]\h]+time[[:blank:]\h]+zone/i )
                {
                    warn( "Warning: Your system is missing key timezone components. Module::Generic::DateTime is reverting to UTC instead of local time zone." );
                    $opts->{time_zone} = 'UTC';
                    $dt = DateTime->new( %$opts );
                    my $dt_fmt = DateTime::Format::Strptime->new(
                        pattern => '%FT%T%z',
                        locale => 'en_GB',
                    );
                    $dt->set_formatter( $dt_fmt );
                }
                else
                {
                    return( $this->error( "Error while creating a DateTime object: $@" ) );
                }
            }
        }
    }
    return( bless( { dt => $dt->clone } => ( ref( $this ) || $this ) )->init( @_ ) );
}

# This class does not convert to an HASH, but the TO_JSON method will convert to a string
sub as_hash { return( $_[0] ); }

sub as_string { return( shift->stringify( @_ ) ); }

sub datetime { return( shift->_set_get_object_without_init( 'dt' => 'DateTime' ) ); }

sub from_epoch
{
    my $this = shift( @_ );
    my $dt;
    # try-catch
    local $@;
    eval
    {
        $dt = DateTime->from_epoch( @_ );
    };
    if( $@ )
    {
        return( $this->error( "Error trying to create a new DateTime object using new_from_epoch(): $@" ) );
    }
    return( $this->new( $dt ) );
}

sub now
{
    my $this = shift( @_ );
    my $dt;
    # try-catch
    local $@;
    eval
    {
        $dt = DateTime->now( @_ );
    };
    if( $@ )
    {
        return( $this->error( "Error trying to create a new DateTime object: $@" ) );
    }
    return( $this->new( $dt ) );
}

sub op
{
    no overloading;
    my( $self, $other, $swap, $op ) = @_;
    my $class = ref( $self ) || $self;
    no strict;
    my $dt1 = $self->{dt};
    my $dt2;
    # We use a simple $class as key, because it does not matter whether this is in a process or thread
    my $err_key = $class;
    my $repo = Module::Generic::Global->new( 'local_tz' => $class, key => $err_key );

    if( Scalar::Util::blessed( $other ) && $other->isa( 'DateTime' ) )
    {
        $dt2 = $other;
    }
    elsif( Scalar::Util::blessed( $other ) && ref( $other ) eq ref( $self ) )
    {
        $dt2 = $other->{dt};
    }
    # Might trigger an error if this does not work with DateTime, but that's the developer's problem
    elsif( Scalar::Util::blessed( $other ) )
    {
        $dt2 = $other;
    }
    # Unix time
    elsif( $other =~ /^\d{10}$/ )
    {
        my $has_local_tz = $repo->get;
        if( !defined( $has_local_tz ) )
        {
            # try-catch
            local $@;
            eval
            {
                $dt2 = DateTime->from_epoch( epoch => $other, time_zone => 'local' );
            };

            $has_local_tz = $@ ? 0 : 1;
            $repo->set( $has_local_tz );

            if( $@ )
            {
                warn( "Your system is missing key timezone components. ${class} is reverting to UTC instead of local time zone." );
                $dt2 = DateTime->from_epoch( epoch => $other, time_zone => 'UTC' );
            }
        }
        else
        {
            # try-catch
            local $@;
            eval
            {
                $dt2 = DateTime->from_epoch( epoch => $other, time_zone => ( $has_local_tz ? 'local' : 'UTC' ) );
            };
            if( $@ )
            {
                warn( "Error trying to set a DateTime object using ", ( $has_local_tz ? 'local' : 'UTC' ), " time zone" );
                $dt2 = DateTime->from_epoch( epoch => $other, time_zone => 'UTC' );
            }
        }
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

        # try-catch
        local $@;
        eval
        {
            $dt2 = DateTime->new( %$hash );
            $dt2->set_time_zone( $re->{tz_offset} ) if( length( $re->{tz_offset} ) );
            my $dt3 = $dt2->clone;
            $dt3->set_time_zone( 'UTC' );
        };
        if( $@ )
        {
            warn( "Unable to create DateTime object from parsing '$other': $@\n" );
        }
    }
    use overloading;
    my $eval = $swap ? "\$dt2 $op \$dt1" : "\$dt1 $op \$dt2";
    # I do not want to localise $@ so it can be checked by the caller
    my $res = eval( $eval );
    return( $res );
}

sub op_minus_plus
{
    no overloading;
    my( $self, $other, $swap, $op ) = @_;
    my $class = ref( $self ) || $self;
    my $dt1 = $self->{dt};
    $other = $self->_get_other( $other );
    use overloading;
    my $err_key = $class;
    my $repo = Module::Generic::Global->new( 'local_tz' => $class, key => $err_key );

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

    my $v;
    $v = "$other" if( !ref( $other ) || ( ref( $other ) && overload::Method( $other => '""' ) ) );
    die( "\$other (", overload::StrVal( $other // '' ), ") is not a number, a DateTime, or a DateTime::Duration object!\n" ) if( !defined( $v ) || $v !~ /^(?:$RE{num}{real}|$RE{num}{int})$/ );
    my $new_dt;
    if( $op eq '-' )
    {
        if( $swap )
        {
            # try-catch
            local $@;
            my( $clone, $ts );
            eval
            {
                $clone = $dt1->clone;
                $ts = $clone->epoch;
            };
            if( $@ )
            {
                die( "Error cloning and getting epoch value for DateTime object: $@" );
            }

            my $has_local_tz = $repo->get;
            if( !defined( $has_local_tz ) )
            {
                # try-catch
                local $@;
                eval
                {
                    $clone->set_time_zone( 'local' );
                };

                $has_local_tz = $@ ? 0 : 1;
                $repo->set( $has_local_tz );

                if( $@ )
                {
                    $clone->set_time_zone( 'UTC' );
                    warn( "Your system is missing key timezone components. ${class} is reverting to UTC instead of local time zone.\n" );
                }
            }

            # try-catch
            local $@;
            my $new_ts = $v - $ts;
            eval
            {
                $new_dt = DateTime->from_epoch( epoch => $new_ts, time_zone => $dt1->time_zone );
                my $strp = DateTime::Format::Strptime->new(
                    pattern => '%s',
                    locale => 'en_GB',
                    time_zone => $new_dt->time_zone,
                );
                $new_dt->set_formatter( $strp );
            };
            if( $@ )
            {
                die( "Error instantiating a new DateTime object with epoch timestamp $new_ts and time zone ", $dt1->time_zone );
            }
        }
        else
        {
            # try-catch
            local $@;
            eval
            {
                my $clone = !defined( $swap ) ? $dt1 : $dt1->clone;
                $new_dt = $clone->subtract( seconds => $v );
            };
            if( $@ )
            {
                die( "Failed to subtract ", ( $swap ? $self : $v ), " from ", ( $swap ? $v : $self ), ": $@" );
            }
            # If $swap is undefined, this is an assignment operation such as -=
            return( $self ) if( !defined( $swap ) );
        }
    }
    # +
    else
    {
        if( $swap )
        {
            $new_dt = $dt1->add( seconds => $v );
        }
        else
        {
            # try-catch
            local $@;
            eval
            {
                my $clone = !defined( $swap ) ? $dt1 : $dt1->clone;
                $new_dt = $clone->add( seconds => $v );
            };
            if( $@ )
            {
                die( "Failed to add ", ( $swap ? $self : $v ), " to ", ( $swap ? $v : $self ), ": $@" );
            }
            return( $self ) if( !defined( $swap ) );
        }
    }
    return( $self->_make_my_own( $new_dt ) );
}

sub _get_other
{
    my( $self, $other ) = @_;
    if( Scalar::Util::blessed( $other ) )
    {
        if( $other->isa( 'Module::Generic::DateTime' ) )
        {
            $other = $other->{dt};
        }
        elsif( $other->isa( 'Module::Generic::DateTime::Interval' ) )
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
        return( Module::Generic::DateTime::Interval->new( $res ) );
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

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
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

sub TO_JSON
{
    my $self = CORE::shift( @_ );
    CORE::return( '' ) if( !$self->{dt} || !Scalar::Util::blessed( $self->{dt} ) );
    CORE::return( $self->{dt}->stringify );
}

# NOTE: DESTROY
# Avoid getting caught by AUTOLOAD
DESTROY
{
    # <https://perldoc.perl.org/perlobj#Destructors>
    CORE::local( $., $@, $!, $^E, $? );
    CORE::return if( ${^GLOBAL_PHASE} eq 'DESTRUCT' );
    my $self = CORE::shift( @_ );
    CORE::return if( !CORE::defined( $self ) );
    undef( $self->{dt} ) if( defined( $self->{dt} ) );
    return( $self );
};

# NOTE: AUTOLOAD
AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    if( !ref( $self ) )
    {
        if( DateTime->can( $method ) )
        {
            my $rv = DateTime->$method( @_ );
            if( Scalar::Util::blessed( $rv ) && $rv->isa( 'DateTime' ) )
            {
                return( $class->new( $rv ) );
            }
            else
            {
                return( $rv );
            }
        }
        else
        {
            die( "Method ${method} unsupported by DateTime\n" );
        }
    }
    die( "DateTime object is gone !\n" ) if( !ref( $self->{dt} ) );
    no overloading;
    my $dt = $self->{dt};
    if( $dt->can( $method ) )
    {
        my $rv;
        # try-catch
        local $@;
        eval
        {
            $rv = $dt->$method( @_ );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to call DateTime::$method with arguments: '", join( "', '", @_ ), "': $@" ) );
        }
        return( $rv );
    }
    else
    {
        return( $self->error( "No method \"$method\" available in DateTime" ) );
    }
};

# NOTE: package Module::Generic::DateTime::Interval
package Module::Generic::DateTime::Interval;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use overload (
        '""'     => 'as_string',
        'bool'   => sub{1},
        '+'      => '__add_overload',
        '-'      => '__subtract_overload',
        '*'      => '__multiply_overload',
        '<=>'    => '__compare_overload',
        'cmp'    => '__compare_overload',
        fallback => 1,
    );
    use DateTime;
    use Scalar::Util ();
    use Wanted;
};

sub new
{
    my $this = shift( @_ );
    my $dur  = shift( @_ ) || return;
    return( bless( { interval => $dur->clone } => ( ref( $this ) || $this ) )->init( @_ ) );
}

# This class does not convert to an HASH
sub as_hash { return( $_[0] ); }

sub as_string
{
    my $self = shift( @_ );
    return( $self->{interval}->in_units( 'seconds' ) );
}

sub dump
{
    my $self = shift( @_ );
    my @info = $self->{interval}->in_units( qw( years months weeks days hours minutes seconds nanoseconds ) );
    my $tmpl = <<EOT;
Years ... %d
Months .. %d
Weeks ... %d
Days .... %d
Hours ... %d
Minutes . %d
Seconds . %d
EOT
    return( sprintf( $tmpl, @info ) );
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
    elsif( Scalar::Util::blessed( $other ) && 
           ( $other->isa( 'DateTime::Duration' ) || $other->isa( 'Module::Generic::DateTime::Interval' ) ) )
    {
        $other = $other->{interval} if( $other->isa( 'Module::Generic::DateTime::Interval' ) );
        $res = $swap ? ( $other + $dur1 ) : ( $dur1 + $other );
        return( $self->_make_my_own( $res ) );
    }
    elsif( !ref( $other ) || overload::Method( $other => '""' ) )
    {
        $other = $other + 0;
        my $d = $dur1->in_units( 'seconds' );
        my $n = $swap ? ( $other + $d ) : ( $d + $other );
        $res = DateTime::Duration->new( seconds => $n );
        return( $self->_make_my_own( $res ) );
    }
    else
    {
        die( "Usupported data '", ref( $other ), "' in subtraction\n" );
    }
}

sub __compare_overload
{
    my( $self, $other, $swap ) = @_;
    my $d1 = $self->{interval};
    my $d2 = $self->_get_other( $other );
    # my $dt = DateTime->now;
    ( $d1, $d2 ) = ( $d2, $d1 ) if( $swap );
    my $to_secs = sub
    {
        my $this = shift( @_ );
        if( Scalar::Util::blessed( $this ) )
        {
            if( $this->isa( 'DateTime::Duration' ) )
            {
                return( $this->in_units( 'seconds' ) );
            }
            elsif( $this->isa( 'DateTime' ) )
            {
                return( $this->epoch );
            }
            elsif( $this->isa( 'Module::Generic::DateTime' ) )
            {
                return( $this->{dt}->epoch );
            }
            elsif( $this->isa( 'Module::Generic::DateTime::Duration' ) )
            {
                return( $this->{duration}->in_units( 'seconds' ) );
            }
            elsif( overload::Method( $this => '""' ) )
            {
                return( $this + 0 );
            }
            else
            {
                die( "Unsupported object '", ref( $this ), "'\n" );
            }
        }
        else
        {
            return( $this + 0 );
        }
    };

#     return( DateTime->compare(
#         $dt->clone->add_duration( $d1 ),
#         $dt->clone->add_duration( $d2 )
#     ) );
    my $d1_secs = $to_secs->( $d1 );
    my $d2_secs = $to_secs->( $d2 );
    return( $d1_secs <=> $d2_secs );
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
    elsif( Scalar::Util::blessed( $num ) && $num->isa( 'Module::Generic::DateTime::Interval' ) )
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

    my $update_value = sub
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
    elsif( Scalar::Util::blessed( $other ) && 
           ( $other->isa( 'DateTime::Duration' ) || $other->isa( 'Module::Generic::DateTime::Interval' ) ) )
    {
        $other = $other->{interval} if( $other->isa( 'Module::Generic::DateTime::Interval' ) );
        $res = $swap ? ( $other - $dur1 ) : ( $dur1 - $other );
        return( $self->_make_my_own( $res ) );
    }
    elsif( !ref( $other ) || overload::Method( $other => '""' ) )
    {
        $other = $other + 0;
        my $d = $dur1->in_units( 'seconds' );
        my $n = $swap ? ( $other - $d ) : ( $d - $other );
        $res = DateTime::Duration->new( seconds => $n );
        return( $self->_make_my_own( $res ) );
    }
    else
    {
        die( "Usupported data '", ref( $other ), "' in subtraction\n" );
    }
}

sub _get_other
{
    my( $self, $other ) = @_;
    if( Scalar::Util::blessed( $other ) )
    {
        if( $other->isa( 'Module::Generic::DateTime' ) )
        {
            $other = $other->{dt};
        }
        elsif( $other->isa( 'Module::Generic::DateTime::Interval' ) )
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
        return( Module::Generic::DateTime->new( $res ) );
    }
    else
    {
        return( $res );
    }
}

# NOTE: DESTROY
DESTROY
{
    # <https://perldoc.perl.org/perlobj#Destructors>
    CORE::local( $., $@, $!, $^E, $? );
    my $self = CORE::shift( @_ );
    CORE::return if( ${^GLOBAL_PHASE} eq 'DESTRUCT' );
    CORE::return if( !CORE::defined( $self ) );
    undef( $self->{interval} ) if( defined( $self->{interval} ) );
    return( $self );
};

# NOTE: AUTOLOAD
AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    die( "DateTime::Duration object is gone !\n" ) if( !ref( $self->{interval} ) );
    no overloading;
    my $dur = $self->{interval};
    if( $dur->can( $method ) )
    {
        my $rv;
        # try-catch
        local $@;
        eval
        {
            $rv = $dur->$method( @_ );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to call DateTime::Duration::$method with arguments: '", join( "', '", @_ ), "': $@" ) );
        }
        return( $rv );
    }
    else
    {
        return( $self->error( "No method \"$method\" available in DateTime::Duration" ) );
    }
};

# NOTE: FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Module::Generic::DateTime - A DateTime wrapper for enhanced features

=head1 SYNOPSIS

    use Module::Generic::DateTime;

    my $dt = DateTime->new;
    my $gdt = Module::Generic::DateTime->new( $dt );
    # or directly will instantiate a default DateTime value based on DateTime->now
    my $gdt = Module::Generic::DateTime->new;

    # Now you can do operations that are not normally possible with DateTime
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
    # DateTime::Duration are represented by Module::Generic::DateTime::Interval
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

    v0.6.2

=head1 DESCRIPTION

L<Module::Generic::DateTime> is a thin wrapper around L<DateTime> to provide additional features as exemplified above.

It also enables the L<DateTime> object to be thawed and frozen and converted to L<JSON> with the respective methods C<STORABLE_freeze>, C<STORABLE_thaw>, C<TO_JSON>

All other method calls not in this API are passed to L<DateTime> using C<AUTOLOAD> with the added benefit that, if a method called triggers a fatal exception, it is caught using L<Nice::Try> try-catch block and an L<error|Module::Generic/error> is set and C<return> is returned instead.

=head1 CONSTRUCTOR

=head2 new

Provided with an optional L<DateTime> object and this returns a new instance of L<Module::Generic::DateTime>.

If no L<DateTime> object was provided, this will instantiate one implicitly and set the formatter to stringify it to an iso8601 string, such as: C<2022-03-08T14:22:10+0000>. By default the instantiated L<DateTime> object use the default time zone, which is C<GMT>. You can change the time zone afterward using L<DateTime/set_time_zone>:

    $dt->set_time_zone( 'Asia/Tokyo' );

=head2 from_epoch

    my $d = Module::Generic::DateTime->from_epoch( epoch => $unix_timestamp );

Instantiate a new L<Module::Generic::DateTime> using the L<DateTime> method C<from_epoch>. Any parameters are passed through to L<DateTime/from_epoch>

If a L<DateTime> error occurs, it will be caught and an L<error|Module::Generic/error> will be set and C<undef> will be returned.

=head2 now

    my $d = Module::Generic::DateTime->now;

Instantiate a new L<Module::Generic::DateTime> using the L<DateTime> method C<now>. Any parameters are passed through to L<DateTime/now>

If a L<DateTime> error occurs, it will be caught and an L<error|Module::Generic/error> will be set and C<undef> will be returned.

=head1 METHODS

=head2 as_string

This is an alias to L</stringify>

=head2 datetime

Sets or gets the underlying L<DateTime> object.

=head2 op

This method is called to overload the following operations:

=over 4

=item * C<""> stringification

=item * C<bool>

=item * C<>> greater than

=item * C<>=> greater or equal than

=item * C<<> lower than

=item * C<<=> lower or equal than

=item * C<==> euqal

=item * C<!=> not equal

=item * C<-> minus

=item * C<+> plus

=back

=head2 op_minus_plus

This methods handles cases of overloading for C<minus> and C<plus>

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

=for Pod::Coverage TO_JSON

Serialisation by L<CBOR|CBOR::XS>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>) is supported by this package. To that effect, the following subroutines are implemented: C<FREEZE>, C<THAW>, C<STORABLE_freeze> and C<STORABLE_thaw>

Additionally, upon loading L<Module::Generic::DateTime>, it will ensure the following L<DateTime> modules also have a C<FREEZE> and C<THAW> subroutines if not defined already: L<DateTime>, L<DateTime::TimeZone>, L<DateTime::TimeZone::OffsetOnly>, L<DateTime::Locale::FromData>, L<DateTime::Locale::Base>

=head1 THREAD & PROCESS SAFETY

C<Module::Generic::DateTime> is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event. It relies on L<Module::Generic::Global> for thread-safe storage of shared state and employs synchronisation mechanisms to prevent data corruption and race conditions.

=head2 Synchronisation Mechanisms

=over 4

=item * B<Shared State>

The module uses L<Module::Generic::Global> to cache the availability of the system’s local timezone in the C<local_tz> namespace, storing a boolean (C<0> or C<1>) indicating whether the local timezone is supported. This repository is C<:shared> when C<CAN_THREADS> is true (Perl supports ithreads), protected by L<perlfunc/lock> for Perl threads or L<APR::ThreadRWLock> for mod_perl threaded MPMs without L<threads>. In non-threaded environments, the repository is shared across processes, requiring no additional synchronisation.

=item * B<DateTime Operations>

Methods like L</op> and L</op_minus_plus> perform timezone checks and DateTime operations, which are thread-safe as they rely on L<Module::Generic::Global>’s synchronisation. The underlying L<DateTime> module is thread-safe for most operations, and this module ensures no shared mutable state is accessed without proper locking.

=back

=head2 Context Key Isolation

The C<local_tz> namespace uses a class-level key (C<< <class> >>), where C<class> is C<Module::Generic::DateTime>. This ensures timezone support is cached across processes, with no thread-specific granularity needed, as timezone availability is a global property. The key format enables cross-process sharing, and threaded environments (C<HAS_THREADS> true) maintain isolation via L<Module::Generic::Global>’s synchronisation.

=head2 mod_perl Considerations

=over 4

=item * B<Prefork MPM>

Data is cross-process, requiring no additional synchronisation, as all processes share the same C<local_tz> repository.

=item * B<Threaded MPMs (Worker/Event)>

The C<local_tz> repository is shared across threads and processes, protected by L<Module::Generic::Global>’s synchronisation. Users should call C<Module::Generic::Global->cleanup_register> in mod_perl handlers to clear the repository after requests, preventing memory leaks in long-running processes.

=item * B<Thread-Unsafe Functions>

Avoid Perl functions like C<localtime>, C<readdir>, C<srand>, or operations like C<chdir>, C<umask>, C<chroot> in threaded MPMs, as they may affect all threads. Consult L<perlthrtut|http://perldoc.perl.org/perlthrtut.html> and L<mod_perl documentation|https://perl.apache.org/docs/2.0/user/coding/coding.html#Thread_environment_Issues> for details.

=back

=head2 Thread-Safety Considerations

The module’s thread-safety relies on:

=over 4

=item * B<Shared Repository>: The C<local_tz> namespace is initialised as C<:shared> when C<CAN_THREADS> is true, ensuring safe access across threads and processes.

=item * B<Locking>: L<perlfunc/lock> or L<APR::ThreadRWLock> protects all read/write operations to the repository.

=item * B<Immutable State>: Beyond C<local_tz>, the module avoids shared mutable state, relying on L<DateTime>’s thread-safe operations.

=back

In environments where C<%INC> manipulation (e.g., by L<forks>) emulates L<threads>, C<HAS_THREADS> and C<IN_THREAD> may return true. This is generally safe, as L<forks> provides a compatible C<tid> method, but users in untrusted environments should verify C<$INC{'threads.pm'}> points to the actual L<threads> module.

For maximum safety, users running mod_perl with threaded MPMs should ensure Perl is compiled with ithreads and explicitly load L<threads>, or use Prefork MPM for single-threaded operation.

=head1 SEE ALSO

L<Module::Generic>, L<Module::Generic::DateTime::Interval>, L<DateTime>, L<DateTime::Format::Strptime>, L<DatetTime::TimeZone>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2000-2024 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
