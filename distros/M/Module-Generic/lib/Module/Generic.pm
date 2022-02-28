## -*- perl -*-
##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic.pm
## Version v0.21.3
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/08/24
## Modified 2022/02/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic;
BEGIN
{
    use v5.26.1;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw( $MOD_PERL $AUTOLOAD $ERROR $PARAM_CHECKER_LOAD_ERROR $VERBOSE $DEBUG $SILENT_AUTOLOAD $PARAM_CHECKER_LOADED $CALLER_LEVEL $COLOUR_NAME_TO_RGB $true $false $DEBUG_LOG_IO %RE $stderr $stderr_raw );
    use Config;
    use Class::Load ();
    use Clone ();
    use Data::Dump;
    use Devel::StackTrace;
    use Encode ();
    use File::Spec ();
    use Module::Metadata;
    use Nice::Try;
    use Number::Format;
    use Scalar::Util qw( openhandle );
    use Sub::Util ();
    # use B;
    # To get some context on what the caller expect. This is used in our error() method to allow chaining without breaking
    use version;
    use Want;
    use Exporter ();
    our @ISA         = qw( Exporter );
    our @EXPORT      = qw( );
    our @EXPORT_OK   = qw( subclasses );
    our %EXPORT_TAGS = ();
    our $VERSION     = 'v0.21.3';
    # local $^W;
    # mod_perl/2.0.10
    if( exists( $ENV{MOD_PERL} )
        &&
        ( $MOD_PERL = $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ ) )
    {
        select( ( select( STDOUT ), $| = 1 )[ 0 ] );
        require Apache2::Log;
        # For _is_class_loaded method
        require Apache2::Module;
        require Apache2::ServerUtil;
        require Apache2::RequestUtil;
        require Apache2::ServerRec;
        require ModPerl::Util;
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :log OK ) );
    }
    $VERBOSE     = 0;
    $DEBUG       = 0;
    $SILENT_AUTOLOAD      = 1;
    $PARAM_CHECKER_LOADED = 0;
    $CALLER_LEVEL         = 0;
    $COLOUR_NAME_TO_RGB   = {};
    no strict 'refs';
    $DEBUG_LOG_IO = undef();
    use constant COLOUR_OPEN  => '<';
    use constant COLOUR_CLOSE => '>';
    use constant HAS_THREADS  => ( $Config{useithreads} && $INC{'threads.pm'} );
};

use strict;

# We put it here to avoid 'redefine' error
require Module::Generic::Array;
require Module::Generic::Boolean;
require Module::Generic::DateTime;
require Module::Generic::Dynamic;
require Module::Generic::Exception;
require Module::Generic::File;
# Module::Generic::File->import( qw( stderr ) );
require Module::Generic::Hash;
require Module::Generic::Iterator;
require Module::Generic::Null;
require Module::Generic::Number;
require Module::Generic::Scalar;

require IO::File;
our $stderr = IO::File->new;
$stderr->fdopen( fileno( STDERR ), 'w' );
$stderr->binmode( ':utf8' );
$stderr->autoflush( 1 );
our $stderr_raw = IO::File->new;
$stderr_raw->fdopen( fileno( STDERR ), 'w' );
$stderr_raw->binmode( ':raw' );
$stderr_raw->autoflush( 1 );
# $stderr = stderr( binmode => 'utf-8', autoflush => 1 );
# $stderr_raw = stderr( binmode => 'raw', autoflush => 1 );

{
    no warnings 'once';
    $true  = $Module::Generic::Boolean::true;
    $false = $Module::Generic::Boolean::false;
}
    
# no warnings 'redefine';
sub import
{
    my $self = shift( @_ );
    my( $pkg, $file, $line ) = caller();
    local $Exporter::ExportLevel = 1;
    Exporter::import( $self, @_ );
    our $SILENT_AUTOLOAD;
    
    ( my $dir = $pkg ) =~ s/::/\//g;
    my $path  = $INC{ $dir . '.pm' };
    if( defined( $path ) )
    {
        ## Try absolute path name
        $path =~ s/^(.*)$dir\.pm$/$1auto\/$dir\/autosplit.ix/;
        eval
        {
            local $SIG{ '__DIE__' }  = sub{ };
            local $SIG{ '__WARN__' } = sub{ };
            require $path;
        };
        if( $@ )
        {
            $path = "auto/$dir/autosplit.ix";
            eval
            {
                local $SIG{ '__DIE__' }  = sub{ };
                local $SIG{ '__WARN__' } = sub{ };
                require $path;
            };
        }
        if( $@ )
        {
            CORE::warn( $@ ) unless( $SILENT_AUTOLOAD );
        }
    }
}

sub new
{
    my $that  = shift( @_ );
    my $class = ref( $that ) || $that;
    my $self  = {};
    no strict 'refs';
    if( defined( ${ "${class}\::OBJECT_PERMS" } ) )
    {
        require Module::Generic::Tie;
        my %hash  = ();
        my $obj   = tie(
        %hash, 
        'Module::Generic::Tie', 
        'pkg'   => [ __PACKAGE__, $class ],
        'perms' => ${ "${class}::OBJECT_PERMS" },
        );
        $self  = \%hash;
    }
    bless( $self, $class );
    if( defined( ${ "${class}\::LOG_DEBUG" } ) )
    {
        $self->{log_debug} = ${ "${class}::LOG_DEBUG" };
    }
    
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->init( @_ ) );
    }
    my $new = $self->init( @_ );
    # Returned undef; there was an error potentially
    if( !defined( $new ) )
    {
        # If we are called on an object, we hand it the error so the caller can check it using the object:
        # my $new = $old->new || die( $old->error );
        if( $self->_is_object( $that ) && $that->can( 'pass_error' ) )
        {
            return( $that->pass_error( $self->error ) );
        }
        else
        {
            return( $self->pass_error );
        }
    };
    return( $new );
}

# This is used to transform package data set into hash reference suitable for api calls
# If package use AUTOLOAD, those AUtILOAD should make sure to create methods on the fly so they become defined
sub as_hash
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $p = {};
    $p = shift( @_ ) if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' );
    $p->{_seen} = {} if( !exists( $p->{_seen} ) || !ref( $p->{_seen} ) );
    # $self->message( 3, "Parameters are: ", sub{ $self->dumper( $p ) } );
    my $class = ref( $this );
    no strict 'refs';
    my @methods = grep( !/^(?:new|init)$/, grep{ defined &{"${class}::$_"} } keys( %{"${class}::"} ) );

    $self->messagef( 3, "The following methods found in package $class: '%s'.", join( "', '", sort( @methods ) ) );
    use strict 'refs';
    my $ref = {};
    my $added_subs = CORE::exists( $this->{_added_method} ) && ref( $this->{_added_method} ) eq 'HASH'
        ? $this->{_added_method}
        : {};
    
    my $check;
    $check = sub
    {
        my $meth = shift( @_ );
        my $rv   = shift( @_ );
        no overloading;
        $self->message( 3, "Value for method '$meth' is '$rv'." );
        use overloading;
        if( $p->{json} && ( ref( $rv ) eq 'JSON::PP::Boolean' || ref( $rv ) eq 'Module::Generic::Boolean' || ref( $rv ) eq 'Class::Boolean' ) )
        {
            # $self->message( 3, "Encoding boolean to true or false for method '$meth'." );
            # $ref->{ $meth } = Module::Generic::Boolean::TO_JSON( $ref->{ $meth } );
            return( Module::Generic::Boolean::TO_JSON( $ref->{ $meth } ) );
        }
        elsif( $self->_is_object( $rv ) )
        {
            # Order of the checks here matter
            if( $rv->can( 'as_hash' ) && overload::Overloaded( $rv ) && overload::Method( $rv, '""' ) )
            {
                $rv = $rv . '';
                return( $rv );
            }
            elsif( $rv->can( 'as_hash' ) )
            {
                $self->message( 3, "$rv is an object (", ref( $rv ), ") capable of as_hash, calling it." );
                if( !$p->{_seen}->{ Scalar::Util::refaddr( $rv ) } )
                {
                    $p->{_seen}->{ Scalar::Util::refaddr( $rv ) }++;
                    $rv = $rv->as_hash( $p );
                    $self->message( 4, "returned value is '$rv' -> ", sub{ $self->dump( $rv ) });
                    if( Scalar::Util::blessed( $rv ) )
                    {
                        return( $check->( $meth => $rv ) );
                    }
                    else
                    {
                        return( $rv );
                    }
                }
                else
                {
                    return;
                }
            }
            # If the object can be overloaded, and has no TO_JSON method we get its string representation here.
            # If it has a TO_JSON and we are asked to return data for json, we let the JSON module call the TO_JSON method
            elsif( overload::Overloaded( $rv ) && overload::Method( $rv, '""' ) )
            {
                $rv = "$rv" unless( $p->{json} && $rv->can( 'TO_JSON' ) );
                return( $rv );
            }
        }
        else
        {
            return( $rv );
        }
    };
    
    foreach my $meth ( sort( @methods ) )
    {
        next if( substr( $meth, 0, 1 ) eq '_' );
        next if( CORE::exists( $added_subs->{ $meth } ) );
        my $rv = eval{ $self->$meth };
        if( $@ )
        {
            warn( "An error occured while accessing method $meth: $@\n" );
            next;
        }
        $rv = $check->( $meth => $rv );
        next if( !defined( $rv ) );
        
        # $self->message( 3, "Checking field '$meth' with value '$rv'." );
        
        if( ref( $rv ) eq 'HASH' )
        {
            $ref->{ $meth } = $rv if( scalar( keys( %$rv ) ) );
        }
        # If method call returned an array, like array of string or array of object such as in data from Net::API::Stripe::List
        elsif( ref( $rv ) eq 'ARRAY' )
        {
            my $arr = [];
            foreach my $this_ref ( @$rv )
            {
                # my $that_ref = ( $self->_is_object( $this_ref ) && $this_ref->can( 'as_hash' ) ) ? $this_ref->as_hash : $this_ref;
                my $that_ref;
                if( $self->_is_object( $this_ref ) && $this_ref->can( 'as_hash' ) )
                {
                    if( !$p->{_seen}->{ Scalar::Util::refaddr( $this_ref ) } )
                    {
                        $p->{_seen}->{ Scalar::Util::refaddr( $this_ref ) }++;
                        $that_ref = $this_ref->as_hash( $p );
                    }
                }
                else
                {
                    $that_ref = $this_ref;
                }
                CORE::push( @$arr, $that_ref );
            }
            $ref->{ $meth } = $arr if( scalar( @$arr ) );
        }
        elsif( !ref( $rv ) )
        {
            $ref->{ $meth } = $rv if( CORE::length( $rv ) );
        }
        elsif( CORE::length( "$rv" ) )
        {
            $self->message( 3, "Adding value '$rv' to field '$meth' in hash \$ref" );
            $ref->{ $meth } = $rv;
        }
    }
    return( $ref );
}

sub clear
{
    goto( &clear_error );
}

sub clear_error
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    $this->{error} = ${ "$class\::ERROR" } = '';
    return( $self );
}

sub clone
{
    my $self  = shift( @_ );
    try
    {
        # $self->message( 3, "Cloning object '", overload::StrVal( $self ), "'." );
        return( Clone::clone( $self ) );
    }
    catch( $e )
    {
        return( $self->error( "Error cloning object \"", overload::StrVal( $self ), "\": $e" ) );
    }
}

sub colour_close { return( shift->_set_get( 'colour_close', @_ ) ); }

sub colour_closest
{
    my $self    = shift( @_ );
    my $colour  = uc( shift( @_ ) );
    my $this  = $self->_obj2h;
    my $colours = 
    {
    '000000000' => 'black',
    '000000255' => 'blue',
    '000255000' => 'green',
    '000255255' => 'cyan',
    '255000000' => 'red',
    '255000255' => 'magenta',
    '255255000' => 'yellow',
    '255255255' => 'white',
    };
    my( $red, $green, $blue ) = ( '', '', '' );
    our $COLOUR_NAME_TO_RGB;
    if( $colour =~ /^[A-Z]+([A-Z\s]+)*$/ )
    {
        if( !scalar( keys( %$COLOUR_NAME_TO_RGB ) ) )
        {
            # $self->message( 3, "Processing colour map in <DATA> section." );
            while( <DATA> )
            {
                chomp;
                next if( /^[[:blank:]]*$/ );
                last if( /^\=/ );
                my( $r, $g, $b, $name ) = split( /[[:blank:]]+/, $_, 4 );
                $COLOUR_NAME_TO_RGB->{ lc( $name ) } = [ $r, $g, $b ];
            }
            close( DATA );
        }
        if( CORE::exists( $COLOUR_NAME_TO_RGB->{ lc( $colour ) } ) )
        {
            ( $red, $green, $blue ) = @{$COLOUR_NAME_TO_RGB->{ lc( $colour ) }};
        }
    }
    # Colour all in decimal??
    elsif( $colour =~ /^\d{9}$/ )
    {
        # $self->message( 3, "Got colour all in decimal. Less work to do..." );
        $red   = substr( $colour, 0, 3 );
        $green = substr( $colour, 3, 3 );
        $blue  = substr( $colour, 6, 3 );
    }
    # Colour in hexadecimal, convert it
    elsif( $colour =~ /^[A-F0-9]+$/ )
    {
        $red   = hex( substr( $colour, 0, 2 ) );
        $green = hex( substr( $colour, 2, 2 ) );
        $blue  = hex( substr( $colour, 4, 2 ) );
    }
    # Clueless
    else
    {
        # Not undef, but rather empty string. Undef is associated with an error
        return( '' );
    }
    my $dec_colour = CORE::sprintf( '%3d%3d%3d', $red, $green, $blue );
    my $last = '';
    my @colours = reverse( sort( keys( %$colours ) ) );
    $red    = CORE::sprintf( '%03d', $red );
    $green  = CORE::sprintf( '%03d', $green );
    $blue   = CORE::sprintf( '%03d', $blue );
    my $cur = CORE::sprintf( '%03d%03d%03d', $red, $green, $blue );
    my( $red_ok, $green_ok, $blue_ok ) = ( 0, 0, 0 );
    # $self->message( 3, "Current colour: '$cur'." );
    for( my $i = 0; $i < scalar( @colours ); $i++ )
    {
        my $r = CORE::sprintf( '%03d', substr( $colours[ $i ], 0, 3 ) );
        my $g = CORE::sprintf( '%03d', substr( $colours[ $i ], 3, 3 ) );
        my $b = CORE::sprintf( '%03d', substr( $colours[ $i ], 6, 3 ) );
 
        my $r_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 0, 3 ) );
        my $g_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 3, 3 ) );
        my $b_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 6, 3 ) );
 
        # $self->message( 3, "$r ($red), $g ($green), $b ($blue)" );
        if( $red == $r ||
            ( $red < $r && $red > int( $r / 2 ) ) ||
            ( $red > $r && $red < int( $r_p / 2 ) && $r_p ) ||
            $red > $r )
        {
            $red_ok++;
        }
 
        if( $red_ok )
        {
            if( $green == $g ||
                ( $green < $g && $green > int( $g / 2 ) ) ||
                ( $green > $g && $green < int( $g_p / 2 ) && $g_p ) ||
                $green > $g )
            {
                $blue_ok++;
            }
        } 
 
        if( $blue_ok )
        {
            if( $blue == $b ||
                ( $blue < $b && $blue > int( $b / 2 ) ) ||
                ( $blue > $b && $blue < int( $b_p / 2 ) && $b_p ) ||
                $blue > $b )
            {
                $last = $colours[ $i ];
                last;
            }
        }
    }
    return( $colours->{ $last } );
}

sub colour_format
{
    my $self = shift( @_ );
    # style, colour or color and text
    my $opts = shift( @_ );
    return( $self->error( "Parameter hash provided is not an hash reference." ) ) if( !$self->_is_hash( $opts ) );
    my $this = $self->_obj2h;
    # To make it possible to use either text or message property
    $opts->{text} = CORE::delete( $opts->{message} ) if( CORE::length( $opts->{message} ) && !CORE::length( $opts->{text} ) );
    return( $self->error( "No text was provided to format." ) ) if( !CORE::length( $opts->{text} ) );
    
    $opts->{colour} //= CORE::delete( $opts->{color} ) || CORE::delete( $opts->{fg_colour} ) || CORE::delete( $opts->{fg_color} ) || CORE::delete( $opts->{fgcolour} ) || CORE::delete( $opts->{fgcolor} );
    $opts->{bgcolour} //= CORE::delete( $opts->{bgcolor} ) || CORE::delete( $opts->{bg_colour} ) || CORE::delete( $opts->{bg_color} );
    
    my $bold      = "\e[1m";
    my $underline = "\e[4m";
    my $reverse   = "\e[7m";
    my $normal    = "\e[m";
    my $cls       = "\e[H\e[2J";
    my $styles =
    {
    # Bold
    b       => 1,
    bold    => 1,
    strong  => 1,
    # Italic
    i       => 3,
    italic  => 3,
    # Underline
    u       => 4,
    underline => 4,
    underlined => 4,
    blink   => 5,
    # Reverse
    r       => 7,
    reverse => 7,
    reversed => 7,
    # Concealed
    c       => 8,
    conceal => 8,
    concealed => 8,
    strike  => 9,
    striked  => 9,
    striken  => 9,
    };
    
    my $convert_24_To_8bits = sub
    {
        my( $r, $g, $b ) = @_;
        $self->message( 9, "Converting $r, $g, $b to 8 bits" );
        return( ( POSIX::floor( $r * 7 / 255 ) << 5 ) +
                ( POSIX::floor( $g * 7 / 255 ) << 2 ) +
                ( POSIX::floor( $b * 3 / 255 ) ) 
              );
    };
    
    # opacity * original + (1-opacity)*background = resulting pixel
    # https://stackoverflow.com/a/746934/4814971
    my $colour_with_alpha = sub
    {
        my( $r, $g, $b, $a, $bg ) = @_;
        ## Assuming a white background (255)
        my( $bg_r, $bg_g, $bg_b ) = ( 255, 255, 255 );
        if( ref( $bg ) eq 'HASH' )
        {
            ( $bg_r, $bg_g, $bg_b ) = @$bg{qw( red green blue )};
        }
        $r = POSIX::round( ( $a * $r ) + ( ( 1 - $a ) * $bg_r ) );
        $g = POSIX::round( ( $a * $g ) + ( ( 1 - $a ) * $bg_g ) );
        $b = POSIX::round( ( $a * $b ) + ( ( 1 - $a ) * $bg_b ) );
        return( [$r, $g, $b] );
    };
    
    my $check_colour = sub
    {
        my $col = shift( @_ );
        # $self->message( 3, "Checking colour '$col'." );
        # $colours or $bg_colours
        my $map = shift( @_ );
        my $code;
        my $light;
        # Example: 'light red' or 'light_red'
        if( $col =~ /^(?:(?<light>bright|light)[[:blank:]\_]+)?
        (?<colour>
            (?:[a-zA-Z]+)(?:[[:blank:]]+\w+)?
            |
            (?<rgb_type>rgb[a]?)\([[:blank:]]*(?<red>\d{1,3})[[:blank:]]*\,[[:blank:]]*(?<green>\d{1,3})[[:blank:]]*\,[[:blank:]]*(?<blue>\d{1,3})
            (?:[[:blank:]]*\,[[:blank:]]*(?<opacity>\d(?:\.\d+)?))?[[:blank:]]*
            \)
        )$/xi )
        {
            my %regexp = %+;
            $self->message( 9, "Light colour request '$col'. Capture: ", sub{ $self->dumper( \%regexp ) } );
            ( $light, $col ) = ( $+{light}, $+{colour} );
            if( CORE::length( $+{rgb_type} ) &&
                CORE::length( $+{red} ) &&
                CORE::length( $+{green} ) &&
                CORE::length( $+{blue} ) )
            {
                if( $+{opacity} || $light )
                {
                    my $opacity = CORE::length( $+{opacity} )
                        ? $+{opacity}
                        : $light
                            ? 0.5
                            : 1;
                    $col = CORE::sprintf( 'rgba(%03d%03d%03d,%.1f)', $+{red}, $+{green}, $+{blue}, $opacity );
                }
                else
                {
                    $col = CORE::sprintf( 'rgb(%03d%03d%03d)', $+{red}, $+{green}, $+{blue} );
                }
            }
            else
            {
                $self->message( 9, "Colour '$col' is not rgb[a]" );
            }
        }
        elsif( $col =~ /^(?<rgb_type>rgb[a]?)\([[:blank:]]*(?<red>\d{1,3})[[:blank:]]*\,[[:blank:]]*(?<green>\d{1,3})[[:blank:]]*\,[[:blank:]]*(?<blue>\d{1,3})[[:blank:]]*(?:\,[[:blank:]]*(?<opacity>\d(?:\.\d+)?))?[[:blank:]]*\)$/i )
        {
            if( $+{opacity} )
            {
                $col = CORE::sprintf( 'rgba(%03d%03d%03d,%.1f)', $+{red}, $+{green}, $+{blue}, $+{opacity} );
            }
            else
            {
                $col = CORE::sprintf( '%03d%03d%03d', $+{red}, $+{green}, $+{blue} );
            }
        }
        else
        {
            $self->message( 9, "Colour '$col' failed to match our rgba regexp." );
        }
        
        my $col_ref;
        if( $col =~ /^rgb[a]?\((?<red>\d{3})(?<green>\d{3})(?<blue>\d{3})\)$/i )
        {
            $col_ref = {};
            %$col_ref = %+;
            $self->message( 9, "Rgb colour '$+{red}', '$+{green}' and '$+{blue}' found: ", sub{ $self->dumper( $col_ref ) });
            return({
                _24bits => [@$col_ref{qw( red green blue )}],
                _8bits => $convert_24_To_8bits->( @$col_ref{qw( red green blue )} )
            });
        }
        # Treating opacity to make things lighter; not ideal, but standard scheme
        elsif( $col =~ /^rgba\((?<red>\d{3})(?<green>\d{3})(?<blue>\d{3})[[:blank:]]*\,[[:blank:]]*(?<opacity>\d(?:\.\d)?)\)$/i )
        {
            $col_ref = {};
            %$col_ref = %+;
            $self->message( 9, "Rgba colour '$+{red}', '$+{green}' and '$+{blue}' found with opacity $+{opacity}: ", sub{ $self->dumper( $col_ref ) });
            if( $+{opacity} )
            {
                my $opacity = $+{opacity};
                $self->message( 9, "Opacity of $opacity found, applying the factor to the colour." );
                my $bg;
                if( $opts->{bgcolour} )
                {
                    $bg = $self->colour_to_rgb( $opts->{bgcolour} );
                    $self->message( 9, "Calculating new rgb with opacity and background information: ", sub{ $self->dumper( $bg ) });
                }
                my $new_col = $colour_with_alpha->( @$col_ref{qw( red green blue )}, $opacity, $bg );
                $self->message( 9, "New colour with opacity applied: ", sub{ $self->dumper( $new_col ) });
                @$col_ref{qw( red green blue )} = @$new_col;
                $self->message( 9, "Colour $+{red}, $+{green}, $+{blue} * $opacity => $col_ref->{red}, $col_ref->{green}, $col_ref->{blue}" );
            }
            return({
                _24bits => [@$col_ref{qw( red green blue )}],
                _8bits => $convert_24_To_8bits->( @$col_ref{qw( red green blue )} )
            });
        }
        elsif( $self->message( 9, "Checking if rgb value exists for colour '$col'" ) &&
               ( $col_ref = $self->colour_to_rgb( $col ) ) )
        {
            $self->message( 9, "Setting up colour '$col' with data: ", sub{ $self->dumper( $col_ref ) });
            # $code = $map->{ $col };
            return({
                _24bits => [@$col_ref{qw( red green blue )}],
                _8bits => $convert_24_To_8bits->( @$col_ref{qw( red green blue )} )
            });
        }
        else
        {
            $self->message( 9, "Could not find a match for colour '$col'." );
            return( {} );
        }
#         my $is_bg = ( CORE::substr( $code, 0, 1 ) == 4 );
#         if( CORE::length( $code ) && $light )
#         {
#             ## If the colour is a background colour, replace 4 by 10 (e.g.: 42 becomes 103)
#             ## and if foreground colour, replace 3 by 9
#             CORE::substr( $code, 0, 1 ) = ( $is_bg ? 10 : 9 );
#         }
#         return( $code );
    };
    my $data = [];
    my $data8 = [];
    my $params = [];
    # 8 bits parameters compatible
    my $params8 = [];
    if( $opts->{colour} || $opts->{color} || $opts->{fgcolour} || $opts->{fgcolor} || $opts->{fg_colour} || $opts->{fg_color} )
    {
        $opts->{colour} ||= CORE::delete( $opts->{color} ) || CORE::delete( $opts->{fg_colour} ) || CORE::delete( $opts->{fg_color} ) || CORE::delete( $opts->{fgcolour} ) || CORE::delete( $opts->{fgcolor} );
        # my $col_ref = $check_colour->( $opts->{colour}, $colours );
        my $col_ref = $check_colour->( $opts->{colour} );
        # CORE::push( @$params, $col ) if( CORE::length( $col ) );
        if( scalar( keys( %$col_ref ) ) )
        {
            $self->message( 9, "Foreground colour '$opts->{colour}' data are: ", sub{ $self->dumper( $col_ref ) });
            CORE::push( @$params8, sprintf( '38;5;%d', $col_ref->{_8bits} ) );
            CORE::push( @$params, sprintf( '38;2;%d;%d;%d', @{$col_ref->{_24bits}} ) );
        }
        else
        {
            $self->message( 9, "Could not resolve the foreground colour '$opts->{colour}'." );
        }
    }
    if( $opts->{bgcolour} || $opts->{bgcolor} || $opts->{bg_colour} || $opts->{bg_color} )
    {
        $opts->{bgcolour} ||= CORE::delete( $opts->{bgcolor} ) || CORE::delete( $opts->{bg_colour} ) || CORE::delete( $opts->{bg_color} );
        # my $col_ref = $check_colour->( $opts->{bgcolour}, $bg_colours );
        my $col_ref = $check_colour->( $opts->{bgcolour} );
        ## CORE::push( @$params, $col ) if( CORE::length( $col ) );
        if( scalar( keys( %$col_ref ) ) )
        {
            $self->message( 9, "Foreground colour '$opts->{bgcolour}' data are: ", sub{ $self->dumper( $col_ref ) });
            CORE::push( @$params8, sprintf( '48;5;%d', $col_ref->{_8bits} ) );
            CORE::push( @$params, sprintf( '48;2;%d;%d;%d', @{$col_ref->{_24bits}} ) );
        }
        else
        {
            $self->message( 9, "Could not resolve the background colour '$opts->{colour}'." );
        }
    }
    if( $opts->{style} )
    {
        # $self->message( 9, "Style '$opts->{style}' provided." );
        my $those_styles = [CORE::split( /\|/, $opts->{style} )];
        # $self->message( 9, "Split styles: ", sub{ $self->dumper( $those_styles ) } );
        foreach my $s ( @$those_styles )
        {
            # $self->message( 9, "Adding style '$s'" ) if( CORE::exists( $styles->{lc($s)} ) );
            if( CORE::exists( $styles->{lc($s)} ) )
            {
                CORE::push( @$params, $styles->{lc($s)} );
                # We add the 8 bits compliant version only if any colour was provided, i.e.
                # This is not just a style definition
                CORE::push( @$params8, $styles->{lc($s)} ) if( scalar( @$params8 ) );
            }
        }
    }
    CORE::push( @$data, "\e[" . CORE::join( ';', @$params8 ) . "m" ) if( scalar( @$params8 ) );
    CORE::push( @$data, "\e[" . CORE::join( ';', @$params ) . "m" ) if( scalar( @$params ) );
    $self->message( 9, "Pre final colour data contains: ", sub{ $self->dumper( $data ) });
    # If the text contains libe breaks, we must stop the formatting before, or else there would be an ugly formatting on the entire screen following the line break
    if( scalar( @$params ) && $opts->{text} =~ /\n+/ )
    {
        my $text_parts = [CORE::split( /\n/, $opts->{text} )];
        my $fmt = CORE::join( '', @$data );
        my $fmt8 = CORE::join( '', @$data8 );
        for( my $i = 0; $i < scalar( @$text_parts ); $i++ )
        {
            # Empty due to \n repeated
            next if( !CORE::length( $text_parts->[$i] ) );
            $text_parts->[$i] = $fmt . $text_parts->[$i] . $normal;
        }
        $opts->{text} = CORE::join( "\n", @$text_parts );
        CORE::push( @$data, $opts->{text} );
    }
    else
    {
        CORE::push( @$data, $opts->{text} );
        CORE::push( @$data, $normal, $normal ) if( scalar( @$params ) );
    }
    ## $self->message( "Returning '", quotemeta( CORE::join( '', @$data ) ), "'" );
    return( CORE::join( '', @$data ) );
}

sub colour_open { return( shift->_set_get( 'colour_open', @_ ) ); }

sub colour_parse
{
    my $self = shift( @_ );
    my $txt  = join( '', @_ );
    my $this  = $self->_obj2h;
    my $open  = $this->{colour_open} || COLOUR_OPEN;
    my $close = $this->{colour_close} || COLOUR_CLOSE;
    no strict;
    my $re = qr/
(?<all>
\Q$open\E(?!\/)(?<params>.*?)\Q$close\E
    (?<content>
        (?:
            (?> [^$open$close]+ )
            |
            (?R)
        )*+
    )
\Q$open\E\/\Q$close\E
)
    /x;
    my $colour_re = qr/(?:(?:bright|light)[[:blank:]])?(?:[a-zA-Z]+(?:[[:blank:]]+[\w\-]+)?|rgb[a]?\([[:blank:]]*\d{1,3}[[:blank:]]*\,[[:blank:]]*\d{1,3}[[:blank:]]*\,[[:blank:]]*\d{1,3}[[:blank:]]*(?:\,[[:blank:]]*\d(?:\.\d)?)?[[:blank:]]*\))/;
    my $style_re = qr/(?:bold|faint|italic|underline|blink|reverse|conceal|strike)/;
    my $parse;
    $parse = sub
    {
        my $str = shift( @_ );
        # $self->message( 9, "Parsing coloured text '$str'" );
        $str =~ s{$re}
        {
            my $re = { %- };
            my $catch = substr( $str, $-[0], $+[0] - $-[0] );
            ## $self->message( 9, "Regexp is: ", sub{ $self->dump( $re ) } );
            my $all = $+{all};
            my $ct = $+{content};
            my $params = $+{params};
            if( index( $ct, $open ) != -1 && index( $ct, $close ) != -1 )
            {
                $ct = $parse->( $ct );
            }
            my $def = {};
            if( $params =~ /^[[:blank:]]*(?:(?<style1>$style_re)[[:blank:]]+)?(?<fg_colour>$colour_re)(?:[[:blank:]]+(?<style2>$style_re))?(?:[[:blank:]]+on[[:blank:]]+(?<bg_colour>$colour_re))?[[:blank:]]*$/i )
            {
                my $style = $+{style1} || $+{style2};
                my $fg = $+{fg_colour};
                my $bg = $+{bg_colour};
                # $self->message( 9, "Found style '$style', colour '$fg' and background colour '$bg'." );
                $def = 
                {
                style => $style,
                colour => $fg,
                bg_colour => $bg,
                };
            }
            else
            {
                # $self->message( 9, "Evaluating the styling '$params'." );
                local $SIG{__WARN__} = sub{};
                local $SIG{__DIE__} = sub{};
                my @res = eval( $params );
                # $self->message( 9, "Evaluation result is: ", sub{ $self->dump( [ @res ] ) } );
                $def = { @res } if( scalar( @res ) && !( scalar( @res ) % 2 ) );
                if( $@ || ref( $def ) ne 'HASH' )
                {
                    my $err = $@ || "Invalid styling \"${params}\"";
                    $self->message( 9, "Error evaluating: $err" );
                    $def = {};
                }
            }
            if( scalar( keys( %$def ) ) )
            {
                $def->{text} = $ct;
                $self->message( 9, "Calling colour_parse with parameters: ", sub{ $self->dump( $def )} );
                my $res = $self->colour_format( $def );
                length( $res ) ? $res : $catch;
            }
            else
            {
                $self->message( 9, "Returning '$catch'" );
                $catch;
            }
        }gex;
        return( $str );
    };
    return( $parse->( $txt ) );
}

sub colour_to_rgb
{
    my $self    = shift( @_ );
    my $colour  = lc( shift( @_ ) );
    my $this  = $self->_obj2h;
    my( $red, $green, $blue ) = ( '', '', '' );
    our $COLOUR_NAME_TO_RGB;
    $self->message( 9, "Checking rgb value for '$colour'. Called from line ", (caller)[2] );
    if( $colour =~ /^[A-Za-z]+([\w\-]+)*([[:blank:]]+\w+)?$/ )
    {
        $self->message( 9, "Checking colour '$colour' as string. Looking up its rgb value." );
        if( !scalar( keys( %$COLOUR_NAME_TO_RGB ) ) )
        {
            $self->message( 9, "Processing colour map in <DATA> section." );
            my $colour_data = $self->__colour_data;
            $COLOUR_NAME_TO_RGB = eval( $colour_data );
            if( $@ )
            {
                return( $self->error( "An error occurred loading data from __colour_data: $@" ) );
            }
        }
        if( CORE::exists( $COLOUR_NAME_TO_RGB->{ $colour } ) )
        {
            ( $red, $green, $blue ) = @{$COLOUR_NAME_TO_RGB->{ $colour }};
            $self->message( 9, "Found rgb '$red, $green, $blue' for colour '$colour'." );
        }
        else
        {
            $self->message( 9, "Could not find colour '$colour' in our colour map." );
            return( '' );
        }
    }
    ## Colour all in decimal??
    elsif( $colour =~ /^\d{9}$/ )
    {
        ## $self->message( 9, "Got colour all in decimal. Less work to do..." );
        $red   = substr( $colour, 0, 3 );
        $green = substr( $colour, 3, 3 );
        $blue  = substr( $colour, 6, 3 );
    }
    ## Colour in hexadecimal, convert it
    elsif( $colour =~ /^[A-F0-9]+$/ )
    {
        $red   = hex( substr( $colour, 0, 2 ) );
        $green = hex( substr( $colour, 2, 2 ) );
        $blue  = hex( substr( $colour, 4, 2 ) );
    }
    ## Clueless
    else
    {
        $self->message( 9, "Clueless about what to do with colour '$colour'." );
        ## Not undef, but rather empty string. Undef is associated with an error
        return( '' );
    }
    return({ red => $red, green => $green, blue => $blue });
}

sub coloured
{
    my $self = shift( @_ );
    my $pref = shift( @_ );
    my $text = CORE::join( '', @_ );
    my $this  = $self->_obj2h;
    my( $style, $fg, $bg );
    ## my $colour_re = qr/(?:(?:bright|light)[[:blank:]])?[a-zA-Z]+/;
    my $colour_re = qr/(?:(?:bright|light)[[:blank:]])?(?:[a-zA-Z]+(?:[[:blank:]]+[\w\-]+)?|rgb[a]?\([[:blank:]]*\d{1,3}[[:blank:]]*\,[[:blank:]]*\d{1,3}[[:blank:]]*\,[[:blank:]]*\d{1,3}[[:blank:]]*(?:\,[[:blank:]]*\d(?:\.\d)?)?[[:blank:]]*\))/;
    my $style_re = qr/(?:bold|faint|italic|underline|blink|reverse|conceal|strike)/;
    if( $pref =~ /^(?:(?<style1>$style_re)[[:blank:]]+)?(?<fg_colour>$colour_re)(?:[[:blank:]]+(?<style2>$style_re))?(?:[[:blank:]]+on[[:blank:]]+(?<bg_colour>$colour_re))?$/i )
    {
        $style = $+{style1} || $+{style2};
        $fg = $+{fg_colour};
        $bg = $+{bg_colour};
        ## $self->message( 9, "Found style '$style', colour '$fg' and background colour '$bg'." );
        return( $self->colour_format({ text => $text, style => $style, colour => $fg, bg_colour => $bg }) );
    }
    else
    {
        $self->message( 9, "No match." );
        return( '' );
    }
}

sub debug
{
    my $self  = shift( @_ );
    my $class = ( ref( $self ) || $self );
    my $this  = $self->_obj2h;
    no strict 'refs';
    if( @_ )
    {
        my $flag = shift( @_ );
        $this->{debug} = $flag;
        if( $this->{debug} &&
            !$this->{debug_level} )
        {
            $this->{debug_level} = $this->{debug};
        }
    }
    return( $this->{debug} || ${"$class\:\:DEBUG"} );
}

sub dump
{
    my $self = shift( @_ );
    my $opts = {};
    if( @_ > 1 && 
        ref( $_[-1] ) eq 'HASH' && 
        exists( $_[-1]->{filter} ) && 
        ref( $_[-1]->{filter} ) eq 'CODE' )
    {
        $opts = pop( @_ );
        return( Data::Dump::dumpf( @_, $opts->{filter} ) );
    }
    else
    {
        return( Data::Dump::dump( @_ ) );
    }
}

sub dump_hex
{
    my $self = shift( @_ );
    try
    {
        require Devel::Hexdump;
        return( Devel::Hexdump::xd( shift( @_ ) ) );
    }
    catch( $e )
    {
        return( $self->error( "Devel::Hexdump is not installed on your system." ) );
    }
}

## For backward compatibility and traceability
sub dump_print { return( shift->dumpto_printer( @_ ) ); }

sub dumper
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' );
    try
    {
        no warnings 'once';
        require Data::Dumper;
        # local $Data::Dumper::Sortkeys = 1;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Maxdepth = $opts->{depth} if( CORE::length( $opts->{depth} ) );
        local $Data::Dumper::Sortkeys = sub
        {
            my $h = shift( @_ );
            return( [ sort( grep{ ref( $h->{ $_ } ) !~ /^(DateTime|DateTime\:\:)/ } keys( %$h ) ) ] );
        };
        return( Data::Dumper::Dumper( @_ ) );
    }
    catch( $e )
    {
        return( $self->error( "Data::Dumper is not installed on your system." ) );
    }
}

sub printer
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' );
    try
    {
        local $SIG{__WARN__} = sub{ };
        require Data::Printer;
        if( scalar( keys( %$opts ) ) )
        {
            return( Data::Printer::np( @_, %$opts ) );
        }
        else
        {
            return( Data::Printer::np( @_ ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Data::Printer is not installed on your system." ) );
    }
}

{
    no warnings 'once';
    *dumpto = \&dumpto_dumper;
}

sub dumpto_printer
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    $file = Module::Generic::File::file( $file );
    my $fh =  $file->open( '>', { binmode => 'utf-8', autoflush => 1 }) || 
        die( "Unable to create file '$file': $!\n" );
    $fh->print( Data::Dump::dump( $data ), "\n" );
    $fh->close;
    # 666 so it can work under command line and web alike
    chmod( 0666, $file );
    return(1);
}

sub dumpto_dumper
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    try
    {
        require Data::Dumper;
        local $Data::Dumper::Sortkeys = 1;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Useqq = 1;
        $file = Module::Generic::File::file( $file );
        my $fh =  $file->open( '>', { autoflush => 1 }) || 
            die( "Unable to create file '$file': $!\n" );
        if( ref( $data ) )
        {
            $fh->print( Data::Dumper::Dumper( $data ), "\n" );
        }
        else
        {
            $fh->binmode( ':utf8' );
            $fh->print( $data );
        }
        $fh->close;
        ## 666 so it can work under command line and web alike
        chmod( 0666, $file );
        return(1);
    }
    catch( $e )
    {
        return( $self->error( "Unable to dump data to \"$file\" using Data::Dumper: $e" ) );
    }
}

sub errno
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    if( @_ )
    {
        $this->{errno} = shift( @_ ) if( $_[ 0 ] =~ /^\-?\d+$/ );
        return( $self->error( @_ ) ) if( @_ );
    }
    return( $this->{errno} );
}

sub error
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    our $MOD_PERL;
    my $this = $self->_obj2h;
    my $o;
    no strict 'refs';
    if( @_ )
    {
        $self->message( 4, "Called from package ", [caller]->[0], " at line ", [caller]->[2], " from sub ", [caller(1)]->[3] );
        my $args = {};
        # We got an object as first argument. It could be a child from our exception package or from another package
        # Either way, we use it as it is
        if( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) ) ||
            Scalar::Util::blessed( $_[0] ) )
        {
            $o = shift( @_ );
        }
        elsif( ref( $_[0] ) eq 'HASH' )
        {
            $args  = shift( @_ );
        }
        else
        {
            $args->{message} = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @_ ) );
        }
        $args->{class} //= '';
        my $max_len = ( CORE::exists( $this->{error_max_length} ) && $this->{error_max_length} =~ /^[-+]?\d+$/ )
            ? $this->{error_max_length}
            : 0;
        $args->{message} = substr( $args->{message}, 0, $this->{error_max_length} ) if( $max_len > 0 && length( $args->{message} ) > $max_len );
        # Reset it
        $this->{_msg_no_exec_sub} = 0;
        # Note Taken from Carp to find the right point in the stack to start from
        my $caller_func;
        $caller_func = \&{"CORE::GLOBAL::caller"} if( defined( &{"CORE::GLOBAL::caller"} ) );
        if( defined( $o ) )
        {
            $this->{error} = ${ $class . '::ERROR' } = $o;
        }
        else
        {
            my $ex_class = CORE::length( $args->{class} )
                ? $args->{class}
                : ( CORE::exists( $this->{_exception_class} ) && CORE::length( $this->{_exception_class} ) )
                    ? $this->{_exception_class}
                    : 'Module::Generic::Exception';
            $self->message( 4, "Using exception class '$ex_class'. Property '_exception_class' is '$this->{_exception_class}'" );
            unless( $this->_is_class_loaded( $ex_class ) || scalar( keys( %{"${ex_class}\::"} ) ) )
            {
                my $pl = "use $ex_class;";
                # $self->message( 3, "Evaluating '$pl'" );
                local $SIG{__DIE__} = sub{};
                eval( $pl );
                # We have to die, because we have an error within another error
                die( __PACKAGE__ . "::error() is unable to load exception class \"$ex_class\": $@" ) if( $@ );
            }
            $o = $this->{error} = ${ $class . '::ERROR' } = $ex_class->new( $args );
        }
        
        # Get the warnings status of the caller. We use caller(1) to skip one frame further, ie our caller's caller
        # This can be changed by using 'no warnings'
        my $should_display_warning = 0;
        my $no_use_warnings = 1;
        unless( $this->{quiet} )
        {
            # Try to get the warnings status if is enabled at all.
            $should_display_warning = $self->_warnings_is_enabled;
            $no_use_warnings = 0;
        
            ## If no warnings are registered for our package, we display warnings.
            if( $no_use_warnings && !defined( $warnings::Bits{ $class } ) )
            {
                $no_use_warnings = 0;
                $should_display_warning = 1;
            }
        }
        
        if( $no_use_warnings )
        {
            my $call_offset = 0;
            while( my @call_data = $caller_func ? $caller_func->( $call_offset ) : caller( $call_offset ) )
            {
                my @prev_stack = $caller_func ? $caller_func->( $call_offset - 1 ) : caller( $call_offset - 1 );
                unless( $call_offset > 0 && $call_data[0] ne $class && $prev_stack[0] eq $class )
                {
                    $call_offset++;
                    next;
                }
                last if( $call_data[9] || ( $call_offset > 0 && $prev_stack[0] ne $class ) );
                $call_offset++;
            }
            my $bitmask = $caller_func ? ($caller_func->( $call_offset ))[9] : ( caller( $call_offset ) )[9];
            my $offset = $warnings::Offsets{uninitialized};
            $should_display_warning = vec( $bitmask, $offset, 1 );
        }
        
        my $r;
        if( $MOD_PERL )
        {
            try
            {
                $r = Apache2::RequestUtil->request;
                $r->warn( $o->as_string ) if( $r );
            }
            catch( $e )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $e\n" );
            }
        }
        
        my $err_handler = $self->error_handler;
        if( $err_handler && ref( $err_handler ) eq 'CODE' )
        {
            $err_handler->( $o );
        }
        elsif( $r )
        {
            if( my $log_handler = $r->get_handlers( 'PerlPrivateErrorHandler' ) )
            {
                $log_handler->( $o );
            }
            else
            {
                $r->warn( $o->as_string ) if( $should_display_warning );
            }
        }
        elsif( $this->{fatal} || ( defined( ${"${class}\::FATAL_ERROR"} ) && ${"${class}\::FATAL_ERROR"} ) )
        {
            # my $enc_str = eval{ Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK ) };
            # die( $@ ? $o : $enc_str );
            die( $o );
        }
        elsif( $should_display_warning )
        {
            if( $r )
            {
                $r->warn( $o->as_string );
            }
            else
            {
                my $enc_str = eval{ Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK ) };
                ## Display warnings if warnings for this class is registered and enabled or if not registered
                warn( $@ ? $o : $enc_str );
            }
        }
        
        if( overload::Overloaded( $self ) )
        {
            my $overload_meth_ref = overload::Method( $self, '""' );
            my $overload_meth_name = '';
            $overload_meth_name = Sub::Util::subname( $overload_meth_ref ) if( ref( $overload_meth_ref ) );
            # use Sub::Identify ();
            # my( $over_file, $over_line ) = Sub::Identify::get_code_location( $overload_meth_ref );
            # my( $over_call_pack, $over_call_file, $over_call_line ) = caller();
            my $call_sub = $caller_func ? ($caller_func->(1))[3] : (caller(1))[3];
            # overloaded method name can be, for example: My::Package::as_string
            # or, for anonymous sub: My::Package::__ANON__[lib/My/Package.pm:12]
            # caller sub will reliably be the same, so we use it to check if we are called from an overloaded stringification and return undef right here.
            # Want::want check of being called in an OBJECT context triggers a perl segmentation fault
            if( length( $overload_meth_name ) && $overload_meth_name eq $call_sub )
            {
                return;
            }
        }
        
        # https://metacpan.org/pod/Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef
        # https://perlmonks.org/index.pl?node_id=741847
        # Because in list context this would create a lit with one element undef()
        # A bare return will return an empty list or an undef scalar
        # return( undef() );
        # return;
        # As of 2019-10-13, Module::Generic version 0.6, we use this special package Module::Generic::Null to be returned in chain without perl causing the error that a method was called on an undefined value
        # 2020-05-12: Added the no_return_null_object to instruct not to return a null object
        # This is especially needed when an error is called from TIEHASH that returns a special object.
        # A Null object would trigger a fatal perl segmentation fault
        if( !$args->{no_return_null_object} && want( 'OBJECT' ) )
        {
            my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, has_error => 1 });
            rreturn( $null );
        }
        return;
    }
    # To avoid the perl error of 'called on undefined value' and so the user can do
    # $o->error->message for example without concerning himself/herself whether an exception object is actually set
    if( !$this->{error} && want( 'OBJECT' ) )
    {
        my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, wants => 'object' });
        rreturn( $null );
    }
    return( ref( $self ) ? $this->{error} : ${ $class . '::ERROR' } );
}

sub error_handler { return( shift->_set_get_code( '_error_handler', @_ ) ); }

{
    no warnings 'once';
    *errstr = \&error;
}

sub fatal { return( shift->_set_get_boolean( 'fatal', @_ ) ); }

sub get
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my @data = map{ $data->{ $_ } } @_;
    return( wantarray() ? @data : $data[ 0 ] );
}

sub init
{
    my $self = shift( @_ );
    my $pkg  = ref( $self );
    no warnings 'uninitialized';
    no overloading;
    my $this = $self->_obj2h;
    no strict 'refs';
    $this->{verbose} = defined( ${ $pkg . '::VERBOSE' } ) ? ${ $pkg . '::VERBOSE' } : 0 if( !length( $this->{verbose} ) );
    $this->{debug}   = defined( ${ $pkg . '::DEBUG' } ) ? ${ $pkg . '::DEBUG' } : 0 if( !length( $this->{debug} ) );
    $this->{version} = ${ $pkg . '::VERSION' } if( !defined( $this->{version} ) && defined( ${ $pkg . '::VERSION' } ) );
    $this->{level}   = 0;
    $this->{colour_open} = COLOUR_OPEN if( !length( $this->{colour_open} ) );
    $this->{colour_close} = COLOUR_CLOSE if( !length( $this->{colour_close} ) );
    $this->{_exception_class} = 'Module::Generic::Exception' unless( CORE::defined( $this->{_exception_class} ) && CORE::length( $this->{_exception_class} ) );
    $this->{_init_params_order} = [] unless( ref( $this->{_init_params_order} ) );
    ## If no debug level was provided when calling message, this level will be assumed
    ## Example: message( "Hello" );
    ## If _message_default_level was set to 3, this would be equivalent to message( 3, "Hello" )
    $this->{_init_strict_use_sub} = 0 unless( length( $this->{_init_strict_use_sub} ) );
    $this->{_log_handler} = '' unless( length( $this->{_log_handler} ) );
    $this->{_message_default_level} = 0;
    $this->{_msg_no_exec_sub} = 0 unless( length( $this->{_msg_no_exec_sub} ) );
    $this->{error_max_length} = '' unless( length( $this->{error_max_length} ) );
    my $data = $this;
    if( $this->{_data_repo} )
    {
        $this->{ $this->{_data_repo} } = {} if( !$this->{ $this->{_data_repo} } );
        $data = $this->{ $this->{_data_repo} };
    }
    
    ## If the calling module wants to set up object cleanup
    if( $self->{_mod_perl_cleanup} && $MOD_PERL )
    {
        try
        {
            local $SIG{__DIE__};
            ## Must enable GlobalRequest for this to work.
            my $r = Apache2::RequestUtil->request;
            if( $r )
            {
                $r->pool->cleanup_register(sub
                {
                    $self->message( 3, "Cleaning up object." );
                    map{ delete( $self->{ $_ } ) } keys( %$self );
                    undef( %$self );
                    return( 1 );
                });
            }
        }
        catch( $e )
        {
            print( STDERR "Error trying to get the global Apache2::ApacheRec object and setting up a cleanup handler: $e\n" );
        }
    }
    
    @_ = () if( @_ == 1 && !defined( $_[0] ) );
    if( @_ )
    {
        my @args = @_;
        my $vals;
        if( ref( $args[0] ) eq 'HASH' ||
            ( Scalar::Util::blessed( $args[0] ) && $args[0]->isa( 'Module::Generic::Hash' ) ) )
        {
            ## $self->_message( 3, "Got an hash ref" );
            my $h = shift( @args );
            my $debug_value;
            $debug_value = $h->{debug} if( CORE::exists( $h->{debug} ) );
            $vals = [ %$h ];
            unshift( @$vals, debug => $debug_value ) if( CORE::defined( $debug_value ) );
        }
        elsif( ref( $args[0] ) eq 'ARRAY' )
        {
            ## $self->_message( 3, "Got an array ref" );
            $vals = $args[0];
        }
        ## Special case when there is an undefined value passed (null) even though it is declared as a hash or object
        elsif( scalar( @args ) == 1 && !defined( $args[0] ) )
        {
            $self->message( 3, "Only argument is provided to init ", ref( $self ), " object and its value is undefined." );
            return( $self->error( "Only argument is provided to init ", ref( $self ), " object and its value is undefined." ) );
        }
        elsif( ( scalar( @args ) % 2 ) )
        {
            $self->message( 3, sprintf( "Uneven number of parameters provided (%d). Should receive key => value pairs. Parameters provideds are: %s", scalar( @args ), join( ', ', @args ) ) );
            return( $self->error( sprintf( "Uneven number of parameters provided (%d). Should receive key => value pairs. Parameters provideds are: %s", scalar( @args ), join( ', ', @args ) ) ) );
        }
        else
        {
            ## $self->message( 3, "Got an array: ", sub{ $self->dumper( \@args ) } );
            $vals = \@args;
        }
        
        my $order = $self->{_init_params_order};
        if( scalar( @$order ) )
        {
            my $new = [];
            foreach my $param ( @$order )
            {
                for( my $i = 0; $i < scalar( @$vals ); $i += 2 )
                {
                    if( defined( $vals->[$i] ) && $vals->[$i] eq $param )
                    {
                        push( @$new, splice( @$vals, $i, 2 ) );
                    }
                }
            }
            if( scalar( @$new ) )
            {
                push( @$new, @$vals );
                @$vals = @$new;
            }
        }
        
        # Check if there is a debug parameter, and if we find one, set it first so that that 
        # calls to the package subroutines can produce verbose feedback as necessary
        for( my $i = 0; $i < scalar( @$vals ); $i++ )
        {
            next if( !defined( $vals->[$i] ) );
            if( $vals->[$i] eq 'debug' )
            {
                my $v = $vals->[$i + 1];
                $self->debug( $v );
                CORE::splice( @$vals, $i, 2 );
            }
        }
        
        for( my $i = 0; $i < scalar( @$vals ); $i++ )
        {
            my $name = $vals->[ $i ];
            my $val  = $vals->[ ++$i ];
            my $meth = $self->can( $name );
            # $self->message( 3, "Does the object from class (", ref( $self ), ") has a method $name? ", ( defined( $meth ) ? 'yes' : 'no' ) );
            if( defined( $meth ) )
            {
                if( !defined( $self->$name( $val ) ) )
                {
                    if( defined( $val ) && $self->error )
                    {
                        warn( "Warning: method $name returned undef while initialising object ", ref( $self ), ": ", ( $self->error ? $self->error->message : '' ), "\n" );
                        return;
                    }
                }
                next;
            }
            elsif( $this->{_init_strict_use_sub} )
            {
                # $self->message( 3, "Checking if method $name exist in class ", ref( $self ), ": ", $self->can( $name ) ? 'yes' : 'no' );
                $self->message( 3, "Unknown method '$name' in class $pkg -> ", sub
                {
                    $self->_get_stack_trace->as_string;
                });
                $self->error( "Unknown method $name in class $pkg" );
                next;
            }
            elsif( exists( $data->{ $name } ) )
            {
                ## Pre-existing field value looks like a module package and that package is already loaded
                if( ( index( $data->{ $name }, '::' ) != -1 || $data->{ $name } =~ /^[a-zA-Z][a-zA-Z\_]*[a-zA-Z]$/ ) &&
                    $self->_is_class_loaded( $data->{ $name } ) )
                {
                    my $thisPack = $data->{ $name };
                    if( !Scalar::Util::blessed( $val ) )
                    {
                        $self->message( 3, "$name parameter expects a package $thisPack object, but instead got '$val'." );
                        return( $self->error( "$name parameter expects a package $thisPack object, but instead got '$val'." ) );
                    }
                    elsif( !$val->isa( $thisPack ) )
                    {
                        $self->message( 3, "$name parameter expects a package $thisPack object, but instead got an object from package '" );
                        return( $self->error( "$name parameter expects a package $thisPack object, but instead got an object from package '", ref( $val ), "'." ) );
                    }
                }
                elsif( $this->{_init_strict} )
                {
                    if( ref( $data->{ $name } ) eq 'ARRAY' )
                    {
                        $self->message( 3, "$name parameter expects an array reference, but instead got '$val'." ) if( Scalar::Util::reftype( $val ) ne 'ARRAY' );
                        return( $self->error( "$name parameter expects an array reference, but instead got '$val'." ) ) if( Scalar::Util::reftype( $val ) ne 'ARRAY' );
                    }
                    elsif( ref( $data->{ $name } ) eq 'HASH' )
                    {
                        $self->message( 3, "$name parameter expects an hash reference, but instead got '$val'." ) if( Scalar::Util::reftype( $val ) ne 'HASH' );
                        return( $self->error( "$name parameter expects an hash reference, but instead got '$val'." ) ) if( Scalar::Util::reftype( $val ) ne 'HASH' );
                    }
                    elsif( ref( $data->{ $name } ) eq 'SCALAR' )
                    {
                        $self->message( 3, "$name parameter expects a scalar reference, but instead got '$val'." ) if( Scalar::Util::reftype( $val ) ne 'SCALAR' );
                        return( $self->error( "$name parameter expects a scalar reference, but instead got '$val'." ) ) if( Scalar::Util::reftype( $val ) ne 'SCALAR' );
                    }
                }
            }
            ## The name parameter does not exist
            else
            {
                ## If we are strict, we reject
                next if( $this->{_init_strict} );
            }
            ## We passed all tests
            $data->{ $name } = $val;
        }
    }
    return( $self );
}

sub log_handler { return( shift->_set_get_code( '_log_handler', @_ ) ); }

sub message
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this = $self->_obj2h;
    no strict 'refs';
    if( $this->{verbose} || $this->{debug} || ${ $class . '::DEBUG' } )
    {
        my $r;
        if( $MOD_PERL )
        {
            try
            {
                $r = Apache2::RequestUtil->request;
            }
            catch( $e )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $e\n" );
            }
        }
    
        my $ref;
        $ref = $self->message_check( @_ );
        return( 1 ) if( !$ref );
        
        my $opts = {};
        $opts = pop( @$ref ) if( ref( $ref->[-1] ) eq 'HASH' );

        my $stackFrame = $self->message_frame( (caller(1))[3] ) || 1;
        $stackFrame = 1 unless( $stackFrame =~ /^\d+$/ );
        $stackFrame-- if( $stackFrame );
        $stackFrame++ if( ( (caller(1))[3] // '' ) eq 'Module::Generic::messagef' || 
                          ( (caller(1))[3] // '' ) eq 'Module::Generic::message_colour' );
        $stackFrame++ if( ( (caller(2))[3] // '' ) eq 'Module::Generic::messagef_colour' );
        my( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
        my $sub = ( caller( $stackFrame + 1 ) )[3] // '';
        my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        if( ref( $this->{_message_frame} ) eq 'HASH' )
        {
            if( exists( $this->{_message_frame}->{ $sub2 } ) )
            {
                my $frameNo = int( $this->{_message_frame}->{ $sub2 } );
                if( $frameNo > 0 )
                {
                    ( $pkg, $file, $line, $sub ) = caller( $frameNo );
                    $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
                }
            }
        }
        if( $sub2 eq 'message' )
        {
            $stackFrame++;
            ( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
            my $sub = ( caller( $stackFrame + 1 ) )[3] // '';
            $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        }
        my $txt;
        if( $opts->{message} )
        {
            if( ref( $opts->{message} ) eq 'ARRAY' )
            {
                $txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : ( $_ // '' ), @{$opts->{message}} ) );
            }
            else
            {
                $txt = $opts->{message};
            }
        }
        else
        {
            $txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : ( $_ // '' ), @$ref ) );
        }
        ## Reset it
        $this->{_msg_no_exec_sub} = 0;
        my $prefix = CORE::length( $opts->{prefix} ) ? $opts->{prefix} : '##';
        no overloading;
        $opts->{caller_info} = 1 if( !CORE::exists( $opts->{caller_info} ) || !CORE::length( $opts->{caller_info} ) );
        my $proc_info = " [PID: $$]";
        if( HAS_THREADS )
        {
            my $tid = threads->tid;
            $proc_info .= ' -> [thread id ' . $tid . ']' if( $tid );
        }
        my $mesg_raw = $opts->{caller_info} ? ( "${pkg}::${sub2}( $self ) [$line]${proc_info}: " . $txt ) : $txt;
        $mesg_raw    =~ s/\n$//gs;
        my $mesg = "${prefix} " . join( "\n${prefix} ", split( /\n/, $mesg_raw ) );
        
        my $info = 
        {
        'formatted' => $mesg,
        'message'   => $txt,
        'file'      => $file,
        'line'      => $line,
        'package'   => $class,
        'sub'       => $sub2,
        'level'     => ( $_[0] =~ /^\d+$/ ? $_[0] : CORE::exists( $opts->{level} ) ? $opts->{level} : 0 ),
        };
        $info->{type} = $opts->{type} if( $opts->{type} );
        
        ## If Mod perl is activated AND we are not using a private log
        if( $r && !${ "${class}::LOG_DEBUG" } )
        {
            if( my $log_handler = $r->get_handlers( 'PerlPrivateLogHandler' ) )
            {
                $log_handler->( $mesg_raw );
            }
            elsif( $this->{_log_handler} && ref( $this->{_log_handler} ) eq 'CODE' )
            {
                $this->{_log_handler}->( $info );
            }
            else
            {
                $r->log->debug( $mesg_raw );
            }
        }
        ## Using ModPerl Server to log
        elsif( $MOD_PERL && !${ "${class}::LOG_DEBUG" } )
        {
            require Apache2::ServerUtil;
            my $s = Apache2::ServerUtil->server;
            $s->log->debug( $mesg );
        }
        ## e.g. in our package, we could set the handler using the curry module like $self->{_log_handler} = $self->curry::log
        elsif( !-t( STDIN ) && $this->{_log_handler} && ref( $this->{_log_handler} ) eq 'CODE' )
        {
            $this->{_log_handler}->( $info );
        }
        elsif( !-t( STDIN ) && ${ $class . '::MESSAGE_HANDLER' } && ref( ${ $class . '::MESSAGE_HANDLER' } ) eq 'CODE' )
        {
            my $h = ${ $class . '::MESSAGE_HANDLER' };
            $h->( $info );
        }
        ## Or maybe then into a private log file?
        ## This way, even if the log method is superseeded, we can keep using ours without interfering with the other one
        elsif( $self->message_log( $mesg, "\n" ) )
        {
            return( 1 );
        }
        ## Otherwise just on the stderr
        else
        {
            if( $opts->{no_encoding} )
            {
                $stderr_raw->print( $mesg, "\n" );
            }
            else
            {
                $stderr->print( $mesg, "\n" );
            }
        }
    }
    return( 1 );
}

sub message_check
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this = $self->_obj2h;
    no warnings 'uninitialized';
    no strict 'refs';
    if( @_ )
    {
        if( $_[0] !~ /^\d/ )
        {
            # The last parameter is an options parameter which has the level property set
            if( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
            {
                # Then let's use this
            }
            elsif( $this->{ '_message_default_level' } =~ /^\d+$/ &&
                $this->{ '_message_default_level' } > 0 )
            {
                unshift( @_, $this->{ '_message_default_level' } );
            }
            else
            {
                unshift( @_, 1 );
            }
        }
        # If the first argument looks line a number, and there is more than 1 argument
        # and it is greater than 1, and greater than our current debug level
        # well, we do not output anything then...
        if( ( $_[0] =~ /^\d+$/ || 
              ( ref( $_[-1] ) eq 'HASH' && 
                CORE::exists( $_[-1]->{level} ) && 
                $_[-1]->{level} =~ /^\d+$/ 
              )
            ) && @_ > 1 )
        {
            my $message_level = 0;
            if( $_[0] =~ /^\d+$/ )
            {
                $message_level = shift( @_ );
            }
            elsif( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
            {
                $message_level = $_[-1]->{level};
            }
            my $target_re = '';
            if( ref( ${ "${class}::DEBUG_TARGET" } ) eq 'ARRAY' )
            {
                $target_re = scalar( @${ "${class}::DEBUG_TARGET" } ) ? join( '|', @${ "${class}::DEBUG_TARGET" } ) : '';
            }
            if( int( $this->{debug} ) >= $message_level ||
                int( $this->{verbose} ) >= $message_level ||
                ( defined( ${ $class . '::DEBUG' } ) && ${ $class . '::DEBUG' } >= $message_level ) ||
                int( $this->{debug_level} ) >= $message_level ||
                int( $this->{debug} ) >= 100 || 
                ( length( $target_re ) && $class =~ /^$target_re$/ && ${ $class . '::GLOBAL_DEBUG' } >= $message_level ) )
            {
                return( [ @_ ] );
            }
            else
            {
                return(0);
            }
        }
    }
    return(0);
}

{
    no warnings 'once';
    *message_color = \&message_colour;
}

sub message_colour
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    if( $this->{verbose} || $this->{debug} || ${ $class . '::DEBUG' } )
    {
        my $level = ( $_[0] =~ /^\d+$/ ? shift( @_ ) : undef() );
        my $opts = {};
        if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' && ( CORE::exists( $_[-1]->{level} ) || CORE::exists( $_[-1]->{type} ) || CORE::exists( $_[-1]->{message} ) ) )
        {
            $opts = pop( @_ );
        }
        my $ref = [@_];
        $level = $opts->{level} if( !defined( $level ) && CORE::exists( $opts->{level} ) );
        my $txt;
        if( $opts->{message} )
        {
            if( ref( $opts->{message} ) eq 'ARRAY' )
            {
                $txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @{$opts->{message}} ) );
            }
            else
            {
                $txt = $opts->{message};
            }
        }
        else
        {
            $txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @$ref ) );
        }
        $txt = $self->colour_parse( $txt );
        $opts->{message} = $txt;
        $opts->{level} = $level if( defined( $level ) );
        return( $self->message( ( $level || 0 ), $opts ) );
    }
    return( 1 );
}

sub message_frame
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    $this->{_message_frame } = {} if( !exists( $this->{_message_frame} ) );
    my $mf = $this->{_message_frame};
    if( @_ )
    {
        my $args = {};
        if( ref( $_[0] ) eq 'HASH' )
        {
            $args = shift( @_ );
            my @k = keys( %$args );
            @$mf{ @k } = @$args{ @k };
        }
        elsif( !( @_ % 2 ) )
        {
            $args = { @_ };
            my @k = keys( %$args );
            @$mf{ @k } = @$args{ @k };
        }
        elsif( scalar( @_ ) == 1 )
        {
            my $sub = shift( @_ );
            $sub = substr( $sub, rindex( $sub, '::' ) + 2 ) if( index( $sub, '::' ) != -1 );
            return( $mf->{ $sub } );
        }
        else
        {
            return( $self->error( "I was expecting a key => value pair such as routine => stack frame (integer)" ) );
        }
    }
    return( $mf );
}

sub message_log
{
    my $self = shift( @_ );
    my $io   = $self->message_log_io;
    return( undef() ) if( !$io );
    return( undef() ) if( !Scalar::Util::openhandle( $io ) && $io );
    ## 2019-06-14: I decided to remove this test, because if a log is provided it should print to it
    ## If we are on the command line, we can easily just do tail -f log_file.txt for example and get the same result as
    ## if it were printed directly on the console
    my $rc = $io->print( scalar( localtime( time() ) ), " [$$]: ", @_ ) || return( $self->error( "Unable to print to log file: $!" ) );
    return( $rc );
}

sub message_log_io
{
    #return( shift->_set_get( 'log_io', @_ ) );
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    if( @_ )
    {
        my $io = shift( @_ );
        $self->_set_get( 'log_io', $io );
    }
    elsif( ${ "${class}::LOG_DEBUG" } && 
        !$self->_set_get( 'log_io' ) && 
        ${ "${class}::DEB_LOG" } )
    {
        our $DEB_LOG = ${ "${class}::DEB_LOG" };
        unless( $DEBUG_LOG_IO )
        {
            $DEB_LOG = Module::Generic::File::file( $DEB_LOG );
            $DEBUG_LOG_IO = $DEB_LOG->open( '>>', { binmode => 'utf-8', autoflush => 1 }) || 
                die( "Unable to open debug log file $DEB_LOG in append mode: $!\n" );
        }
        $self->_set_get( 'log_io', $DEBUG_LOG_IO );
    }
    return( $self->_set_get( 'log_io' ) );
}

sub messagef
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    if( $this->{verbose} || $this->{debug} || ${ $class . '::DEBUG' } )
    {
        my $level = ( $_[0] =~ /^\d+$/ ? shift( @_ ) : undef() );
        my $opts = {};
        if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' && ( CORE::exists( $_[-1]->{level} ) || CORE::exists( $_[-1]->{type} ) || CORE::exists( $_[-1]->{message} ) || CORE::exists( $_[-1]->{colour} ) ) )
        {
            $opts = pop( @_ );
        }
        $level = $opts->{level} if( !defined( $level ) && CORE::exists( $opts->{level} ) );
        my( $ref, $fmt );
        if( $opts->{message} )
        {
            if( ref( $opts->{message} ) eq 'ARRAY' )
            {
                $ref = $opts->{message};
                $fmt = shift( @$ref );
            }
            else
            {
                $fmt = $opts->{message};
                $ref = \@_;
            }
        }
        else
        {
            $ref = \@_;
            $fmt = shift( @$ref );
        }
        my $txt = sprintf( $fmt, map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @$ref ) );
        $txt = $self->colour_parse( $txt ) if( $opts->{colour} );
        $opts->{message} = $txt;
        $opts->{level} = $level if( defined( $level ) );
        return( $self->message( ( $level || 0 ), $opts ) );
    }
    return( 1 );
}

sub messagef_colour
{
    my $self  = shift( @_ );
    my $this  = $self->_obj2h;
    my $class = ref( $self ) || $self;
    no strict 'refs';
    if( $this->{verbose} || $this->{debug} || ${ $class . '::DEBUG' } )
    {
        my @args = @_;
        my $opts = {};
        if( scalar( @args ) > 1 && ref( $args[-1] ) eq 'HASH' && ( CORE::exists( $args[-1]->{level} ) || CORE::exists( $args[-1]->{type} ) || CORE::exists( $args[-1]->{message} ) ) )
        {
            $opts = pop( @args );
        }
        $opts->{colour} = 1;
        CORE::push( @args, $opts );
        ## $self->message( 0, "Sending arguments: ", sub{ $self->dumper( \@args ) } );
        return( $this->messagef( @args ) );
    }
    return( 1 );
}

sub new_array
{
    my $self = shift( @_ );
    return( Module::Generic::Array->new( @_ ) );
}

sub new_file
{
    my $self = shift( @_ );
    return( Module::Generic::File->new( @_ ) );
}

sub new_hash
{
    my $self = shift( @_ );
    return( Module::Generic::Hash->new( @_ ) );
}

sub new_null
{
    my $self = shift( @_ );
    my $what = Want::want( 'LIST' )
        ? 'LIST'
        : Want::want( 'HASH' )
            ? 'HASH'
            : Want::want( 'ARRAY' )
                ? 'ARRAY'
                : Want::want( 'OBJECT' )
                    ? 'OBJECT'
                    : Want::want( 'CODE' )
                        ? 'CODE'
                        : Want::want( 'REFSCALAR' )
                            ? 'REFSCALAR'
                            : Want::want( 'BOOLEAN' )
                                ? 'BOOLEAN'
                                : Want::want( 'GLOB' )
                                    ? 'GLOB'
                                    : Want::want( 'SCALAR' )
                                        ? 'SCALAR'
                                        : Want::want( 'VOID' )
                                            ? 'VOID'
                                            : '';
    # $self->message( 3, "Caller wants $what." );
    if( $what eq 'OBJECT' )
    {
        return( Module::Generic::Null->new( @_ ) );
    }
    elsif( $what eq 'ARRAY' )
    {
        return( [] );
    }
    elsif( $what eq 'HASH' )
    {
        return( {} );
    }
    elsif( $what eq 'CODE' )
    {
        return( sub{ return; } );
    }
    elsif( $what eq 'REFSCALAR' )
    {
        return( \undef );
    }
    else
    {
        return;
    }
}

sub new_number
{
    my $self = shift( @_ );
    return( Module::Generic::Number->new( @_ ) );
}

sub new_scalar
{
    my $self = shift( @_ );
    return( Module::Generic::Scalar->new( @_ ) );
}

sub new_tempdir
{
    my $self = shift( @_ );
    return( Module::Generic::File::tempdir( @_ ) );
}

sub new_tempfile
{
    my $self = shift( @_ );
    return( Module::Generic::File::tempfile( @_ ) );
}

sub noexec { $_[0]->{_msg_no_exec_sub} = 1; return( $_[0] ); }

# Purpose is to get an error object thrown from, possibly another package, 
# and make it ours and pass it along
# e.g.:
# $self->pass_error
# $self->pass_error( 'Some error that will be passed to error()' );
# $self->pass_error( $error_object );
# $self->pass_error( $error_object, { class => 'Some::ExceptionClass' } );
# $self->pass_error({ class => 'Some::ExceptionClass' });
sub pass_error
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $opts = {};
    my $err;
    my $class;
    no strict 'refs';
    if( scalar( @_ ) )
    {
        # Either an hash defining a new error and this will be passed along to error(); or
        # an hash with a single property: { class => 'Some::ExceptionClass' }
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
        }
        else
        {
            # $self->pass_error( $error_object, { class => 'Some::ExceptionClass' } );
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $err = $_[0];
        }
    }
    # We set $class only if the hash provided is a one-element hash and not an error-defining hash
    $class = CORE::delete( $opts->{class} ) if( scalar( keys( %$opts ) ) == 1 && [keys( %$opts )]->[0] eq 'class' );
    
    # called with no argument, most likely from the same class to pass on an error 
    # set up earlier by another method; or
    # with an hash containing just one argument class => 'Some::ExceptionClass'
    if( !defined( $err ) && ( !scalar( @_ ) || defined( $class ) ) )
    {
        if( !defined( $this->{error} ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef\n" );
        }
        else
        {
            $self->message( 3, "Reusing previously set error object: $this->{error}" );
            $err = ( defined( $class ) ? bless( $this->{error} => $class ) : $this->{error} );
        }
    }
    elsif( defined( $err ) && 
           Scalar::Util::blessed( $err ) && 
           ( scalar( @_ ) == 1 || 
             ( scalar( @_ ) == 2 && defined( $class ) ) 
           ) )
    {
        $this->{error} = ${ $class . '::ERROR' } = ( defined( $class ) ? bless( $err => $class ) : $err );
    }
    # If the error provided is not an object, we call error to create one
    else
    {
        return( $self->error( @_ ) );
    }
    
    if( want( 'OBJECT' ) )
    {
        my $null = Module::Generic::Null->new( $err, { debug => $this->{debug}, has_error => 1 });
        rreturn( $null );
    }
    my $wantarray = wantarray();
    if( $self->debug )
    {
        my $caller = [caller(1)];
        $self->message( 3, "Not called in object context, returning undef(). Wantarray ($wantarray) is defined? ", ( defined( wantarray() ) ? 'yes' : 'no' ), " for caller in package ", $caller->[0], " in file ", $caller->[1], " at line ", $caller->[2] );
    }
    return;
}

sub quiet { return( shift->_set_get( 'quiet', @_ ) ); }

sub save
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my( $file, $data );
    if( @_ == 2 )
    {
        $opts->{data} = shift( @_ );
        $opts->{file} = shift( @_ );
    }
    return( $self->error( "No file was provided to save data to." ) ) if( !$opts->{file} );
    $file = Module::Generic::File::file( $opts->{file} );
    my $fh = $file->open( '>', {
        ( $opts->{encoding} ? ( binmode => $opts->{encoding} ) : () ),
        autoflush => 1,
    }) ||
        return( $self->error( "Unable to open file \"$file\" in write mode: $!" ) );
    if( !defined( $fh->print( ref( $opts->{data} ) eq 'SCALAR' ? ${$opts->{data}} : $opts->{data} ) ) )
    {
        return( $self->error( "Unable to write data to file \"$file\": $!" ) )
    }
    $fh->close;
    my $bytes = -s( $opts->{file} );
    return( $bytes );
}

sub set
{
    my $self = shift( @_ );
    my %arg  = ();
    if( @_ )
    {
        %arg = ( @_ );
        my $this = $self->_obj2h;
        my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
        my @keys = keys( %arg );
        @$data{ @keys } = @arg{ @keys };
    }
    return( scalar( keys( %arg ) ) );
}

sub subclasses
{
    my $self  = shift( @_ );
    my $that  = '';
    $that     = @_ ? shift( @_ ) : $self;
    my $base  = ref( $that ) || $that;
    $base  =~ s,::,/,g;
    $base .= '.pm';
    
    require IO::Dir;
    # remove '.pm'
    my $dir = substr( $INC{ $base }, 0, ( length( $INC{ $base } ) ) - 3 );
    
    my @packages = ();
    my $io = IO::Dir->open( $dir );
    if( defined( $io ) )
    {
        @packages = map{ substr( $_, 0, length( $_ ) - 3 ) } grep{ substr( $_, -3 ) eq '.pm' && -f( "$dir/$_" ) } $io->read();
        $io->close ||
        warn( "Unable to close directory \"$dir\": $!\n" );
    }
    else
    {
        warn( "Unable to open directory \"$dir\": $!\n" );
    }
    return( wantarray() ? @packages : \@packages );
}

sub true  { return( $Module::Generic::Boolean::true ); }

sub false { return( $Module::Generic::Boolean::false ); }

sub verbose
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    if( @_ )
    {
        my $flag = shift( @_ );
        $this->{verbose} = $flag;
    }
    return( $this->{verbose} );
}

sub will
{
    ( @_ >= 2 && @_ <= 3 ) || die( 'Usage: $obj->can( "method" ) or Module::Generic::will( $obj, "method" )' );
    my( $obj, $meth, $level );
    if( @_ == 3 && ref( $_[ 1 ] ) )
    {
        $obj  = $_[ 1 ];
        $meth = $_[ 2 ];
    }
    else
    {
        ( $obj, $meth, $level ) = @_;
    }
    return if( !ref( $obj ) && index( $obj, '::' ) == -1 );
    no strict 'refs';
    # Give a chance to UNIVERSAL::can
    my $ref = undef;
    if( Scalar::Util::blessed( $obj ) && ( $ref = $obj->can( $meth ) ) )
    {
        return( $ref );
    }
    my $class = ref( $obj ) || $obj;
    my $origi = $class;
    if( index( $meth, '::' ) != -1 )
    {
        $origi = substr( $meth, 0, rindex( $meth, '::' ) );
        $meth  = substr( $meth, rindex( $meth, '::' ) + 2 );
    }
    $ref = \&{ "$class\::$meth" } if( defined( &{ "$class\::$meth" } ) );
    return( $ref ) if( defined( $ref ) );
    # We do not go further down the rabbit hole if level is greater or equal to 10
    $level ||= 0;
    return if( $level >= 10 );
    $level++;
    # Let's see what Alice has got for us... :-)
    # We look in the @ISA to see if the method exists in the package from which we
    # possibly inherited
    if( @{ "$class\::ISA" } )
    {
        foreach my $pack ( @{ "$class\::ISA" } )
        {
            my $ref = &will( $pack, "$origi\::$meth", $level );
            return( $ref ) if( defined( $ref ) );
        }
    }
    # Then, maybe there is an AUTOLOAD to trap undefined routine?
    # But, we do not want any loop, do we?
    # Since will() is called from Module::Generic::AUTOLOAD to check if EXTRA_AUTOLOAD exists
    # we are not going to call Module::Generic::AUTOLOAD for EXTRA_AUTOLOAD...
    if( $class ne 'Module::Generic' && $meth ne 'EXTRA_AUTOLOAD' && defined( &{ "$class\::AUTOLOAD" } ) )
    {
        my $sub = sub
        {
            $class::AUTOLOAD = "$origi\::$meth";
            &{ "$class::AUTOLOAD" }( @_ );
        };
        return( $sub );
    }
    return;
}

## Initially those data were stored after the __END__, but it seems some module is interfering with <DATA>
## and so those data could not be loaded reliably
## This is called once by colour_to_rgb to generate the hash reference COLOUR_NAME_TO_RGB
sub __colour_data
{
    my $colour_data = <<EOT;
{'alice blue' => ['240','248','255'],'aliceblue' => ['240','248','255'],'antique white' => ['250','235','215'],'antiquewhite' => ['250','235','215'],'antiquewhite1' => ['255','239','219'],'antiquewhite2' => ['238','223','204'],'antiquewhite3' => ['205','192','176'],'antiquewhite4' => ['139','131','120'],'aquamarine' => ['127','255','212'],'aquamarine1' => ['127','255','212'],'aquamarine2' => ['118','238','198'],'aquamarine3' => ['102','205','170'],'aquamarine4' => ['69','139','116'],'azure' => ['240','255','255'],'azure1' => ['240','255','255'],'azure2' => ['224','238','238'],'azure3' => ['193','205','205'],'azure4' => ['131','139','139'],'beige' => ['245','245','220'],'bisque' => ['255','228','196'],'bisque1' => ['255','228','196'],'bisque2' => ['238','213','183'],'bisque3' => ['205','183','158'],'bisque4' => ['139','125','107'],'black' => ['0','0','0'],'blanched almond' => ['255','235','205'],'blanchedalmond' => ['255','235','205'],'blue' => ['0','0','255'],'blue violet' => ['138','43','226'],'blue1' => ['0','0','255'],'blue2' => ['0','0','238'],'blue3' => ['0','0','205'],'blue4' => ['0','0','139'],'blueviolet' => ['138','43','226'],'brown' => ['165','42','42'],'brown1' => ['255','64','64'],'brown2' => ['238','59','59'],'brown3' => ['205','51','51'],'brown4' => ['139','35','35'],'burlywood' => ['222','184','135'],'burlywood1' => ['255','211','155'],'burlywood2' => ['238','197','145'],'burlywood3' => ['205','170','125'],'burlywood4' => ['139','115','85'],'cadet blue' => ['95','158','160'],'cadetblue' => ['95','158','160'],'cadetblue1' => ['152','245','255'],'cadetblue2' => ['142','229','238'],'cadetblue3' => ['122','197','205'],'cadetblue4' => ['83','134','139'],'chartreuse' => ['127','255','0'],'chartreuse1' => ['127','255','0'],'chartreuse2' => ['118','238','0'],'chartreuse3' => ['102','205','0'],'chartreuse4' => ['69','139','0'],'chocolate' => ['210','105','30'],'chocolate1' => ['255','127','36'],'chocolate2' => ['238','118','33'],'chocolate3' => ['205','102','29'],'chocolate4' => ['139','69','19'],'coral' => ['255','127','80'],'coral1' => ['255','114','86'],'coral2' => ['238','106','80'],'coral3' => ['205','91','69'],'coral4' => ['139','62','47'],'cornflower blue' => ['100','149','237'],'cornflowerblue' => ['100','149','237'],'cornsilk' => ['255','248','220'],'cornsilk1' => ['255','248','220'],'cornsilk2' => ['238','232','205'],'cornsilk3' => ['205','200','177'],'cornsilk4' => ['139','136','120'],'cyan' => ['0','255','255'],'cyan1' => ['0','255','255'],'cyan2' => ['0','238','238'],'cyan3' => ['0','205','205'],'cyan4' => ['0','139','139'],'dark blue' => ['0','0','139'],'dark cyan' => ['0','139','139'],'dark goldenrod' => ['184','134','11'],'dark gray' => ['169','169','169'],'dark green' => ['0','100','0'],'dark grey' => ['169','169','169'],'dark khaki' => ['189','183','107'],'dark magenta' => ['139','0','139'],'dark olive green' => ['85','107','47'],'dark orange' => ['255','140','0'],'dark orchid' => ['153','50','204'],'dark red' => ['139','0','0'],'dark salmon' => ['233','150','122'],'dark sea green' => ['143','188','143'],'dark slate blue' => ['72','61','139'],'dark slate gray' => ['47','79','79'],'dark slate grey' => ['47','79','79'],'dark turquoise' => ['0','206','209'],'dark violet' => ['148','0','211'],'darkblue' => ['0','0','139'],'darkcyan' => ['0','139','139'],'darkgoldenrod' => ['184','134','11'],'darkgoldenrod1' => ['255','185','15'],'darkgoldenrod2' => ['238','173','14'],'darkgoldenrod3' => ['205','149','12'],'darkgoldenrod4' => ['139','101','8'],'darkgray' => ['169','169','169'],'darkgreen' => ['0','100','0'],'darkgrey' => ['169','169','169'],'darkkhaki' => ['189','183','107'],'darkmagenta' => ['139','0','139'],'darkolivegreen' => ['85','107','47'],'darkolivegreen1' => ['202','255','112'],'darkolivegreen2' => ['188','238','104'],'darkolivegreen3' => ['162','205','90'],'darkolivegreen4' => ['110','139','61'],'darkorange' => ['255','140','0'],'darkorange1' => ['255','127','0'],'darkorange2' => ['238','118','0'],'darkorange3' => ['205','102','0'],'darkorange4' => ['139','69','0'],'darkorchid' => ['153','50','204'],'darkorchid1' => ['191','62','255'],'darkorchid2' => ['178','58','238'],'darkorchid3' => ['154','50','205'],'darkorchid4' => ['104','34','139'],'darkred' => ['139','0','0'],'darksalmon' => ['233','150','122'],'darkseagreen' => ['143','188','143'],'darkseagreen1' => ['193','255','193'],'darkseagreen2' => ['180','238','180'],'darkseagreen3' => ['155','205','155'],'darkseagreen4' => ['105','139','105'],'darkslateblue' => ['72','61','139'],'darkslategray' => ['47','79','79'],'darkslategray1' => ['151','255','255'],'darkslategray2' => ['141','238','238'],'darkslategray3' => ['121','205','205'],'darkslategray4' => ['82','139','139'],'darkslategrey' => ['47','79','79'],'darkturquoise' => ['0','206','209'],'darkviolet' => ['148','0','211'],'deep pink' => ['255','20','147'],'deep sky blue' => ['0','191','255'],'deeppink' => ['255','20','147'],'deeppink1' => ['255','20','147'],'deeppink2' => ['238','18','137'],'deeppink3' => ['205','16','118'],'deeppink4' => ['139','10','80'],'deepskyblue' => ['0','191','255'],'deepskyblue1' => ['0','191','255'],'deepskyblue2' => ['0','178','238'],'deepskyblue3' => ['0','154','205'],'deepskyblue4' => ['0','104','139'],'dim gray' => ['105','105','105'],'dim grey' => ['105','105','105'],'dimgray' => ['105','105','105'],'dimgrey' => ['105','105','105'],'dodger blue' => ['30','144','255'],'dodgerblue' => ['30','144','255'],'dodgerblue1' => ['30','144','255'],'dodgerblue2' => ['28','134','238'],'dodgerblue3' => ['24','116','205'],'dodgerblue4' => ['16','78','139'],'firebrick' => ['178','34','34'],'firebrick1' => ['255','48','48'],'firebrick2' => ['238','44','44'],'firebrick3' => ['205','38','38'],'firebrick4' => ['139','26','26'],'floral white' => ['255','250','240'],'floralwhite' => ['255','250','240'],'forest green' => ['34','139','34'],'forestgreen' => ['34','139','34'],'gainsboro' => ['220','220','220'],'ghost white' => ['248','248','255'],'ghostwhite' => ['248','248','255'],'gold' => ['255','215','0'],'gold1' => ['255','215','0'],'gold2' => ['238','201','0'],'gold3' => ['205','173','0'],'gold4' => ['139','117','0'],'goldenrod' => ['218','165','32'],'goldenrod1' => ['255','193','37'],'goldenrod2' => ['238','180','34'],'goldenrod3' => ['205','155','29'],'goldenrod4' => ['139','105','20'],'gray' => ['190','190','190'],'gray0' => ['0','0','0'],'gray1' => ['3','3','3'],'gray10' => ['26','26','26'],'gray100' => ['255','255','255'],'gray11' => ['28','28','28'],'gray12' => ['31','31','31'],'gray13' => ['33','33','33'],'gray14' => ['36','36','36'],'gray15' => ['38','38','38'],'gray16' => ['41','41','41'],'gray17' => ['43','43','43'],'gray18' => ['46','46','46'],'gray19' => ['48','48','48'],'gray2' => ['5','5','5'],'gray20' => ['51','51','51'],'gray21' => ['54','54','54'],'gray22' => ['56','56','56'],'gray23' => ['59','59','59'],'gray24' => ['61','61','61'],'gray25' => ['64','64','64'],'gray26' => ['66','66','66'],'gray27' => ['69','69','69'],'gray28' => ['71','71','71'],'gray29' => ['74','74','74'],'gray3' => ['8','8','8'],'gray30' => ['77','77','77'],'gray31' => ['79','79','79'],'gray32' => ['82','82','82'],'gray33' => ['84','84','84'],'gray34' => ['87','87','87'],'gray35' => ['89','89','89'],'gray36' => ['92','92','92'],'gray37' => ['94','94','94'],'gray38' => ['97','97','97'],'gray39' => ['99','99','99'],'gray4' => ['10','10','10'],'gray40' => ['102','102','102'],'gray41' => ['105','105','105'],'gray42' => ['107','107','107'],'gray43' => ['110','110','110'],'gray44' => ['112','112','112'],'gray45' => ['115','115','115'],'gray46' => ['117','117','117'],'gray47' => ['120','120','120'],'gray48' => ['122','122','122'],'gray49' => ['125','125','125'],'gray5' => ['13','13','13'],'gray50' => ['127','127','127'],'gray51' => ['130','130','130'],'gray52' => ['133','133','133'],'gray53' => ['135','135','135'],'gray54' => ['138','138','138'],'gray55' => ['140','140','140'],'gray56' => ['143','143','143'],'gray57' => ['145','145','145'],'gray58' => ['148','148','148'],'gray59' => ['150','150','150'],'gray6' => ['15','15','15'],'gray60' => ['153','153','153'],'gray61' => ['156','156','156'],'gray62' => ['158','158','158'],'gray63' => ['161','161','161'],'gray64' => ['163','163','163'],'gray65' => ['166','166','166'],'gray66' => ['168','168','168'],'gray67' => ['171','171','171'],'gray68' => ['173','173','173'],'gray69' => ['176','176','176'],'gray7' => ['18','18','18'],'gray70' => ['179','179','179'],'gray71' => ['181','181','181'],'gray72' => ['184','184','184'],'gray73' => ['186','186','186'],'gray74' => ['189','189','189'],'gray75' => ['191','191','191'],'gray76' => ['194','194','194'],'gray77' => ['196','196','196'],'gray78' => ['199','199','199'],'gray79' => ['201','201','201'],'gray8' => ['20','20','20'],'gray80' => ['204','204','204'],'gray81' => ['207','207','207'],'gray82' => ['209','209','209'],'gray83' => ['212','212','212'],'gray84' => ['214','214','214'],'gray85' => ['217','217','217'],'gray86' => ['219','219','219'],'gray87' => ['222','222','222'],'gray88' => ['224','224','224'],'gray89' => ['227','227','227'],'gray9' => ['23','23','23'],'gray90' => ['229','229','229'],'gray91' => ['232','232','232'],'gray92' => ['235','235','235'],'gray93' => ['237','237','237'],'gray94' => ['240','240','240'],'gray95' => ['242','242','242'],'gray96' => ['245','245','245'],'gray97' => ['247','247','247'],'gray98' => ['250','250','250'],'gray99' => ['252','252','252'],'green' => ['0','255','0'],'green yellow' => ['173','255','47'],'green1' => ['0','255','0'],'green2' => ['0','238','0'],'green3' => ['0','205','0'],'green4' => ['0','139','0'],'greenyellow' => ['173','255','47'],'grey' => ['190','190','190'],'grey0' => ['0','0','0'],'grey1' => ['3','3','3'],'grey10' => ['26','26','26'],'grey100' => ['255','255','255'],'grey11' => ['28','28','28'],'grey12' => ['31','31','31'],'grey13' => ['33','33','33'],'grey14' => ['36','36','36'],'grey15' => ['38','38','38'],'grey16' => ['41','41','41'],'grey17' => ['43','43','43'],'grey18' => ['46','46','46'],'grey19' => ['48','48','48'],'grey2' => ['5','5','5'],'grey20' => ['51','51','51'],'grey21' => ['54','54','54'],'grey22' => ['56','56','56'],'grey23' => ['59','59','59'],'grey24' => ['61','61','61'],'grey25' => ['64','64','64'],'grey26' => ['66','66','66'],'grey27' => ['69','69','69'],'grey28' => ['71','71','71'],'grey29' => ['74','74','74'],'grey3' => ['8','8','8'],'grey30' => ['77','77','77'],'grey31' => ['79','79','79'],'grey32' => ['82','82','82'],'grey33' => ['84','84','84'],'grey34' => ['87','87','87'],'grey35' => ['89','89','89'],'grey36' => ['92','92','92'],'grey37' => ['94','94','94'],'grey38' => ['97','97','97'],'grey39' => ['99','99','99'],'grey4' => ['10','10','10'],'grey40' => ['102','102','102'],'grey41' => ['105','105','105'],'grey42' => ['107','107','107'],'grey43' => ['110','110','110'],'grey44' => ['112','112','112'],'grey45' => ['115','115','115'],'grey46' => ['117','117','117'],'grey47' => ['120','120','120'],'grey48' => ['122','122','122'],'grey49' => ['125','125','125'],'grey5' => ['13','13','13'],'grey50' => ['127','127','127'],'grey51' => ['130','130','130'],'grey52' => ['133','133','133'],'grey53' => ['135','135','135'],'grey54' => ['138','138','138'],'grey55' => ['140','140','140'],'grey56' => ['143','143','143'],'grey57' => ['145','145','145'],'grey58' => ['148','148','148'],'grey59' => ['150','150','150'],'grey6' => ['15','15','15'],'grey60' => ['153','153','153'],'grey61' => ['156','156','156'],'grey62' => ['158','158','158'],'grey63' => ['161','161','161'],'grey64' => ['163','163','163'],'grey65' => ['166','166','166'],'grey66' => ['168','168','168'],'grey67' => ['171','171','171'],'grey68' => ['173','173','173'],'grey69' => ['176','176','176'],'grey7' => ['18','18','18'],'grey70' => ['179','179','179'],'grey71' => ['181','181','181'],'grey72' => ['184','184','184'],'grey73' => ['186','186','186'],'grey74' => ['189','189','189'],'grey75' => ['191','191','191'],'grey76' => ['194','194','194'],'grey77' => ['196','196','196'],'grey78' => ['199','199','199'],'grey79' => ['201','201','201'],'grey8' => ['20','20','20'],'grey80' => ['204','204','204'],'grey81' => ['207','207','207'],'grey82' => ['209','209','209'],'grey83' => ['212','212','212'],'grey84' => ['214','214','214'],'grey85' => ['217','217','217'],'grey86' => ['219','219','219'],'grey87' => ['222','222','222'],'grey88' => ['224','224','224'],'grey89' => ['227','227','227'],'grey9' => ['23','23','23'],'grey90' => ['229','229','229'],'grey91' => ['232','232','232'],'grey92' => ['235','235','235'],'grey93' => ['237','237','237'],'grey94' => ['240','240','240'],'grey95' => ['242','242','242'],'grey96' => ['245','245','245'],'grey97' => ['247','247','247'],'grey98' => ['250','250','250'],'grey99' => ['252','252','252'],'honeydew' => ['240','255','240'],'honeydew1' => ['240','255','240'],'honeydew2' => ['224','238','224'],'honeydew3' => ['193','205','193'],'honeydew4' => ['131','139','131'],'hot pink' => ['255','105','180'],'hotpink' => ['255','105','180'],'hotpink1' => ['255','110','180'],'hotpink2' => ['238','106','167'],'hotpink3' => ['205','96','144'],'hotpink4' => ['139','58','98'],'indian red' => ['205','92','92'],'indianred' => ['205','92','92'],'indianred1' => ['255','106','106'],'indianred2' => ['238','99','99'],'indianred3' => ['205','85','85'],'indianred4' => ['139','58','58'],'ivory' => ['255','255','240'],'ivory1' => ['255','255','240'],'ivory2' => ['238','238','224'],'ivory3' => ['205','205','193'],'ivory4' => ['139','139','131'],'khaki' => ['240','230','140'],'khaki1' => ['255','246','143'],'khaki2' => ['238','230','133'],'khaki3' => ['205','198','115'],'khaki4' => ['139','134','78'],'lavender' => ['230','230','250'],'lavender blush' => ['255','240','245'],'lavenderblush' => ['255','240','245'],'lavenderblush1' => ['255','240','245'],'lavenderblush2' => ['238','224','229'],'lavenderblush3' => ['205','193','197'],'lavenderblush4' => ['139','131','134'],'lawn green' => ['124','252','0'],'lawngreen' => ['124','252','0'],'lemon chiffon' => ['255','250','205'],'lemonchiffon' => ['255','250','205'],'lemonchiffon1' => ['255','250','205'],'lemonchiffon2' => ['238','233','191'],'lemonchiffon3' => ['205','201','165'],'lemonchiffon4' => ['139','137','112'],'light blue' => ['173','216','230'],'light coral' => ['240','128','128'],'light cyan' => ['224','255','255'],'light goldenrod' => ['238','221','130'],'light goldenrod yellow' => ['250','250','210'],'light gray' => ['211','211','211'],'light green' => ['144','238','144'],'light grey' => ['211','211','211'],'light pink' => ['255','182','193'],'light salmon' => ['255','160','122'],'light sea green' => ['32','178','170'],'light sky blue' => ['135','206','250'],'light slate blue' => ['132','112','255'],'light slate gray' => ['119','136','153'],'light slate grey' => ['119','136','153'],'light steel blue' => ['176','196','222'],'light yellow' => ['255','255','224'],'lightblue' => ['173','216','230'],'lightblue1' => ['191','239','255'],'lightblue2' => ['178','223','238'],'lightblue3' => ['154','192','205'],'lightblue4' => ['104','131','139'],'lightcoral' => ['240','128','128'],'lightcyan' => ['224','255','255'],'lightcyan1' => ['224','255','255'],'lightcyan2' => ['209','238','238'],'lightcyan3' => ['180','205','205'],'lightcyan4' => ['122','139','139'],'lightgoldenrod' => ['238','221','130'],'lightgoldenrod1' => ['255','236','139'],'lightgoldenrod2' => ['238','220','130'],'lightgoldenrod3' => ['205','190','112'],'lightgoldenrod4' => ['139','129','76'],'lightgoldenrodyellow' => ['250','250','210'],'lightgray' => ['211','211','211'],'lightgreen' => ['144','238','144'],'lightgrey' => ['211','211','211'],'lightpink' => ['255','182','193'],'lightpink1' => ['255','174','185'],'lightpink2' => ['238','162','173'],'lightpink3' => ['205','140','149'],'lightpink4' => ['139','95','101'],'lightsalmon' => ['255','160','122'],'lightsalmon1' => ['255','160','122'],'lightsalmon2' => ['238','149','114'],'lightsalmon3' => ['205','129','98'],'lightsalmon4' => ['139','87','66'],'lightseagreen' => ['32','178','170'],'lightskyblue' => ['135','206','250'],'lightskyblue1' => ['176','226','255'],'lightskyblue2' => ['164','211','238'],'lightskyblue3' => ['141','182','205'],'lightskyblue4' => ['96','123','139'],'lightslateblue' => ['132','112','255'],'lightslategray' => ['119','136','153'],'lightslategrey' => ['119','136','153'],'lightsteelblue' => ['176','196','222'],'lightsteelblue1' => ['202','225','255'],'lightsteelblue2' => ['188','210','238'],'lightsteelblue3' => ['162','181','205'],'lightsteelblue4' => ['110','123','139'],'lightyellow' => ['255','255','224'],'lightyellow1' => ['255','255','224'],'lightyellow2' => ['238','238','209'],'lightyellow3' => ['205','205','180'],'lightyellow4' => ['139','139','122'],'lime green' => ['50','205','50'],'limegreen' => ['50','205','50'],'linen' => ['250','240','230'],'magenta' => ['255','0','255'],'magenta1' => ['255','0','255'],'magenta2' => ['238','0','238'],'magenta3' => ['205','0','205'],'magenta4' => ['139','0','139'],'maroon' => ['176','48','96'],'maroon1' => ['255','52','179'],'maroon2' => ['238','48','167'],'maroon3' => ['205','41','144'],'maroon4' => ['139','28','98'],'medium aquamarine' => ['102','205','170'],'medium blue' => ['0','0','205'],'medium orchid' => ['186','85','211'],'medium purple' => ['147','112','219'],'medium sea green' => ['60','179','113'],'medium slate blue' => ['123','104','238'],'medium spring green' => ['0','250','154'],'medium turquoise' => ['72','209','204'],'medium violet red' => ['199','21','133'],'mediumaquamarine' => ['102','205','170'],'mediumblue' => ['0','0','205'],'mediumorchid' => ['186','85','211'],'mediumorchid1' => ['224','102','255'],'mediumorchid2' => ['209','95','238'],'mediumorchid3' => ['180','82','205'],'mediumorchid4' => ['122','55','139'],'mediumpurple' => ['147','112','219'],'mediumpurple1' => ['171','130','255'],'mediumpurple2' => ['159','121','238'],'mediumpurple3' => ['137','104','205'],'mediumpurple4' => ['93','71','139'],'mediumseagreen' => ['60','179','113'],'mediumslateblue' => ['123','104','238'],'mediumspringgreen' => ['0','250','154'],'mediumturquoise' => ['72','209','204'],'mediumvioletred' => ['199','21','133'],'midnight blue' => ['25','25','112'],'midnightblue' => ['25','25','112'],'mint cream' => ['245','255','250'],'mintcream' => ['245','255','250'],'misty rose' => ['255','228','225'],'mistyrose' => ['255','228','225'],'mistyrose1' => ['255','228','225'],'mistyrose2' => ['238','213','210'],'mistyrose3' => ['205','183','181'],'mistyrose4' => ['139','125','123'],'moccasin' => ['255','228','181'],'navajo white' => ['255','222','173'],'navajowhite' => ['255','222','173'],'navajowhite1' => ['255','222','173'],'navajowhite2' => ['238','207','161'],'navajowhite3' => ['205','179','139'],'navajowhite4' => ['139','121','94'],'navy' => ['0','0','128'],'navy blue' => ['0','0','128'],'navyblue' => ['0','0','128'],'old lace' => ['253','245','230'],'oldlace' => ['253','245','230'],'olive drab' => ['107','142','35'],'olivedrab' => ['107','142','35'],'olivedrab1' => ['192','255','62'],'olivedrab2' => ['179','238','58'],'olivedrab3' => ['154','205','50'],'olivedrab4' => ['105','139','34'],'orange' => ['255','165','0'],'orange red' => ['255','69','0'],'orange1' => ['255','165','0'],'orange2' => ['238','154','0'],'orange3' => ['205','133','0'],'orange4' => ['139','90','0'],'orangered' => ['255','69','0'],'orangered1' => ['255','69','0'],'orangered2' => ['238','64','0'],'orangered3' => ['205','55','0'],'orangered4' => ['139','37','0'],'orchid' => ['218','112','214'],'orchid1' => ['255','131','250'],'orchid2' => ['238','122','233'],'orchid3' => ['205','105','201'],'orchid4' => ['139','71','137'],'pale goldenrod' => ['238','232','170'],'pale green' => ['152','251','152'],'pale turquoise' => ['175','238','238'],'pale violet red' => ['219','112','147'],'palegoldenrod' => ['238','232','170'],'palegreen' => ['152','251','152'],'palegreen1' => ['154','255','154'],'palegreen2' => ['144','238','144'],'palegreen3' => ['124','205','124'],'palegreen4' => ['84','139','84'],'paleturquoise' => ['175','238','238'],'paleturquoise1' => ['187','255','255'],'paleturquoise2' => ['174','238','238'],'paleturquoise3' => ['150','205','205'],'paleturquoise4' => ['102','139','139'],'palevioletred' => ['219','112','147'],'palevioletred1' => ['255','130','171'],'palevioletred2' => ['238','121','159'],'palevioletred3' => ['205','104','137'],'palevioletred4' => ['139','71','93'],'papaya whip' => ['255','239','213'],'papayawhip' => ['255','239','213'],'peach puff' => ['255','218','185'],'peachpuff' => ['255','218','185'],'peachpuff1' => ['255','218','185'],'peachpuff2' => ['238','203','173'],'peachpuff3' => ['205','175','149'],'peachpuff4' => ['139','119','101'],'peru' => ['205','133','63'],'pink' => ['255','192','203'],'pink1' => ['255','181','197'],'pink2' => ['238','169','184'],'pink3' => ['205','145','158'],'pink4' => ['139','99','108'],'plum' => ['221','160','221'],'plum1' => ['255','187','255'],'plum2' => ['238','174','238'],'plum3' => ['205','150','205'],'plum4' => ['139','102','139'],'powder blue' => ['176','224','230'],'powderblue' => ['176','224','230'],'purple' => ['160','32','240'],'purple1' => ['155','48','255'],'purple2' => ['145','44','238'],'purple3' => ['125','38','205'],'purple4' => ['85','26','139'],'red' => ['255','0','0'],'red1' => ['255','0','0'],'red2' => ['238','0','0'],'red3' => ['205','0','0'],'red4' => ['139','0','0'],'rosy brown' => ['188','143','143'],'rosybrown' => ['188','143','143'],'rosybrown1' => ['255','193','193'],'rosybrown2' => ['238','180','180'],'rosybrown3' => ['205','155','155'],'rosybrown4' => ['139','105','105'],'royal blue' => ['65','105','225'],'royalblue' => ['65','105','225'],'royalblue1' => ['72','118','255'],'royalblue2' => ['67','110','238'],'royalblue3' => ['58','95','205'],'royalblue4' => ['39','64','139'],'saddle brown' => ['139','69','19'],'saddlebrown' => ['139','69','19'],'salmon' => ['250','128','114'],'salmon1' => ['255','140','105'],'salmon2' => ['238','130','98'],'salmon3' => ['205','112','84'],'salmon4' => ['139','76','57'],'sandy brown' => ['244','164','96'],'sandybrown' => ['244','164','96'],'sea green' => ['46','139','87'],'seagreen' => ['46','139','87'],'seagreen1' => ['84','255','159'],'seagreen2' => ['78','238','148'],'seagreen3' => ['67','205','128'],'seagreen4' => ['46','139','87'],'seashell' => ['255','245','238'],'seashell1' => ['255','245','238'],'seashell2' => ['238','229','222'],'seashell3' => ['205','197','191'],'seashell4' => ['139','134','130'],'sienna' => ['160','82','45'],'sienna1' => ['255','130','71'],'sienna2' => ['238','121','66'],'sienna3' => ['205','104','57'],'sienna4' => ['139','71','38'],'sky blue' => ['135','206','235'],'skyblue' => ['135','206','235'],'skyblue1' => ['135','206','255'],'skyblue2' => ['126','192','238'],'skyblue3' => ['108','166','205'],'skyblue4' => ['74','112','139'],'slate blue' => ['106','90','205'],'slate gray' => ['112','128','144'],'slate grey' => ['112','128','144'],'slateblue' => ['106','90','205'],'slateblue1' => ['131','111','255'],'slateblue2' => ['122','103','238'],'slateblue3' => ['105','89','205'],'slateblue4' => ['71','60','139'],'slategray' => ['112','128','144'],'slategray1' => ['198','226','255'],'slategray2' => ['185','211','238'],'slategray3' => ['159','182','205'],'slategray4' => ['108','123','139'],'slategrey' => ['112','128','144'],'snow' => ['255','250','250'],'snow1' => ['255','250','250'],'snow2' => ['238','233','233'],'snow3' => ['205','201','201'],'snow4' => ['139','137','137'],'spring green' => ['0','255','127'],'springgreen' => ['0','255','127'],'springgreen1' => ['0','255','127'],'springgreen2' => ['0','238','118'],'springgreen3' => ['0','205','102'],'springgreen4' => ['0','139','69'],'steel blue' => ['70','130','180'],'steelblue' => ['70','130','180'],'steelblue1' => ['99','184','255'],'steelblue2' => ['92','172','238'],'steelblue3' => ['79','148','205'],'steelblue4' => ['54','100','139'],'tan' => ['210','180','140'],'tan1' => ['255','165','79'],'tan2' => ['238','154','73'],'tan3' => ['205','133','63'],'tan4' => ['139','90','43'],'thistle' => ['216','191','216'],'thistle1' => ['255','225','255'],'thistle2' => ['238','210','238'],'thistle3' => ['205','181','205'],'thistle4' => ['139','123','139'],'tomato' => ['255','99','71'],'tomato1' => ['255','99','71'],'tomato2' => ['238','92','66'],'tomato3' => ['205','79','57'],'tomato4' => ['139','54','38'],'turquoise' => ['64','224','208'],'turquoise1' => ['0','245','255'],'turquoise2' => ['0','229','238'],'turquoise3' => ['0','197','205'],'turquoise4' => ['0','134','139'],'violet' => ['238','130','238'],'violet red' => ['208','32','144'],'violetred' => ['208','32','144'],'violetred1' => ['255','62','150'],'violetred2' => ['238','58','140'],'violetred3' => ['205','50','120'],'violetred4' => ['139','34','82'],'wheat' => ['245','222','179'],'wheat1' => ['255','231','186'],'wheat2' => ['238','216','174'],'wheat3' => ['205','186','150'],'wheat4' => ['139','126','102'],'white' => ['255','255','255'],'white smoke' => ['245','245','245'],'whitesmoke' => ['245','245','245'],'yellow' => ['255','255','0'],'yellow green' => ['154','205','50'],'yellow1' => ['255','255','0'],'yellow2' => ['238','238','0'],'yellow3' => ['205','205','0'],'yellow4' => ['139','139','0'],'yellowgreen' => ['154','205','50']}
EOT
}

sub __instantiate_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $o;
    try
    {
        # https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
        # require $class unless( defined( *{"${class}::"} ) );
        # Either it passes and returns the class loaded or it raises an error trapped in catch
        my $rc = Class::Load::load_class( $class );
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        $o = scalar( @_ ) ? $class->new( @_ ) : $class->new;
        return( $self->pass_error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
        $o->debug( $this->{debug} ) if( $o->can( 'debug' ) );
    }
    catch( $e ) 
    {
        return( $self->error({ code => 500, message => $e }) );
    }
    return( $o );
}

sub _can
{
    my $self = shift( @_ );
    no overloading;
    # Nothing provided
    return if( !scalar( @_ ) );
    return if( !defined( $_[0] ) );
    return if( !Scalar::Util::blessed( $_[0] ) );
    return( $_[0]->can( $_[1] ) );
}

sub _get_args_as_array
{
    my $self = shift( @_ );
    return( [] ) if( !scalar( @_ ) );
    my $ref = [];
    if( scalar( @_ ) == 1 && $self->_is_array( $_[0] ) )
    {
        $ref = shift( @_ );
    }
    else
    {
        $ref = [ @_ ];
    }
    return( $ref );
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    return( {} ) if( !scalar( @_ ) );
    no warnings 'uninitialized';
    my $ref = {};
    if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] ) )
    {
        $ref = shift( @_ );
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $ref = { @_ };
    }
    return( $ref );
}

## Call to the actual method doing the work
## The reason for doing so is because _instantiate_object() may be inherited, but
## _set_get_class or _set_get_hash_as_object created dynamic class which requires to call _instantiate_object
## If _instantiate_object is inherited, it will yield unpredictable results
sub _instantiate_object { return( shift->__instantiate_object( @_ ) ); }

sub _get_stack_trace
{
    my $self = shift( @_ );
    my $trace = Devel::StackTrace->new( skip_frames => 1, indent => 1 );
    return( $trace );
}

sub _is_a
{
    my $self = shift( @_ );
    my $obj = shift( @_ );
    my $pkg = shift( @_ );
    no overloading;
    return if( !$obj || !$pkg );
    return if( !$self->_is_object( $obj ) );
    if( $pkg !~ /^\w+(?:\:\:\w+)*$/ )
    {
        warn( "Warning only: package name provided \"$pkg\" contains illegal characters.\n" );
    }
    return( $obj->isa( $pkg ) );
}

sub _is_class_loadable
{
    my $self = shift( @_ );
    my $class = shift( @_ ) || return(0);
    my $version = shift( @_ );
    no strict 'refs';
    $self->message( 3, "Checking module '$class' with version '$version'." );
    try
    {
        my $file  = File::Spec->catfile( split( /::/, $class ) ) . '.pm';
        my $inc   = File::Spec::Unix->catfile( split( /::/, $class ) ) . '.pm';
        $self->message( 3, "Is module '$class' already loaded? ", defined( $INC{ $inc } ) ? 'yes' : 'no' );
        if( defined( $INC{ $inc } ) )
        {
            if( defined( $version ) )
            {
                my $alter_version = ${"${class}\::VERSION"};
                $self->message( 3, "Module '$class' version is '$alter_version' against required version '$version'." );
                return( version->parse( $alter_version ) >= version->parse( $version ) );
            }
            else
            {
                return(1);
            }
        }
        foreach my $dir ( @INC )
        {
            my $fpath = File::Spec->catfile( $dir, $file );
            next if( !-e( $fpath ) || !-r( $fpath ) || -z( $fpath ) );
            if( defined( $version ) )
            {
                my $info = Module::Metadata->new_from_file( $fpath );
                my $alter_version = $info->version;
                return( version->parse( $alter_version ) >= version->parse( $version ) );
            }
            return(1);
        }
        return(0);
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error occurred while trying to check if module \"$class\" with version '$version' is loadable: $e" ) );
    }
}

sub _is_class_loaded
{
    my $self = shift( @_ );
    my $class = shift( @_ );
    if( $MOD_PERL )
    {
        # https://perl.apache.org/docs/2.0/api/Apache2/Module.html#C_loaded_
        # $self->message( 3, "Does module $class exists in \%INC using Apache2::Module ? ", Apache2::Module::loaded( $class ) ? 'yes' : 'no' );
        return( Apache2::Module::loaded( $class ) );
    }
    else
    {
        ( my $pm = $class ) =~ s{::}{/}gs;
        $pm .= '.pm';
        $self->message( 3, "Does module $class ($pm) exists in \%INC ? ", CORE::exists( $INC{ $pm } ) ? 'yes' : 'no' );
        return( CORE::exists( $INC{ $pm } ) );
        # return(1) if( CORE::exists( $INC{ $pm } ) );
        # For inline package
        # $self->message( 3, "Is module $class an inline module already loaded? Checking \%${class}\:: ", scalar( keys( %{"${class}\::"} ) ) ? 'yes' : 'no', ". Its keys are: '", join( "', '", sort( keys( %{"${class}\::"} ) ) ), "'" );
        # return( scalar( keys( %{"${class}\::"} ) ) ? 1 : 0 );
    }
}

# UNIVERSAL::isa works for both array or array as objects
# sub _is_array { return( UNIVERSAL::isa( $_[1], 'ARRAY' ) ); }
sub _is_array
{
    return( 0 ) if( scalar( @_ < 2 ) );
    return( 0 ) if( !defined( $_[1] ) );
    return( Scalar::Util::reftype( $_[1] ) eq 'ARRAY' );
}

sub _is_hash
{
    return( 0 ) if( scalar( @_ < 2 ) );
    return( 0 ) if( !defined( $_[1] ) );
    return( Scalar::Util::reftype( $_[1] ) eq 'HASH' );
}

sub _is_integer { return( $_[1] =~ /^[\+\-]?\d+$/ ? 1 : 0 ); }

sub _is_ip
{
    my $self = shift( @_ );
    my $ip   = shift( @_ );
    return(0) if( !length( $ip ) );
    # Already loaded
    unless( $RE{net}{IPv4} )
    {
        $self->_load_class( 'Regexp::Common' ) || return( $self->pass_error );
        Regexp::Common->import( 'net' );
    }
    # We need to return either 1 or 0. By default, perl return undef for false
    # supports IPv4 and IPv6 in CIDR notation or not
    my $ip4or6 = qr/($RE{net}{IPv4}(\/(3[0-2]|[1-2][0-9]|[0-9]))?)|($RE{net}{IPv6}(\/(12[0-8]|1[0-1][0-9]|[1-9][0-9]|[0-9]))?)/;
    return( $ip =~ /^$ip4or6$/ ? 1 : 0 );
}

sub _is_number
{
    return( 0 ) if( scalar( @_ < 2 ) );
    return( 0 ) if( !defined( $_[1] ) );
    $_[0]->_load_class( 'Regexp::Common' ) || return( $_[0]->pass_error );
    no warnings 'once';
    return( $_[1] =~ /^$Regexp::Common::RE{num}{real}$/ );
}

sub _is_object
{
    return( 0 ) if( scalar( @_ < 2 ) );
    return( 0 ) if( !defined( $_[1] ) );
    return( Scalar::Util::blessed( $_[1] ) );
}

sub _is_scalar
{
    return( 0 ) if( scalar( @_ < 2 ) );
    return( 0 ) if( !defined( $_[1] ) );
    return( Scalar::Util::reftype( $_[1] ) eq 'SCALAR' );
}

sub _is_uuid { return( $_[1] =~ /^[a-fA-F0-9]{8}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{12}$/ ? 1 : 0 ); }

sub _load_class
{
    my $self  = shift( @_ );
    my $class = shift( @_ ) || return( $self->error( "No package name was provided to load." ) );
    my $opts  = {};
    $opts     = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $args  = $self->_get_args_as_array( @_ );
    # Get the caller's package so we load the module in context
    my $caller_class = $opts->{caller} || CORE::caller;
    # Return if already loaded
    if( $self->_is_class_loaded( $class ) )
    {
        # $self->message( 3, "Class '$class' is already loaded." );
        return( $class );
    }
    my $pl = "package ${caller_class}; use $class";
    $pl .= ' ' . $opts->{version} if( CORE::defined( $opts->{version} ) && CORE::length( $opts->{version} ) );
    $pl .= ' qw( ' . CORE::join( ' ', @$args ) . ' );' if( scalar( @$args ) );
    # $self->message( 3, "Evaluating '$pl'" );
    local $SIG{__DIE__} = sub{};
    eval( $pl );
    # $self->message( 3, "Loading package $class triggered error? -> '$@'" );
    return( $self->error( "Unable to load package ${class}: $@" ) ) if( $@ );
    # $self->message( 3, "Is package $class loaded now? ", $self->_is_class_loaded( $class ) ? 'yes' : 'no' );
    return( $self->_is_class_loaded( $class ) ? $class : '' );
}

sub _obj2h
{
    my $self = shift( @_ );
    # The method that called message was itself called using the package name like My::Package->some_method
    # We are going to check if global $DEBUG or $VERBOSE variables are set and create the related debug and verbose entry into the hash we return
    no strict 'refs';
    if( !ref( $self ) )
    {
        my $class = $self;
        my $hash =
        {
        debug   => ${ "${class}\::DEBUG" },
        verbose => ${ "${class}\::VERBOSE" },
        error   => ${ "${class}\::ERROR" },
        };
        return( bless( $hash => $class ) );
    }
    elsif( Scalar::Util::reftype( $self ) eq 'HASH' )
    {
        return( $self );
    }
    elsif( Scalar::Util::reftype( $self ) eq 'GLOB' )
    {
        return( \%{*$self} );
    }
    # Because object may be accessed as My::Package->method or My::Package::method
    # there is not always an object available, so we need to fake it to avoid error
    # This is primarly itended for generic methods error(), errstr() to work under any conditions.
    else
    {
        return( {} );
    }
}

# Ref:
# <https://en.wikipedia.org/wiki/Date_format_by_country>
sub _parse_timestamp
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    # No value was actually provided
    return if( !length( $str ) );
    $str = "$str";
    my $this = $self->_obj2h;
    my $tz = DateTime::TimeZone->new( name => 'local' );
    # my $tz = DateTime::TimeZone->new( name => 'Europe/Berlin' );
    unless( DateTime->can( 'TO_JSON' ) )
    {
        no warnings 'once';
        *DateTime::TO_JSON = sub
        {
            return( $_[0]->stringify );
        };
    }
    my $error = 0;
    # For some Japanese here
    use utf8;
    my $opt = 
    {
    pattern   => '%Y-%m-%d %T',
    locale    => 'en_GB',
    time_zone => $tz->name,
    on_error => sub{ $error++ },
    };
    
    my $fmt =
    {
    pattern   => '%Y-%m-%d %T',
    locale    => 'en_GB',
    time_zone => $tz->name,
    };
    
    my $formatter = 'DateTime::Format::Strptime';
    
    my $roman2regular =
    {
    I   => 1,
    II  => 2,
    III => 3,
    IV  => 4,
    V   => 5,
    VI  => 6,
    VII => 7,
    VIII=> 8,
    IX  => 9,
    X   => 10,
    XI  => 11,
    XII => 12,
    i   => 1,
    ii  => 2,
    iii => 3,
    iv  => 4,
    v   => 5,
    vi  => 6,
    vii => 7,
    viii=> 8,
    ix  => 9,
    x   => 10,
    xi  => 11,
    xii => 12,
    };
    # (^(?=[MDCLXVI])M*(C[MD]|D?C{0,3})(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})$)
    # <https://stackoverflow.com/a/36576402/4814971>
    # 
    # ^(I[VX]|VI{0,3}|I{1,3})|((X[LC]|LX{0,3}|X{1,3})(I[VX]|V?I{0,3}))|((C[DM]|DC{0,3}|C{1,3})(X[LC]|L?X{0,3})(I[VX]|V?I{0,3}))|(M+(C[DM]|D?C{0,3})(X[LC]|L?X{0,3})(I[VX]|V?I{0,3}))$
    # <https://stackoverflow.com/a/60469651/4814971>
    
    # Of course, when an era starts and another era ends, it is during the same Gregorian year, so we use the new era for the year start although it is perfectly correct to use the nth year for the year end as well, but that would mean two eras for the same year, and although for humans it is ok, for computing it does not work.
    # For example end of Meiji is in 1912 (45th year) which is also the first of the Taisho era
    # Ref: <http://www.ajnet.ne.jp/benri/conversion.hpml>
    
    # GNU PO file
    # 2019-10-03 19-44+0000
    # 2019-10-03 19:44:01+0000
    if( $str =~ /^(?<year>\d{4})(?<d_sep>\D)(?<month>\d{1,2})\D(?<day>\d{1,2})(?<sep>[\s\t]+)(?<hour>\d{1,2})(?<t_sep>\D)(?<minute>\d{1,2})(?:\D(?<second>\d{1,2}))?(?<tz>([+-])(\d{2})(\d{2}))$/ )
    {
        my $re = { %+ };
        $self->message( 3, "Pattern 1 (PO): ", sub{ $self->dump( $re )} );
        $fmt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . join( $re->{t_sep}, qw( %H %M ) );
        if( length( $re->{second} ) )
        {
            $fmt->{pattern} .= $re->{t_sep} . '%S';
        }
        $fmt->{pattern} .= '%z';
        $str = join( '-', @$re{qw( year month day )} ) . ' ' . join( ':', @$re{qw( hour minute )}, ( length( $re->{second} ) ? $re->{second} : '00' ) ) . $re->{tz};
        $opt->{pattern} = '%F %T%z';
        $fmt->{time_zone} = $opt->{time_zone} = $re->{tz};
    }
    ## 2019-06-19 23:23:57.000000000+0900
    ## From PostgreSQL: 2019-06-20 11:02:36.306917+09
    ## ISO 8601: 2019-06-20T11:08:27
    elsif( $str =~ /^(?<year>\d{4})(?<d_sep>[-|\/])(?<month>\d{1,2})[-|\/](?<day>\d{1,2})(?<sep>[[:blank:]]+|T)(?<time>\d{1,2}:\d{1,2}:\d{1,2})(?:\.(?<milli>\d+))?(?<tz>(?:\+|\-)\d{2,4})?$/ )
    {
        my $re = { %+ };
        $self->message( 3, "Pattern 2 (SQL): ", sub{ $self->dump( $re )} );
        $opt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . '%T';
        $str = join( $re->{d_sep}, @$re{qw( year month day )} ) . $re->{sep} . $re->{time};
        if( length( $re->{milli} ) )
        {
            $opt->{pattern} .= '.%' . length( $re->{milli} ) . 'N';
            $str .= '.' . $re->{milli};
        }
        $fmt->{pattern} = $opt->{pattern};
        
        if( length( $re->{tz} ) )
        {
            $opt->{pattern} .= '%z';
            $re->{tz} .= '00' if( length( $re->{tz} ) == 3 );
            $str .= $re->{tz};
            $fmt->{pattern} .= '%z';
            $fmt->{time_zone} = $opt->{time_zone} = $re->{tz};
        }
    }
    # From SQLite: 2019-06-20 02:03:14
    # From MySQL: 2019-06-20 11:04:01
    elsif( $str =~ /^(?<year>\d{4})(?<d_sep>[-|\/])(?<month>\d{1,2})[-|\/](?<day>\d{1,2})(?<sep>[[:blank:]]+|T)(?<time>\d{1,2}:\d{1,2}:\d{1,2})$/ )
    {
        my $re = { %+ };
        # $opt->{pattern} = $fmt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . $re->{time};
        $opt->{pattern} = $fmt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . '%T';
        $str = join( $re->{d_sep}, @$re{qw( year month day )} ) . $re->{sep} . $re->{time};
        my $dt = DateTime->now( time_zone => $tz );
        my $offset = $dt->offset;
        # e.g. 9 or possibly 9.5
        my $offset_hour = ( $offset / 3600 );
        # e.g. 9.5 => 0.5 * 60 = 30
        my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
        $str .= sprintf( '%+03d%02d', $offset_hour, $offset_min );
        # XXX
        # $self->message( 3, "Time zone '$tz', offset: '$offset', offset hour '$offset_hour', offset minute '$offset_min'. Resulting string is '$str' and pattern is '$opt->{pattern}'" );
        $opt->{pattern} .= '%z';
    }
    # e.g. Sun, 06 Oct 2019 06:41:11 GMT
    elsif( $str =~ /^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),[[:blank:]]+(?<day>\d{2})[[:blank:]]+(?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[[:blank:]]+(?<year>\d{4})[[:blank:]]+(?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2})[[:blank:]]+GMT$/ )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = q{%a, %d %b %Y %T GMT};
        $self->message( 3, "Pattern 'Sun, 06 Oct 2019 06:41:11 GMT'" );
    }
    # 12 March 2001 17:07:30 JST
    # 12-March-2001 17:07:30 JST
    # 12/March/2001 17:07:30 JST
    # 12 March 2001 17:07
    # 12 March 2001 17:07 JST
    # 12 March 2001 17:07:30+0900
    # 12 March 2001 17:07:30 +0900
    # Monday, 12 March 2001 17:07:30 JST
    # Monday, 12 Mar 2001 17:07:30 JST
    # 03/Feb/1994:00:00:00 0000
    elsif( $str =~ /^
        (?:
            (?:
                (?<wd>Mon|Tue|Wed|Thu|Fri|Sat|Sun)
                |
                (?<wd_long>Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)
            )
            (?<wd_comma>\,)?(?<blank0>[[:blank:]]+)
        )?
        (?<day>\d{1,2})
        (?<sep1>[[:blank:]]+|[-\/])
        (?:
            (?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
            |
            (?<month_long>January|February|March|April|May|June|July|August|September|Octocber|November|December)
        )
        (?<sep2>[[:blank:]]+|[-\/])
        (?<year>\d{2}|\d{4})
        (?<blank1>[[:blank:]]+)
        (?<hour>\d{1,2})
        :
        (?<minute>\d{1,2})
        (?:\:(?<second>\d{1,2}))?
        (?<tz>
            (?:
                (?<blank2>[[:blank:]]*)
                (?<tz1>[-+]?\d{2,4})
            )
            |
            (?:
                (?<blank2>[[:blank:]]+)
                (?<tz2>(?![APap][Mm]\b)[A-Za-z]+)
            )
        )?$/x )
    {
        my $re = { %+ };
        my @buff = ();
        if( $re->{wd} || $re->{wd_long} )
        {
            push( @buff, ( $re->{wd} || $re->{wd_long} ) );
            push( @buff, ',' ) if( $re->{wd_comma} );
            push( @buff, $re->{blank0} );
        }
        push( @buff, length( $re->{day} ) > 1 ? '%d' : '%e' );
        push( @buff, $re->{sep1} );
        push( @buff, ( $re->{month} ? '%b' : '%B' ) );
        push( @buff, $re->{sep2} );
        push( @buff, length( $re->{year} ) == 2 ? '%y' : '%Y' );
        push( @buff, $re->{blank1} );
        if( $re->{hour} && $re->{minute} && $re->{second} )
        {
            push( @buff, '%T' );
        }
        elsif( $re->{hour} && $re->{minute} )
        {
            push( @buff, '%H:%M' );
        }
        
        if( length( $re->{tz} ) )
        {
            push( @buff, ( length( $re->{tz1} ) ? ( ( $re->{blank2} // '' ) . $re->{tz1} ) : ( $re->{blank2} . $re->{tz2} ) ) );
        }
        $opt->{pattern} = $fmt->{pattern} = join( '', @buff );
        $self->message( 3, "Pattern 'Monday, 12 March 2001 17:07:30 JST'" );
    }
    # 2019-06-20
    # 2019/06/20
    # 2016.04.22
    elsif( $str =~ /^(?<year>\d{4})(?<d_sep>\D)(?<month>\d{1,2})\D(?<day>\d{1,2})$/ )
    {
        my $re = { %+ };
        $str = join( $re->{d_sep}, @$re{qw( year month day )} );
        $opt->{pattern} = $fmt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) );
    }
    # 2014, Feb 17
    elsif( $str =~ /^(?<year>\d{4}),(?<sep1>[[:blank:]\h]+)(?<month>[a-zA-Z]{3,4})(?<sep2>[[:blank:]\h]+)(?<day>\d{1,2})$/ )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = '%Y,' . $re->{sep1} . '%b' . $re->{sep2} . '%d';
    }
    # 17 Feb, 2014
    elsif( $str =~ /^(?<day>\d{1,2})(?<sep1>[[:blank:]\h]+)(?<month>[a-zA-Z]{3,4}),(?<sep2>[[:blank:]\h]+)(?<year>\d{4})$/ )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = '%d' . $re->{sep1} . '%b,' . $re->{sep2} . '%Y';
    }
    # February 17, 2009
    elsif( $str =~ /^(?<month>[a-zA-Z]{3,9})(?<sep1>[[:blank:]\h]+)(?<day>\d{1,2}),(?<sep2>[[:blank:]\h]+)(?<year>\d{4})$/ )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = '%B' . $re->{sep1} . '%d,' . $re->{sep2} . '%Y';
    }
    # 15 July 2021
    elsif( $str =~ /^(?<day>\d{1,2})(?<sep1>[[:blank:]\h]+)(?<month>[a-zA-Z]{3,9})(?<sep2>[[:blank:]\h]+)(?<year>\d{4})$/ )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = '%d' . $re->{sep1} . '%B' . $re->{sep2} . '%Y';
    }
    # 22.04.2016
    # 22-04-2016
    # 17. 3. 2018.
    elsif( $str =~ /^(?<day>\d{1,2})(?<sep>\D)(?<blank1>[[:blank:]\h]+)?(?<month>\d{1,2})\D(?<blank2>[[:blank:]\h]+)?(?<year>\d{4})(?<trailing_dot>\.)?$/ )
    {
        my $re = { %+ };
        # $opt->{pattern} = $fmt->{pattern} = join( $re->{sep}, qw( %d %m %Y ) );
        $opt->{pattern} = $fmt->{pattern} = "%d$re->{sep}$re->{blank1}%m$re->{sep}$re->{blank2}%Y$re->{trailing_dot}";
        $fmt->{leading_zero} = 1 if( substr( $re->{day}, 0, 1 ) == 0 || substr( $re->{month}, 0, 1 ) == 0 );
        {
            package
                DateTime::Format::DMY;
            sub new
            {
                my $this = shift( @_ );
                my $hash = { @_ };
                return( bless( $hash => ( ref( $this ) || $this ) ) );
            }
            sub format_datetime
            {
                my( $self, $dt ) = @_;
                my $d = $dt->day;
                my $m = $dt->month;
                my $y = $dt->year;
                my $pat = $self->{pattern};
                $pat =~ s/\%d/$d/;
                $pat =~ s/\%m/$m/;
                $pat =~ s/\%Y/$y/;
                return( $pat );
            }
        }
        if( $fmt->{leading_zero} )
        {
            # We do not want it to interfere with the module supported parameters
            delete( $fmt->{leading_zero} );
        }
        else
        {
            $formatter = 'DateTime::Format::DMY';
        }
    }
    # 17.III.2020
    # 17. III. 2018.
    elsif( $str =~ /^(?<day>\d{1,2})\.(?<blank1>[[:blank:]\h]+)?(?<month>XI{0,2}|I{0,3}|IV|VI{0,3}|IX)\.(?<blank2>[[:blank:]\h]+)?(?<year>\d{4})(?<trailing_dot>\.)?$/i )
    {
        my $re = { %+ };
        $re->{month} = $roman2regular->{ $re->{month} };
        $str = join( '-', @$re{qw( year month day )} );
        $opt->{pattern} = '%F';
        $fmt->{pattern} = "%d.$re->{blank1}%m.$re->{blank2}%Y$re->{trailing_dot}";
        {
            package
                DateTime::Format::RomanDDXXXYYYY;
            our $ROMAN2REGULAR = $roman2regular;
            sub new
            {
                my $this = shift( @_ );
                my $hash = { @_ };
                return( bless( $hash => ( ref( $this ) || $this ) ) );
            }
            
            sub parse_datetime {}
            
            sub parse_duration {}
            
            sub format_duration {}
            
            sub format_datetime
            {
                my( $self, $dt ) = @_;
                my $d = $dt->day;
                my $m = $dt->month;
                my $y = $dt->year;
                foreach my $k ( keys( %$ROMAN2REGULAR ) )
                {
                    # Skip lowercase ones
                    next if( $k =~ /^[a-z]+$/ );
                    if( $ROMAN2REGULAR->{ $k } == $m )
                    {
                        $m = $k;
                        last;
                    }
                }
                my $pat = $self->{pattern};
                $pat =~ s/\%d/$d/;
                $pat =~ s/\%m/$m/;
                $pat =~ s/\%Y/$y/;
                return( $pat );
            }
        }
        $formatter = 'DateTime::Format::RomanDDXXXYYYY';
    }
    # 20030613
    elsif( $str =~ /^(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})$/ )
    {
        my $re = { %+ };
        # $self->message( 3, "Pattern 10: ", sub{ $self->dump( $re )} );
        $opt->{pattern} = '%F';
        $str = join( '-', @$re{qw( year month day )} );
        $fmt->{pattern} = join( '', qw( %Y %m %d ) );
        # $opt->{pattern} = $fmt->{pattern} = join( '', qw( %d %m %Y ) );
    }
    # 2021年7月14日
    # 令和3年7月14日
    elsif( $str =~ /^(?<era>\p{Han})?(?<year>\d{1,4})年(?<month>\d{1,2})月(?<day>\d{1,2})日$/ )
    {
        my $re = { %+ };
        if( $re->{era} )
        {
            try
            {
                require DateTime::Format::JP;
                my $parser = DateTime::Format::JP->new( pattern => '%E%Y年%m月%d日', time_zone => 'local' );
                my $dt = $parser->parse_datetime( $str );
                $dt->set_formatter( $parser );
                return( $dt );
            }
            catch( $e )
            {
                return( $self->error( "An error occurred while trying to use DateTime::Format::JP: $e" ) );
            }
        }
        else
        {
            $opt->{pattern} = '%F';
            $str = join( '-', @$re{qw( year month day )} );
            use utf8;
            $fmt->{pattern} = '%Y年%m月%d日';
        }
    }
    # <https://en.wikipedia.org/wiki/Date_format_by_country>
    # Possibly followed by a dot and some integer for milliseconds as provided by Time::HiRes
    elsif( $str =~ /^\d{1,10}(?:\.\d+)?$/ )
    {
        try
        {
            # $self->message( 4, "Got here for epoch '$str'" );
            my $dt = DateTime->from_epoch( epoch => $str, time_zone => 'local' );
            $opt->{pattern} = ( CORE::index( $str, '.' ) != -1 ? '%s.%N' : '%s' );
            my $strp = DateTime::Format::Strptime->new( %$opt );
            $dt->set_formatter( $strp );
            return( $dt );
        }
        catch( $e )
        {
            return( $self->error( "An error occurred while parsing the time stamp based on the unix timestamp '$str': $e" ) );
        }
    }
    elsif( $str =~ /^([\+\-]?\d+)([YyMDdhms])?$/ )
    {
        my( $num, $unit ) = ( $1, $2 );
        $unit = 's' if( !length( $unit ) );
        # $self->message( 3, "Value is actually a variable time." );
        my $interval =
        {
            's' => 1,
            'm' => 60,
            'h' => 3600,
            'D' => 86400,
            'd' => 86400,
            'M' => 86400 * 30,
            'Y' => 86400 * 365,
            'y' => 86400 * 365,
        };
        my $offset = ( $interval->{ $unit } || 1 ) * int( $num );
        my $ts = time() + $offset;
        try
        {
            my $dt = DateTime->from_epoch( epoch => $ts, time_zone => 'local' );
            return( $dt );
        }
        catch( $e )
        {
            return( $self->error( "An error occurred while trying to create a DateTime object with the relative timestamp '$str' that translated into the unix time stamp '$ts': $e" ) );
        }
    }
    elsif( lc( $str ) eq 'now' )
    {
        # $self->message( 3, "\tValue is actually the special keyword: '$str'" );
        my $dt = DateTime->now( time_zone => 'local' );
        return( $dt );
    }
    else
    {
        return( '' );
    }
    
    try
    {
        # $self->message( 3, "Parsing the string '$str' with the format '$opt->{pattern}'." );
        my $strp = DateTime::Format::Strptime->new( %$opt );
        my $dt = $strp->parse_datetime( $str );
        my $strp2 = $formatter->new( %$fmt );
        # To enable the date string to be stringified to its original format
        $dt->set_formatter( $strp2 ) if( $dt );
        return( $dt );
    }
    catch( $e )
    {
        return( $self->error( "Error creating a DateTime object with the timestamp '$str': $e" ) );
    }
}

sub _lvalue : lvalue
{
    my $self = shift( @_ );
    my $def  = shift( @_ );
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $arg = [ $arg ];
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = [@_];
            $has_arg++;
        }
    }
    
    if( $has_arg && CORE::exists( $def->{set} ) && ref( $def->{set} ) eq 'CODE' )
    {
        my $code = $def->{set};
        my $rv = $code->( $self, $arg );
        if( !defined( $rv ) )
        {
            if( $has_arg eq 'assign' )
            {
                my $dummy = '';
                return( $dummy );
            }
            return if( want( 'LVALUE' ) );
            rreturn;
        }
        return( $rv ) if( want( 'LVALUE' ) );
        rreturn( $rv );
    }
    else
    {
        if( CORE::exists( $def->{get} ) && ref( $def->{get} ) eq 'CODE' )
        {
            if( want( 'LVALUE' ) )
            {
                return( $def->{get}->( $self ) );
            }
            rreturn( $def->{get}->( $self ) );
        }
        # lnoreturn;
        return;
    }
}

sub _refaddr { return( Scalar::Util::refaddr( $_[1] ) ); }

sub _set_get
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
        $data->{ $field } = $val;
    }
    if( wantarray() )
    {
        if( ref( $data->{ $field } ) eq 'ARRAY' )
        {
            return( @{ $data->{ $field } } );
        }
        elsif( ref( $data->{ $field } ) eq 'HASH' )
        {
            return( %{ $data->{ $field } } );
        }
        else
        {
            return( ( $data->{ $field } ) );
        }
    }
    else
    {
        return( $data->{ $field } );
    }
}

sub _set_get_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
        $data->{ $field } = $val;
    }
    return( $data->{ $field } );
}

sub _set_get_array_as_object : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg++;
    }
    else
    {
        if( @_ )
        {
            $arg = ( @_ == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
            $has_arg++;
        }
    }
    
    my $callbacks = {};
    if( ref( $field ) eq 'HASH' )
    {
        my $def = $field;
        $field = $def->{field} if( CORE::exists( $def->{field} ) && defined( $def->{field} ) && CORE::length( $def->{field} ) );
        $callbacks = $def->{callbacks} if( CORE::exists( $def->{callbacks} ) && ref( $def->{callbacks} ) eq 'HASH' );
    }
    
    if( $has_arg )
    {
        my $val = ( ( Scalar::Util::blessed( $arg ) && $arg->isa( 'ARRAY' ) ) || ref( $arg ) eq 'ARRAY' ) ? $arg : [ $arg ];
        # $self->message( 4, "Processing value provided '$val' (", overload::StrVal( $val ), ")." );
        my $o = $data->{ $field };
        ## Some existing data, like maybe default value
        if( $o )
        {
            if( !$self->_is_object( $o ) )
            {
                my $tmp = $o;
                $o = Module::Generic::Array->new( $tmp );
            }
            $o->set( $val );
        }
        else
        {
            $o = Module::Generic::Array->new( $val );
            $data->{ $field } = $o;
            if( scalar( keys( %$callbacks ) ) && CORE::exists( $callbacks->{add} ) )
            {
                my $coderef = ref( $callbacks->{add} ) eq 'CODE' ? $callbacks->{add} : $self->can( $callbacks->{add} );
                if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
                {
                    $coderef->( $self );
                }
            }
        }
    }
    if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
    {
        my $o = Module::Generic::Array->new( ( defined( $data->{ $field } ) && CORE::length( $data->{ $field } ) ) ? $data->{ $field } : [] );
        $data->{ $field } = $o;
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
}

sub _set_get_boolean : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg++;
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    
    my $callbacks = {};
    if( ref( $field ) eq 'HASH' )
    {
        my $def = $field;
        $field = $def->{field} if( CORE::exists( $def->{field} ) && defined( $def->{field} ) && CORE::length( $def->{field} ) );
        $callbacks = $def->{callbacks} if( CORE::exists( $def->{callbacks} ) && ref( $def->{callbacks} ) eq 'HASH' );
    }
    
    if( $has_arg )
    {
        my $val = $arg;
        $val //= '';
        no warnings 'uninitialized';
        if( Scalar::Util::blessed( $val ) && 
            ( $val->isa( 'JSON::PP::Boolean' ) || $val->isa( 'Module::Generic::Boolean' ) ) )
        {
            $data->{ $field } = $val;
        }
        elsif( Scalar::Util::reftype( $val ) eq 'SCALAR' )
        {
            $data->{ $field } = defined( $$val )
                ? $$val
                    ? Module::Generic::Boolean->true
                    : Module::Generic::Boolean->false
                : Module::Generic::Boolean->false;
        }
        elsif( lc( $val ) eq 'true' || lc( $val ) eq 'false' )
        {
            $data->{ $field } = lc( $val ) eq 'true' ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
        }
        else
        {
            $data->{ $field } = $val
                ? Module::Generic::Boolean->true
                : Module::Generic::Boolean->false;
        }
        
        if( scalar( keys( %$callbacks ) ) && CORE::exists( $callbacks->{add} ) )
        {
            my $coderef = ref( $callbacks->{add} ) eq 'CODE' ? $callbacks->{add} : $self->can( $callbacks->{add} );
            if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
            {
                $coderef->( $self );
            }
        }
    }
    # If there is a value set, like a default value and it is not an object or at least not one we recognise
    # We transform it into a Module::Generic::Boolean object
    if( CORE::length( $data->{ $field } ) && 
        ( 
            !Scalar::Util::blessed( $data->{ $field } ) || 
            ( 
                Scalar::Util::blessed( $data->{ $field } ) && 
                !$data->{ $field }->isa( 'Module::Generic::Boolean' ) && 
                !$data->{ $field }->isa( 'JSON::PP::Boolean' ) 
            ) 
        ) )
    {
        my $val = $data->{ $field };
        $data->{ $field } = $val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
}

sub __create_class
{
    my $self  = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field was provided to create a dynamic class." ) );
    my $def   = shift( @_ );
    my $class;
    if( $def->{_class} )
    {
        $class = $def->{_class};
    }
    else
    {
        my $new_class = $field;
        $new_class =~ tr/-/_/;
        $new_class =~ s/\_{2,}/_/g;
        $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
        $class = ( ref( $self ) || $self ) . "\::${new_class}";
    }
    unless( Class::Load::is_class_loaded( $class ) )
    {
        my $type2func =
        {
        array       => '_set_get_array',
        array_as_object => '_set_get_array_as_object',
        boolean     => '_set_get_boolean',
        class       => '_set_get_class',
        class_array => '_set_get_class_array',
        datetime    => '_set_get_datetime',
        decimal     => '_set_get_number',
        hash        => '_set_get_hash',
        hash_as_object => '_set_get_hash_as_mix_object',
        integer     => '_set_get_number',
        number      => '_set_get_number',
        object      => '_set_get_object',
        object_array => '_set_get_object_array',
        object_array_object => '_set_get_object_array_object',
        scalar      => '_set_get_scalar',
        scalar_as_object => '_set_get_scalar_as_object',
        scalar_or_object => '_set_get_scalar_or_object',
        uri         => '_set_get_uri',
        };
        # Alias
        $type2func->{string} = $type2func->{scalar};
        
        my $perl = <<EOT;
package $class;
BEGIN
{
    use strict;
    use Module::Generic;
    use parent -norequire, qw( Module::Generic );
};

EOT
        my $call_sub = ( split( /::/, ( caller(1) )[3] ) )[-1];
        my $call_frame = $call_sub eq '_set_get_class' ? 1 : 0;
        my( $pack, $file, $line ) = caller( $call_frame );
        my $code_lines = [];
        foreach my $f ( sort( keys( %$def ) ) )
        {
            # $self->message( 3, "Checking field '$f'." );
            my $info = $def->{ $f };
            ## Convenience
            $info->{class} = $info->{package} if( $info->{package} && !length( $info->{class} ) );
            my $type = lc( $info->{type} );
            if( !CORE::exists( $type2func->{ $type } ) )
            {
                warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, but the type provided \"$type\" is unknown to us, so we are skipping this field \"$f\" in the creation of our virtual class.\n" );
                next;
            }
            my $func = $type2func->{ $type };
            if( $type eq 'object' || 
                $type eq 'scalar_or_object' || 
                $type eq 'object_array_object' ||
                $type eq 'object_array' )
            {
                if( !$info->{class} && !$info->{package} )
                {
                    warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, and class \"$class\" field \"$f\" is to require an object, but no object class name was provided. Use the \"class\" or \"package\" property parameter. So we are skipping this field \"$f\" in the creation of our virtual class.\n" );
                    next;
                }
                my $this_class = $info->{class} || $info->{package};
                CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', '$this_class', \@_ ) ); }" );
            }
            elsif( $type eq 'class' || $type eq 'class_array' )
            {
                my $this_def = $info->{definition};
                if( !CORE::exists( $info->{definition} ) )
                {
                    warn( "Warning only: No dynamic class fields definition was provided for this field \"$f\". Skipping this field.\n" );
                    next;
                }
                elsif( ref( $this_def ) ne 'HASH' )
                {
                    warn( "Warning only: I was expecting a fields definition hash reference for dynamic class field \"$f\", but instead got '$this_def'. Skipping this field.\n" );
                    next;
                }
                # my $d = Data::Dumper->new( [ $this_def ] );
                # $d->Indent( 0 );
                # $d->Purity( 1 );
                # $d->Pad( '' );
                # $d->Terse( 1 );
                # $d->Sortkeys( 1 );
                # my $hash_str = $d->Dump;
                my $hash_str = Data::Dump::dump( $this_def );
                CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', $hash_str, \@_ ) ); }" );
            }
            else
            {
                CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', \@_ ) ); }" );
            }
        }
        $perl .= join( "\n\n", @$code_lines );

        $perl .= <<EOT;


1;

EOT
        my $rc = eval( $perl );
        die( "Unable to dynamically create module $class: $@" ) if( $@ );
    }
    return( $class );
}

# $self->_set_get_class( 'my_field', {
# _class => 'My::Class',
# field1 => { type => 'datetime' },
# field2 => { type => 'scalar' },
# field3 => { type => 'boolean' },
# field4 => { type => 'object', class => 'Some::Class' },
# }, @_ );
sub _set_get_class
{
    my $self  = shift( @_ );
    # $self->message( 3, "Got here with arguments: '", join( "', '", @_ ), "'." );
    my $field = shift( @_ );
    my $def   = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( ref( $def ) ne 'HASH' )
    {
        CORE::warn( "Warning only: dynamic class field definition hash ($def) for field \"$field\" is not a hash reference.\n" );
        return;
    }
    
    my $class = $self->__create_class( $field, $def ) || die( "Failed to create the dynamic class for field \"$field\".\n" );
    
    if( @_ )
    {
        my $hash = shift( @_ );
        # my $o = $class->new( $hash );
        $self->messagef( 3, "Instantiating object of class '$class' with hash '$hash' containing %d elements: '%s'", scalar( keys( %$hash ) ), join( "', '", map{ "$_ => $hash->{$_}" } sort( keys( %$hash ) ) ) );
        ## $self->messagef( 3, "Instantiating object of class '$class' with hash '$hash' containing %d elements: '%s'", scalar( keys( %$hash ) ), $self->dumper( $hash ) );
        my $o = $self->__instantiate_object( $field, $class, $hash );
        # $self->message( 3, "\tReturning object for field '$field' and class '$class': '$o'." );
        $data->{ $field } = $o;
    }
    
    if( !$data->{ $field } )
    {
        my $o = $self->__instantiate_object( $field, $class );
        $data->{ $field } = $o;
    }
    return( $data->{ $field } );
}

sub _set_get_class_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $def   = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( ref( $def ) ne 'HASH' )
    {
        CORE::warn( "Warning only: dynamic class field definition hash ($def) for field \"$field\" is not a hash reference.\n" );
        return;
    }
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    my $class = $self->__create_class( $field, $def ) || die( "Failed to create the dynamic class for field \"$field\".\n" );
    ## return( $self->_set_get_object_array( $field, $class, @_ ) );
    if( @_ )
    {
        my $ref = shift( @_ );
        ## $self->message( 7, "Populating data for class '$class' using '$ref' (containing ", scalar( @$ref ), " elements): ", sub{ $self->dump( $ref ) } );
        return( $self->error( "I was expecting an array ref, but instead got '$ref'. _is_array returned: '", $self->_is_array( $ref ), "'" ) ) if( !$self->_is_array( $ref ) );
        my $arr = [];
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( ref( $ref->[$i] ) ne 'HASH' )
            {
                return( $self->error( "Array offset $i is not a hash reference. I was expecting a hash reference to instantiate an object of class $class." ) );
            }
            my $o = $self->__instantiate_object( $field, $class, $ref->[$i] ) || return( $self->pass_error );
            ## If an error occurred, we report it to the caller and do not add it, since even if we did add it, it would be undef, because no object would have been created.
            ## And the caller needs to know there has been some errors
            CORE::push( @$arr, $o );
        }
        $data->{ $field } = $arr;
    }
    return( $data->{ $field } );
}

sub _set_get_code : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    
    if( $has_arg )
    {
        my $v = $arg;
        if( ref( $v ) ne 'CODE' )
        {
            my $error = "Value provided for \"$field\" ($v) is not an anonymous subroutine (code). You can pass as argument something like \$self->curry::my_sub or something like sub { some_code_here; }";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        $data->{ $field } = $v;
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
}

sub _set_get_datetime : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    
    my $process = sub
    {
        my $time = shift( @_ );
        # $self->message( 3, "Processing time stamp $time possibly of ref (", ref( $time ), ")." );
        my $now;
        if( Scalar::Util::blessed( $time ) )
        {
            return( $self->error( "Object provided as value for $field, but this is not a DateTime or a Module::Generic::DateTime object" ) ) if( !$time->isa( 'DateTime' ) && !$time->isa( 'Module::Generic::DateTime' ) );
            $data->{ $field } = $time;
            return( $data->{ $field } );
        }
        elsif( $time =~ /^\d+$/ && $time !~ /^\d{1,10}$/ )
        {
            return( $self->error( "DateTime value ($time) provided for field $field does not look like a unix timestamp" ) );
        }
        # Parsed successfully and transformed into a DateTime object
        elsif( $now = $self->_parse_timestamp( $time ) )
        {
            # Found a parsed datetime value
            # $data->{ $field } = $now;
            # return( $now );
            # $self->message( 4, "Got a timestamp '$now' from _parse_timestamp" );
        }
        
        # $self->message( 3, "Creating a DateTime object out of $time\n" );
        try
        {
            unless( Scalar::Util::blessed( $now ) && ( $now->isa( 'DateTime' ) || $now->isa( 'Module::Generic::DateTime' ) ) )
            {
                require DateTime;
                $now = DateTime->from_epoch(
                    epoch => $time,
                    time_zone => 'local',
                );
            }
            # We only set a default formatter if one was not set already
            unless( $now->formatter )
            {
                require DateTime::Format::Strptime;
                my $strp = DateTime::Format::Strptime->new(
                    pattern => '%s',
                    locale => 'en_GB',
                    time_zone => 'local',
                );
                $now->set_formatter( $strp );
            }
            ## $self->message( 3, "Setting the DateTime object '$now' (", overload::StrVal( $now ), ") for field \"$field\"." );
            return( $now );
        }
        catch( $e )
        {
            $self->message( "Error while trying to get the DateTime object for field $field with value '$time': $e" );
        }
    };
    
    if( $has_arg )
    {
        my $time = $arg;
        if( !defined( $time ) )
        {
            $data->{ $field } = $time;
            return( $data->{ $field } ) if( want( 'LVALUE' ) );
            rreturn( $data->{ $field } );
        }
        my $now = $process->( $time ) || do
        {
            if( $has_arg eq 'assign' )
            {
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->pass_error ) if( want( 'LVALUE' ) );
            rreturn( $self->pass_error );
        };
        $data->{ $field } = $now;
    }
    # So that a call to this field will not trigger an error: "Can't call method "xxx" on an undefined value"
    if( !$data->{ $field } && want( 'OBJECT' ) )
    {
        my $null = Module::Generic::Null->new( '', { debug => $this->{debug}, has_error => 1 });
        rreturn( $null );
    }
    elsif( defined( $data->{ $field } ) && length( $data->{ $field } ) && !$self->_is_a( $data->{ $field }, 'DateTime' ) )
    {
        my $now = $process->( $data->{ $field } ) || do
        {
            if( $has_arg eq 'assign' )
            {
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->pass_error ) if( want( 'LVALUE' ) );
            rreturn( $self->pass_error );
        };
        $data->{ $field } = $now;
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
}

sub _set_get_file : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    no overloading;
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    if( $has_arg )
    {
        my $val = Module::Generic::File->new( $arg ) || do
        {
            my $error = Module::Generic::File->error;
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        };
        $data->{ $field } = $val;
        my $dummy = 'dummy';
        # We need to return something else than our object, or by virtue of perl's way of working
        # we would return our object as coded below, and that object will be assigned the
        # very value we will have passed in assignment !
        return( $dummy ) if( $has_arg eq 'assign' );
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
    # To make perl happy
    return;
}

sub _set_get_hash : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    # $self->message( 3, "Called for field '$field' with data '", join( "', '", @_ ), "'." );
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        if( @_ )
        {
            if( ref( $_[0] ) eq 'HASH' )
            {
                $arg = shift( @_ );
            }
            elsif( !( @_ % 2 ) )
            {
                $arg = { @_ };
            }
            else
            {
                $arg = shift( @_ );
            }
            $has_arg++;
        }
    }
    if( $has_arg )
    {
        if( ref( $arg ) ne 'HASH' )
        {
            my $error = "Method $field takes only a hash or reference to a hash, but value provided ($arg) is not supported";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        # $self->message( 3, "Setting value $val for field $field" );
        $data->{ $field } = $arg;
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
}

sub _set_get_hash_as_mix_object : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        if( @_ )
        {
            if( ref( $_[0] ) eq 'HASH' )
            {
                $arg = shift( @_ );
            }
            elsif( ref( $_[0] ) eq 'Module::Generic::Hash' )
            {
                $arg = $_[0]->clone;
            }
            elsif( ( @_ % 2 ) )
            {
                $arg = { @_ };
            }
            else
            {
                $arg = shift( @_ );
                my $error = "Method $field takes only a hash or reference to a hash, but value provided ($arg) is not supported";
                if( $has_arg eq 'assign' )
                {
                    $self->error( $error );
                    my $dummy = 'dummy';
                    return( $dummy );
                }
                return( $self->error( $error ) ) if( want( 'LVALUE' ) );
                rreturn( $self->error( $error ) );
            }
            $has_arg++;
        }
    }
    # $self->message( 3, "Called for field '$field' with data '", join( "', '", @_ ), "'." );
    if( $has_arg )
    {
        my $val = $arg;
        if( ref( $val ) eq 'Module::Generic::Hash' )
        {
            $data->{ $field } = $val;
            return( $data->{ $field } ) if( want( 'LVALUE' ) );
            rreturn( $data->{ $field } );
        }
        else
        {
            # $self->message( 3, "Setting value $val for field $field" );
            $data->{ $field } = Module::Generic::Hash->new( $val );
        }
    }
    if( $data->{ $field } && !$self->_is_object( $data->{ $field } ) )
    {
        my $o = Module::Generic::Hash->new( $data->{ $field } );
        $data->{ $field } = $o;
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
}

# There is no lvalue here on purpose
sub _set_get_hash_as_object
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    # $self->message( 3, "Called with args: ", $self->dumper( \@_ ) );
    my $field = shift( @_ ) || return( $self->error( "No field provided for _set_get_hash_as_object" ) );
    my $class;
    @_ = () if( @_ == 1 && !defined( $_[0] ) );
    no strict 'refs';
    if( @_ )
    {
        ## No class was provided
        # if( ref( $_[0] ) eq 'HASH' )
        if( Scalar::Util::reftype( $_[0] ) eq 'HASH' )
        {
            my $new_class = $field;
            $new_class =~ tr/-/_/;
            $new_class =~ s/\_{2,}/_/g;
            $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
            $class = ( ref( $self ) || $self ) . "\::${new_class}";
        }
        elsif( ref( $_[0] ) )
        {
            return( $self->error( "Class name in _set_get_hash_as_object helper method cannot be a reference. Received: \"", overload::StrVal( $_[0] ), "\"." ) );
        }
        else
        {
            $class = shift( @_ );
        }
    }
    else
    {
        my $new_class = $field;
        $new_class =~ tr/-/_/;
        $new_class =~ s/\_{2,}/_/g;
        $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
        $class = ( ref( $self ) || $self ) . "\::${new_class}";
    }
    # my $class = shift( @_ );
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    unless( Class::Load::is_class_loaded( $class ) )
    {
        my $perl = <<EOT;
package $class;
BEGIN
{
    use strict;
    use warnings::register;
    use Module::Generic;
    use parent -norequire, qw( Module::Generic::Dynamic );
};

1;

EOT
        my $rc = eval( $perl );
        die( "Unable to dynamically create module \"$class\" for field \"$field\" based on our own class \"", ( ref( $self ) || $self ), "\": $@" ) if( $@ );
    }
    
    if( @_ )
    {
        my $hash = shift( @_ );
        # $self->message( 4, "Initiating class '$class' with hash ", sub{ $self->dumper( $hash )} );
        my $o = $self->__instantiate_object( $field, $class, $hash );
        $data->{ $field } = $o;
    }
    
    if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
    {
        my $o = $data->{ $field } = $self->__instantiate_object( $field, $class, $data->{ $field } );
    }
    return( $data->{ $field } );
}

sub _set_get_ip : lvalue
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    if( $has_arg )
    {
        my $v = $arg;
        # If the user wants to remove it
        if( !defined( $v ) )
        {
            $data->{ $field } = $v;
        }
        # If the user provided a string, let's check it
        elsif( length( $v ) && !$self->_is_ip( $v ) )
        {
            my $error = "Value provided ($v) is not a valid ip address.";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        $data->{ $field } = $self->new_scalar( $v );
    }
    my $v = $self->_is_a( $data->{ $field }, 'Module::Generic::Scalar' )
        ? $data->{ $field }
        : $self->new_scalar( $data->{ $field } );
    if( !$v->defined )
    {
        if( Want::want( 'OBJECT' ) )
        {
            # We might have need to specify, because I found a race condition where
            # even though the context is object, once in Null, the context became 'code'
            return( Module::Generic::Null->new( wants => 'OBJECT' ) );
        }
        else
        {
            return if( want( 'LVALUE' ) );
            rreturn;
        }
    }
    else
    {
        return( $v ) if( want( 'LVALUE' ) );
        rreturn( $v );
    }
}

sub _set_get_lvalue : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        my( $a ) = want( 'ASSIGN' );
        $data->{ $field } = $a;
        # lnoreturn;
        return( $data->{ $field } );
    }
    else
    {
        if( @_ )
        {
            @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
            $data->{ $field } = shift( @_ );
        }
        return( $data->{ $field } ) if( want( 'LVALUE' ) );
        rreturn( $data->{ $field } );
    }
    return;
}

sub _set_get_number : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    no overload;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    
    my $callbacks = {};
    if( ref( $field ) eq 'HASH' )
    {
        my $def = $field;
        $field = $def->{field} if( CORE::exists( $def->{field} ) && defined( $def->{field} ) && CORE::length( $def->{field} ) );
        $callbacks = $def->{callbacks} if( CORE::exists( $def->{callbacks} ) && ref( $def->{callbacks} ) eq 'HASH' );
    }
    
    my $do_callback = sub
    {
        if( scalar( keys( %$callbacks ) ) && CORE::exists( $callbacks->{add} ) )
        {
            my $coderef = ref( $callbacks->{add} ) eq 'CODE' ? $callbacks->{add} : $self->can( $callbacks->{add} );
            if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
            {
                $coderef->( $self );
            }
        }
    };
    
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        my( $a ) = want( 'ASSIGN' );
        $data->{ $field } = Module::Generic::Number->new( $a );
        $do_callback->();
        return( $data->{ $field } );
    }
    else
    {
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        if( @_ )
        {
            $data->{ $field } = Module::Generic::Number->new( shift( @_ ) );
            $do_callback->();
        }
        
        if( CORE::length( $data->{ $field } ) && !ref( $data->{ $field } ) )
        {
            $data->{ $field } = Module::Generic::Number->new( $data->{ $field } );
        }
        elsif( !CORE::length( $data->{ $field } ) && want( 'OBJECT' ) )
        {
            my $null = Module::Generic::Null->new( '', { debug => $this->{debug} });
            rreturn( $null );
        }
        return( $data->{ $field } ) if( want( 'LVALUE' ) );
        rreturn( $data->{ $field } );
    }
    return;
}

sub _set_get_number_as_object : lvalue { return( shift->_set_get_number( @_ ) ); }

sub _set_get_number_or_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        if( ref( $_[0] ) eq 'HASH' || Scalar::Util::blessed( $_[0] ) )
        {
            return( $self->_set_get_object( $field, $class, @_ ) );
        }
        else
        {
            return( $self->_set_get_number( $field, @_ ) );
        }
    }
    return( $data->{ $field } );
}

sub _set_get_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    no overloading;
    # $self->message( 3, "Called for field '$field' and class '$class'." );
    if( @_ )
    {
        if( scalar( @_ ) == 1 )
        {
            # $self->message( 3, "Object provided is '", overload::StrVal( $_[0] ), "' for class '$class'. Is it a legit object? ", ( $self->_is_a( $_[0], $class ) ? 'yes' : 'no' ) );
            # User removed the value by passing it an undefined value
            if( !defined( $_[0] ) )
            {
                $data->{ $field } = undef();
            }
            # User pass an object
            elsif( Scalar::Util::blessed( $_[0] ) )
            {
                my $o = shift( @_ );
                # $self->message( 3, "Object provided (", ref( $o ), ") for $field is not a valid $class object" ) if( !$o->isa( "$class" ) );
                return( $self->error( "Object provided (", ref( $o ), ") for $field is not a valid $class object" ) ) if( !$o->isa( "$class" ) );
                # XXX Bad idea:
                # $o->debug( $this->{debug} ) if( $o->can( 'debug' ) );
                $data->{ $field } = $o;
            }
            else
            {
                # $self->message( 3, "Got here, instantiating object for field '$field' and class '$class'." );
                my $o = $self->_instantiate_object( $field, $class, @_ ) || do
                {
                    if( $class->can( 'error' ) )
                    {
                        return( $self->pass_error( $class->error ) );
                    }
                    else
                    {
                        return( $self->error( "Unable to instantiate an object for class \"$class\" and values provided: '", join( "', '", @_ ), "'." ) );
                    }
                };
                # $self->message( 3, "Setting field $field value to $o" );
                $data->{ $field } = $o;
            }
        }
        else
        {
            # $self->message( 3, "Argument provideds ('", join( "', '", map( overload::StrVal( $_ ), @_ ) ), "'), instantiating object for field '$field' and class '$class' called from file ", [caller(1)]->[1], " at line ", [caller(1)]->[2], "." );
            # There is already an object, so we pass any argument to the existing object
            if( $data->{ $field } && $self->_is_a( $data->{ $field }, $class ) )
            {
                warn( "Re-setting existing object '", overload::StrVal( $data->{ $field } ), "' for field '$field' and class '$class'\n" );
            }
            
            my $o = $self->_instantiate_object( $field, $class, @_ ) || do
            {
                if( $class->can( 'error' ) )
                {
                    return( $self->pass_error( $class->error ) );
                }
                else
                {
                    return( $self->error( "Unable to instantiate an object for class \"$class\" with no value provided." ) );
                }
            };
            # $self->message( 3, "Setting field $field value to $o" );
            $data->{ $field } = $o;
        }
    }
    # If nothing has been set for this field, ie no object, but we are called in chain
    # we set a dummy object that will just call itself to avoid perl complaining about undefined value calling a method
    if( !$data->{ $field } && want( 'OBJECT' ) )
    {
        my $o = $self->_instantiate_object( $field, $class, @_ ) || do
        {
            if( $class->can( 'error' ) )
            {
                return( $self->pass_error( $class->error ) );
            }
            else
            {
                return( $self->error( "Unable to instantiate an object for class \"$class\" with no value provided." ) );
            }
        };
        $data->{ $field } = $o;
        return( $o );
    }
    # $self->message( 3, "Returning for field '$field' value: ", $self->{ $field } );
    return( $data->{ $field } );
}

sub _set_get_object_lvalue : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    no overloading;
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    if( $has_arg )
    {
        if( !defined( $arg ) )
        {
            $data->{ $field } = undef();
        }
        # User pass an object
        elsif( Scalar::Util::blessed( $arg ) )
        {
            if( !$arg->isa( "$class" ) )
            {
                my $error = "Object provided (" . ref( $arg ) . ") for $field is not a valid $class object";
                if( $has_arg eq 'assign' )
                {
                    $self->error( $error );
                    my $dummy = 'dummy';
                    return( $dummy );
                }
                return( $self->error( $error ) ) if( want( 'LVALUE' ) );
                rreturn( $self->error( $error ) );
            }
            $data->{ $field } = $arg;
        }
        else
        {
            my $error = "Value provided (" . overload::StrVal( $arg ) . " is not an object.";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        my $dummy = 'dummy';
        # We need to return something else than our object, or by virtue of perl's way of working
        # we would return our object as coded below, and that object will be assigned the
        # very value we will have passed in assignment !
        return( $dummy ) if( $has_arg eq 'assign' );
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
    # To make perl happy
    return;
}

sub _set_get_object_without_init
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    no overloading;
    if( @_ )
    {
        if( scalar( @_ ) == 1 )
        {
            # User removed the value by passing it an undefined value
            if( !defined( $_[0] ) )
            {
                $data->{ $field } = undef();
            }
            # User pass an object
            elsif( Scalar::Util::blessed( $_[0] ) )
            {
                my $o = shift( @_ );
                $self->message( 4, "Object provided (", ref( $o ), ") for $field is not a valid $class object" ) if( !$o->isa( "$class" ) );
                return( $self->error( "Object provided (", ref( $o ), ") for $field is not a valid $class object" ) ) if( !$o->isa( "$class" ) );
                # XXX Bad idea:
                # $o->debug( $this->{debug} ) if( $o->can( 'debug' ) );
                $data->{ $field } = $o;
            }
            else
            {
                my $o = $self->_instantiate_object( $field, $class, @_ ) || do
                {
                    if( $class->can( 'error' ) )
                    {
                        return( $self->pass_error( $class->error ) );
                    }
                    else
                    {
                        return( $self->error( "Unable to instantiate an object for class \"$class\" and values provided: '", join( "', '", @_ ), "'." ) );
                    }
                };
                # $self->message( 3, "Setting field $field value to $o" );
                $data->{ $field } = $o;
            }
        }
        else
        {
            my $o = $self->_instantiate_object( $field, $class, @_ ) || do
            {
                if( $class->can( 'error' ) )
                {
                    return( $self->pass_error( $class->error ) );
                }
                else
                {
                    return( $self->error( "Unable to instantiate an object for class \"$class\" with no value provided." ) );
                }
            };
            # $self->message( 3, "Setting field $field value to $o" );
            $data->{ $field } = $o;
        }
    }
    ## If nothing has been set for this field, ie no object, but we are called in chain, this will fail on purpose.
    ## To avoid this, use _set_get_object
    return( $data->{ $field } );
}

sub _set_get_object_array2
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $data_to_process = shift( @_ );
        return( $self->error( "I was expecting an array ref, but instead got '$data_to_process'. _is_array returned: '", $self->_is_array( $data_to_process ), "'" ) ) if( !$self->_is_array( $data_to_process ) );
        my $arr1 = [];
        foreach my $ref ( @$data_to_process )
        {
            return( $self->error( "I was expecting an embeded array ref, but instead got '$ref'." ) ) if( ref( $ref ) ne 'ARRAY' );
            my $arr = [];
            for( my $i = 0; $i < scalar( @$ref ); $i++ )
            {
                my $o;
                if( defined( $ref->[$i] ) )
                {
                    return( $self->error( "Parameter provided for adding object of class $class is not a reference." ) ) if( !ref( $ref->[$i] ) );
                    if( Scalar::Util::blessed( $ref->[$i] ) )
                    {
                        return( $self->error( "Array offset $i contains an object from class ", $ref->[$i], ", but was expecting an object of class $class." ) ) if( !$ref->[$i]->isa( $class ) );
                        $o = $ref->[$i];
                    }
                    elsif( ref( $ref->[$i] ) eq 'HASH' )
                    {
                        #$o = $class->new( $h, $ref->[$i] );
                        $o = $self->_instantiate_object( $field, $class, $ref->[$i] );
                    }
                    else
                    {
                        $self->error( "Warning only: data provided to instaantiate object of class $class is not a hash reference" );
                    }
                }
                else
                {
                    #$o = $class->new( $h );
                    $o = $self->_instantiate_object( $field, $class );
                }
                return( $self->error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
                # $o->{ '_parent' } = $self->{ '_parent' };
                push( @$arr, $o );
            }
            push( @$arr1, $arr );
        }
        $data->{ $field } = $arr1;
    }
    return( $data->{ $field } );
}

sub _set_get_object_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    my $process = sub
    {
        my $ref = shift( @_ );
        return( $self->error( "I was expecting an array ref, but instead got '$ref'. _is_array returned: '", $self->_is_array( $ref ), "'" ) ) if( !$self->_is_array( $ref ) );
        my $arr = [];
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( defined( $ref->[$i] ) )
            {
#                 return( $self->error( "Array offset $i is not a reference. I was expecting an object of class $class or an hash reference to instantiate an object." ) ) if( !ref( $ref->[$i] ) );
                if( Scalar::Util::blessed( $ref->[$i] ) )
                {
                    return( $self->error( "Array offset $i contains an object from class ", $ref->[$i], ", but was expecting an object of class $class." ) ) if( !$ref->[$i]->isa( $class ) );
                    push( @$arr, $ref->[$i] );
                }
#                 elsif( ref( $ref->[$i] ) eq 'HASH' )
#                 {
#                     #$o = $class->new( $h, $ref->[$i] );
#                     $o = $self->_instantiate_object( $field, $class, $ref->[$i] ) || return;
#                     push( @$arr, $o );
#                 }
#                 else
#                 {
#                     $self->error( "Warning only: data provided to instantiate object of class $class is not a hash reference" );
#                 }
                else
                {
                    my $o = $self->_instantiate_object( $field, $class, $ref->[$i] ) || return( $self->pass_error );
                    push( @$arr, $o );
                }
            }
            else
            {
                return( $self->error( "Array offset $i contains an undefined value. I was expecting an object of class $class." ) );
                my $o = $self->_instantiate_object( $field, $class ) || return( $self->pass_error );
                push( @$arr, $o );
            }
        }
        return( $arr );
    };
    
    if( @_ )
    {
        $data->{ $field } = $process->( @_ );
    }
    # For example, if the object property is set at init, without using a method
    if( $data->{ $field } && ref( $data->{ $field } ) ne 'ARRAY' )
    {
        $data->{ $field } = $process->( $data->{ $field } );
    }
    return( $data->{ $field } );
}

sub _set_get_object_array_object
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field name was provided for this array of object." ) );
    my $class = shift( @_ ) || return( $self->error( "No class was provided for this array of objects." ) );
    my $this = $self->_obj2h;
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    my $process = sub
    {
        my $that = ( scalar( @_ ) == 1 && UNIVERSAL::isa( $_[0], 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
        my $ref = $self->_set_get_object_array( $field, $class, $that ) || return( $self->pass_error );
        return( Module::Generic::Array->new( $ref ) );
    };
    
    if( @_ )
    {
        $data->{ $field } = $process->( @_ );
    }
    ## Default value so that call to the caller's method like my_sub->length will not produce something like "Can't call method "length" on an undefined value"
    ## Also, this will make it possible to set default value in caller's object and we would turn it into array object.
    if( !$data->{ $field } || !$self->_is_a( $data->{ $field }, 'Module::Generic::Array' ) )
    {
        $data->{ $field } = $process->( CORE::defined( $data->{ $field } ) ? $data->{ $field } : () );
    }
    return( $data->{ $field } );
}

sub _set_get_object_variant
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    ## The class precisely depends on what we find looking ahead
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $process = sub
    {
        if( ref( $_[0] ) eq 'HASH' )
        {
            my $o = $self->_instantiate_object( $field, $class, @_ );
            return( $o );
        }
        ## An array of objects hash
        elsif( ref( $_[0] ) eq 'ARRAY' )
        {
            my $arr = shift( @_ );
            my $res = [];
            foreach my $data ( @$arr )
            {
                my $o = $self->_instantiate_object( $field, $class, $data ) || return( $self->error( "Unable to create object: ", $self->error ) );
                push( @$res, $o );
            }
            return( $res );
        }
    };
    
    if( @_ )
    {
        $data->{ $field } = $process->( @_ );
    }
    return( $data->{ $field } );
}

sub _set_get_scalar : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = ( @_ == 1 ) ? shift( @_ ) : join( '', @_ );
            $has_arg++;
        }
    }

    if( $has_arg )
    {
        my $val = $arg;
        # Just in case, we force stringification
        # $val = "$val" if( defined( $val ) );
        if( ref( $val ) eq 'HASH' || ref( $val ) eq 'ARRAY' )
        {
            my $error = "Method $field takes only a scalar, but value provided ($val) is a reference";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        $data->{ $field } = $val;
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
}

sub _set_get_scalar_as_object : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    
    my $callbacks = {};
    if( ref( $field ) eq 'HASH' )
    {
        my $def = $field;
        $field = $def->{field};
        $callbacks = $def->{callbacks};
    }

    if( $has_arg )
    {
        my $val;
        # $self->message( 4, "Processing value provided '$arg' (", overload::StrVal( $arg ), ")." );
        if( ref( $arg ) eq 'SCALAR' || 
            UNIVERSAL::isa( $arg, 'SCALAR' ) )
        {
            $val = $$arg;
        }
        elsif( ref( $arg ) && 
               $self->_is_object( $arg ) && 
               overload::Overloaded( $arg ) && 
               overload::Method( $arg, '""' ) )
        {
            # $self->message( 3, "Value provided is an overloaded object with stringification capability. Changing it into a plain string => '$arg'." );
            $val = "$arg";
        }
        elsif( ref( $arg ) )
        {
            my $error = "I was expecting a string or a scalar reference, but instead got '$arg'";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        else
        {
            $val = $arg;
        }
        
        my $o = $data->{ $field };
        # $self->message( 3, "Value to use is '$val' and current object is '", ref( $o ), "'." );
        if( ref( $o ) )
        {
            $o->set( $val );
        }
        else
        {
            $data->{ $field } = Module::Generic::Scalar->new( $val );
            if( scalar( keys( %$callbacks ) ) && CORE::exists( $callbacks->{add} ) )
            {
                my $coderef = ref( $callbacks->{add} ) eq 'CODE' ? $callbacks->{add} : $self->can( $callbacks->{add} );
                if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
                {
                    $coderef->( $self );
                }
            }
        }
        # $self->message( 3, "Object now is: '", ref( $data->{ $field } ), "'." );
    }
    
    # $self->message( 3, "Checking if object '", ref( $data->{ $field } ), "' is set. Is it an object? ", $self->_is_object( $data->{ $field } ) ? 'yes' : 'no', " and its stringified value is '", $data->{ $field }, "'." );
    if( !$self->_is_object( $data->{ $field } ) || ( $self->_is_object( $data->{ $field } ) && ref( $data->{ $field } ) ne ref( $self ) ) )
    {
        # $self->message( 3, "No object is set yet, initiating one." );
        $data->{ $field } = Module::Generic::Scalar->new( $data->{ $field } );
    }
    my $v = $data->{ $field };
    if( !$v->defined )
    {
        if( Want::want( 'OBJECT' ) )
        {
            # We might have need to specify, because I found a race condition where
            # even though the context is object, once in Null, the context became 'code'
            return( Module::Generic::Null->new( wants => 'OBJECT' ) );
        }
        else
        {
            return if( want( 'LVALUE' ) );
            rreturn;
        }
    }
    else
    {
        return( $v ) if( want( 'LVALUE' ) );
        rreturn( $v );
    }
}

sub _set_get_scalar_or_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        if( ref( $_[0] ) eq 'HASH' || Scalar::Util::blessed( $_[0] ) )
        {
            return( $self->_set_get_object( $field, $class, @_ ) );
        }
        else
        {
            return( $self->_set_get_scalar( $field, @_ ) );
        }
    }
    if( !$data->{ $field } && want( 'OBJECT' ) )
    {
        # $self->message( 3, "Called in a chain for field $field and class $class, but no object is set, reverting to dummy object." );
        # $self->messagef( 3, "Expecting void? '%s'. Want scalar? '%s'. Want hash? '%s', wantref: '%s'", want('VOID'), want('SCALAR'), Want::want('HASH'), Want::wantref() );
        my $null = Module::Generic::Null->new({ debug => $this->{debug}, has_error => 1 });
        rreturn( $null );
    }
    return( $data->{ $field } );
}

sub _set_get_uri : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }

    if( $has_arg )
    {
        try
        {
            require URI if( !$self->_is_class_loaded( 'URI' ) );
        }
        catch( $e )
        {
            my $error = "Error trying to load module URI: $e";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        
        my $str = $arg;
        if( Scalar::Util::blessed( $str ) && $str->isa( 'URI' ) )
        {
            $data->{ $field } = $str;
        }
        elsif( defined( $str ) && ( $str =~ /^[a-zA-Z]+:\/{2}/ || $str =~ /^urn\:[a-z]+\:/ || $str =~ /^[a-z]+\:/ ) )
        {
            $data->{ $field } = URI->new( $str );
            warn( "URI subclass is missing to handle this specific URI '$str'\n" ) if( !$data->{ $field }->has_recognized_scheme );
        }
        ## Is it an absolute path?
        elsif( substr( $str, 0, 1 ) eq '/' )
        {
            $data->{ $field } = URI->new( $str );
        }
        elsif( defined( $str ) )
        {
            try
            {
                my $u = URI->new( $str );
                $data->{ $field } = $u;
            }
            catch( $e )
            {
                my $error = "URI value provided '$str' does not look like an URI, so I do not know what to do with it: $e";
                if( $has_arg eq 'assign' )
                {
                    $self->error( $error );
                    my $dummy = 'dummy';
                    return( $dummy );
                }
                return( $self->error( $error ) ) if( want( 'LVALUE' ) );
                rreturn( $self->error( $error ) );
            }
        }
        else
        {
            $data->{ $field } = undef();
        }
    }
    # Data was pre-set or directly set but is not an URI object, so we convert it now
    if( $data->{ $field } && !$self->_is_a( $data->{ $field }, 'URI' ) )
    {
        # Force stringification if this is an overloaded value
        $data->{ $field } = URI->new( $data->{ $field } . '' );
    }
    return( $data->{ $field } ) if( want( 'LVALUE' ) );
    rreturn( $data->{ $field } );
}

# Universally Unique Identifier
sub _set_get_uuid : lvalue
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $has_arg = 0;
    my $arg;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }
    if( $has_arg )
    {
        my $v = $arg;
        # If the user wants to remove it
        if( !defined( $v ) )
        {
            $data->{ $field } = $v;
        }
        # If the user provided a string, let's check it
        elsif( length( $v ) && !$self->_is_uuid( $v ) )
        {
            my $error = "Value provided is not a valid uuid.";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( want( 'LVALUE' ) );
            rreturn( $self->error( $error ) );
        }
        $data->{ $field } = $self->new_scalar( $v );
    }
    my $v = $self->_is_a( $data->{ $field }, 'Module::Generic::Scalar' )
        ? $data->{ $field }
        : $self->new_scalar( $data->{ $field } );
    if( !$v->defined )
    {
        if( Want::want( 'OBJECT' ) )
        {
            # We might have need to specify, because I found a race condition where
            # even though the context is object, once in Null, the context became 'code'
            return( Module::Generic::Null->new( wants => 'OBJECT' ) ) if( want( 'LVALUE' ) );
            rreturn( Module::Generic::Null->new( wants => 'OBJECT' ) );
        }
        else
        {
            return if( want( 'LVALUE' ) );
            rreturn;
        }
    }
    else
    {
        return( $v ) if( want( 'LVALUE' ) );
        rreturn( $v );
    }
}

sub _to_array_object
{
    my $self = shift( @_ );
    my $data = scalar( @_ ) == 1 && $self->_is_array( $_[0] ) 
        ? shift( @_ ) 
        : ( scalar( @_ ) == 0 || ( scalar( @_ ) == 1 && !defined( $_[0] ) ) )
            ? [] 
            : [ @_ ];
    return( $self->new_array( $data ) );
}

sub _warnings_is_enabled
{
#     return( warnings::enabled( $_[0] ) );
    return( 0 ) if( !defined( $warnings::Bits{ ref( $_[0] ) || $_[0] } ) );
    return( warnings::enabled( ref( $_[0] ) || $_[0] ) );
}

sub __dbh
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    if( !$this->{__dbh} )
    {
        return( '' ) if( !${ "$class\::DB_DSN" } );
        require DBI;
        ## Connecting to database
        my $db_opt = {};
        $db_opt->{RaiseError} = ${ "$class\::DB_RAISE_ERROR" } if( length( ${ "$class\::DB_RAISE_ERROR" } ) );
        $db_opt->{AutoCommit} = ${ "$class\::DB_AUTO_COMMIT" } if( length( ${ "$class\::DB_AUTO_COMMIT" } ) );
        $db_opt->{PrintError} = ${ "$class\::DB_PRINT_ERROR" } if( length( ${ "$class\::DB_PRINT_ERROR" } ) );
        $db_opt->{ShowErrorStatement} = ${ "$class\::DB_SHOW_ERROR_STATEMENT" } if( length( ${ "$class\::DB_SHOW_ERROR_STATEMENT" } ) );
        $db_opt->{client_encoding} = ${ "$class\::DB_CLIENT_ENCODING" } if( length( ${ "$class\::DB_CLIENT_ENCODING" } ) );
        my $dbh = DBI->connect_cached( ${ "$class\::DB_DSN" } ) ||
        die( "Unable to connect to sql database with dsn '", ${ "$class\::DB_DSN" }, "'\n" );
        $dbh->{pg_server_prepare} = 1 if( ${ "$class\::DB_SERVER_PREPARE" } );
        $this->{__dbh} = $dbh;
    }
    return( $this->{__dbh} );
}

sub DEBUG
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
    my $this = $self->_obj2h;
    no strict 'refs';
    return( ${ $pkg . '::DEBUG' } );
}

sub VERBOSE
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
    my $this = $self->_obj2h;
    no strict 'refs';
    return( ${ $pkg . '::VERBOSE' } );
}

AUTOLOAD
{
    my $self;
    $self = shift( @_ ) if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic' ) );
    my( $class, $meth );
    $class = ref( $self ) || $self;
    ## Leave this commented out as we need it a little bit lower
    my( $pkg, $file, $line ) = caller();
    my $sub = ( caller( 1 ) )[ 3 ];
    no overloading;
    no strict 'refs';
    if( $sub eq 'Module::Generic::AUTOLOAD' )
    {
        my $mesg = "Module::Generic::AUTOLOAD (called at line '$line') is looping for autoloadable method '$AUTOLOAD' and args '" . join( "', '", @_ ) . "'.";
        if( $MOD_PERL )
        {
            try
            {
                my $r = Apache2::RequestUtil->request;
                $r->log->debug( $mesg );
            }
            catch( $e )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $e\n" );
            }
        }
        else
        {
            print( $stderr $mesg, "\n" );
        }
        exit( 0 );
    }
    $meth = $AUTOLOAD;
    if( CORE::index( $meth, '::' ) != -1 )
    {
        my $idx = rindex( $meth, '::' );
        $class = substr( $meth, 0, $idx );
        $meth  = substr( $meth, $idx + 2 );
    }
    
    if( $self && $self->can( 'autoload' ) )
    {
        if( my $code = $self->autoload( $meth ) )
        {
            return( $code->( $self ) ) if( $code );
        }
    }
    
    $meth = lc( $meth );
    my $this;
    $this = $self->_obj2h if( defined( $self ) );
    my $data;
    if( $this )
    {
        $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    }
    if( $data && CORE::exists( $data->{ $meth } ) )
    {
        if( @_ )
        {
            my $val = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
            $data->{ $meth } = $val;
        }
        if( wantarray() )
        {
            if( ref( $data->{ $meth } ) eq 'ARRAY' )
            {
                return( @{ $data->{ $meth } } );
            }
            elsif( ref( $data->{ $meth } ) eq 'HASH' )
            {
                return( %{ $data->{ $meth } } );
            }
            else
            {
                return( ( $data->{ $meth } ) );
            }
        }
        else
        {
            return( $data->{ $meth } );
        }
    }
    # Because, if it does not exist in the caller's package, 
    # calling the method will get us here infinitly,
    # since UNIVERSAL::can will somehow return true even if it does not exist
    elsif( $self && $self->can( $meth ) && defined( &{ "$class\::$meth" } ) )
    {
        return( $self->$meth( @_ ) );
    }
    elsif( defined( &$meth ) )
    {
        no strict 'refs';
        *$meth = \&$meth;
        return( &$meth( $self, @_ ) ) if( $self );
        return( &$meth( @_ ) );
    }
    else
    {
        my $sub = $AUTOLOAD;
        my( $pkg, $func ) = ( $sub =~ /(.*)::([^:]+)$/ );
        my $mesg = "Module::Generic::AUTOLOAD(): Searching for routine '$func' from package '$pkg'.";
        if( $MOD_PERL )
        {
            try
            {
                my $r = Apache2::RequestUtil->request;
                $r->log->debug( $mesg );
            }
            catch( $e )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $e\n" );
            }
        }
        else
        {
            print( STDERR $mesg . "\n" ) if( $DEBUG );
        }
        $pkg =~ s/::/\//g;
        my $filename;
        if( defined( $filename = $INC{ "$pkg.pm" } ) )
        {
            $filename =~ s/^(.*)$pkg\.pm\z/$1auto\/$pkg\/$func.al/s;
            if( -r( $filename ) )
            {
                unless( $filename =~ m|^/|s )
                {
                    $filename = "./$filename";
                }
            }
            else
            {
                $filename = undef();
            }
        }
        if( !defined( $filename ) )
        {
            $filename = "auto/$sub.al";
            $filename =~ s/::/\//g;
        }
        my $save = $@;
        eval
        {
            local $SIG{ '__DIE__' }  = sub{ };
            local $SIG{ '__WARN__' } = sub{ };
            require $filename;
        };
        if( $@ )
        {
            if( substr( $sub, -9 ) eq '::DESTROY' )
            {
                *$sub = sub {};
            }
            else
            {
                # The load might just have failed because the filename was too
                # long for some old SVR3 systems which treat long names as errors.
                # If we can succesfully truncate a long name then it's worth a go.
                # There is a slight risk that we could pick up the wrong file here
                # but autosplit should have warned about that when splitting.
                if( $filename =~ s/(\w{12,})\.al$/substr( $1, 0, 11 ) . ".al"/e )
                {
                    eval
                    {
                        local $SIG{ '__DIE__' }  = sub{ };
                        local $SIG{ '__WARN__' } = sub{ };
                        require $filename
                    };
                }
                if( $@ )
                {
                    ## Look up in our caller's @ISA to see if there is any package that has this special
                    ## EXTRA_AUTOLOAD() sub routine
                    my $sub_ref = '';
                    die( "EXTRA_AUTOLOAD: ", join( "', '", @_ ), "\n" ) if( $func eq 'EXTRA_AUTOLOAD' );
                    if( $self && $func ne 'EXTRA_AUTOLOAD' && ( $sub_ref = $self->will( 'EXTRA_AUTOLOAD' ) ) )
                    {
                        return( $sub_ref->( $self, $AUTOLOAD, @_ ) );
                    }
                    else
                    {
                        my $keys = CORE::join( ',', keys( %$data ) );
                        my $msg  = "Method $func() is not defined in class $class and not autoloadable in package $pkg in file $file at line $line.\n";
                        $msg    .= "There are actually the following fields in the object '$self': '$keys'\n";
                        die( $msg );
                    }
                }
            }
        }
        $@ = $save;
        if( $DEBUG )
        {
            my $mesg = "unshifting '$self' to args for sub '$sub'.";
            if( $MOD_PERL )
            {
                try
                {
                    my $r = Apache2::RequestUtil->request;
                    $r->log->debug( $mesg );
                }
                catch( $e )
                {
                    print( STDERR "Error trying to get the global Apache2::ApacheRec: $e\n" );
                }
            }
            else
            {
                print( $stderr "$mesg\n" );
            }
        }
        unshift( @_, $self ) if( $self );
        goto &$sub;
    }
};

DESTROY
{
    # Do nothing
};

1;

# XXX POD
__END__

=encoding utf8

=head1 NAME

Module::Generic - Generic Module to inherit from

=head1 SYNOPSIS

    package MyModule;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
    };

    sub init
    {
        my $self = shift( @_ );
        # Requires parameters provided to have their equivalent method
        $self->{_init_strict_use_sub} = 1;
        # Smartly accepts key-value pairs as list or hash reference
        $self->SUPER::init( @_ );
        # This won't be affected by parameters provided during instantiation
        $self->{_private_param} = 'some value';
        return( $self );
    }
    
    sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }
    sub address { return( shift->_set_get_object( 'address', 'My::Address', @_ ) ); }
    sub age { return( shift->_set_get_number( 'age', @_ ) ); }
    sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }
    sub uuid { return( shift->_set_get_uuid( 'uuid', @_ ) ); }
    sub remote_addr { return( shift->_set_get_ip( 'remote_addr', @_ ) ); }
    sub discount
    {
        return( shift->_set_get_class_array( 'discount',
        {
        amount      => { type => 'number' },
        discount    => { type => 'object', class => 'My::Discount' },
        }, @_ ) );
    }
    sub settings 
    {
        return( shift->_set_get_class( 'settings',
        {
        # Will create a Module::Generic::Array array object of objects of class MY::Item
        items => { type => 'object_array_object', class => 'My::Item' },
        notify => { type => 'boolean' },
        resumes_at => { type => 'datetime' },
        timeout => { type => 'integer' },
        customer => {
                definition => {
                    billing_address => { package => "My::Address", type => "object" },
                    email => { type => "scalar" },
                    name => { type => "scalar" },
                    shipping_address => { package => "My::Address", type => "object" },
                },
                type => "class",
            },
        }, @_ ) );
    }

=head1 VERSION

    v0.21.3

=head1 DESCRIPTION

L<Module::Generic> as its name says it all, is a generic module to inherit from.
It is designed to provide a useful framework and speed up coding and debugging.
It contains standard and support methods that may be superseded by your module.

It also contains an AUTOLOAD transforming any hash object key into dynamic methods and also recognize the dynamic routine a la AutoLoader. The reason is that while C<AutoLoader> provides the user with a convenient AUTOLOAD, I wanted a way to also keep the functionnality of L<Module::Generic> AUTOLOAD that were not included in C<AutoLoader>. So the only solution was a merger.

=head1 METHODS

=head2 import

B<import>() is used for the AutoLoader mechanism and hence is not a public method.
It is just mentionned here for info only.

=head2 new

B<new> will create a new object for the package, pass any argument it might receive to the special standard routine B<init> that I<must> exist. 
Then it returns what returns L</"init">.

To protect object inner content from sneaking by third party, you can declare the package global variable I<OBJECT_PERMS> and give it a Unix permission, but only 1 digit.
It will then work just like Unix permission. That is, if permission is 7, then only the module who generated the object may read/write content of the object. However, if you set 5, the, other may look into the content of the object, but may not modify it.
7, as you would have guessed, allow other to modify the content of an object.
If I<OBJECT_PERMS> is not defined, permissions system is not activated and hence anyone may access and possibly modify the content of your object.

If the module runs under mod_perl, and assuming you have set the variable C<GlobalRequest> in your Apache configuration, it is recognised and a clean up registered routine is declared to Apache to clean up the content of the object.

This methods calls L</init>, which does all the work of setting object properties and calling methods to that effect.

=head2 as_hash

This will recursively transform the object into an hash suitable to be encoded in json.

It does this by calling each method of the object and build an hash reference with the method name as the key and the method returned value as the value.

If the method returned value is an object, it will call its L</"as_hash"> method if it supports it.

It returns the hash reference built

=head2 clear

Alias for L</clear_error>

=head2 clear_error

Clear all error from the object and from the available global variable C<$ERROR>.

This is a handy method to use at the beginning of other methods of calling package, so the end user may do a test such as:

    $obj->some_method( 'some arguments' );
    die( $obj->error() ) if( $obj->error() );

    ## some_method() would then contain something like:
    sub some_method
    {
        my $self = shift( @_ );
        ## Clear all previous error, so we may set our own later one eventually
        $self->clear_error();
        ## ...
    }

This way the end user may be sure that if C<$obj->error()> returns true something wrong has occured.

=head2 clone

Clone the current object if it is of type hash or array reference. It returns an error if the type is neither.

It returns the clone.

=head2 colour_close

The marker to be used to set the closing of a command line colour sequence.

Defaults to ">"

=head2 colour_closest

Provided with a colour, this returns the closest standard one supported by terminal.

A colour provided can be a colour name, or a 9 digits rgb value or an hexadecimal value

=head2 colour_format

Provided with a hash reference of parameters, this will return a string properly formatted to display colours on the command line.

Parameters are:

=over 4

=item I<text> or I<message>

This is the text to be formatted in colour.

=item I<bgcolour> or I<bgcolor> or I<bg_colour> or I<bg_color>

The value for the background colour.

=item I<colour> or I<color> or I<fg_colour> or I<fg_color> or I<fgcolour> or I<fgcolor>

The value for the foreground colour.

Valid value can be a colour name, an rgb value like C<255255255>, a rgb annotation like C<rgb(255, 255, 255)> or a rgba annotation like C<rgba(255,255,255,0.5)>

A colour can be preceded by the words C<light> or C<bright> to provide slightly lighter colour where supported.

Similarly, if an rgba value is provided, and the opacity is less than 1, this is equivalent to using the keyword C<light>

It returns the text properly formatted to be outputted in a terminal.

=item I<style>

The possible values are: I<bold>, I<italic>, I<underline>, I<blink>, I<reverse>, I<conceal>, I<strike>

=back

=head2 colour_open

The marker to be used to set the opening of a command line colour sequence.

Defaults to "<"

=head2 colour_parse

Provided with a string, this will parse the string for colour formatting. Formatting can be encapsulated in another formatting, and can be expressed in 2 different ways. For example:

    $self->colour_parse( "And {style => 'i|b', color => green}what about{/} {style => 'blink', color => yellow}me{/} ?" );

would result with the words C<what about> in italic, bold and green colour and the word C<me> in yellow colour blinking (if supported).

Another way is:

    $self->colour_parse( "And {bold light red on white}what about{/} {underline yellow}me too{/} ?" );

would return a string with the words C<what about> in light red bold text on a white background, and the words C<me too> in yellow with an underline.

    $self->colour_parse( "Hello {bold red on white}everyone! This is {underline rgb(0,0,255)}embedded{/}{/} text..." );

would return a string with the words C<everyone! This is> in bold red characters on white background and the word C<embedded> in underline blue color

The idea for this syntax, not the code, is taken from L<Term::ANSIColor>

=head2 colour_to_rgb

Convert a human colour keyword like C<red>, C<green> into a rgb equivalent.

=head2 coloured

Provided with a colouring preference expressed as the first argument as string, and followed by 1 or more arguments that are concatenated to form the text string to format. For example:

    print( $o->coloured( 'bold white on red', "Hello it's me!\n" ) );

A colour can be expressed as a rgb, such as :

    print( $o->coloured( 'underline rgb( 0, 0, 255 ) on white', "Hello everyone!" ), "\n" );

rgb can also be rgba with the last decimal, normally an opacity used here to set light color if the value is less than 1. For example :

    print( $o->coloured( 'underline rgba(255, 0, 0, 0.5)', "Hello everyone!" ), "\n" );

=head2 debug

Set or get the debug level. This takes and return an integer.

Based on the value, L</"message"> will or will not print out messages. For example :

    $self->debug( 2 );
    $self->message( 2, "Debugging message here." );

Since C<2> used in L</"message"> is equal to the debug value, the debugging message is printed.

If the debug value is switched to 1, the message will be silenced.

=head2 dump

Provided with some data, this will return a string representation of the data formatted by L<Data::Printer>

=head2 dump_hex

Returns an hexadecimal dump of the data provided.

This requires the module L<Devel::Hexdump> and will return C<undef> and set an L</error> if not found.

=head2 dump_print

Provided with a file to write to and some data, this will format the string representation of the data using L<Data::Printer> and save it to the given file.

=head2 dumper

Provided with some data, and optionally an hash reference of parameters as last argument, this will create a string representation of the data using L<Data::Dumper> and return it.

This sets L<Data::Dumper> to be terse, to indent, to use C<qq> and optionally to not exceed a maximum I<depth> if it is provided in the argument hash reference.

=head2 dumpto

Alias for L</dumpto_dumper>

=head2 printer

Same as L</"dumper">, but using L<Data::Printer> to format the data.

=head2 dumpto_printer

Same as L</"dump_print"> above that is an alias of this method.

=head2 dumpto_dumper

Same as L</"dumpto_printer"> above, but using L<Data::Dumper>

=head2 errno

Sets or gets an error number.

=head2 error

Provided with a list of strings or an hash reference of parameters and this will set the current error issuing a L<Module::Generic::Exception> object, call L<perlfunc/warn>, or C<$r->warn> under Apache2 modperl, and returns undef() or an empty list in list context:

    if( $some_condition )
    {
        return( $self->error( "Some error." ) );
    }

Note that you do not have to worry about a trailing line feed sequence.
L</error> takes care of it.

The script calling your module could write calls to your module methods like this:

    my $cust_name = $object->customer->name ||
        die( "Got an error in file ", $object->error->file, " at line ", $object->error->line, ": ", $object->error->trace, "\n" );
    # or simply:
    my $cust_name = $object->customer->name ||
        die( "Got an error: ", $object->error, "\n" );

If you want to use an hash reference instead, you can pass the following parameters. Any other parameters will be passed to the exception class.

=over 4

=item I<class>

The package name or class to use to instantiate the error object. By default, it will use L<Module::Generic::Exception> class or the one specified with the object property C<_exception_class>

    $self->do_something_bad ||
        return( $self->error({
            code => 500,
            message => "Oopsie",
            class => "My::NoWayException",
        }) );
    my $exception = $self->error; # an My::NoWayException object

Note, however, that if the class specified cannot be loaded for some reason, L<Module::Generic/error> will die since this would be an error within another error.

=item I<message>

The error message.

=back

Note also that by calling L</error> it will not clear the current error. For that
you have to call L</clear_error> explicitly.

Also, when an error is set, the global variable I<ERROR> in the inheriting package is set accordingly. This is
especially usefull, when your initiating an object and that an error occured. At that
time, since the object could not be initiated, the end user can not use the object to 
get the error message, and then can get it using the global module variable 
I<ERROR>, for example:

    my $obj = Some::Package->new ||
    die( $Some::Package::ERROR, "\n" );

If the caller has disabled warnings using the pragma C<no warnings>, L</error> will 
respect it and not call B<warn>. Calling B<warn> can also be silenced if the object has
a property I<quiet> set to true.

The error message can be split in multiple argument. L</error> will concatenate each argument to form a complete string. An argument can even be a reference to a sub routine and will get called to get the resulting string, unless the object property I<_msg_no_exec_sub> is set to false. This can switched off with the method L</"noexec">

If perl runs under Apache2 modperl, and an error handler is set with L</error_handler>, this will call the error handler with the error string.

If an Apache2 modperl log handler has been set, this will also be called to log the error.

If the object property I<fatal> is set to true, this will call die instead of L<perlfunc/"warn">.

Last, but not least since L</error> returns undef in scalar context or an empty list in list context, if the method that triggered the error is chained, it would normally generate a perl error that the following method cannot be called on an undefined value. To solve this, when an object is expected, L</error> returns a special object from module L<Module::Generic::Null> that will enable all the chained methods to be performed and return the error when requested to. For example:

    my $o = My::Package->new;
    my $total $o->get_customer(10)->products->total || die( $o->error, "\n" );

Assuming this method here C<get_customer> returns an error, the chaining will continue, but produce nothing and ultimately returns undef.

=head2 error_handler

Sets or gets a code reference that will be called to handle errors that have been triggered when calling L</error>

=head2 errors

Used by B<error>() to store the error sent to him for history.

It returns an array of all error that have occured in lsit context, and the last 
error in scalar context.

=head2 errstr

Set/get the error string, period. It does not produce any warning like B<error> would do.

=head2 fatal

Boolean. If enabled, any error will call L<perlfunc/die> instead of returning L<perlfunc/undef> and setting an L<error|Module::Generic/error>.

Defaults to false.

You can enable it in your own package by initialising it in your own C<init> method like this:

    sub init
    {
        my $self = shift( @_ );
        $self->{fatal} = 1;
        return( $self->SUPER::init( @_ ) );
    }

=head2 get

Uset to get an object data key value:

    $obj->set( 'verbose' => 1, 'debug' => 0 );
    ## ...
    my $verbose = $obj->get( 'verbose' );
    my @vals = $obj->get( qw( verbose debug ) );
    print( $out "Verbose level is $vals[ 0 ] and debug level is $vals[ 1 ]\n" );

This is no more needed, as it has been more conveniently bypassed by the AUTOLOAD
generic routine with which you may say:

    $obj->verbose( 1 );
    $obj->debug( 0 );
    ## ...
    my $verbose = $obj->verbose();

Much better, no?

=head2 init

This is the L</new> package object initializer. It is called by L</new>
and is used to set up any parameter provided in a hash like fashion:

    my $obj My::Module->new( 'verbose' => 1, 'debug' => 0 );

You may want to superseed L</init> to have it suit your needs.

L</init> needs to returns the object it received in the first place or an error if
something went wrong, such as:

    sub init
    {
        my $self = shift( @_ );
        my $dbh  = DB::Object->connect() ||
        return( $self->error( "Unable to connect to database server." ) );
        $self->{dbh} = $dbh;
        return( $self );
    }

In this example, using L</error> will set the global variable C<$ERROR> that will
contain the error, so user can say:

    my $obj = My::Module->new() || die( $My::Module::ERROR );

If the global variable I<VERBOSE>, I<DEBUG>, I<VERSION> are defined in the module,
and that they do not exist as an object key, they will be set automatically and
accordingly to those global variable.

The supported data type of the object generated by the L</"new"> method may either be
a hash reference or a glob reference. Those supported data types may very well be
extended to an array reference in a near future.

When provided with an hash reference, and when object property I<_init_strict_use_sub> is set to true, L</init> will call each method corresponding to the key name and pass it the key value and it will set an error and skip it if the corresponding method does not exist. Otherwise, it calls each corresponding method and pass it whatever value was provided and check for that method return value. If the return value is L<perlfunc/undef> and the value provided is B<not> itself C<undef>, then it issues a warning and return the L</error> that is assumed having being set by that method.

Otherwise if the object property I<_init_strict> is set to true, it will check the object property matching the hash key for the default value type and set an error and return undef if it does not match. Foe example, L</"init"> in your module could be like this:

    sub init
    {
        my $self = shift( @_ );
        $self->{_init_strict} = 1;
        $self->{products} = [];
        return( $self->SUPER::init( @_ ) );
    }

Then, if init is called like this:

    $object->init({ products => $some_string_but_not_array }) || die( $object->error, "\n" );

This would cause your script to die, because C<products> value is a string and not an array reference.

Otherwise, if none of those special object properties are set, the init will create an object property matching the key of the hash and set its value accordingly. For example :

    sub init
    {
        my $self = shift( @_ );
        return( $self->SUPER::init( @_ ) );
    }

Then, if init is called like this:

    $object->init( products => $array_ref, first_name => 'John', last_name => 'Doe' });

The object would then contain the properties I<products>, I<first_name> and I<last_name> and can be accessed as methods, such as :

    my $fname = $object->first_name;

You can also alter the way L</init> process the parameters received using the following properties you can set in your own C<init> method, for example:

    sub init
    {
        my $self = shift( @_ );
        # Set the order in which the parameters are processed, because some methods may rely on other methods' value
        $self->{_init_params_order} [qw( method1 method2 )];
        # Enable strict sub, which means the corresponding method must exist for the parameter provided
        $self->{_init_strict_use_sub} = 1;
        # Set the class name of the exception to use in error()
        # Here My::Package::Exception should inherit from Module::Generic::Exception or some other Exception package
        $self->{_exception_class} = 'My::Package::Exception';
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        return( $self );
    }

You can also specify a default exception class that will be used by L</error> to create exception object, by setting the object property C<_exception_class>:

    sub init
    {
        my $self = shift( @_ );
        $self->{name} = 'default_name';
        # For any key-value pairs to be matched by a corresponding method
        $self->{_init_strict_use_sub} = 1;
        $self->{_exception_class} = 'My::Exception';
        return( $self->SUPER::init( @_ ) );
    }

=head2 log_handler

Provided a reference to a sub routine or an anonymous sub routine, this will set the handler that is called by L</"message">

It returns the current value set.

=head2 message

B<message>() is used to display verbose/debug output. It will display something to the extend that either I<verbose> or I<debug> are toggled on.

If so, all debugging message will be prepended by C< E<35>E<35> > by default or the prefix string specified with the I<prefix> option, to highlight the fact that this is a debugging message.

Addionally, if a number is provided as first argument to B<message>(), it will be treated as the minimum required level of debugness. So, if the current debug state level is not equal or superior to the one provided as first argument, the message will not be displayed.

For example:

    ## Set debugness to 3
    $obj->debug( 3 );
    ## This message will not be printed
    $obj->message( 4, "Some detailed debugging stuff that we might not want." );
    ## This will be displayed
    $obj->message( 2, "Some more common message we want the user to see." );

Now, why debug is used and not verbose level? Well, because mostly, the verbose level needs only to be true, that is equal to 1 to be efficient. You do not really need to have a verbose level greater than 1. However, the debug level usually may have various level.

Also, the text provided can be separated by comma, and even be a code reference, such as:

    $self->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

If the object has a property I<_msg_no_exec_sub> set to true, then a code reference will not be called and instead be added to the string as is. This can be done simply like this:

    $self->noexec->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

L</message> also takes an optional hash reference as the last parameter with the following recognised options:

=over 4

=item I<caller_info>

This is a boolean value, which is true by default.

When true, this will prepend the debug message with information about the caller of L</message>

=item I<level>

An integer. Debugging level.

=item I<message>

The text of the debugging message. This is optional since this can be provided as first or consecutive arguments like in a list as demonstrated in the example above. This allows you to do something like this:

    $self->message( 2, { message => "Some debug message here", prefix => ">>" });

or

    $self->message( { message => "Some debug message here", prefix => ">>", level => 2 });

=item I<no_encoding>

Boolean value. If true and when the debugging is set to be printed to a file, this will not set the binmode to C<utf-8>

=item I<prefix>

By default this is set to C<E<35>E<35>>. This value is used as the prefix used in debugging output.

=item I<type>

Type of debugging

=back

=head2 message_check

This is called by L</"message">

Provided with a list of arguments, this method will check if the first argument is an integer and find out if a debug message should be printed out or not. It returns the list of arguments as an array reference.

=head2 message_color

Alias for L</message_colour>

=head2 message_colour

This is the same as L</"message">, except this will check for colour formatting, which
L</"message"> does not do. For example:

    $self->message_colour( 3, "And {bold light white on red}what about{/} {underline green}me again{/} ?" );

L</"message_colour"> can also be called as B<message_color>

See also L</"colour_format"> and L</"colour_parse">

=head2 message_frame

Return the optional hash reference of parameters, if any, that can be provided as the last argument to L</message>

=head2 messagef

This works like L<perlfunc/"sprintf">, so provided with a format and a list of arguments, this print out the message. For example :

    $self->messagef( 1, "Customer name is %s", $cust->name );

Where 1 is the debug level set with L</"debug">

=head2 messagef_colour

This method is same as L</message_colour> and L<messagef> combined.

It enables to pass sprintf-like parameters while enabling colours.

=head2 message_log

This is called from L</"message">.

Provided with a message to log, this will check if L</"message_log_io"> returns a valid file handler, presumably to log file, and if so print the message to it.

If no file handle is set, this returns undef, other it returns the value from C<$io->print>

=head2 message_log_io

Set or get the message log file handle. If set, L</"message_log"> will use it to print messages received from L</"message">

If no argument is provided bu your module has a global variable C<LOG_DEBUG> set to true and global variable C<DEB_LOG> set presumably to the file path of a log file, then this attempts to open in write mode the log file.

It returns the current log file handle, if any.

=head2 new_array

Instantiate a new L<Module::Generic::Array> object. If any arguments are provided, it will pass it to L<Module::Generic::Array/new> and return the object.

=head2 new_file

Instantiate a new L<Module::Generic::File> object. If any arguments are provided, it will pass it to L<Module::Generic::File/new> and return the object.

=head2 new_hash

Instantiate a new L<Module::Generic::Hash> object. If any arguments are provided, it will pass it to L<Module::Generic::Hash/new> and return the object.

=head2 new_null

Returns a null value based on the expectations of the caller and thus without breaking the caller's call flow.

If the caller wants an hash reference, it returns an empty hash reference.

If the caller wants an array reference, it returns an empty array reference.

If the caller wants a code reference, it returns an anonymous subroutine that returns C<undef> or an empty list.

If the caller is calling another method right after, this means this is an object context and L</new_null> will instantiate a new L<Module::Generic::Null> object. If any arguments were provided to L</new_null>, they will be passed along to L<Module::Generic::Null/new> and the new object will be returned.

In any other context, C<undef> is returned or an empty list.

Without using L</new_null>, if you return simply undef, like:

    my $val = $object->return_false->[0];
    
    sub return_false{ return }

The above would trigger an error that the value returned by C<return_false> is not an array reference.
Instead of checking on the recipient end what kind of returned value was returned, the caller only need to check if it is defined or not, no matter the context in which it is called.

For example:

    my $this = My::Object->new;
    my $val  = $this->call1;
    # return undef)
    
    # object context
    $val = $this->call1->call_again;
    # $val is undefined
    
    # hash reference context
    $val = $this->call1->fake->{name};
    # $val is undefined
    
    # array reference context
    $val = $this->call1->fake->[0];
    # $val is undefined

    # code reference context
    $val = $this->call1->fake->();
    # $val is undefined

    # scalar reference context
    $val = ${$this->call1->fake};
    # $val is undefined

    # simple scalar
    $val = $this->call1->fake;
    # $val is undefined

    package My::Object;
    use parent qw( Module::Generic );

    sub call1
    {
        return( shift->call2 );
    }

    sub call2 { return( shift->new_null ); }

    sub call_again
    {
        my $self = shift( @_ );
        print( "Got here in call_again\n" );
        return( $self );
    }

This technique is also used by L</error> to set an error object and return undef but still allow chaining beyond the error. See L</error> and L<Module::Generic::Exception> for more information.

=head2 new_number

Instantiate a new L<Module::Generic::Number> object. If any arguments are provided, it will pass it to L<Module::Generic::Number/new> and return the object.

=head2 new_scalar

Instantiate a new L<Module::Generic::Scalar> object. If any arguments are provided, it will pass it to L<Module::Generic::Scalar/new> and return the object.

=head2 new_tempdir

Returns a new temporary directory by calling L<Module::Generic::File/tempdir>

=head2 new_tempfile

Returns a new temporary directory by calling L<Module::Generic::File/tempfile>

=head2 noexec

Sets the module property I<_msg_no_exec_sub> to true, so that any call to L</"message"> whose arguments include a reference to a sub routine, will not try to execute the code. For example, imagine you have a sub routine such as:

    sub hello
    {
        return( "Hello !" );
    }

And in your code, you write:

    $self->message( 2, "Someone said: ", \&hello );

If I<_msg_no_exec_sub> is set to false (by default), then the above would print out the following message:

    Someone said Hello !

But if I<_msg_no_exec_sub> is set to true, then the same would rather produce the following :

    Someone said CODE(0x7f9103801700)

=head2 pass_error

Provided with an error, typically a L<Module::Generic::Exception> object, but it could be anything as long as it is an object, hopefully an exception object, this will set the error value to the error provided, and without issuing any new warning nor creating a new L<Module::Generic::Exception> object.

It makes it possible to pass the error along so the caller can retrieve it later. This is typically used by a method calling another one in another module that produced an error. For example :

    sub getCustomerInfo
    {
        my $self = shift( @_ );
        # Maybe a LWP::UserAgent sub class?
        my $client = $self->lwp_client_object;
        my $res = $client->get( $remote_api_endpoint ) ||
            return( $self->pass_error( $client->error ) );
    }

Then :

    my $client_info = $object->getCustomerInfo || die( $object->error, "\n" );

Which would return the http client error that has been passed along

=head2 quiet

Set or get the object property I<quiet> to true or false. If this is true, no warning will be issued when L</"error"> is called.

=head2 save

Provided with some data and a file path, or alternatively an hash reference of options with the properties I<data>, I<encoding> and I<file>, this will write to the given file the provided I<data> using the encoding I<encoding>.

This is designed to simplify the tedious task of write to files.

If it cannot open the file in write mode, or cannot print to it, this will set an error and return undef. Otherwise this returns the size of the file in bytes.

=head2 set

B<set>() sets object inner data type and takes arguments in a hash like fashion:

    $obj->set( 'verbose' => 1, 'debug' => 0 );

=head2 subclasses

Provided with a I<CLASS> value, this method try to guess all the existing sub classes of the provided I<CLASS>.

If I<CLASS> is not provided, the class into which was blessed the calling object will
be used instead.

It returns an array of subclasses in list context and a reference to an array of those
subclasses in scalar context.

If an error occured, undef is returned and an error is set accordingly. The latter can
be retrieved using the B<error> method.

=head2 true

Returns a C<true> variable from L<Module::Generic::Boolean>

=head2 false

Returns a C<false> variable from L<Module::Generic::Boolean>

=head2 verbose

Set or get the verbosity level with an integer.

=head2 will

This will try to find out if an object supports a given method call and returns the code reference to it or undef if none is found.

=head2 AUTOLOAD

The special B<AUTOLOAD>() routine is called by perl when no matching routine was found
in the module.

B<AUTOLOAD>() will then try hard to process the request.
For example, let's assue we have a routine B<foo>.

It will first, check if an equivalent entry of the routine name that was called exist in
the hash reference of the object. If there is and that more than one argument were
passed to this non existing routine, those arguments will be stored as a reference to an
array as a value of the key in the object. Otherwise the single argument will simply be stored
as the value of the key of the object.

Then, if called in list context, it will return a array if the value of the key entry was an array
reference, or a hash list if the value of the key entry was a hash reference, or finally the value
of the key entry.

If this non existing routine that was called is actually defined, the routine will be redeclared and
the arguments passed to it.

If this fails too, it will try to check for an AutoLoadable file in C<auto/PackageName/routine_name.al>

If the filed exists, it will be required, the routine name linked into the package name space and finally
called with the arguments.

If the require process failed or if the AutoLoadable routine file did not exist, B<AUTOLOAD>() will
check if the special routine B<EXTRA_AUTOLOAD>() exists in the module. If it does, it will call it and pass
it the arguments. Otherwise, B<AUTOLOAD> will die with a message explaining that the called routine did 
not exist and could not be found in the current class.

=head1 SUPPORT METHODS

Those methods are designed to be called from the package inheriting from L<Module::Generic> to perform various function and speed up development.

=head2 __instantiate_object

Provided with an object property name, and a class/package name, this will attempt to load the module if it is not already loaded. It does so using L<Class::Load/"load_class">. Once loaded, it will init an object passing it the other arguments received. It returns the object instantiated upon success or undef and sets an L</"error">

This is a support method used by L</"_instantiate_object">

=head2 _instantiate_object

This does the same thing as L</"__instantiate_object"> and the purpose is for this method to be potentially superseded in your own module. In your own module, you would call L</"__instantiate_object">

=head2 _can

Provided with a value and a method name, and this will return true if the value provided is an object that L<UNIVERSAL/can> perform the method specified, or false otherwise.

This makes it more convenient to write:

    if( $self->_can( $obj, 'some_method' ) )
    {
        # ...
    }

than to write:

    if( Scalar::Util::bless( $obj ) && $obj->can( 'some_method' )
    {
        # ...
    }

=head2 _get_args_as_array

Provided with arguments and this support method will return the arguments provided as an array reference irrespective of whether they were initially provided as array reference or a simple array.

For example:

    my $array = $self->_get_args_as_array(qw( those are arguments ));
    # returns an array reference containing: 'those', 'are', 'arguments'
    my $array = $self->_get_args_as_array( [qw( those are arguments )] );
    # same result as previous example
    my $array = $self->_get_args_as_array(); # no args provided
    # returns an empty array reference

=head2 _get_args_as_hash

Provided with arguments and this support method will return the arguments provided as hash reference irrespective of whether they were initially provided as hash reference or a simple hash.

For example:

    my $ref = $self->_get_args_as_hash( first => 'John', last => 'Doe' );
    # returns hash reference { first => 'John', last => 'Doe' }
    my $ref = $self->_get_args_as_hash({ first => 'John', last => 'Doe' });
    # same result as previous example
    my $res = $self->_get_args_as_hash(); # no args provided
    # returns an empty hash reference

However, this will return empty:

    my $ref = $self->_get_args_as_hash( { age => 42, city => 'Tokyo' }, some_other => 'parameter' );

This returns an empty hash reference, because although the first parameter is an hash reference, there is more than on parameter.

=head2 _get_stack_trace

This will return a L<Devel::StackTrace> object initiated with the following options set:

=over 4

=item I<indent> 1

This will set an initial indent tab

=item I<skip_frames> 1

This is set to 1 so this very method is not included in the frames stack

=back

=head2 _is_a

Provided with an object and a package name and this will return true if the object is a blessed object from this package name (or a sub package of it), or false if not.

The value of this is to reduce the burden of having to check whether the object actually exists, i.e. is not null or undef, if it is an object and if it is from that class. This allows to do it in just one method call like this:

    if( $self->_is_a( $obj, 'My::Package' ) )
    {
        # Do something
    }

Of course, if you are sure the object is actually an object, then you can directly do:

    if( $obj->isa( 'My::Package' ) )
    {
        # Do something
    }

=head2 _is_class_loadable

Takes a module name and an optional version number and this will check if the module exist and can be loaded by looking at the C<@INC> and using L<version> to compare required version and existing version.

It returns true if the module can be loaded or false otherwise.

=head2 _is_class_loaded

Provided with a class/package name, this returns true if the module is already loaded or false otherwise.

It performs this test by checking if the module is already in C<%INC>.

=head2 _is_array

Provided with some data, this checks if the data is of type array, even if it is an object.

This uses L<Scalar::Util/"reftype"> to achieve that purpose. So for example, an object such as :

    package My::Module;

    sub new
    {
        return( bless( [] => ( ref( $_[0] ) || $_[0] ) ) );
    }

This would produce an object like :

    My::Module=ARRAY(0x7f8f3b035c20)

When checked with L</"_is_array"> this, would return true just like an ordinary array.

If you would use :

    ref( $object );

It would rather return the module package name: C<My::Module>

=head2 _is_hash

Same as L</"_is_array">, but for hash reference.

=head2 _is_integer

Returns true if the value provided is an integer, or false otherwise. A valid value includes an integer starting with C<+> or C<->

=head2 _is_ip

Returns true if the given IP has a syntax compliant with IPv4 or IPv6 including CIDR notation or not, false otherwise.

For this method to work, you need to have installed L<Regexp::Common::net>

=head2 _is_number

Returns true if the provided value looks like a number, false otherwise.

=head2 _is_object

Provided with some data, this checks if the data is an object. It uses L<Scalar::Util/"blessed"> to achieve that purpose.

=head2 _is_scalar

Provided with some data, this checks if the data is of type scalar reference, e.g. C<SCALAR(0x7fc0d3b7cea0)>, even if it is an object.

=head2 _is_uuid

Provided with a non-zero length value and this will check if it looks like a valid C<UUID>, i.e. a unique universal ID, and upon successful validation will set the value and return its representation as a L<Module::Generic::Scalar> object.

An empty string or C<undef> can be provided and will not be checked.

=head2 _load_class

    $self->_load_class( 'My::Module' ) || die( $self->error );
    $self->_load_class( 'My::Module', qw( :some_tags SOME_CONSTANTS_TO_IMPORT ) ) || die( $self->error );
    $self->_load_class(
        'My::Module',
        qw( :some_tags SOME_CONSTANTS_TO_IMPORT ),
        { version => 'v1.2.3', caller => 'Its::Me' }
    ) || die( $self->error );

Provided with a class/package name, some optional list of semantics to import, and, as the last parameter, an optional hash reference of options and this will attempt to load the module. This uses L<perlfunc/use>, no external module.

Upon success, it returns the package name loaded.

It traps any error with an eval and return L<perlfunc/undef> if an error occurred and sets an L</error> accordingly.

Possible options are:

=over 4

=item I<caller>

The package name of the caller. If this is not provided, it will default to the value provided with L<perlfunc/caller>

=item I<version>

The minimum version for this class to load. This value is passed directly to L<perlfunc/use>

=back

=head2 _lvalue

This provides a generic L<lvalue|perlsub> method that can be used both in assign context or lvalue context.

You only need to specify a setter and getter callback.

This takes an hash reference having either of the following properties:

=over 4

=item I<get>

A code reference that will be called, passing it the module object. It takes whatever value is returned and returns it to the caller.

=item I<set>

A code reference that will be called when values were provided either in assign or regular method context:

    my $now = DateTime->now;
    $o->datetime = $now;
    # or
    $o->datetime( $now );

=back

For example, in your module:

    sub datetime : lvalue { return( shift->_lvalue({
        set => sub
        {
            my( $self, $args ) = @_;
            if( $self->_is_a( $args->[0] => 'DateTime' ) )
            {
                return( $self->{datetime} = shift( @$args ) );
            }
            else
            {
                return( $self->error( "Value provided is not a datetime." ) );
            }
        },
        get => sub
        {
            my $self = shift( @_ );
            my $dt = $self->{datetime};
            return( $dt );
        }
    }, @_ ) ); }
    # ^^^^
    # Don't forget the @_ !

Be mindful that even if the setter callback returns C<undef> in case of an error, perl does not permit C<undef> to be returned from an lvalue method, and besides the return value in assign context is useless anyway:

    my $dt = $o->datetime = DateTime->now;

If you want to check if assignment worked, you should opt to make error fatal and catch exceptions, such as:

    $o->fatal(1);
    try
    {
        $o->datetime = $not_a_datetime_object;
    }
    catch( $e )
    {
        die( "You provided a non DateTime object!: $e\n" );
    }

or you can check if an error was set:

    $o->datetime = $not_a_datetime_object;
    die( "Did not work: ", $o->error ) if( $o->error );

=head2 _obj2h

This ensures the module object is an hash reference, such as when the module object is based on a file handle for example. This permits L<Module::Generic> to work no matter what is the underlying data type blessed into an object.

=head2 _parse_timestamp

Provided with a string representing a date or datetime, and this will try to parse it and return a L<DateTime> object. It will also create a L<DateTime::Format::Strptime> to preserve the original date/datetime string representation and assign it to the L<DateTime> object. So when the L<DateTime> object is stringified, it displays the same string that was originally parsed.

=head2 _set_get

Provided with an object property name and some value and this will set or get that value for that property.

However, if the value stored is an array and is called in list context, it will return the array as a list and not the array reference. Same thing for an hash reference. It will return an hash in list context. In scalar context, it returns whatever the value is, such as array reference, hash reference or string, etc.

=head2 _set_get_array

Provided with an object property name and some data and this will store the data as an array reference.

It returns the current value stored, such as an array reference notwithstanding it is called in list or scalar context.

Example :

    sub products { return( shift->_set_get_array( 'products', @_ ) ); }

=head2 _set_get_array_as_object

Provided with an object property name and some data and this will store the data as an object of L<Module::Generic::Array>

If this is called with no data set, an object is created with no data inside and returned

Example :

    # In your module
    sub products { return( shift->_set_get_array_as_object( 'products', @_ ) ); }

And using your method:

    printf( "There are %d products\n", $object->products->length );
    $object->products->push( $new_product );

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item field

The object property name

=item callbacks

An hash reference of operation type (C<add> or C<remove>) to callback subroutine name or code reference pairs.

=back

For example:

    sub children { return( shift->set_get_array_as_object({
        field => 'children',
        callbacks => 
        {
            add => '_some_add_callback',
            remove => 'som_remove_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

=head2 _set_get_boolean

Provided with an object property name and some data and this will store the data as a boolean value.

If the data provided is a L<JSON::PP::Boolean> or L<Module::Generic::Boolean> object, the data is stored as is.

If the data is a scalar reference, its referenced value is check and L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

If the data is a string with value of C<true> or C<val> L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

Otherwise the data provided is checked if it is a true value or not and L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

If no value is provided, and the object property has already been set, this performs the same checks as above and returns either a L<JSON::PP::Boolean> or a L<Module::Generic::Boolean> object.

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item field

The object property name

=item callbacks

An hash reference of operation type (C<add> or C<remove>) to callback subroutine name or code reference pairs.

=back

For example:

    sub is_valid { return( shift->set_get_boolean({
        field => 'is_valid',
        callbacks => 
        {
            add => '_some_add_callback',
            remove => 'som_remove_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

=head2 __create_class

Provided with an object property name and an hash reference representing a dictionary and this will produce a dynamically created class/module.

If a property I<_class> exists in the dictionary, it will be used as the class/package name, otherwise a name will be derived from the calling object class and the object property name. For example, in your module :

    sub products { return( 'products', shift->_set_get_class(
    {
    name        => { type => 'scalar' },
    customer    => { type => 'object', class => 'My::Customer' },
    orders      => { type => 'array_as_object' },
    active      => { type => 'boolean' },
    created     => { type => 'datetime' },
    metadata    => { type => 'hash' },
    stock       => { type => 'number' },
    url         => { type => 'uri' },
    }, @_ ) ); }

Then calling your module method B<products> such as :

    my $prod = $object->products({
        name => 'Cool product',
        customer => { first_name => 'John', last_name => 'Doe', email => 'john.doe@example.com' },
        orders => [qw( 123 987 456 654 )],
        active => 1,
        metadata => { transaction_id => 123, api_call_id => 456 },
        stock => 10,
        uri => 'https://example.com/p/20'
    });

Using the resulting object C<$prod>, we can access this dynamically created class/module such as :

    printf( <<EOT, $prod->name, $prod->orders->length, $prod->customer->last_name,, $prod->url->path )
    Product name: %s
    No of orders: %d
    Customer name: %s
    Product page path: %s
    EOT

=head2 _set_get_class

Given an object property name, a dynamic class fiels definition hash (dictionary), and optional arguments, this special method will create perl packages on the fly by calling the support method L</"__create_class">

For example, consider the following:

    #!/usr/local/bin/perl
    BEGIN
    {
        use strict;
        use Data::Dumper;
    };

    {
        my $o = MyClass->new( debug => 3 );
        $o->setup->age( 42 );
        print( "Age is: ", $o->setup->age, "\n" );
        print( "Setup object is: ", $o->setup, "\n" );
        $o->setup->billing->interval( 'month' );
        print( "Billing interval is: ", $o->setup->billing->interval, "\n" );
        print( "Billing object is: ", $o->setup->billing, "\n" );
        $o->setup->rgb( 255, 122, 100 );
        print( "rgb: ", join( ', ', @{$o->setup->rgb} ), "\n" );
        exit( 0 );
    }

    package MyClass;
    BEGIN
    {
        use strict;
        use lib './lib';
        use parent qw( Module::Generic );
    };

    sub setup 
    {
        return( shift->_set_get_class( 'setup',
        {
        name => { type => 'scalar' },
        age => { type => 'number' },
        metadata => { type => 'hash' },
        rgb => { type => 'array' },
        url => { type => 'uri' },
        online => { type => 'boolean' },
        created => { type => 'datetime' },
        billing => { type => 'class', definition =>
            {
            interval => { type => 'scalar' },
            frequency => { type => 'number' },
            nickname => { type => 'scalar' },
            }}
        }) );
    }

    1;

    __END__

This will yield:

    Age is: 42
    Setup object is: MyClass::Setup=HASH(0x7fa805abcb20)
    Billing interval is: month
    Billing object is: MyClass::Setup::Billing=HASH(0x7fa804ec3f40)
    rgb: 255, 122, 100

The advantage of this over B<_set_get_hash_as_object> is that here one controls what fields / method are supported and with which data type.

=head2 _set_get_class_array

Provided with an object property name, a dictionary to create a dynamic class with L</"__create_class"> and an array reference of hash references and this will create an array of object, each one matching a set of data provided in the array reference. So for example, imagine you had a method such as below in your module :

    sub products { return( shift->_set_get_class_array( 'products', 
    {
    name        => { type => 'scalar' },
    customer    => { type => 'object', class => 'My::Customer' },
    orders      => { type => 'array_as_object' },
    active      => { type => 'boolean' },
    created     => { type => 'datetime' },
    metadata    => { type => 'hash' },
    stock       => { type => 'number' },
    url         => { type => 'uri' },
    }, @_ ) ); }

Then your script would call this method like this :

    $object->products([
    { name => 'Cool product', customer => { first_name => 'John', last_name => 'Doe', email => 'john.doe@example.com' }, active => 1, stock => 10, created => '2020-04-12T07:10:30' },
    { name => 'Awesome tool', customer => { first_name => 'Mary', last_name => 'Donald', email => 'm.donald@example.com' }, active => 1, stock => 15, created => '2020-05-12T15:20:10' },
    ]);

And this would store an array reference containing 2 objects with the above data.

=head2 _set_get_code

Provided with an object property name and some code reference and this stores and retrieve the current value.

It returns under and set an error if the provided value is not a code reference.

=head2 _set_get_datetime

Provided with an object property name and asome date or datetime string and this will attempt to parse it and save it as a L<DateTime> object.

If the data is a 10 digits integer, this will treat it as a unix timestamp.

Parsing also recognise special word such as C<now>

The created L<DateTime> object is associated a L<DateTime::Format::Strptime> object which enables the L<DateTime> object to be stringified as a unix timestamp using local time stamp, whatever it is.

Even if there is no value set, and this method is called in chain, it returns a L<Module::Generic::Null> whose purpose is to enable chaining without doing anything meaningful. For example, assuming the property I<created> of your object is not set yet, but in your script you call it like this:

    $object->created->iso8601

Of course, the value of C<iso8601> will be empty since this is a fake method produced by L<Module::Generic::Null>. The return value of a method should always be checked.

=head2 _set_get_file

Provided with an object property name and a file and this will store the given file as a L<Module::Generic::File> object.

It returns under and set an error if the provided value is not a proper file.

Note that the files does not need to exist and it can also be a directory or a symbolic link or any other file on the system.

=head2 _set_get_hash

Provided with an object property name and an hash reference and this set the property name with this hash reference.

You can even pass it an associative array, and it will be saved as a hash reference, such as :

    $object->metadata(
        transaction_id => 123,
        customer_id => 456
    );

    my $hash = $object->metadata;

=head2 _set_get_hash_as_mix_object

Provided with an object property name, and an optional hash reference and this returns a L<Module::Generic::Hash> object, which allows to manipulate the hash just like any regular hash, but it provides on top object oriented method described in details in L<Module::Generic::Hash>.

This is different from L</_set_get_hash_as_object> below whose keys and values are accessed as dynamic methods and method arguments.

=head2 _set_get_hash_as_object

Provided with an object property name, an optional class name and an hash reference and this does the same as in L</"_set_get_hash">, except it will create a class/package dynamically with a method for each of the hash keys, so that you can call the hash keys as method.

Also it does this recursively while handling looping, in which case, it will reuse the object previously created, and also it takes care of adapting the hash key to a proper field name, so something like C<99more-options> would become C<more_options>. If the value itself is a hash, it processes it recursively transforming C<99more-options> to a proper package name C<MoreOptions> prepended by C<$class_name> provided as argument or whatever upper package was used in recursion processing.

For example in your module :

    sub metadata { return( shift->_set_get_hash_as_object( 'metadata', @_ ) ); }

Then populating the data :

    $object->metadata({
        first_name => 'John',
        last_name => 'Doe',
        email => 'john.doe@example.com',
    });

    printf( "Customer name is %s\n", $object->metadata->last_name );

=head2 _set_get_ip

This helper method takes a value and check if it is a valid IP address using L</_is_ip>. If C<undef> or zero-byte value is provided, it will merely accept it, as it can be used to reset the value by the caller.

If a value is successfully set, it returns a L<Module::Generic::Scalar> object representing the string passed.

From there you can pass the result to L<Net::IP> in your own code, assuming you have that module installed.

=head2 _set_get_lvalue

This helper method makes it very easy to implement a L<perlsub/"Lvalue subroutines"> method.

    package MyObject;
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    
    sub debug : lvalue { return( shift->_set_get_lvalue( 'debug', @_ ) ); }

And then, this method can be called either as a lvalue method:

    my $obj = MyObject->new;
    $obj->debug = 3;

But also as a regular method:

    $obj->debug( 1 );
    printf( "Debug value is %d\n", $obj->debug );

It uses L<Want> to achieve this. See also L<Sentinel>

=head2 _set_get_number

Provided with an object property name and a number, and this will create a L<Module::Generic::Number> object and return it.

As of version v0.13.0 it also works as a lvalue method. See L<perlsub>

In your module:

    package MyObject;
    use parent qw( Module::Generic );
    
    sub level : lvalue { return( shift->_set_get_number( 'level', @_ ) ); }

In the script using module C<MyObject>:

    my $obj = MyObject->new;
    $obj->level = 3; # level is now 3
    # or
    $obj->level( 4 ) # level is now 4
    print( "Level is: ", $obj->level, "\n" ); # Level is 4
    print( "Is it an odd number: ", $obj->level->is_odd ? 'yes' : 'no', "\n" );
    # Is it an od number: no
    $obj->level++; # level is now 5

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item field

The object property name

=item callbacks

An hash reference of operation type (C<add> or C<remove>) to callback subroutine name or code reference pairs.

=back

For example:

    sub length { return( shift->set_get_number({
        field => 'length',
        callbacks => 
        {
            add => '_some_add_callback',
            remove => 'som_remove_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

=head2 _set_get_number_or_object

Provided with an object property name and a number or an object and this call the value using L</"_set_get_number"> or L</"_set_get_object"> respectively

=head2 _set_get_object

Provided with an object property name, a class/package name and some data and this will initiate a new object of the given class passing it the data.

If you pass an undefined value, it will set the property as undefined, removing whatever was set before.

You can also provide an existing object of the given class. L</"_set_get_object"> will check the object provided does belong to the specified class or it will set an error and return undef.

It returns the object currently set, if any.

=head2 _set_get_object_lvalue

Same as L</_set_get_object_without_init> but with the possibility of setting the object value as an lvalue method:

    $o->my_property = $my_object;

=head2 _set_get_object_without_init

Sets or gets an object, but countrary to L</_set_get_object> this method will not try to instantiate the object.

=head2 _set_get_object_array2

Provided with an object property name, a class/package name and some array reference itself containing array references each containing hash references or objects, and this will create an array of array of objects.

=head2 _set_get_object_array

Provided with an object property name and a class/package name and similar to L</"_set_get_object_array2"> this will create an array reference of objects.

=head2 _set_get_object_array_object

Provided with an object property name, a class/package name and some data and this will create an array of object similar to L</"_set_get_object_array">, except the array produced is a L<Module::Generic::Array>

=head2 _set_get_object_variant

Provided with an object property name, a class/package name and some data, and depending whether the data provided is an hash reference or an array reference, this will either instantiate an object for the given hash reference or an array of objects with the hash references in the given array.

This means the value stored for the object property will vary between an hash or array reference.

=head2 _set_get_scalar

Provided with an object property name, and a string, possibly a number or anything really and this will set the property value accordingly. Very straightforward.

It returns the currently value stored.

=head2 _set_get_scalar_as_object

Provided with an object property name, and a string or a scalar reference and this stores it as an object of L<Module::Generic::Scalar>

If there is already an object set for this property, the value provided will be assigned to it using L<Module::Generic::Scalar/"set">

If it is called and not value is set yet, this will instantiate a L<Module::Generic::Scalar> object with no value.

So a call to this method can safely be chained to access the L<Module::Generic::Scalar> methods. For example :

    sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

Then, calling it :

    $object->name( 'John Doe' );

Getting the value :

    my $cust_name = $object->name;
    print( "Nothing set yet.\n" ) if( !$cust_name->length );

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item field

The object property name

=item callbacks

An hash reference of operation type (C<add> or C<remove>) to callback subroutine name or code reference pairs.

=back

For example:

    sub name { return( shift->set_get_scalar_as_object({
        field => 'name',
        callbacks => 
        {
            add => '_some_add_callback',
            remove => 'som_remove_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

=head2 _set_get_scalar_or_object

Provided with an object property name, and a class/package name and this stores the value as an object calling L</"_set_get_object"> if the value is an object of class I<class> or as a string calling L</"_set_get_scalar">

If no value has been set yet, this returns a L<Module::Generic::Null> object to enable chaining.

=head2 _set_get_uri

Provided with an object property name, and an uri and this creates a L<URI> object and sets the property value accordingly.

It accepts an L<URI> object, an uri or urn string, or an absolute path, i.e. a string starting with C</>.

It returns the current value, if any, so the return value could be undef, thus it cannot be chained. Maybe it should return a L<Module::Generic::Null> object ?

=head2 _set_get_uuid

Provided with an object property name, and an UUID (Universal Unique Identifier) and this stores it as an object of L<Module::Generic::Scalar>.

If an empty or undefined value is provided, it will be stored as is.

However, if there is no value and this method is called in object context, such as in chaining, this will return a special L<Module::Generic::Null> object that prevents perl error that whatever method follows was called on an undefined value.

=head2 _to_array_object

Provided with arguments or not, and this will return a L<Module::Generic::Array> object of those data.

    my $array = $self->_to_array_object( qw( Hello world ) ); # Becomes an array object of 'Hello' and 'world'
    my $array = $self->_to_array_object( [qw( Hello world )] ); # Becomes an array object of 'Hello' and 'world'

=head2 _warnings_is_enabled

Returns true of warnings are enabled, false otherwise.

=head2 __dbh

if your module has the global variables C<DB_DSN>, this will create a database handler using L<DBI>

It will also use the following global variables in your module to set the database object: C<DB_RAISE_ERROR>, C<DB_AUTO_COMMIT>, C<DB_PRINT_ERROR>, C<DB_SHOW_ERROR_STATEMENT>, C<DB_CLIENT_ENCODING>, C<DB_SERVER_PREPARE>

If C<DB_SERVER_PREPARE> is provided and true, C<pg_server_prepare> will be set to true in the database handler.

It returns the database handler object.

=head2 DEBUG

Return the value of your global variable I<DEBUG>, if any.

=head2 VERBOSE

Return the value of your global variable I<VERBOSE>, if any.

=head1 ERROR & EXCEPTION HANDLING

This module has been developed on the idea that only the main part of the application should control the flow and trigger exit. Thus, this module and all the others in this distribution do not die, but rather set and L<error|Module::Generic/error> and return undef. So you should always check for the return value.

Error triggered are transformed into an L<Module::Generic::Exception> object, or any exception class that is specified by the object property C<_exception_class>. For example:

    sub init
    {
        my $self = shift( @_ );
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        $self->{_exception_class} = 'My::Exception';
        return( $self );
    }

Those error objects can then be retrieved by calling L</error>

If, however, you wanted errors triggered to be fatal, you can set the object property C<fatal> to a true value and/or set your package global variable C<$FATAL_ERROR> to true. When L</error> is called with an error, it will L<perlfunc/die> with the error object rather than merely returning C<undef>. For example:

    package My::Module;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        our $VERSION = 'v0.1.0';
        our $FATAL_ERROR = 1;
    };

    sub init
    {
        my $self = shift( @_ );
        $self->{fatal} = 1;
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        $self->{_exception_class} = 'My::Exception';
        return( $self );
    }

To catch fatal error you can use a C<try-catch> block such as implemented by L<Nice::Try>.

Since L<perl version 5.33.7|https://perldoc.perl.org/blead/perlsyn#Try-Catch-Exception-Handling> you can use the try-catch block using an experimental feature C<use feature 'try';>, but this does not support C<catch> by exception class.

However

=head1 SEE ALSO

L<Module::Generic::Exception>, L<Module::Generic::Array>, L<Module::Generic::Scalar>, L<Module::Generic::Boolean>, L<Module::Generic::Number>, L<Module::Generic::Null>, L<Module::Generic::Dynamic> and L<Module::Generic::Tie>, L<Module::Generic::File>, L<Module::Generic::Finfo>, L<Module::Generic::SharedMem>, L<Module::Generic::Scalar::IO>

L<Number::Format>, L<Class::Load>, L<Scalar::Util>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2000-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
