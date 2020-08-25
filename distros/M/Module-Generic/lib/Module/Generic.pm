## -*- perl -*-
##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic.pm
## Version v0.13.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.local>
## Created 2019/08/24
## Modified 2020/07/17
## 
##----------------------------------------------------------------------------
package Module::Generic;
BEGIN
{
    require 5.6.0;
    use strict;
    use warnings::register;
    use Scalar::Util qw( openhandle );
    use Sub::Util ();
    use Clone ();
    use Data::Dumper;
    use Data::Dump; 
    use Devel::StackTrace;
    use Number::Format;
    use Nice::Try;
    use B;
    ## To get some context on what the caller expect. This is used in our error() method to allow chaining without breaking
    use Want;
    use Class::Load ();
    use Encode ();
    our( @ISA, @EXPORT_OK, @EXPORT, %EXPORT_TAGS, $AUTOLOAD );
    our( $VERSION, $ERROR, $SILENT_AUTOLOAD, $VERBOSE, $DEBUG, $MOD_PERL );
    our( $PARAM_CHECKER_LOAD_ERROR, $PARAM_CHECKER_LOADED, $CALLER_LEVEL );
    our( $OPTIMIZE_MESG_SUB, $COLOUR_NAME_TO_RGB );
    use Exporter ();
    @ISA         = qw( Exporter );
    @EXPORT      = qw( );
    @EXPORT_OK   = qw( subclasses );
    %EXPORT_TAGS = ();
    $VERSION     = 'v0.13.0';
    $VERBOSE     = 0;
    $DEBUG       = 0;
    $SILENT_AUTOLOAD      = 1;
    $PARAM_CHECKER_LOADED = 0;
    $CALLER_LEVEL         = 0;
    $OPTIMIZE_MESG_SUB    = 0;
    $COLOUR_NAME_TO_RGB   = {};
    # local $^W;
    no strict qw(refs);
    use constant COLOUR_OPEN => '<';
    use constant COLOUR_CLOSE => '>';
};

INIT
{
    our $true  = ${"Module::Generic::Boolean::true"};
    our $false = ${"Module::Generic::Boolean::false"};
    while( <DATA> )
    {
        chomp;
        print( "INIT: found colour data: '$_'\n" );
    }
};

{
    ## mod_perl/2.0.10
    if( exists( $ENV{ 'MOD_PERL' } )
        &&
        ( $MOD_PERL = $ENV{ 'MOD_PERL' } =~ /^mod_perl\/\d+\.[\d\.]+/ ) )
    {
        select( ( select( STDOUT ), $| = 1 )[ 0 ] );
        require Apache2::Log;
        require Apache2::ServerUtil;
        require Apache2::RequestUtil;
        require Apache2::ServerRec;
    }
    
    our $DEBUG_LOG_IO = undef();
    
    our $DB_NAME = $DATABASE;
    our $DB_HOST = $SQL_SERVER;
    our $DB_USER = $DB_LOGIN;
    our $DB_PWD  = $DB_PASSWD;
    our $DB_RAISE_ERROR = $SQL_RAISE_ERROR;
    our $DB_AUTO_COMMIT = $SQL_AUTO_COMMIT;
}

sub import
{
    my $self = shift( @_ );
    my( $pkg, $file, $line ) = caller();
    local $Exporter::ExportLevel = 1;
    ## local $Exporter::Verbose = $VERBOSE;
    Exporter::import( $self, @_ );
    
    ##print( STDERR "Module::Generic::import(): called from package '$pkg' in file '$file' at line '$line'.\n" ) if( $DEBUG );
    ( my $dir = $pkg ) =~ s/::/\//g;
    my $path  = $INC{ $dir . '.pm' };
    ##print( STDERR "Module::Generic::import(): using primary path of '$path'.\n" ) if( $DEBUG );
    if( defined( $path ) )
    {
        ## Try absolute path name
        $path =~ s/^(.*)$dir\.pm$/$1auto\/$dir\/autosplit.ix/;
        ##print( STDERR "Module::Generic::import(): using treated path of '$path'.\n" ) if( $DEBUG );
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
        ##print( STDERR "Module::Generic::import(): '$path' ", $@ ? 'not ' : '', "loaded.\n" ) if( $DEBUG );
    }
}

sub new
{
    my $that  = shift( @_ );
    my $class = ref( $that ) || $that;
    ## my $pkg   = ( caller() )[ 0 ];
    ## print( STDERR __PACKAGE__ . "::new(): our calling package is '", ( caller() )[ 0 ], "', our class is '$class'.\n" );
    my $self  = {};
    ## print( STDERR "${class}::OBJECT_READONLY: ", ${ "${class}\::OBJECT_READONLY" }, "\n" );
    if( defined( ${ "${class}\::OBJECT_PERMS" } ) )
    {
        my %hash  = ();
        my $obj   = tie(
        %hash, 
        'Module::Generic::Tie', 
        'pkg'        => [ __PACKAGE__, $class ],
        'perms'        => ${ "${class}::OBJECT_PERMS" },
        );
        $self  = \%hash;
    }
    bless( $self, $class );
    if( $MOD_PERL )
    {
        my $r = Apache2::RequestUtil->request;
        $r->pool->cleanup_register
        (
          sub
          {
          ## my( $pkg, $file, $line ) = caller();
          ## print( STDERR "Apache procedure: Deleting all the object keys for object '$self' and package '$class' called within package '$pkg' in file '$file' at line '$line'.\n" );
          map{ delete( $self->{ $_ } ) } keys( %$self );
          undef( %$self );
          }
        );
    }
    if( defined( ${ "${class}\::LOG_DEBUG" } ) )
    {
        $self->{ 'log_debug' } = ${ "${class}::LOG_DEBUG" };
    }
    return( $self->init( @_ ) );
}

## This is used to transform package data set into hash refer suitable for api calls
## If package use AUTOLOAD, those AUtILOAD should make sure to create methods on the fly so they become defined
sub as_hash
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $p = {};
    $p = shift( @_ ) if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' );
    # $self->message( 3, "Parameters are: ", sub{ $self->dumper( $p ) } );
    my $class = ref( $self );
    no strict 'refs';
    my @methods = grep{ defined &{"${class}::$_"} } keys( %{"${class}::"} );
    # $self->messagef( 3, "The following methods found in package $class: '%s'.", join( "', '", sort( @methods ) ) );
    use strict 'refs';
    my $ref = {};
    foreach my $meth ( sort( @methods ) )
    {
        next if( substr( $meth, 0, 1 ) eq '_' );
        my $rv = eval{ $self->$meth };
        if( $@ )
        {
            warn( "An error occured while accessing method $meth: $@\n" );
            next;
        }
        no overloading;
        # $self->message( 3, "Value for method '$meth' is '$rv'." );
        use overloading;
        if( $p->{json} && ( ref( $rv ) eq 'JSON::PP::Boolean' || ref( $rv ) eq 'Module::Generic::Boolean' ) )
        {
            # $self->message( 3, "Encoding boolean to true or false for method '$meth'." );
            $ref->{ $meth } = Module::Generic::Boolean::TO_JSON( $ref->{ $meth } );
            next;
        }
        elsif( $self->_is_object( $rv ) )
        {
            if( $rv->can( 'as_hash' ) && overload::Overloaded( $rv ) && overload::Method( $rv, '""' ) )
            {
                $rv = $rv . '';
            }
            elsif( $rv->can( 'as_hash' ) )
            {
                # $self->message( 3, "$rv is an object (", ref( $rv ), ") capable of as_hash, calling it." );
                $rv = $rv->as_hash( $p );
            }
        }
        
        ## $self->message( 3, "Checking field '$meth' with value '$rv'." );
        
        if( ref( $rv ) eq 'HASH' )
        {
            $ref->{ $meth } = $rv if( scalar( keys( %$rv ) ) );
        }
        ## If method call returned an array, like array of string or array of object such as in data from Net::API::Stripe::List
        elsif( ref( $rv ) eq 'ARRAY' )
        {
            my $arr = [];
            foreach my $this_ref ( @$rv )
            {
                my $that_ref = ( $self->_is_object( $this_ref ) && $this_ref->can( 'as_hash' ) ) ? $this_ref->as_hash : $this_ref;
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
    $this->{error} = ${ "$class\::ERROR" } = '';
    return( 1 );
}

# sub clone
# {
#     my $self  = shift( @_ );
#     if( Scalar::Util::reftype( $self ) eq 'HASH' )
#     {
#         return( bless( { %$self } => ( ref( $self ) || $self ) ) );
#     }
#     elsif( Scalar::Util::reftype( $self ) eq 'ARRAY' )
#     {
#         return( bless( [ @$self ] => ( ref( $self ) || $self ) ) );
#     }
#     else
#     {
#         return( $self->error( "Cloning is unsupported for type \"", ref( $self ), "\". Only hash or array references are supported." ) );
#     }
# }

sub clone
{
    my $self  = shift( @_ );
    try
    {
        $self->message( 3, "Cloning object '", overload::StrVal( $self ), "'." );
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
    if( $colour =~ /^[A-Z]+([A-Z\s]+)*$/ )
    {
        if( !scalar( keys( %$COLOUR_NAME_TO_RGB ) ) )
        {
            ## $self->message( 3, "Processing colour map in <DATA> section." );
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
    ## Colour all in decimal??
    elsif( $colour =~ /^\d{9}$/ )
    {
        ## $self->message( 3, "Got colour all in decimal. Less work to do..." );
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
        ## Not undef, but rather empty string. Undef is associated with an error
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
    ## $self->message( 3, "Current colour: '$cur'." );
    for( my $i = 0; $i < scalar( @colours ); $i++ )
    {
        my $r = CORE::sprintf( '%03d', substr( $colours[ $i ], 0, 3 ) );
        my $g = CORE::sprintf( '%03d', substr( $colours[ $i ], 3, 3 ) );
        my $b = CORE::sprintf( '%03d', substr( $colours[ $i ], 6, 3 ) );
 
        my $r_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 0, 3 ) );
        my $g_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 3, 3 ) );
        my $b_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 6, 3 ) );
 
        ## $self->message( 3, "$r ($red), $g ($green), $b ($blue)" );
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
    ## style, colour or color and text
    my $opts = shift( @_ );
    return( $self->error( "Parameter hash provided is not an hash reference." ) ) if( !$self->_is_hash( $opts ) );
    my $this = $self->_obj2h;
    ## To make it possible to use either text or message property
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
    
    local $convert_24_To_8bits = sub
    {
        my( $r, $g, $b ) = @_;
        $self->message( 9, "Converting $r, $g, $b to 8 bits" );
        return( ( POSIX::floor( $r * 7 / 255 ) << 5 ) +
                ( POSIX::floor( $g * 7 / 255 ) << 2 ) +
                ( POSIX::floor( $b * 3 / 255 ) ) 
              );
    };
    
    ## opacity * original + (1-opacity)*background = resulting pixel
    ## https://stackoverflow.com/a/746934/4814971
    local $colour_with_alpha = sub
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
    
    local $check_colour = sub
    {
        my $col = shift( @_ );
        ## $self->message( 3, "Checking colour '$col'." );
        ## $colours or $bg_colours
        my $map = shift( @_ );
        my $code;
        my $light;
        ## Example: 'light red' or 'light_red'
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
        ## Treating opacity to make things lighter; not ideal, but standard scheme
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
                $self->message( 9, "Colour $+{red}, $+{green}, $+{blue} * $opacity => $col_ref->{red}, $col_red->{green}, $col_ref->{blue}" );
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
            ## $code = $map->{ $col };
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
    my $params = [];
    ## 8 bits parameters compatible
    my $params8 = [];
    if( $opts->{colour} || $opts->{color} || $opts->{fgcolour} || $opts->{fgcolor} || $opts->{fg_colour} || $opts->{fg_color} )
    {
        $opts->{colour} ||= CORE::delete( $opts->{color} ) || CORE::delete( $opts->{fg_colour} ) || CORE::delete( $opts->{fg_color} ) || CORE::delete( $opts->{fgcolour} ) || CORE::delete( $opts->{fgcolor} );
        my $col_ref = $check_colour->( $opts->{colour}, $colours );
        ## CORE::push( @$params, $col ) if( CORE::length( $col ) );
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
        my $col_ref = $check_colour->( $opts->{bgcolour}, $bg_colours );
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
        ## $self->message( 9, "Style '$opts->{style}' provided." );
        my $those_styles = [CORE::split( /\|/, $opts->{style} )];
        ## $self->message( 9, "Split styles: ", sub{ $self->dumper( $those_styles ) } );
        foreach my $s ( @$those_styles )
        {
            ## $self->message( 9, "Adding style '$s'" ) if( CORE::exists( $styles->{lc($s)} ) );
            if( CORE::exists( $styles->{lc($s)} ) )
            {
                CORE::push( @$params, $styles->{lc($s)} );
                ## We add the 8 bits compliant version only if any colour was provided, i.e.
                ## This is not just a style definition
                CORE::push( @$params8, $styles->{lc($s)} ) if( scalar( @$params8 ) );
            }
        }
    }
    CORE::push( @$data, "\e[" . CORE::join( ';', @$params8 ) . "m" ) if( scalar( @$params8 ) );
    CORE::push( @$data, "\e[" . CORE::join( ';', @$params ) . "m" ) if( scalar( @$params ) );
    $self->message( 9, "Pre final colour data contains: ", sub{ $self->dumper( $data ) });
    ## If the text contains libe breaks, we must stop the formatting before, or else there would be an ugly formatting on the entire screen following the line break
    if( scalar( @$params ) && $opts->{text} =~ /\n+/ )
    {
        my $text_parts = [CORE::split( /\n/, $opts->{text} )];
        my $fmt = CORE::join( '', @$data );
        my $fmt8 = CORE::join( '', @$data8 );
        for( my $i = 0; $i < scalar( @$text_parts ); $i++ )
        {
            ## Empty due to \n repeated
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
    local $parse = sub
    {
        my $str = shift( @_ );
        ## $self->message( 9, "Parsing coloured text '$str'" );
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
                $style = $+{style1} || $+{style2};
                $fg = $+{fg_colour};
                $bg = $+{bg_colour};
                ## $self->message( 9, "Found style '$style', colour '$fg' and background colour '$bg'." );
                $def = 
                {
                style => $style,
                colour => $fg,
                bg_colour => $bg,
                };
            }
            else
            {
                ## $self->message( 9, "Evaluating the styling '$params'." );
                my @res = eval( $params );
                ## $self->message( 9, "Evaluation result is: ", sub{ $self->dump( [ @res ] ) } );
                $def = { @res } if( scalar( @res ) && !( scalar( @res ) % 2 ) );
                if( $@ || ref( $def ) ne 'HASH' )
                {
                    $err = $@ || "Invalid styling \"${params}\"";
                    $self->message( 9, "Error evaluating: $@" );
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
    my $class = ref( $self );
    my $this  = $self->_obj2h;
    if( @_ )
    {
        my $flag = shift( @_ );
        $this->{debug} = $flag;
        $self->message_switch( $flag ) if( $OPTIMIZE_MESG_SUB );
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

## For backward compatibility and traceability
sub dump_print { return( shift->dumpto_printer( @_ ) ); }

sub dumper
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' );
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

sub printer
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' );
    local $SIG{__WARN__} = sub{ };
    eval
    {
        require Data::Printer;
    };
    unless( $@ )
    {
        if( scalar( keys( %$opts ) ) )
        {
            return( Data::Printer::np( @_, %$opts ) );
        }
        else
        {
            return( Data::Printer::np( @_ ) );
        }
    }
}

*dumpto = \&dumpto_dumper;

sub dumpto_printer
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    my $fh = IO::File->new( ">$file" ) || die( "Unable to create file '$file': $!\n" );
    $fh->binmode( ':utf8' );
    $fh->print( Data::Dump::dump( $data ), "\n" );
    $fh->close;
    ## 666 so it can work under command line and web alike
    chmod( 0666, $file );
    return( 1 );
}

sub dumpto_dumper
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Useqq = 1;
    my $fh = IO::File->new( ">$file" ) || die( "Unable to create file '$file': $!\n" );
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
    return( 1 );
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
    my $this = $self->_obj2h;
    if( @_ )
    {
        my $args = {};
        if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) )
        {
            $args->{object} = shift( @_ );
        }
        elsif( ref( $_[0] ) eq 'HASH' )
        {
            $args  = shift( @_ );
        }
        else
        {
            $args->{message} = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @_ ) );
        }
        $args->{message} = substr( $args->{message}, 0, $this->{error_max_length} ) if( $this->{error_max_length} > 0 && length( $args->{message} ) > $this->{error_max_length} );
        # Reset it
        $this->{_msg_no_exec_sub} = 0;
        my $n = 1;
        # $n++ while( ( caller( $n ) )[0] eq 'Module::Generic' );
        $args->{skip_frames} = $n + 1;
        ## my( $p, $f, $l ) = caller( $n );
        ## my( $sub ) = ( caller( $n + 1 ) )[3];
        my $o = $this->{error} = ${ $class . '::ERROR' } = Module::Generic::Exception->new( $args );
        ## printf( STDERR "%s::error() called from package %s ($p) in file %s ($f) at line %d ($l) from sub %s ($sub)\n", __PACKAGE__, $o->package, $o->file, $o->line, $o->subroutine );
        
        ## Get the warnings status of the caller. We use caller(1) to skip one frame further, ie our caller's caller
        ## This can be changed by using 'no warnings'
        my $should_display_warning = 0;
        my $no_use_warnings = 1;
        ## Try to get the warnings status if is enabled at all.
        try
        {
            $should_display_warning = $self->_warnings_is_enabled;
            $no_use_warnings = 0;
        }
        catch( $e )
        {
            # 
        }
        
        if( $no_use_warnings )
        {
            my $call_offset = 0;
            while( my @call_data = caller( $call_offset ) )
            {
                ## printf( STDERR "[$call_offset] In file $call_data[1] at line $call_data[2] from subroutine %s has bitmask $call_data[9]\n", (caller($call_offset+1))[3] );
                unless( $call_offset > 0 && $call_data[0] ne $class && (caller($call_offset-1))[0] eq $class )
                {
                    ## print( STDERR "Skipping package $call_data[0]\n" );
                    $call_offset++;
                    next;
                }
                last if( $call_data[9] || ( $call_offset > 0 && (caller($call_offset-1))[0] ne $class ) );
                $call_offset++;
            }
            ## print( STDERR "Using offset $call_offset with bitmask ", ( caller( $call_offset ) )[9], "\n" );
            my $bitmask = ( caller( $call_offset ) )[9];
            my $offset = $warnings::Offsets{uninitialized};
            ## $self->message( 3, "Caller (2)'s bitmask is '$bitmask', warnings offset is '$offset' and vector is '", vec( $bitmask, $offset, 1 ), "'." );
            $should_display_warning = vec( $bitmask, $offset, 1 );
        }
        
        my $r;
        $r = Apache2::RequestUtil->request if( $MOD_PERL );
        # $r->log_error( "Called for error $o" ) if( $r );
        $r->warn( $o->as_string ) if( $r );
        my $err_handler = $self->error_handler;
        if( $err_handler && ref( $err_handler ) eq 'CODE' )
        {
            # $r->log_error( "Module::Generic::error(): called for object error hanler" ) if( $r );
            $err_handler->( $o );
        }
        elsif( $r )
        {
            # $r->log_error( "Module::Generic::error(): called for Apache mod_perl error hanler" ) if( $r );
            if( my $log_handler = $r->get_handlers( 'PerlPrivateErrorHandler' ) )
            {
                $log_handler->( $o );
            }
            else
            {
                # $r->log_error( "Module::Generic::error(): No Apache mod_perl error handler set, reverting to log_error" ) if( $r );
                # $r->log_error( "$o" );
                $r->warn( $o->as_string ) if( $should_display_warning );
            }
        }
        elsif( $this->{fatal} )
        {
            ## die( sprintf( "Within package %s in file %s at line %d: %s\n", $o->package, $o->file, $o->line, $o->message ) );
            # $r->log_error( "Module::Generic::error(): called calling die" ) if( $r );
            my $enc_str = eval{ Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK ) };
            die( $@ ? $o : $enc_str );
        }
        elsif( !exists( $this->{quiet} ) || !$this->{quiet} )
        {
            # $r->log_error( "Module::Generic::error(): calling warn" ) if( $r );
            if( $r )
            {
                $r->warn( $o->as_string ) if( $should_display_warning );
            }
            else
            {
                my $enc_str = eval{ Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK ) };
                warn( $@ ? $o : $enc_str ) if( $should_display_warning );
            }
        }
        
        if( overload::Overloaded( $self ) )
        {
            my $overload_meth_ref = overload::Method( $self, '""' );
            my $overload_meth_name = '';
            $overload_meth_name = Sub::Util::subname( $overload_meth_ref ) if( ref( $overload_meth_ref ) );
            ## use Sub::Identify ();
            ## my( $over_file, $over_line ) = Sub::Identify::get_code_location( $overload_meth_ref );
            # my( $over_call_pack, $over_call_file, $over_call_line ) = caller();
            my $call_sub = (caller(1))[3];
            # my $call_hash = (caller(0))[10];
            # my @call_keys = CORE::keys( %$call_hash );
            # print( STDERR "\$self is overloaded and stringification method is '$overload_meth', its sub name is '$overload_meth_name' from file '$over_file' at line '$over_line' and our caller subroutine is '$call_sub' from file '$over_call_file' at line '$over_call_line' with hint hash keys '@call_keys'.\n" );
            ## overloaded method name can be, for example: My::Package::as_string
            ## or, for anonymous sub: My::Package::__ANON__[lib/My/Package.pm:12]
            ## caller sub will reliably be the same, so we use it to check if we are called from an overloaded stringification and return undef right here.
            ## Want::want check of being called in an OBJECT context triggers a perl segmentation fault
            if( length( $overload_meth_name ) && $overload_meth_name eq $call_sub )
            {
                return;
            }
        }
        
        ## https://metacpan.org/pod/Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef
        ## https://perlmonks.org/index.pl?node_id=741847
        ## Because in list context this would create a lit with one element undef()
        ## A bare return will return an empty list or an undef scalar
        ## return( undef() );
        ## return;
        ## As of 2019-10-13, Module::Generic version 0.6, we use this special package Module::Generic::Null to be returned in chain without perl causing the error that a method was called on an undefined value
        ## 2020-05-12: Added the no_return_null_object to instruct not to return a null object
        ## This is especially needed when an error is called from TIEHASH that returns a special object.
        ## A Null object would trigger a fatal perl segmentation fault
        if( !$args->{no_return_null_object} && want( 'OBJECT' ) )
        {
            my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, has_error => 1 });
            rreturn( $null );
        }
        return;
    }
    return( ref( $self ) ? $this->{error} : ${ $class . '::ERROR' } );
}

sub error_handler { return( shift->_set_get_code( '_error_handler', @_ ) ); }

*errstr = \&error;

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
    my $this = $self->_obj2h;
    $this->{verbose} = ${ $pkg . '::VERBOSE' } if( !length( $this->{verbose} ) );
    $this->{debug}   = ${ $pkg . '::DEBUG' } if( !length( $this->{debug} ) );
    $this->{version} = ${ $pkg . '::VERSION' } if( !defined( $this->{version} ) );
    $this->{level}   = 0;
    $this->{colour_open} = COLOUR_OPEN if( !length( $this->{colour_open} ) );
    $this->{colour_close} = COLOUR_CLOSE if( !length( $this->{colour_close} ) );
    ## If no debug level was provided when calling message, this level will be assumed
    ## Example: message( "Hello" );
    ## If _message_default_level was set to 3, this would be equivalent to message( 3, "Hello" )
    $this->{ '_message_default_level' } = 0;
    my $data = $this;
    if( $this->{_data_repo} )
    {
        $this->{ $this->{_data_repo} } = {} if( !$this->{ $this->{_data_repo} } );
        $data = $this->{ $this->{_data_repo} };
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
            ## $vals = [ %{$_[0]} ];
        }
        elsif( ref( $args[0] ) eq 'ARRAY' )
        {
            ## $self->_message( 3, "Got an array ref" );
            $vals = $args[0];
        }
        ## Special case when there is an undefined value passed (null) even though it is declared as a hash or object
        elsif( scalar( @args ) == 1 && !defined( $args[0] ) )
        {
            # return( undef() );
            return;
        }
        elsif( ( scalar( @args ) % 2 ) )
        {
            return( $self->error( sprintf( "Uneven number of parameters provided (%d). Should receive key => value pairs. Parameters provideds are: %s", scalar( @args ), join( ', ', @args ) ) ) );
        }
        else
        {
            ## $self->message( 3, "Got an array: ", sub{ $self->dumper( \@args ) } );
            $vals = \@args;
        }
        ## Check if there is a debug parameter, and if we find one, set it first so that that 
        ## calls to the package subroutines can produce verbose feedback as necessary
        for( my $i = 0; $i < scalar( @$vals ); $i++ )
        {
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
                $self->$name( $val );
                next;
            }
            elsif( $this->{_init_strict_use_sub} )
            {
                # $self->message( 3, "Checking if method $name exist in class ", ref( $self ), ": ", $self->can( $name ) ? 'yes' : 'no' );
                #if( !defined( $meth = $self->can( $name ) ) )
                #{
                    $self->error( "Unknown method $name in class $pkg" );
                    next;
                #}
                # $self->message( 3, "Calling method $name with value $val" );
                # $self->$meth( $val );
                # $meth->( $self, $val );
                #$self->$name( $val );
                #next;
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
                        return( $self->error( "$name parameter expects a package $thisPack object, but instead got '$val'." ) );
                    }
                    elsif( !$val->isa( $thisPack ) )
                    {
                        return( $self->error( "$name parameter expects a package $thisPack object, but instead got an object from package '", ref( $val ), "'." ) );
                    }
                }
                elsif( $this->{_init_strict} )
                {
                    if( ref( $data->{ $name } ) eq 'ARRAY' )
                    {
                        return( $self->error( "$name parameter expects an array reference, but instead got '$val'." ) ) if( Scalar::Util::reftype( $val ) ne 'ARRAY' );
                    }
                    elsif( ref( $data->{ $name } ) eq 'HASH' )
                    {
                        return( $self->error( "$name parameter expects an hash reference, but instead got '$val'." ) ) if( Scalar::Util::reftype( $val ) ne 'HASH' );
                    }
                    elsif( ref( $data->{ $name } ) eq 'SCALAR' )
                    {
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
    $self->message_switch( $this->{debug} );
#     if( $OPTIMIZE_MESG_SUB && !$this->{verbose} && !$this->{debug} )
#     {
#         if( defined( &{ "$pkg\::message" } ) )
#         {
#             *{ "$pkg\::message_off" } = \&{ "$pkg\::message" } unless( defined( &{ "$pkg\::message_off" } ) );
#             *{ "$pkg\::message" } = sub { 1 };
#         }
#     }
    return( $self );
}

sub log_handler { return( shift->_set_get_code( '_log_handler', @_ ) ); }

# sub log4perl
# {
#   my $self = shift( @_ );
#   if( @_ )
#   {
#       require Log::Log4perl;
#       my $ref = shift( @_ );
#       Log::Log4perl::init( $ref->{ 'config_file' } );
#       my $log = Log::Log4perl->get_logger( $ref->{ 'domain' } );
#       $self->{ 'log4perl' } = $log;
#   }
#   else
#   {
#       $self->{ 'log4perl' };
#   }
# }

sub message
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    ## my( $pack, $file, $line ) = caller;
    my $this = $self->_obj2h;
    ## print( STDERR __PACKAGE__ . "::message(): Called from package $pack in file $file at line $line with debug value '$hash->{debug}', package DEBUG value '", ${ $class . '::DEBUG' }, "' and params '", join( "', '", @_ ), "'\n" );
    my $r;
    $r = Apache2::RequestUtil->request if( $MOD_PERL );
    if( $this->{verbose} || $this->{debug} || ${ $class . '::DEBUG' } )
    {
        # $r->log_error( "Got here in Module::Generic::message before checking message." ) if( $r );
        my $ref;
        $ref = $self->message_check( @_ );
        ## print( STDERR __PACKAGE__ . "::message(): message_check() returns '$ref' (", join( '', @$ref ), ")\n" );
        ## return( 1 ) if( !( $ref = $self->message_check( @_ ) ) );
        return( 1 ) if( !$ref );
        
        my $opts = {};
        $opts = pop( @$ref ) if( ref( $ref->[-1] ) eq 'HASH' );
        ## print( STDERR __PACKAGE__ . "::message(): \$opts contains: ", $self->dumper( $opts ), "\n" );
        
        ## By now, we should have a reference to @_ in $ref
        ## my $class = ref( $self ) || $self;
        ## print( STDERR __PACKAGE__ . "::message(): caller at 0 is ", (caller(0))[3], " and at 1 is ", (caller(1))[3], "\n" );
        ## $r->log_error( "Got here in Module::Generic::message checking frames stack." ) if( $r );
        my $stackFrame = $self->message_frame( (caller(1))[3] ) || 1;
        $stackFrame = 1 unless( $stackFrame =~ /^\d+$/ );
        $stackFrame-- if( $stackFrame );
        $stackFrame++ if( (caller(1))[3] eq 'Module::Generic::messagef' || 
                          (caller(1))[3] eq 'Module::Generic::message_colour' );
        $stackFrame++ if( (caller(2))[3] eq 'Module::Generic::messagef_colour' );
        my( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
        my $sub = ( caller( $stackFrame + 1 ) )[3];
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
        ## $r->log_error( "Called from package $pkg in file $file at line $line from sub $sub2 ($sub)" ) if( $r );
        if( $sub2 eq 'message' )
        {
            $stackFrame++;
            ( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
            my $sub = ( caller( $stackFrame + 1 ) )[3];
            $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        }
        ## $r->log_error( "Got here in Module::Generic::message building the message string." ) if( $r );
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
        ## Reset it
        $this->{_msg_no_exec_sub} = 0;
        ## $r->log_error( "Got here in Module::Generic::message with message string '$txt'." ) if( $r );
        no overloading;
        my $mesg = "${pkg}::${sub2}( $self ) [$line]: " . $txt;
        $mesg    =~ s/\n$//gs;
        $mesg = '## ' . join( "\n## ", split( /\n/, $mesg ) );
        
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
        
        ## $r->log_error( "Got here in Module::Generic::message checkin if we run under ModPerl." ) if( $r );
        ## If Mod perl is activated AND we are not using a private log
        ## my $r;
        ## if( $MOD_PERL && !${ "${class}::LOG_DEBUG" } && ( $r = eval{ require Apache2::RequestUtil; Apache2::RequestUtil->request; } ) )
        if( $r && !${ "${class}::LOG_DEBUG" } )
        {
            ## $r->log_error( "Got here in Module::Generic::message, going to call our log handler." );
            if( my $log_handler = $r->get_handlers( 'PerlPrivateLogHandler' ) )
            {
                # my $meta = B::svref_2object( $log_handler );
                # $r->log_error( "Module::Generic::message(): Log handler code routine name is " . $meta->GV->NAME . " called in file " . $meta->GV->FILE . " at line " . $meta->GV->LINE );
                $log_handler->( $mesg );
            }
            else
            {
                $r->log_error( $mesg );
            }
        }
        ## Using ModPerl Server to log
        elsif( $MOD_PERL && !${ "${class}::LOG_DEBUG" } )
        {
            require Apache2::ServerUtil;
            my $s = Apache2::ServerUtil->server;
            $s->log_error( $mesg );
        }
        ## e.g. in our package, we could set the handler using the curry module like $self->{_log_handler} = $self->curry::log
        elsif( !-t( STDIN ) && $this->{_log_handler} && ref( $this->{_log_handler} ) eq 'CODE' )
        {
            # $r = Apache2::RequestUtil->request;
            # $r->log_error( "Got here in Module::Generic::message, going to call our log handler without using Apache callbacks." );
            # my $meta = B::svref_2object( $self->{_log_handler} );
            # $r->log_error( "Log handler code routine name is " . $meta->GV->NAME . " called in file " . $meta->GV->FILE . " at line " . $meta->GV->LINE );
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
            my $err = IO::File->new;
            $err->fdopen( fileno( STDERR ), 'w' );
            $err->binmode( ":utf8" ) unless( $opts->{no_encoding} );
            $err->autoflush( 1 );
            $err->print( $mesg, "\n" );
        }
    }
    return( 1 );
}

sub message_check
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this = $self->_obj2h;
    ## printf( STDERR "Our class is $class and DEBUG_TARGET contains: '%s' and debug value is %s\n", join( ', ', @${ "${class}::DEBUG_TARGET" } ), $hash->{ 'debug' } );
    if( @_ )
    {
        if( $_[0] !~ /^\d/ )
        {
            ## The last parameter is an options parameter which has the level property set
            if( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
            {
                ## Then let's use this
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
        ## If the first argument looks line a number, and there is more than 1 argument
        ## and it is greater than 1, and greater than our current debug level
        ## well, we do not output anything then...
        if( ( $_[ 0 ] =~ /^\d+$/ || ( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) ) ) && 
            @_ > 1 )
        {
            my $message_level;
            if( $_[ 0 ] =~ /^\d+$/ )
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
            if( $this->{debug} >= $message_level ||
                $this->{verbose} >= $message_level ||
                ${ $class . '::DEBUG' } >= $message_level ||
                $this->{debug_level} >= $message_level ||
                $this->{debug} >= 100 || 
                ( length( $target_re ) && $class =~ /^$target_re$/ && ${ $class . '::GLOBAL_DEBUG' } >= $message_level ) )
            {
                ## print( STDERR ref( $self ) . "::message_check(): debug is '$hash->{debug}', verbose '$hash->{verbose}', DEBUG '", ${ $class . '::DEBUG' }, "', debug_level = $hash->{debug_level}\n" );
                return( [ @_ ] );
            }
            else
            {
                return( 0 );
            }
        }
    }
    return( 0 );
}

*message_color = \&message_colour;

sub message_colour
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
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
    #print( STDERR "Module::Generic::log: \$io now is '$io'\n" );
    return( undef() ) if( !$io );
    #print( STDERR "Module::Generic::log: \$io is not an open handle\n" ) if( !openhandle( $io ) && $io );
    return( undef() ) if( !Scalar::Util::openhandle( $io ) && $io );
    ## 2019-06-14: I decided to remove this test, because if a log is provided it should print to it
    ## If we are on the command line, we can easily just do tail -f log_file.txt for example and get the same result as
    ## if it were printed directly on the console
#   my $rc = CORE::print( $io @_ ) || return( $self->error( "Unable to print to log file: $!" ) );
    my $rc = $io->print( scalar( localtime( time() ) ), " [$$]: ", @_ ) || return( $self->error( "Unable to print to log file: $!" ) );
    ## print( STDERR "Module::Generic::log (", ref( $self ), "): successfully printed to debug log file. \$rc is $rc, \$io is '$io' and message is: ", join( '', @_ ), "\n" );
    return( $rc );
}

sub message_log_io
{
    #return( shift->_set_get( 'log_io', @_ ) );
    my $self  = shift( @_ );
    my $class = ref( $self );
    my $this  = $self->_obj2h;
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
            $DEBUG_LOG_IO = IO::File->new( ">>$DEB_LOG" ) || die( "Unable to open debug log file $DEB_LOG in append mode: $!\n" );
            $DEBUG_LOG_IO->binmode( ':utf8' );
            $DEBUG_LOG_IO->autoflush( 1 );
        }
        $self->_set_get( 'log_io', $DEBUG_LOG_IO );
    }
    return( $self->_set_get( 'log_io' ) );
}

sub message_switch
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
    my $this = $self->_obj2h;
    if( @_ )
    {
        my $flag = shift( @_ );
        if( $flag )
        {
            if( defined( &{ "$pkg\::message_off" } ) )
            {
                ## Restore previous backup
                *{ "${pkg}::message" } = \&{ "${pkg}::message_off" };
            }
            else
            {
                *{ "${pkg}::message" } = \&{ "Module::Generic::message" };
            }
        }
        ## We switch it down if nobody is going to use it
        elsif( !$flag && !$this->{verbose} && !$this->{debug} )
        {
            *{ "${pkg}::message_off" } = \&{ "${pkg}::message" } unless( defined( &{ "${pkg}::message_off" } ) );
            *{ "${pkg}::message" } = sub { 1 };
        }
    }
    return( 1 );
}

sub messagef
{
    my $self  = shift( @_ );
    ## print( STDERR "got here: ", ref( $self ), "::messagef\n" );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
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
        ## $self->message( 3, "Option colour set? '$opts->{colour}'. Text is: '$txt'" );
        $txt = $self->colour_parse( $txt ) if( $opts->{colour} );
        ## print( STDERR ref( $self ), "::messagef \$txt is '$txt'\n" );
        $opts->{message} = $txt;
        $opts->{level} = $level if( defined( $level ) );
        # return( $self->message( defined( $level ) ? ( $level, $txt ) : $txt ) );
        return( $self->message( ( $level || 0 ), $opts ) );
    }
    return( 1 );
}

sub messagef_colour
{
    my $self  = shift( @_ );
    my $this  = $self->_obj2h;
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

sub new_hash
{
    my $self = shift( @_ );
    return( Module::Generic::Hash->new( @_ ) );
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

sub noexec { $_[0]->{_msg_no_exec_sub} = 1; return( $_[0] ); }

## Purpose is to get an error object thrown from another package, and make it ours and pass it along
sub pass_error
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $err  = shift( @_ );
    return if( !ref( $err ) || !Scalar::Util::blessed( $err ) );
    $this->{error} = ${ $class . '::ERROR' } = $err;
    if( want( 'OBJECT' ) )
    {
        my $null = Module::Generic::Null->new( $err, { debug => $this->{debug}, has_error => 1 });
        rreturn( $null );
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
    my $fh = IO::File->new( ">$opts->{file}" ) || return( $self->error( "Unable to open file \"$opts->{file}\" in write mode: $!" ) );
    $fh->binmode( ':' . $opts->{encoding} ) if( $opts->{encoding} );
    $fh->autoflush( 1 );
    if( !defined( $fh->print( ref( $opts->{data} ) eq 'SCALAR' ? ${$opts->{data}} : $opts->{data} ) ) )
    {
        return( $self->error( "Unable to write data to file \"$opts->{file}\": $!" ) )
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
    ## remove '.pm'
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

sub true  { ${"Module::Generic::Boolean::true"} }

sub false { ${"Module::Generic::Boolean::false"} }

sub verbose
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    if( @_ )
    {
        my $flag = shift( @_ );
        $this->{verbose} = $flag;
        $self->message_switch( $flag ) if( $OPTIMIZE_MESG_SUB );
    }
    return( $this->{verbose} );
}

sub will
{
    ( @_ >= 2 && @_ <= 3 ) || die( 'Usage: $obj->can( "method" ) or Module::Generic::will( $obj, "method" )' );
    my( $obj, $meth, $level );
    ## $obj->will( $other_obj, 'method' );
    if( @_ == 3 && ref( $_[ 1 ] ) )
    {
        $obj  = $_[ 1 ];
        $meth = $_[ 2 ];
    }
    else
    {
        ( $obj, $meth, $level ) = @_;
    }
    return( undef() ) if( !ref( $obj ) && index( $obj, '::' ) == -1 );
    ## Give a chance to UNIVERSAL::can
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
    ## print( $err "\t" x $level, "UNIVERSAL::can ", defined( $ref ) ? "succeeded" : "failed", " in finding the method \"$meth\" in object/class $obj.\n" );
    ## print( $err "\t" x $level, defined( $ref ) ? "succeeded" : "failed", " in finding the method \"$meth\" in object/class $obj.\n" );
    return( $ref ) if( defined( $ref ) );
    ## We do not go further down the rabbit hole if level is greater or equal to 10
    $level ||= 0;
    return( undef() ) if( $level >= 10 );
    $level++;
    ## Let's see what Alice has got for us... :-)
    ## We look in the @ISA to see if the method exists in the package from which we
    ## possibly inherited
    if( @{ "$class\::ISA" } )
    {
        ## print( STDERR "\t" x $level, "Checking ", scalar( @{ "$class\::ISA" } ), " entries in \"\@${class}\:\:ISA\".\n" );
        foreach my $pack ( @{ "$class\::ISA" } )
        {
            ## print( STDERR "\t" x $level, "Looking up method \"$meth\" in inherited package \"$pack\".\n" );
            my $ref = &will( $pack, "$origi\::$meth", $level );
            return( $ref ) if( defined( $ref ) );
        }
    }
    ## Then, maybe there is an AUTOLOAD to trap undefined routine?
    ## But, we do not want any loop, do we?
    ## Since will() is called from Module::Generic::AUTOLOAD to check if EXTRA_AUTOLOAD exists
    ## we are not going to call Module::Generic::AUTOLOAD for EXTRA_AUTOLOAD...
    if( $class ne 'Module::Generic' && $meth ne 'EXTRA_AUTOLOAD' && defined( &{ "$class\::AUTOLOAD" } ) )
    {
        ## print( STDERR "\t" x ( $level - 1 ), "Found an AUTOLOAD in class \"$class\". Ok.\n" );
        my $sub = sub
        {
            $class::AUTOLOAD = "$origi\::$meth";
            &{ "$class::AUTOLOAD" }( @_ );
        };
        return( $sub );
    }
    return( undef() );
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
        ## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
        ## require $class unless( defined( *{"${class}::"} ) );
        my $rc = eval{ Class::Load::load_class( $class ); };
        return( $self->error( "Unable to load class $class: $@" ) ) if( $@ );
        # $self->message( 3, "Called with args: ", sub{ $self->dumper( \@_ ) } );
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        $o = @_ ? $class->new( @_ ) : $class->new;
        $o->debug( $this->{debug} ) if( $o->can( 'debug' ) );
        return( $self->pass_error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
    }
    catch( $e ) 
    {
        return( $self->error({ code => 500, message => $e }) );
    }
    return( $o );
}

## Call to the actual method doing the work
## The reason for doing so is because _instantiate_object() may be inherited, but
## _set_get_class or _set_get_hash_as_object created dynamic class which requires to call _instantiate_object
## If _instantiate_object is inherited, it will yield unpredictable results
sub _instantiate_object { return( shift->__instantiate_object( @_ ) ); }

sub _is_a
{
    my $self = shift( @_ );
    my $obj = shift( @_ );
    my $pkg = shift( @_ );
    no overloading;
    return if( !$obj || !$pkg );
    return if( !$self->_is_object( $obj ) );
    return( $obj->isa( $pkg ) );
}

sub _is_class_loaded { shift( @_ ); return( Class::Load::is_class_loaded( @_ ) ); }

## UNIVERSAL::isa works for both array or array as objects
## sub _is_array { return( UNIVERSAL::isa( $_[1], 'ARRAY' ) ); }
sub _is_array { return( Scalar::Util::reftype( $_[1] ) eq 'ARRAY' ); }

## sub _is_hash { return( UNIVERSAL::isa( $_[1], 'HASH' ) ); }
sub _is_hash { return( Scalar::Util::reftype( $_[1] ) eq 'HASH' ); }

sub _is_object { return( Scalar::Util::blessed( $_[1] ) ); }

sub _is_scalar{ return( Scalar::Util::reftype( $_[1] ) eq 'SCALAR' ); }

sub _load_class
{
    my $self = shift( @_ );
    my $class = shift( @_ ) || return( $self->error( "No package name was provided to load." ) );
    try
    {
        return( Class::Load::load_class( "$class" ) );
    }
    catch( $e )
    {
        return( $self->error( $e ) );
    }
}

sub _obj2h
{
    my $self = shift( @_ );
    ## print( STDERR "_obj2h(): Getting a hash refernece out of the object '$self'\n" );
    if( Scalar::Util::reftype( $self ) eq 'HASH' )
    {
        return( $self );
    }
    elsif( Scalar::Util::reftype( $self ) eq 'GLOB' )
    {
        ## print( STDERR "Returning a reference to an hash for glob $self\n" );
        return( \%{*$self} );
    }
    ## The method that called message was itself called using the package name like My::Package->some_method
    ## We are going to check if global $DEBUG or $VERBOSE variables are set and create the related debug and verbose entry into the hash we return
    elsif( !ref( $self ) )
    {
        my $class = $self;
        my $hash =
        {
        'debug' => ${ "${class}\::DEBUG" },
        'verbose' => ${ "${class}\::VERBOSE" },
        'error' => ${ "${class}\::ERROR" },
        };
        ## XXX 
        ## print( STDERR "Called with '$self' with debug value '$hash->{debug}' and verbose '$hash->{verbose}'\n" );
        return( bless( $hash => $class ) );
    }
    ## Because object may be accessed as My::Package->method or My::Package::method
    ## there is not always an object available, so we need to fake it to avoid error
    ## This is primarly itended for generic methods error(), errstr() to work under any conditions.
    else
    {
        return( {} );
    }
}

sub _parse_timestamp
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    ## No value was actually provided
    return( undef() ) if( !length( $str ) );
    my $this = $self->_obj2h;
    my $tz = DateTime::TimeZone->new( name => 'local' );
    my $error = 0;
    my $opt = 
    {
    pattern   => '%Y-%m-%d %T',
    locale    => 'en_GB',
    time_zone => $tz->name,
    on_error => sub{ $error++ },
    };
    # $self->message( 3, "Checking timestamp string '$str' for appropriate pattern" );
    ## 2019-06-19 23:23:57.000000000+0900
    ## From PostgreSQL: 2019-06-20 11:02:36.306917+09
    ## ISO 8601: 2019-06-20T11:08:27
    if( $str =~ /(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})(?:[[:blank:]]+|T)(\d{1,2}:\d{1,2}:\d{1,2})(?:\.\d+)?((?:\+|\-)\d{2,4})?/ )
    {
        my( $date, $time, $zone ) = ( "$1-$2-$3", $4, $5 );
        if( !length( $zone ) )
        {
            my $dt = DateTime->now( time_zone => $tz );
            my $offset = $dt->offset;
            ## e.g. 9 or possibly 9.5
            my $offset_hour = ( $offset / 3600 );
            ## e.g. 9.5 => 0.5 * 60 = 30
            my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
            $zone  = sprintf( '%+03d%02d', $offset_hour, $offset_min );
        }
        # $self->message( 3, "\tMatched pattern #1 with date '$date', time '$time' and time zone '$zone'." );
        $date =~ tr/\//-/;
        $zone .= '00' if( length( $zone ) == 3 );
        $str = "$date $time$zone";
        $self->message( 3, "\tChanging string to '$str'" );
        $opt->{pattern} = '%Y-%m-%d %T%z';
    }
    ## From SQLite: 2019-06-20 02:03:14
    ## From MySQL: 2019-06-20 11:04:01
    elsif( $str =~ /(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})(?:[[:blank:]]+|T)(\d{1,2}:\d{1,2}:\d{1,2})/ )
    {
        my( $date, $time ) = ( "$1-$2-$3", $4 );
        # $self->message( 3, "\tMatched pattern #2 with date '$date', time '$time' and without time zone." );
        my $dt = DateTime->now( time_zone => $tz );
        my $offset = $dt->offset;
        ## e.g. 9 or possibly 9.5
        my $offset_hour = ( $offset / 3600 );
        ## e.g. 9.5 => 0.5 * 60 = 30
        my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
        my $offset_str  = sprintf( '%+03d%02d', $offset_hour, $offset_min );
        $date =~ tr/\//-/;
        $str = "$date $time$offset_str";
        $self->message( 3, "\tAdding time zone '", $tz->name, "' offset of $offset_str with result: '$str'." );
        $opt->{pattern} = '%Y-%m-%d %T%z';
    }
    elsif( $str =~ /^(\d{4})[-|\/](\d{1,2})[-|\/](\d{1,2})$/ )
    {
        $str = "$1-$2-$3";
        # $self->message( 3, "\tMatched pattern #3 with date '$date' only." );
        $opt->{pattern} = '%Y-%m-%d';
    }
    else
    {
        return( '' );
    }
    my $strp = DateTime::Format::Strptime->new( %$opt );
    my $dt = $strp->parse_datetime( $str );
    return( $dt );
}

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

sub _set_get_array_as_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
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
        }
    }
    if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
    {
        my $o = Module::Generic::Array->new( $data->{ $field } );
        $data->{ $field } = $o;
    }
    return( $data->{ $field } );
}

sub _set_get_boolean
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = shift( @_ );
        # $self->message( 3, "Value provided for field '$field' is '$val' of reference (", ref( $val ), ")." );
        if( Scalar::Util::blessed( $val ) && 
            ( $val->isa( 'JSON::PP::Boolean' ) || $val->isa( 'Module::Generic::Boolean' ) ) )
        {
            $data->{ $field } = $val;
        }
        elsif( Scalar::Util::reftype( $val ) eq 'SCALAR' )
        {
            $data->{ $field } = $$val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
        }
        elsif( lc( $val ) eq 'true' || lc( $val ) eq 'false' )
        {
            $data->{ $field } = lc( $val ) eq 'true' ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
        }
        else
        {
            $data->{ $field } = $val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
        }
        # $self->message( 3, "Boolean field now has value $self->{$field} (", ref( $self->{ $field } ), ")." );
    }
    ## If there is a value set, like a default value and it is not an object or at least not one we recognise
    ## We transform it into a Module::Generic::Boolean object
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
    return( $data->{ $field } );
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
        $class = ref( $self ) . "\::${new_class}";
    }
    unless( Class::Load::is_class_loaded( $class ) )
    {
        # $self->message( 3, "Class '$class' is not created yet, creating it." );
        my $type2func =
        {
        array       => '_set_get_array',
        array_as_object => '_set_get_array_as_object',
        boolean     => '_set_get_boolean',
        class       => '_set_get_class',
        class_array => '_set_get_class_array',
        datetime    => '_set_get_datetime',
        hash        => '_set_get_hash',
        number      => '_set_get_number',
        object      => '_set_get_object',
        object_array => '_set_get_object_array',
        object_array_object => '_set_get_object_array_object',
        scalar      => '_set_get_scalar',
        scalar_or_object => '_set_get_scalar_or_object',
        uri         => '_set_get_uri',
        };
        ## Alias
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
            my $type = lc( $info->{type} );
            if( !CORE::exists( $type2func->{ $type } ) )
            {
                warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, but the type provided \"$type\" is unknown to us, so we are skipping this field \"$f\" in the creation of our virtual class.\n" );
                next;
            }
            my $func = $type2func->{ $type };
            if( $type eq 'object' || 
                $type eq 'scalar_or_object' || 
                $type eq 'object_array' )
            {
                if( !$info->{class} )
                {
                    warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, and class \"$class\" field \"$f\" is to require an object, but no object class name was provided. Use the \"class\" property parameter. So we are skipping this field \"$f\" in the creation of our virtual class.\n" );
                    next;
                }
                my $this_class = $info->{class};
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
                my $d = Data::Dumper->new( [ $this_def ] );
                $d->Indent( 0 );
                $d->Purity( 1 );
                $d->Pad( '' );
                $d->Terse( 1 );
                $d->Sortkeys( 1 );
                my $hash_str = $d->Dump;
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
        # $self->message( 3, "Evaluating code:\n$perl" );
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
        my $rc = eval( $perl );
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
        die( "Unable to dynamically create module $class: $@" ) if( $@ );
    }
    return( $class );
}

## $self->_set_get_class( 'my_field', {
## _class => 'My::Class',
## field1 => { type => 'datetime' },
## field2 => { type => 'scalar' },
## field3 => { type => 'boolean' },
## field4 => { type => 'object', class => 'Some::Class' },
## }, @_ );
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
        return( $self->error( "I was expecting an array ref, but instead got '$ref'. _is_array returned: '", $self->_is_array( $ref ), "'" ) ) if( !$self->_set_get_array( $ref ) );
        my $arr = [];
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( ref( $ref->[$i] ) ne 'HASH' )
            {
                return( $self->error( "Array offset $i is not a hash reference. I was expecting a hash reference to instantiate an object of class $class." ) );
            }
            my $o = $self->__instantiate_object( $field, $class, $ref->[$i] );
            CORE::push( @$arr, $o );
        }
        $data->{ $field } = $arr;
    }
    return( $data->{ $field } );
}

sub _set_get_code
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->error( "Value provided for \"$field\" ($v) is not an anonymous subroutine (code). You can pass as argument something like \$self->curry::my_sub or something like sub { some_code_here; }" ) ) if( ref( $v ) ne 'CODE' );
        $data->{ $field } = $v;
    }
    return( $data->{ $field } );
}

sub _set_get_datetime
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $time = shift( @_ );
        # $self->message( 3, "Processing time stamp $time possibly of ref (", ref( $time ), ")." );
        my $now;
        if( !defined( $time ) )
        {
            $data->{ $field } = $time;
            return( $data->{ $field } );
        }
        elsif( Scalar::Util::blessed( $time ) )
        {
            return( $self->error( "Object provided as value for $field, but this is not a DateTime object" ) ) if( !$time->isa( 'DateTime' ) );
            $data->{ $field } = $time;
            return( $data->{ $field } );
        }
        elsif( $time =~ /^\d+$/ && $time !~ /^\d{10}$/ )
        {
            return( $self->error( "DateTime value ($time) provided for field $field does not look like a unix timestamp" ) );
        }
        elsif( $now = $self->_parse_timestamp( $time ) )
        {
            ## Found a parsed datetime value
            $data->{ $field } = $now;
            return( $now );
        }
        
        # $self->message( 3, "Creating a DateTime object out of $time\n" );
        eval
        {
            require DateTime;
            require DateTime::Format::Strptime;
            $now = DateTime->from_epoch(
                epoch => $time,
                time_zone => 'local',
            );
            my $strp = DateTime::Format::Strptime->new(
                pattern => '%s',
                locale => 'en_GB',
                time_zone => 'local',
            );
            $now->set_formatter( $strp );
        };
        if( $@ )
        {
            $self->message( "Error while trying to get the DateTime object for field $k with value $time" );
        }
        else
        {
            # $self->message( 3, "Returning the DateTime object '$now'" );
            $data->{ $field } = $now;
        }
    }
    ## So that a call to this field will not trigger an error: "Can't call method "xxx" on an undefined value"
    if( !$data->{ $field } && want( 'OBJECT' ) )
    {
        my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, has_error => 1 });
        rreturn( $null );
    }
    return( $data->{ $field } );
}

sub _set_get_hash
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    # $self->message( 3, "Called for field '$field' with data '", join( "', '", @_ ), "'." );
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
        my $val;
        if( ref( $_[0] ) eq 'HASH' )
        {
            $val = shift( @_ );
        }
        elsif( ( @_ % 2 ) )
        {
            $val = { @_ };
        }
        else
        {
            my $val = shift( @_ );
            return( $self->error( "Method $field takes only a hash or reference to a hash, but value provided ($val) is not supported" ) );
        }
        # $self->message( 3, "Setting value $val for field $field" );
         $data->{ $field } = $val;
    }
    return( $data->{ $field } );
}

sub _set_get_hash_as_mix_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    # $self->message( 3, "Called for field '$field' with data '", join( "', '", @_ ), "'." );
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( @_ )
    {
        my $val;
        if( ref( $_[0] ) eq 'HASH' )
        {
            $val = shift( @_ );
        }
        elsif( ( @_ % 2 ) )
        {
            $val = { @_ };
        }
        else
        {
            my $val = shift( @_ );
            return( $self->error( "Method $field takes only a hash or reference to a hash, but value provided ($val) is not supported" ) );
        }
        # $self->message( 3, "Setting value $val for field $field" );
        $data->{ $field } = Module::Generic::Hash->new( $val );
    }
    if( $data->{ $field } && !$self->_is_object( $data->{ $field } ) )
    {
        my $o = Module::Generic::Hash->new( $data->{ $field } );
        $data->{ $field } = $o;
    }
    return( $data->{ $field } );
}

sub _set_get_hash_as_object
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    # $self->message( 3, "Called with args: ", $self->dumper( \@_ ) );
    my $field = shift( @_ ) || return( $self->error( "No field provided for _set_get_hash_as_object" ) );
    my $class;
    @_ = () if( @_ == 1 && !defined( $_[0] ) );
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
            $class = ref( $self ) . "\::${new_class}";
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
        $class = ref( $self ) . "\::${new_class}";
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
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
        my $rc = eval( $perl );
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
        die( "Unable to dynamically create module \"$class\" for field \"$field\" based on our own class \"", ref( $self ), "\": $@" ) if( $@ );
    }
    
    if( @_ )
    {
        my $hash = shift( @_ );
        # my $o = $class->new( $hash );
        # print( STDERR ref( $self ), "::_set_get_hash_as_object instantiating hash with ref (", ref( $hash ), ") ", overload::StrVal( $hash ), "\n" );
        my $o = $self->__instantiate_object( $field, $class, $hash );
        $self->message( 3, "Resulting object contains: ", sub{ $self->dumper( $o ) } );
        $data->{ $field } = $o;
    }
    
    if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
    {
        my $o = $data->{ $field } = $self->__instantiate_object( $field, $class, $data->{ $field } );
    }
    return( $data->{ $field } );
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

# sub _set_get_number
# {
#     my $self  = shift( @_ );
#     my $field = shift( @_ );
#     my $this  = $self->_obj2h;
#     my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
#     @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
#     if( @_ )
#     {
#         $data->{ $field } = Module::Generic::Number->new( shift( @_ ) );
#     }
#     return( $data->{ $field } );
# }
sub _set_get_number : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    no overload;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    # print( STDERR ref( $self ), "::_set_get_number: Current value is '", overload::StrVal( $data->{ $field } ), "'\n" );
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        my( $a ) = want( 'ASSIGN' );
        # print( STDERR ref( $self ), "::_set_get_number: Setting Module::Generic::Number object for lvalue '$a'.\n" );
        $data->{ $field } = Module::Generic::Number->new( $a );
        # print( STDERR ref( $self ), "::_set_get_number: Lvalue context, object now is '", overload::StrVal( $data->{ $field } ), "'\n" );
        # print( STDERR ref( $self ), "::_set_get_number: Returning value '", overload::StrVal( $data->{ $field } ), "' in LVALUE context\n" );
        return( $data->{ $field } );
    }
    else
    {
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        if( @_ )
        {
            # print( STDERR ref( $self ), "::_set_get_number: Setting Module::Generic::Number object for regular values '", join( "', '", @_ ), "'.\n" );
            $data->{ $field } = Module::Generic::Number->new( shift( @_ ) );
            # print( STDERR ref( $self ), "::_set_get_number: Regular context, object now is '", overload::StrVal( $data->{ $field } ), "'\n" );
        }
        if( CORE::length( $data->{ $field } ) && !ref( $data->{ $field } ) )
        {
            $data->{ $field } = Module::Generic::Number->new( $data->{ $field } );
        }
        # print( STDERR ref( $self ), "::_set_get_number: Returning value '", overload::StrVal( $data->{ $field } ), "' in regular context\n" );
        return( $data->{ $field } ) if( want( 'LVALUE' ) );
        # print( STDERR ref( $self ), "::_set_get_number: RReturning value '", overload::StrVal( $data->{ $field } ), "' in rvalue context\n" );
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
            ## User removed the value by passing it an undefined value
            if( !defined( $_[0] ) )
            {
                $data->{ $field } = undef();
            }
            ## User pass an object
            elsif( Scalar::Util::blessed( $_[0] ) )
            {
                my $o = shift( @_ );
                return( $self->error( "Object provided (", ref( $o ), ") for $field is not a valid $class object" ) ) if( !$o->isa( "$class" ) );
                ## XXX Bad idea:
                ## $o->debug( $this->{debug} ) if( $o->can( 'debug' ) );
                $data->{ $field } = $o;
            }
            else
            {
                my $o = $self->_instantiate_object( $field, $class, @_ ) || return( $self->pass_error( $class->error ) );
                # $self->message( 3, "Setting field $field value to $o" );
                $data->{ $field } = $o;
            }
        }
        else
        {
            my $o = $self->_instantiate_object( $field, $class, @_ ) || return( $self->pass_error( $class->error ) );
            # $self->message( 3, "Setting field $field value to $o" );
            $data->{ $field } = $o;
        }
    }
    ## If nothing has been set for this field, ie no object, but we are called in chain
    ## we set a dummy object that will just call itself to avoid perl complaining about undefined value calling a method
    if( !$data->{ $field } && want( 'OBJECT' ) )
    {
        # print( STDERR __PACKAGE__, "::_set_get_object(): Called in a chain for field $field and class $class, but no object is set, reverting to dummy object\n" );
        # $self->message( 3, "Called in a chain, but no object is set, reverting to dummy object." );
        ## my $null = Module::Generic::Null->new( $o, { debug => $self->{debug}, has_error => 1 });
        ## rreturn( $null );
        my $o = $self->_instantiate_object( $field, $class, @_ ) || return( $self->pass_error( $class->error ) );
        $data->{ $field } = $o;
        return( $o );
    }
    # $self->message( 3, "Returning for field '$field' value: ", $self->{ $field } );
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
        return( $self->error( "I was expecting an array ref, but instead got '$this'. _is_array returned: '", $self->_is_array( $ref ), "'" ) ) if( !$self->_is_array( $data_to_process ) );
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
                        return( $self->error( "Array offset $i contains an object from class $pack, but was expecting an object of class $class." ) ) if( !$ref->[$i]->isa( $class ) );
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
    if( @_ )
    {
        my $ref = shift( @_ );
        return( $self->error( "I was expecting an array ref, but instead got '$ref'. _is_array returned: '", $self->_is_array( $ref ), "'" ) ) if( !$self->_is_array( $ref ) );
        my $arr = [];
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( defined( $ref->[$i] ) )
            {
                return( $self->error( "Array offset $i is not a reference. I was expecting an object of class $class or an hash reference to instantiate an object." ) ) if( !ref( $ref->[$i] ) );
                if( Scalar::Util::blessed( $ref->[$i] ) )
                {
                    return( $self->error( "Array offset $i contains an object from class $pack, but was expecting an object of class $class." ) ) if( !$ref->[$i]->isa( $class ) );
                    push( @$arr, $ref->[$i] );
                }
                elsif( ref( $ref->[$i] ) eq 'HASH' )
                {
                    #$o = $class->new( $h, $ref->[$i] );
                    $o = $self->_instantiate_object( $field, $class, $ref->[$i] ) || return;
                    push( @$arr, $o );
                }
                else
                {
                    $self->error( "Warning only: data provided to instantiate object of class $class is not a hash reference" );
                }
            }
            else
            {
                return( $self->error( "Array offset $i contains an undefined value. I was expecting an object of class $class." ) );
                $o = $self->_instantiate_object( $field, $class ) || return;
                push( @$arr, $o );
            }
        }
        $data->{ $field } = $arr;
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
    if( @_ )
    {
        my $that = ( scalar( @_ ) == 1 && UNIVERSAL::isa( $_[0], 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
        ## $self->message( 3, "Received following data to store as array object: ", sub{ $self->dump( $that ) } );
        my $ref = $self->_set_get_object_array( $field, $class, $that ) || return;
        ## $self->message( 3, "Object array returned is: ", sub{ $self->dump( $ref ) } );
        $data->{ $field } = Module::Generic::Array->new( $ref );
        ## $self->message( 3, "Now value for field '$field' is: ", $data->{ $field }, " which contains: '", $data->{ $field }->join( "', '" ), "'." );
    }
    ## Default value so that call to the caller's method like my_sub->length will not produce something like "Can't call method "length" on an undefined value"
    ## Also, this will make i possible to set default value in caller's object and we would turn it into array object.
    if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
    {
        my $o = Module::Generic::Array->new( $data->{ $field } );
        $data->{ $field } = $o;
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
    if( @_ )
    {
        if( ref( $_[0] ) eq 'HASH' )
        {
            my $o = $self->_instantiate_object( $field, $class, @_ );
        }
        ## AN array of objects hash
        elsif( ref( $_[0] ) eq 'ARRAY' )
        {
            my $arr = shift( @_ );
            my $res = [];
            foreach my $data ( @$arr )
            {
                my $o = $self->_instantiate_object( $field, $class, $data ) || return( $self->error( "Unable to create object: ", $self->error ) );
                push( @$res, $o );
            }
            $data->{ $field } = $res;
        }
    }
    return( $data->{ $field } );
}

sub _set_get_scalar
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 ) ? shift( @_ ) : join( '', @_ );
        ## Just in case, we force stringification
        ## $val = "$val" if( defined( $val ) );
        return( $self->error( "Method $field takes only a scalar, but value provided ($val) is a reference" ) ) if( ref( $val ) eq 'HASH' || ref( $val ) eq 'ARRAY' );
        $data->{ $field } = $val;
    }
    return( $data->{ $field } );
}

sub _set_get_scalar_as_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val;
        if( ref( $val ) eq 'SCALAR' || UNIVERSAL::isa( $val, 'SCALAR' ) )
        {
            $val = $$_[0];
        }
        elsif( ref( $val ) )
        {
            return( $self->error( "I was expecting a string or a scalar reference, but instead got '$val'" ) );
        }
        else
        {
            $val = shift( @_ );
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
            return( Module::Generic::Null->new );
        }
        else
        {
            return;
        }
    }
    else
    {
        return( $v );
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
        my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, has_error => 1 });
        rreturn( $null );
    }
    return( $data->{ $field } );
}

sub _set_get_uri
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        try
        {
            require URI if( !$self->_is_class_loaded( 'URI' ) );
        }
        catch( $e )
        {
            return( $self->error( "Error trying to load module URI: $e" ) );
        }
        
        my $str = shift( @_ );
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
            return( $self->error( "URI value provided '$str' does not look like an URI, so I do not know what to do with it." ) );
        }
        else
        {
            $data->{ $field } = undef();
        }
    }
    return( $data->{ $field } );
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

sub _warnings_is_enabled { return( warnings::enabled( ref( $_[0] ) || $_[0] ) ); }

sub __dbh
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    if( !$this->{ '__dbh' } )
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
        $this->{ '__dbh' } = $dbh;
    }
    return( $this->{ '__dbh' } );
}

sub DEBUG
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
    my $this = $self->_obj2h;
    return( ${ $pkg . '::DEBUG' } );
}

sub VERBOSE
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
    my $this = $self->_obj2h;
    return( ${ $pkg . '::VERBOSE' } );
}

AUTOLOAD
{
    my $self;
    # $self = shift( @_ ) if( ref( $_[ 0 ] ) && index( ref( $_[ 0 ] ), 'Module::' ) != -1 );
    $self = shift( @_ ) if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic' ) );
    my( $class, $meth );
    $class = ref( $self ) || $self;
    ## Leave this commented out as we need it a little bit lower
    my( $pkg, $file, $line ) = caller();
    my $sub = ( caller( 1 ) )[ 3 ];
    no overloading;
    if( $sub eq 'Module::Generic::AUTOLOAD' )
    {
        my $mesg = "Module::Generic::AUTOLOAD (called at line '$line') is looping for autoloadable method '$AUTOLOAD' and args '" . join( "', '", @_ ) . "'.";
        if( $MOD_PERL )
        {
            my $r = Apache2::RequestUtil->request;
            $r->log_error( $mesg );
        }
        else
        {
            print( $err $mesg, "\n" );
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
    ## CORE::print( STDERR "Storing '$meth' with value ", join( ', ', @_ ), "\n" );
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
    ## Because, if it does not exist in the caller's package, 
    ## calling the method will get us here infinitly,
    ## since UNIVERSAL::can will somehow return true even if it does not exist
    elsif( $self && $self->can( $meth ) && defined( &{ "$class\::$meth" } ) )
    {
        return( $self->$meth( @_ ) );
    }
    elsif( defined( &$meth ) )
    {
        no strict 'refs';
        *$meth = \&$meth;
        return( &$meth( @_ ) );
    }
    else
    {
        my $sub = $AUTOLOAD;
        my( $pkg, $func ) = ( $sub =~ /(.*)::([^:]+)$/ );
        my $mesg = "Module::Generic::AUTOLOAD(): Searching for routine '$func' from package '$pkg'.";
        if( $MOD_PERL )
        {
            my $r = Apache2::RequestUtil->request;
            $r->log_error( $mesg );
        }
        else
        {
            print( STDERR $mesg . "\n" ) if( $DEBUG );
        }
        $pkg =~ s/::/\//g;
        if( defined( $filename = $INC{ "$pkg.pm" } ) )
        {
            $filename =~ s/^(.*)$pkg\.pm\z/$1auto\/$pkg\/$func.al/s;
            ## print( STDERR "Found possible autoloadable file '$filename'.\n" );
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
                    #$@ =~ s/ at .*\n//;
                    #my $error = $@;
                    #CORE::die( $error );
                    ## die( "Method $meth() is not defined in class $class and not autoloadable.\n" );
                    ## print( $err "EXTRA_AUTOLOAD is ", defined( &{ "${class}::EXTRA_AUTOLOAD" } ) ? "defined" : "not defined", " in package '$class'.\n" );
                    ## if( $self && defined( &{ "${class}::EXTRA_AUTOLOAD" } ) )
                    ## Look up in our caller's @ISA to see if there is any package that has this special
                    ## EXTRA_AUTOLOAD() sub routine
                    my $sub_ref = '';
                    die( "EXTRA_AUTOLOAD: ", join( "', '", @_ ), "\n" ) if( $func eq 'EXTRA_AUTOLOAD' );
                    if( $self && $func ne 'EXTRA_AUTOLOAD' && ( $sub_ref = $self->will( 'EXTRA_AUTOLOAD' ) ) )
                    {
                        ## return( &{ "${class}::EXTRA_AUTOLOAD" }( $self, $meth ) );
                        ## return( $self->EXTRA_AUTOLOAD( $AUTOLOAD, @_ ) );
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
                my $r = Apache2::RequestUtil->request;
                $r->log_error( $mesg );
            }
            else
            {
                print( $err "$mesg\n" );
            }
        }
        unshift( @_, $self ) if( $self );
        #use overloading;
        goto &$sub;
        ## die( "Method $meth() is not defined in class $class and not autoloadable.\n" );
        ## my $mesg = "Method $meth() is not defined in class $class and not autoloadable.";
        ## $self->{ 'fatal' } ? die( $mesg ) : return( $self->error( $mesg ) );
    }
};

DESTROY
{
    ## Do nothing
};

package Module::Generic::Exception;
BEGIN
{
    use strict;
    use parent qw( Module::Generic );
    use Scalar::Util;
    use Devel::StackTrace;
    use overload ('""'     => 'as_string',
                  '=='     => sub { _obj_eq(@_) },
                  '!='     => sub { !_obj_eq(@_) },
                  fallback => 1,
                 );
    our( $VERSION ) = '0.1.0';
};

sub init
{
    my $self = shift( @_ );
    # require Data::Dumper::Concise;
    # print( STDERR __PACKAGE__, "::init() Got here with args: ", Data::Dumper::Concise::Dumper( \@_ ), "\n" );
    $self->{code} = '';
    $self->{type} = '';
    $self->{file} = '';
    $self->{line} = '';
    $self->{message} = '';
    $self->{package} = '';
    $self->{retry_after} = '';
    $self->{subroutine} = '';
    my $args = {};
    if( @_ )
    {
        if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) )
        {
            $args->{object} = shift( @_ );
        }
        elsif( ref( $_[0] ) eq 'HASH' )
        {
            $args  = shift( @_ );
        }
        else
        {
            $args->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
        }
    }
    # $self->SUPER::init( @_ );
    my $skip_frame = $args->{skip_frames} || 0;
    ## Skip one frame to exclude us
    $skip_frame++;
    my $trace = Devel::StackTrace->new( skip_frames => $skip_frame, indent => 1 );
    my $frame = $trace->next_frame;
    my $frame2 = $trace->next_frame;
    $trace->reset_pointer;
    if( ref( $args->{object} ) && Scalar::Util::blessed( $args->{object} ) && $args->{object}->isa( 'Module::Generic::Exception' ) )
    {
        my $o = $args->{object};
        $self->{message} = $o->message;
        $self->{code} = $o->code;
        $self->{type} = $o->type;
        $self->{retry_after} = $o->retry_after;
    }
    else
    {
        # print( STDERR __PACKAGE__, "::init() Got here with args: ", Data::Dumper::Concise::Dumper( $args ), "\n" );
        $self->{message} = $args->{message} || '';
        $self->{code} = $args->{code} if( exists( $args->{code} ) );
        $self->{type} = $args->{type} if( exists( $args->{type} ) );
        $self->{retry_after} = $args->{retry_after} if( exists( $args->{retry_after} ) );
        ## I do not want to alter the original hash reference, which may adversely affect the calling code if they depend on its content for further execution for example.
        my $copy = {};
        %$copy = %$args;
        CORE::delete( @$copy{ qw( message code type retry_after skip_frames ) } );
        # print( STDERR __PACKAGE__, "::init() Following non-standard keys to set up: '", join( "', '", sort( keys( %$copy ) ) ), "'\n" );
        ## Do we have some non-standard parameters?
        foreach my $p ( keys( %$copy ) )
        {
            my $p2 = $p;
            $p2 =~ tr/-/_/;
            $p2 =~ s/[^a-zA-Z0-9\_]+//g;
            $p2 =~ s/^\d+//g;
            $self->$p2( $copy->{ $p } );
        }
    }
    $self->{file} = $frame->filename;
    $self->{line} = $frame->line;
    ## The caller sub routine ( caller( n ) )[3] returns the sub called by our caller instead of the sub that called our caller, so we go one frame back to get it
    $self->{subroutine} = $frame2->subroutine;
    $self->{package} = $frame->package;
    $self->{trace} = $trace;
    return( $self );
}

#sub as_string { return( $_[0]->{message} ); }
## This is important as stringification is called by die, so as per the manual page, we need to end with new line
## And will add the stack trace
sub as_string
{
    no overloading;
    my $self = shift( @_ );
    my $str = $self->message;
    $str =~ s/\r?\n$//g;
    $str .= sprintf( " within package %s at line %d in file %s\n%s", $self->package, $self->line, $self->file, $self->trace->as_string );
    return( $str );
}

## if( Module::Generic::Exception->caught( $e ) ) { # do something, it's ours }
sub caught 
{
    my( $class, $e ) = @_;
    return if( ref( $class ) );
    return unless( Scalar::Util::blessed( $e ) && $e->isa( $class ) );
    return( $e );
}

sub code { return( shift->_set_get_scalar( 'code', @_ ) ); }

sub file { return( shift->_set_get_scalar( 'file', @_ ) ); }

sub line { return( shift->_set_get_scalar( 'line', @_ ) ); }

sub message { return( shift->_set_get_scalar( 'message', @_ ) ); }

sub package { return( shift->_set_get_scalar( 'package', @_ ) ); }

sub rethrow 
{
    my $self = shift( @_ );
    return if( !Scalar::Util::blessed( $self ) );
    die( $self );
}

sub retry_after { return( shift->_set_get_scalar( 'retry_after', @_ ) ); }

sub subroutine { return( shift->_set_get_scalar( 'subroutine', @_ ) ); }

sub throw
{
    my $self = shift( @_ );
    my $msg  = shift( @_ );
    my $e = $self->new({
        skip_frames => 1,
        message => $msg,
    });
    die( $e );
}

## Devel::StackTrace has a stringification overloaded so users can use the object to get more information or simply use it as a string to get the stack trace equivalent of doing $trace->as_string
sub trace { return( shift->_set_get_object( 'trace', 'Devel::StackTrace', @_ ) ); }

sub type { return( shift->_set_get_scalar( 'type', @_ ) ); }

sub _obj_eq
{
    ##return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $me;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Exception' ) )
    {
        if( $self->message eq $other->message &&
            $self->file eq $other->file &&
            $self->line == $other->line )
        {
            return( 1 );
        }
        else
        {
            return( 0 );
        }
    }
    ## Compare error message
    elsif( !ref( $other ) )
    {
        my $me = $self->message;
        return( $me eq $other );
    }
    ## Otherwise some reference data to which we cannot compare
    return( 0 ) ;
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $code;
    # print( STDERR __PACKAGE__, "::$method(): Called with value '$_[0]'\n" );
    if( $code = $self->can( $method ) )
    {
        return( $code->( @_ ) );
    }
    ## elsif( CORE::exists( $self->{ $method } ) )
    else
    {
        eval( "sub ${class}::${method} { return( shift->_set_get_scalar( '$method', \@_ ) ); }" );
        die( $@ ) if( $@ );
        return( $self->$method( @_ ) );
    }
};

## Purpose of this package is to provide an object that will be invoked in chain without breaking and then return undef at the end
## Normally if a method in the chain returns undef, perl will then complain that the following method in the chain was called on an undefined value. This Null package alleviate this problem.
## This is an original idea from https://stackoverflow.com/users/2766176/brian-d-foy as document in this Stackoverflow thread here: https://stackoverflow.com/a/7068271/4814971
## And also by user "particle" in this perl monks discussion here: https://www.perlmonks.org/?node_id=265214
package Module::Generic::Null;
BEGIN
{
    use strict;
    use Want;
    use overload ('""'     => sub{ '' },
                  'eq'     => sub { _obj_eq(@_) },
                  'ne'     => sub { !_obj_eq(@_) },
                  fallback => 1,
                 );
    use Want;
    our( $VERSION ) = '0.2.0';
};

sub new
{
    my $this = shift( @_ );
    my $class = ref( $this ) || $this;
    my $error_object = shift( @_ );
    my $hash = ( @_ == 1 && ref( $_[0] ) ? shift( @_ ) : { @_ } );
    $hash->{has_error} = $error_object;
    return( bless( $hash => $class ) );
}

sub _obj_eq 
{
    ##return overload::StrVal( $_[0] ) eq overload::StrVal( $_[1] );
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $me;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Null' ) )
    {
        return( $self eq $other );
    }
    ## Compare error message
    elsif( !ref( $other ) )
    {
        return( '' eq $other );
    }
    ## Otherwise some reference data to which we cannot compare
    return( 0 ) ;
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my $debug = $_[0]->{debug};
    # my( $pack, $file, $file ) = caller;
    # my $sub = ( caller( 1 ) )[3];
    # print( STDERR __PACKAGE__, ": Method $method called in package $pack in file $file at line $line from subroutine $sub (AUTOLOAD = $AUTOLOAD)\n" ) if( $debug );
    ## If we are chained, return our null object, so the chain continues to work
    if( want( 'OBJECT' ) )
    {
        ## No, this is NOT a typo. rreturn() is a function of module Want
        rreturn( $_[0] );
    }
    ## Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
    return;
};

DESTROY {};

package Module::Generic::Dynamic;
BEGIN
{
    use strict;
    use parent qw( Module::Generic );
    use warnings::register;
    use Scalar::Util ();
    # use Class::ISA;
    our( $VERSION ) = '0.1.0';
};

sub new
{
    my $this = shift( @_ );
    my $class = ref( $this ) || $this;
    my $self = bless( {} => $class );
    my $data = $self->{_data} = {};
    ## A Module::Generic object standard parameter
    $self->{_data_repo} = '_data';
    my $hash = {};
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( scalar( @_ ) == 1 && Scalar::Util::reftype( $_[0] ) eq 'HASH' )
    {
        $hash = shift( @_ );
    }
    elsif( @_ )
    {
        CORE::warn( "Parameter provided is not an hash reference: '", join( "', '", @_ ), "'\n" ) if( $this->_warnings_is_enabled );
    }
    ## $self->message( 3, "Data provided are: ", sub{ $self->dumper( $hash ) } );
    ## print( STDERR __PACKAGE__, "::new(): Got for hash: '", join( "', '", sort( keys( %$hash ) ) ), "'\n" );
    local $make_class = sub
    {
        my $k = shift( @_ );
        my $new_class = $k;
        $new_class =~ tr/-/_/;
        $new_class =~ s/\_{2,}/_/g;
        $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
        $new_class = "${class}\::${new_class}";
        ## Sanitise the key which will serve as a method name
        my $clean_field = $k;
        $clean_field =~ tr/-/_/;
        $clean_field =~ s/\_{2,}/_/g;
        $clean_field =~ s/[^a-zA-Z0-9\_]+//g;
        $clean_field =~ s/^\d+//g;
        ## print( STDERR __PACKAGE__, "::new(): \$clean_field now is '$clean_field'\n" );
        my $perl = <<EOT;
package $new_class;
BEGIN
{
    use strict;
    use Module::Generic;
    use parent -norequire, qw( Module::Generic::Dynamic );
};

1;

EOT
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Evaluating\n$perl\n" );
        my $rc = eval( $perl );
        # print( STDERR __PACKAGE__, "::_set_get_hash_as_object(): Returned $rc\n" );
        die( "Unable to dynamically create module $new_class: $@" ) if( $@ );
        return( $new_class, $clean_field );
    };
    
    foreach my $k ( sort( keys( %$hash ) ) )
    {
        if( ref( $hash->{ $k } ) eq 'HASH' )
        {
            my $clean_field = $k;
            $clean_field =~ tr/-/_/;
            $clean_field =~ s/\_{2,}/_/g;
            $clean_field =~ s/[^a-zA-Z0-9\_]+//g;
            $clean_field =~ s/^\d+//g;
#             my( $new_class, $clean_field ) = $make_class->( $k );
            # print( STDERR __PACKAGE__, "::new(): Is hash looping? ", ( $hash->{ $k }->{_looping} ? 'yes' : 'no' ), " (", ref( $hash->{ $k }->{_looping} ), ")\n" );
#             my $o = $hash->{ $k }->{_looping} ? $hash->{ $k }->{_looping} : $new_class->new( $hash->{ $k } );
#             $data->{ $clean_field } = $o;
#             $hash->{ $k }->{_looping} = $o;
            eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object( $clean_field, '$new_class', \@_ ) ); }" );
            die( $@ ) if( $@ );
            $self->$clean_field( $hash->{ $k } );
        }
        elsif( ref( $hash->{ $k } ) eq 'ARRAY' )
        {
            my( $new_class, $clean_field ) = $make_class->( $k );
            # print( STDERR __PACKAGE__, "::new() found an array for key $k, creating objects for class $new_class\n" );
            ## We take a peek at what we have to determine how we will handle the data
            my $mode = lc( scalar( @{$hash->{ $k }} ) ? ref( $hash->{ $k }->[0] ) : '' );
            if( $mode eq 'hash' )
            {
                my $all = [];
                foreach my $this ( @{$hash->{ $k }} )
                {
                    my $o = $this->{_looping} ? $this->{_looping} : $new_class->new( $this );
                    $this->{_looping} = $o;
                    CORE::push( @$all, $o );
                }
                # $data->{ $clean_field } = $all;
                eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_object_array_object( '$clean_field', '$new_class', \@_ ) ); }" );
            }
            else
            {
                # $data->{ $clean_field } = $hash->{ $k };
                eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_array_as_object( '$clean_field', \@_ ) ); }" );
            }
            die( $@ ) if( $@ );
            $self->$clean_field( $hash->{ $k } );
        }
        elsif( !ref( $hash->{ $k } ) )
        {
            my $clean_field = $k;
            $clean_field =~ tr/-/_/;
            $clean_field =~ s/\_{2,}/_/g;
            $clean_field =~ s/[^a-zA-Z0-9\_]+//g;
            $clean_field =~ s/^\d+//g;
            eval( "sub ${new_class}::${clean_field} { return( shift->_set_get_scalar_as_object( '$clean_field', \@_ ) ); }" );
            $self->$clean_field( $hash->{ $k } );
        }
        else
        {
            $self->$k( $hash->{ $k } );
        }
    }
    return( $self );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # my( $class, $method ) = our $AUTOLOAD =~ /^(.*?)::([^\:]+)$/;
    no overloading;
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $code;
    # print( STDERR __PACKAGE__, "::$method(): Called\n" );
    if( $code = $self->can( $method ) )
    {
        return( $code->( @_ ) );
    }
    ## elsif( CORE::exists( $self->{ $method } ) )
    else
    {
        my $ref = lc( ref( $_[0] ) );
        my $handler = '_set_get_scalar_as_object';
        # if( @_ && ( $ref eq 'hash' || $ref eq 'array' ) )
        if( $ref eq 'hash' || $ref eq 'array' )
        {
            # print( STDERR __PACKAGE__, "::$method(): using handler $handler for type $ref\n" );
            $handler = "_set_get_${ref}_as_object";
        }
        elsif( $ref eq 'json::pp::boolean' || 
            $ref eq 'module::generic::boolean' ||
            ( $ref eq 'scalar' && ( $$ref == 1 || $$ref == 0 ) ) )
        {
            $handler = '_set_get_boolean';
        }
        eval( "sub ${class}::${method} { return( shift->$handler( '$method', \@_ ) ); }" );
        die( $@ ) if( $@ );
        ## $self->message( 3, "Calling method '$method' with data: ", sub{ $self->printer( @_ ) } );
        return( $self->$method( @_ ) );
    }
};

package Module::Generic::Boolean;
BEGIN
{
    use common::sense;
    use overload
      "0+"     => sub { ${$_[0]} },
      "++"     => sub { $_[0] = ${$_[0]} + 1 },
      "--"     => sub { $_[0] = ${$_[0]} - 1 },
      fallback => 1;
    # *Module::Generic::Boolean:: = *JSON::PP::Boolean::;
    our( $VERSION ) = '0.1.0';
};

sub new { return( $_[1] ? $true : $false ); }

sub defined { return( 1 ); }

our $true  = do{ bless( \( my $dummy = 1 ) => Module::Generic::Boolean ) };
our $false = do{ bless( \( my $dummy = 0 ) => Module::Generic::Boolean ) };

sub true  () { $true  }
sub false () { $false }

sub is_bool  ($) {           UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }
sub is_true  ($) {  $_[0] && UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }
sub is_false ($) { !$_[0] && UNIVERSAL::isa( $_[0], Module::Generic::Boolean ) }

sub TO_JSON
{
    ## JSON does not check that the value is a proper true or false. It stupidly assumes this is a string
    ## The only way to make it understand is to return a scalar ref of 1 or 0
    # return( $_[0] ? 'true' : 'false' );
    return( $_[0] ? \1 : \0 );
}

package Module::Generic::Array;
BEGIN
{
    use common::sense;
    use warnings;
    use warnings::register;
    use Scalar::Util ();
    use Want;
    ## use Data::Dumper;
    use overload (
        # Turned out to be not such a good ide as it create unexpected results, especially when this is an array of overloaded objects
        # '""'  => 'as_string',
        '=='  => sub { _obj_eq(@_) },
        '!='  => sub { !_obj_eq(@_) },
        'eq'  => sub { _obj_eq(@_) },
        'ne'  => sub { !_obj_eq(@_) },
        '%{}' => 'as_hash',
        fallback => 1,
    );
    our( $VERSION ) = 'v0.1.1';
};

sub new
{
    my $this = CORE::shift( @_ );
    my $init = [];
    $init = CORE::shift( @_ ) if( @_ && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) );
    return( bless( $init => ( ref( $this ) || $this ) ) );
}

sub as_hash
{
    my $self = CORE::shift( @_ );
    my $opts = {};
    $opts = CORE::shift( @_ ) if( Scalar::Util::reftype( $opts ) eq 'HASH' );
    ## print( STDERR ref( $self ), "::as_hash\n" );
    my $ref = {};
    my( @offsets ) = $self->keys;
    if( $opts->{start_from} )
    {
        my $start = CORE::int( $opts->{start_from} );
        for my $i ( 0..$#offsets )
        {
            $offsets[ $i ] += $start;
        }
    }
    @$ref{ @$self } = @offsets;
    ## print( ref( $self ), "::as_hash -> dump: ", Data::Dumper::Dumper( $ref ), "\n" );
    return( Module::Generic::Hash->new( $ref ) );
}

sub as_string
{
    my $self = CORE::shift( @_ );
    my $sort = 0;
    $sort = CORE::shift( @_ ) if( @_ );
    return( $self->sort->as_string ) if( $sort );
    return( "@$self" );
}

sub clone { return( $_[0]->new( [ @{$_[0]} ] ) ); }

sub delete
{
    my $self = CORE::shift( @_ );
    my( $offset, $length ) = @_;
    if( defined( $offset ) )
    {
        if( $offset !~ /^\-?\d+$/ )
        {
            warn( "Non integer offset \"$offset\" provided to delete array element\n" ) if( $self->_warnings_is_enabled );
            return( $self );
        }
        if( CORE::defined( $length ) && $length !~ /^\-?\d+$/ )
        {
            warn( $self, "Non integer length \"$length\" provided to delete array element\n" ) if( $self->_warnings_is_enabled );
            return( $self );
        }
        my @removed = CORE::splice( @$self, $offset, CORE::defined( $length ) ? CORE::int( $length ) : 1 );
        if( Want::want( 'LIST' ) )
        {
            rreturn( @removed );
        }
        else
        {
            rreturn( $self->new( \@removed ) );
        }
        # Required to make the compiler happy, as per Want documentation
        return;
    }
    return( $self );
}

sub each
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ ) || do
    {
        warn( "No subroutine callback as provided for each\n" ) if( $self->_warnings_is_enabled );
        return;
    };
    if( ref( $code ) ne 'CODE' )
    {
        warn( "I was expecting a reference to a subroutine for the callback to each, but got '$code' instead.\n" ) if( $self->_warnings_is_enabled );
        return;
    }
    ## Index starts from 0
    while( my( $i, $v ) = CORE::each( @$self ) )
    {
        local $_ = $v;
        CORE::defined( $code->( $i, $v ) ) || CORE::last;
    }
    return( $self );
}

sub exists
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ );
    return( $self->_number( CORE::scalar( CORE::grep( /^$this$/, @$self ) ) ) );
}

sub first
{
    my $self = CORE::shift( @_ );
    return( $self->[0] ) if( CORE::length( $self->[0] ) );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( Module::Generic::Null->new );
    }
    return( $self->[0] );
}

sub for
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    CORE::for( my $i = 0; $i < scalar( @$self ); $i++ )
    {
        local $_ = $self->[ $i ];
        CORE::defined( $code->( $i, $self->[ $i ] ) ) || CORE::last;
    }
    return( $self );
}

sub foreach
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    CORE::foreach my $v ( @$self )
    {
        local $_ = $v;
        CORE::defined( $code->( $v ) ) || CORE::last;
    }
    return( $self );
}

sub get
{
    my $self = CORE::shift( @_ );
    my $offset = CORE::shift( @_ );
    return( $self->[ CORE::int( $offset ) ] );
}

sub grep
{
    my $self = CORE::shift( @_ );
    my $expr = CORE::shift( @_ );
    my $ref;
    if( ref( $expr ) eq 'CODE' )
    {
        $ref = [CORE::grep( $expr->( $_ ), @$self )];
    }
    else
    {
        $expr = ref( $expr ) eq 'Regexp'
            ? $expr
            : qr/\Q$expr\E/;
        $ref = [ CORE::grep( $_ =~ /$expr/, @$self ) ];
    }
    if( Want::want( 'LIST' ) )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub has { return( CORE::shift->exists( @_ ) ); }

sub index
{
    my $self = CORE::shift( @_ );
    my $pos  = CORE::shift( @_ );
    $pos = CORE::int( $pos );
    return( $self->[ $pos ] );
}

sub iterator { return( Module::Generic::Iterator->new( $self ) ); }

sub join
{
    my $self = CORE::shift( @_ );
    return( $self->_scalar( CORE::join( $_[0], @$self ) ) );
}

sub keys
{
    my $self = CORE::shift( @_ );
    return( $self->new( [ CORE::keys( @$self ) ] ) );
}

sub last
{
    my $self = CORE::shift( @_ );
    return( $self->[-1] ) if( CORE::length( $self->[-1] ) );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( Module::Generic::Null->new );
    }
    return( $self->[-1] );
}

sub length { return( $_[0]->_number( scalar( @{$_[0]} ) ) ); }

sub list { return( @{$_[0]} ); }

sub map
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    my $ref = [ CORE::map( $code->( $_ ), @$self ) ];
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->new( $ref ) );
    }
    elsif( Want::want( 'LIST' ) )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub pop
{
    my $self = CORE::shift( @_ );
    return( CORE::pop( @$self ) );
}

sub pos
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ );
    return if( !CORE::length( $this ) );
    my $is_ref = ref( $this );
    my $ref = $is_ref ? Scalar::Util::refaddr( $this ) : $this;
    foreach my $i ( 0 .. $#$self )
    {
        if( ( $is_ref && Scalar::Util::refaddr( $self->[$i] ) eq $ref ) ||
            ( !$is_ref && $self->[$i] eq $this ) )
        {
            return( $i );
        }
    }
    return;
}

sub push
{
    my $self = CORE::shift( @_ );
    CORE::push( @$self, @_ );
    return( $self );
}

sub push_arrayref
{
    my $self = CORE::shift( @_ );
    my $ref = CORE::shift( @_ );
    return( $self->error( "Data provided ($ref) is not an array reference." ) ) if( !UNIVERSAL::isa( $ref, 'ARRAY' ) );
    CORE::push( @$self, @$ref );
    return( $self );
}

sub reset
{
    my $self = CORE::shift( @_ );
    @$self = ();
    return( $self );
}

sub reverse
{
    my $self = CORE::shift( @_ );
    my $ref = [ CORE::reverse( @$self ) ];
    if( wantarray() )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub scalar { return( CORE::shift->length ); }

sub set
{
    my $self = CORE::shift( @_ );
    my $ref = ( scalar( @_ ) == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? CORE::shift( @_ ) : [ @_ ];
    @$self = @$ref;
    return( $self );
}

sub shift
{
    my $self = CORE::shift( @_ );
    return( CORE::shift( @$self ) );
}

sub size { return( $_[0]->_number( $#{$_[0]} ) ); }

sub sort
{
    my $self = CORE::shift( @_ );
    my $code = CORE::shift( @_ );
    my $ref;
    if( ref( $code ) eq 'CODE' )
    {
        $ref = [sort 
        {
            $code->( $a, $b );
        } @$self];
    }
    else
    {
        $ref = [ CORE::sort( @$self ) ];
    }
    if( Want::want( 'LIST' ) )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub splice
{
    my $self = CORE::shift( @_ );
    my( $offset, $length, @list ) = @_;
    if( defined( $offset ) && $offset !~ /^\-?\d+$/ )
    {
        warn( "Offset provided for splice \"$offset\" is not an integer.\n" ) if( $self->_warnings_is_enabled );
        ## If a list was provided, the user is not looking to get an element removed, but add it, so we return out object
        return( $self ) if( scalar( @list ) );
        return;
    }
    if( defined( $length ) && $length !~ /^\-?\d+$/ )
    {
        warn( "Length provided for splice \"$length\" is not an integer.\n" ) if( $self->_warnings_is_enabled );
        return( $self ) if( scalar( @list ) );
        return;
    }
    ## Adding elements, so we return our object and allow chaining
    ## @_ = offset, length, replacement list
    if( scalar( @_ ) > 2 )
    {
        CORE::splice( @$self, $offset, $length, @list );
        return( $self );
    }
    elsif( !scalar( @_ ) )
    {
        CORE::splice( @$self );
        return( $self );
    }
    else
    {
        return( CORE::splice( @$self, $offset, $length ) ) if( CORE::defined( $offset ) && CORE::defined( $length ) );
        return( CORE::splice( @$self, $offset ) ) if( CORE::defined( $offset ) );
    }
}

sub undef
{
    my $self = CORE::shift( @_ );
    @$self = ();
    return( $self );
}

sub unshift
{
    my $self = CORE::shift( @_ );
    CORE::unshift( @$self, @_ );
    return( $self );
}

sub values
{
    my $self = CORE::shift( @_ );
    my $ref = [ CORE::values( @$self ) ];
    if( Want::want( 'LIST' ) )
    {
        return( @$ref );
    }
    else
    {
        return( $self->new( $ref ) );
    }
}

sub _number
{
    my $self = CORE::shift( @_ );
    my $num = CORE::shift( @_ );
    return if( !defined( $num ) );
    return( $num ) if( !CORE::length( $num ) );
    return( Module::Generic::Number->new( $num ) );
}

sub _obj_eq
{
    no overloading;
    my $self = CORE::shift( @_ );
    my $other = CORE::shift( @_ );
    ## Sorted
    my $strA = $self->as_string(1);
    my $strB;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Array' ) )
    {
        $strB = $other->as_string(1);
    }
    ## Compare error message
    elsif( Scalar::Util::reftype( $other ) eq 'ARRAY' )
    {
        $strB = $self->new( $other )->as_string(1);
    }
    else
    {
        return( 0 );
    }
    ## print( STDERR ref( $self ), "::_obj_eq: Comparing array A (", CORE::scalar( @$self ), ") with '$strA' to array B (", CORE::scalar( @$other ), ") with '$strB'\n" );
    return( $strA eq $strB ) ;
}

sub _scalar
{
    my $self = CORE::shift( @_ );
    my $str  = CORE::shift( @_ );
    return if( !defined( $str ) );
    ## Whether empty or not, return an object
    return( Module::Generic::Scalar->new( $str ) );
}

sub _warnings_is_enabled { return( warnings::enabled( ref( $_[0] ) || $_[0] ) ); }


package Module::Generic::Iterator;
BEGIN
{
    use common::sense;
    use warnings;
    use warnings::register;
    use parent -norequire, qw( Module::Generic );
    use Scalar::Util ();
    use Want;
    our( $VERSION ) = 'v0.1.0';
};

sub init
{
    my $self = CORE::shift( @_ );
    my $init = [];
    $init = CORE::shift( @_ ) if( @_ && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    my $elems = Module::Generic::Array->new;
    ## Wrap each element in an Iterator element to enable next, prev, etc
    foreach my $this ( @$init )
    {
        CORE::push( @$elems, Module::Generic::Iterator::Element->new( $this, { parent => $self, debug => $self->debug } ) );
    }
    $self->{elements} = $elems;
    $self->{pos} = 0;
    return( $self );
}

sub elements { return( shift->_set_get_array_as_object( 'elements', @_ ) ); }

sub eof
{
    my $self = shift( @_ );
    my $pos;
    if( @_ )
    {
        $pos  = $self->_find_pos( @_ );
        return if( !CORE::defined( $pos ) );
    }
    else
    {
        $pos = $self->pos;
    }
    return( $pos >= ( $self->elements->length - 1 ) );
}

sub find
{
    my $self = shift( @_ );
    my $pos  = $self->_find_pos( @_ );
    return if( !CORE::defined( $pos ) );
    return( $self->elements->index( $pos ) );
}

sub first
{
    my $self = shift( @_ );
    $self->pos = 0;
    return( $self->elements->index( 0 ) );
}

sub has_next
{
    my $self = shift( @_ );
    my $pos  = $self->pos;
    return( $pos < ( $self->elements->length - 1 ) );
}

sub has_prev
{
    my $self = shift( @_ );
    my $pos  = $self->pos;
    return( $pos > 0 && $self->elements->length > 0 );
}

sub last
{
    my $self = shift( @_ );
    my $pos = $self->elements->length - 1;
    $self->pos = $pos;
    return( $self->elements->index( $pos ) );
}

sub length { return( shift->elements->length ); }

sub next
{
    my $self = shift( @_ );
    my $pos;
    if( @_ )
    {
        $pos = $self->_find_pos( @_ );
        return if( !CORE::defined( $pos ) );
        return if( $pos >= ( $self->elements->length - 1 ) );
        $pos++;
    }
    else
    {
        $pos = $self->pos;
        return if( $self->eof );
        $self->pos++;
    }
    return( $self->elements->index( $pos ) );
}

sub pos : lvalue
{
    my $self = shift( @_ );
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        my( $a ) = want( 'ASSIGN' );
        if( $a !~ /^\d+$/ )
        {
            CORE::warn( "Position provided \"$a\" is not an integer.\n" );
            lnoreturn;
        }
        $self->{pos} = $a;
        lnoreturn;
    }
    elsif( want( 'RVALUE' ) )
    {
        # $self->message( 3, "Returning rvalue" );
        rreturn( $self->{pos} );
    }
    else
    {
        # $self->message( 3, "Else returning pos value" );
        return( $self->{pos} );
    }
    return;
}

sub prev
{
    my $self = shift( @_ );
    my $pos;
    if( @_ )
    {
        $pos  = $self->_find_pos( @_ );
        return if( !CORE::defined( $pos ) );
        return if ( $pos <= 0 );
        $pos--;
    }
    else
    {
        $pos = $self->pos;
        $self->pos-- if( $pos > 0 );
        ## Position of the given element is at the beginning of our array, there is nothing more
        return if( $pos <= 0 );
        $self->pos--;
    }
    return( $self->elements->index( $pos ) );
}

sub reset
{
    my $self = shift( @_ );
    $self->pos = 0;
    return( $self );
}

sub _find_pos
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    # $self->message( 3, "Searching for \"$this\" (", ref( $this ) ? $this->value : $this, ")" );
    return if( !CORE::length( $this ) );
    my $is_ref = ref( $this );
    my $ref = $is_ref ? Scalar::Util::refaddr( $this ) : $this;
    # $self->message( 3, "\"$this\" reference address is \"$ref\"." );
    my $elems = $self->elements;
    # $self->messagef( 3, "Searching in a %d elements long stack.", $elems->length );
    foreach my $i ( 0 .. $#$elems )
    {
        my $val = $elems->[$i]->value;
        # $self->message( 3, "Checking ", ( ref( $this ) ? $this->value : $this ), " ($ref) with element No $i \"$val\" (", Scalar::Util::refaddr( $elems->[$i] ), ")." );
        if( ( $is_ref && Scalar::Util::refaddr( $elems->[$i] ) eq $ref ) ||
            ( !$is_ref && $val eq $this ) )
        {
            return( $i );
        }
    }
    return;
}

package Module::Generic::Iterator::Element;
BEGIN
{
    use common::sense;
    use warnings;
    use warnings::register;
    use parent -norequire, qw( Module::Generic );
    use Want;
    our( $VERSION ) = 'v0.1.0';
};

sub init
{
    my $self = CORE::shift( @_ );
    ## This could be anything
    my $value = CORE::shift( @_ );
    $self->{value}      = '';
    $self->{parent}     = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{value} = $value;
    return( $self );
}

sub has_next
{
    my $self = shift( @_ );
    my $pos = $self->pos;
    return( $pos < ( $self->parent->elements->length - 1 ) );
}

sub has_prev
{
    my $self = shift( @_ );
    my $pos  = $self->pos;
    return( $pos > 0 && $self->parent->elements->length > 0 );
}

sub next
{
    my $self = shift( @_ );
    my $next = $self->parent->next( $self );
    if( want( 'OBJECT' ) )
    {
        return( $next );
    }
    else
    {
        return( $next->value );
    }
}

sub parent { return( shift->_set_get_object( 'parent', 'Module::Generic::Iterator', @_ ) ); }

sub pos { return( $_[0]->parent->_find_pos( $_[0] ) ); }

sub prev
{
    my $self = shift( @_ );
    my $prev = $self->parent->prev( $self );
    if( want( 'OBJECT' ) )
    {
        return( $prev );
    }
    else
    {
        return( $prev->value );
    }
}

sub value { return( shift->{value} ); }


package Module::Generic::Scalar;
BEGIN
{
    use common::sense;
    use warnings;
    use warnings::register;
    ## So that the user can say $obj->isa( 'Module::Generic::Scalar' ) and it would return true
    ## use parent -norequire, qw( Module::Generic::Scalar );
    use Scalar::Util ();
    use Want;
    use overload (
        '""'    => 'as_string',
        '.='    => sub
        {
            my( $self, $other, $swap ) = @_;
            no warnings 'uninitialized';
            if( !CORE::defined( $$self ) )
            {
                return( $other );
            }
            elsif( !CORE::defined( $other ) )
            {
                return( $$self );
            }
            ## print( STDERR ref( $self ), "::concatenate: Got here with other = '$other', and swap = '$swap'\n" );
            ## print( STDERR "Module::Generic::Scalar::overload->.=: Received arguments '", join( "', '", @_ ), "'\n" );
            my $expr;
            if( $swap )
            {
                $expr = "\$other .= \$$self";
                return( $other );
            }
            else
            {
                $$self .= $other;
                return( $self );
            }
        },
        'x'     => sub
        {
            my( $self, $other, $swap ) = @_;
            no warnings 'uninitialized';
            ## print( STDERR "Module::Generic::Scalar::overload->x: Received arguments '", join( "', '", @_ ), "'\n" );
            my $expr = $swap ? "\"$other" x \"$$self\"" : "\"$$self\" x \"$other\"";
            my $res  = eval( $expr );
            if( $@ )
            {
                CORE::warn( $@ );
                return;
            }
            return( $self->new( $res ) );
        },
        'eq'    => sub
        {
            my( $self, $other, $swap ) = @_;
            no warnings 'uninitialized';
            if( Scalar::Util::blessed( $other ) && ref( $other ) eq ref( $self ) )
            {
                return( $$self eq $$other );
            }
            else
            {
                return( $$self eq "$other" );
            }
        },
        fallback => 1,
    );
    our( $VERSION ) = 'v0.2.3';
};

## sub new { return( shift->_new( @_ ) ); }
sub new
{
    my $this = shift( @_ );
    my $init = '';
    if( ref( $_[0] ) eq 'SCALAR' || UNIVERSAL::isa( $_[0], 'SCALAR' ) )
    {
        $init = ${$_[0]};
    }
    elsif( ref( $_[0] ) eq 'ARRAY' || UNIVERSAL::isa( $_[0], 'ARRAY' ) )
    {
        $init = CORE::join( '', @{$_[0]} );
    }
    elsif( ref( $_[0] ) )
    {
        warn( "I do not know what to do with \"", $_[0], "\"\n" ) if( $this->_warnings_is_enabled );
        return;
    }
    elsif( @_ )
    {
        $init = $_[0];
    }
    else
    {
        $init = undef();
    }
    ## print( STDERR __PACKAGE__, "::new: got here for value '$init' (defined? ", CORE::defined( $init ) ? 'yes' : 'no', ")\n" );
    # CORE::tie( $self, 'Module::Generic::Scalar::Tie', $init );
    return( bless( \$init => ( ref( $this ) || $this ) ) );
}

sub append { ${$_[0]} .= $_[1]; return( $_[0] ); }

sub as_boolean { return( Module::Generic::Boolean->new( ${$_[0]} ? 1 : 0 ) ); }

## sub as_string { CORE::defined( ${$_[0]} ) ? return( ${$_[0]} ) : return; }

sub as_string { return( ${$_[0]} ); }

## Credits: John Gruber, Aristotle Pagaltzis
## https://gist.github.com/gruber/9f9e8650d68b13ce4d78
sub capitalise
{
    my $self = CORE::shift( @_ );
    my @small_words = qw( (?<!q&)a an and as at(?!&t) but by en for if in of on or the to v[.]? via vs[.]? );
    my $small_re = CORE::join( '|', @small_words );

    my $apos = qr/ (?: ['’] [[:lower:]]* )? /x;
    
    my $copy = $$self;
	$copy =~ s{\A\s+}{}, s{\s+\z}{};
	$copy = CORE::lc( $copy ) if( not /[[:lower:]]/ );
	$copy =~ s{
		\b (_*) (?:
			( (?<=[ ][/\\]) [[:alpha:]]+ [-_[:alpha:]/\\]+ |   # file path or
			  [-_[:alpha:]]+ [@.:] [-_[:alpha:]@.:/]+ $apos )  # URL, domain, or email
			|
			( (?i: $small_re ) $apos )                         # or small word (case-insensitive)
			|
			( [[:alpha:]] [[:lower:]'’()\[\]{}]* $apos )       # or word w/o internal caps
			|
			( [[:alpha:]] [[:alpha:]'’()\[\]{}]* $apos )       # or some other word
		) (_*) \b
	}{
		$1 . (
		  defined $2 ? $2         # preserve URL, domain, or email
		: defined $3 ? "\L$3"     # lowercase small word
		: defined $4 ? "\u\L$4"   # capitalize word w/o internal caps
		: $5                      # preserve other kinds of word
		) . $6
	}xeg;


	# Exceptions for small words: capitalize at start and end of title
	$copy =~ s{
		(  \A [[:punct:]]*         # start of title...
		|  [:.;?!][ ]+             # or of subsentence...
		|  [ ]['"“‘(\[][ ]*     )  # or of inserted subphrase...
		( $small_re ) \b           # ... followed by small word
	}{$1\u\L$2}xig;

	$copy =~ s{
		\b ( $small_re )      # small word...
		(?= [[:punct:]]* \Z   # ... at the end of the title...
		|   ['"’”)\]] [ ] )   # ... or of an inserted subphrase?
	}{\u\L$1}xig;

	# Exceptions for small words in hyphenated compound words
	## e.g. "in-flight" -> In-Flight
	$copy =~ s{
		\b
		(?<! -)					# Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (in-flight)
		( $small_re )
		(?= -[[:alpha:]]+)		# lookahead for "-someword"
	}{\u\L$1}xig;

	## # e.g. "Stand-in" -> "Stand-In" (Stand is already capped at this point)
	$copy =~ s{
		\b
		(?<!…)					# Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (stand-in)
		( [[:alpha:]]+- )		# $1 = first word and hyphen, should already be properly capped
		( $small_re )           # ... followed by small word
		(?!	- )					# Negative lookahead for another '-'
	}{$1\u$2}xig;

    return( $self->_new( $copy ) );
}

sub chomp { return( CORE::chomp( ${$_[0]} ) ); }

sub chop { return( CORE::chop( ${$_[0]} ) ); }

sub clone
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->_new( @_ ) );
    }
    else
    {
        return( $self->_new( ${$self} ) );
    }
}

sub crypt { return( __PACKAGE__->_new( CORE::crypt( ${$_[0]}, $_[1] ) ) ); }

sub defined { return( CORE::defined( ${$_[0]} ) ); }

sub fc { return( CORE::fc( ${$_[0]} ) eq CORE::fc( $_[1] ) ); }

sub hex { return( $_[0]->_number( CORE::hex( ${$_[0]} ) ) ); }

sub index
{
    my $self = shift( @_ );
    my( $substr, $pos ) = @_;
    return( $self->_number( CORE::index( ${$self}, $substr, $pos ) ) ) if( CORE::defined( $pos ) );
    return( $self->_number( CORE::index( ${$self}, $substr ) ) );
}

sub is_alpha { return( ${$_[0]} =~ /^[[:alpha:]]+$/ ); }

sub is_alpha_numeric { return( ${$_[0]} =~ /^[[:alnum:]]+$/ ); }

sub is_empty { return( CORE::length( ${$_[0]} ) == 0 ); }

sub is_lower { return( ${$_[0]} =~ /^[[:lower:]]+$/ ); }

sub is_numeric { return( Scalar::Util::looks_like_number( ${$_[0]} ) ); }

sub is_upper { return( ${$_[0]} =~ /^[[:upper:]]+$/ ); }

sub lc { return( __PACKAGE__->_new( CORE::lc( ${$_[0]} ) ) ); }

sub lcfirst { return( __PACKAGE__->_new( CORE::lcfirst( ${$_[0]} ) ) ); }

sub left { return( $_[0]->_new( CORE::substr( ${$_[0]}, 0, CORE::int( $_[1] ) ) ) ); }

sub length { return( $_[0]->_number( CORE::length( ${$_[0]} ) ) ); }

sub like
{
    my $self = shift( @_ );
    my $str = shift( @_ );
    $str = CORE::defined( $str ) 
        ? ref( $str ) eq 'Regexp'
            ? $str
            : qr/(?:\Q$str\E)+/
        : qr/[[:blank:]\r\n]*/;
    return( $$self =~ /$str/ );
}

sub ltrim
{
    my $self = shift( @_ );
    my $str = shift( @_ );
    $str = CORE::defined( $str ) 
        ? ref( $str ) eq 'Regexp'
            ? $str
            : qr/(?:\Q$str\E)+/
        : qr/[[:blank:]\r\n]*/;
    $$self =~ s/^$str//g;
    return( $self );
}

sub match
{
    my( $self, $re ) = @_;
    $re = CORE::defined( $re ) 
        ? ref( $re ) eq 'Regexp'
            ? $re
            : qr/(?:\Q$re\E)+/
        : $re;
    return( $$self =~ /$re/ );
}

sub ord { return( $_[0]->_number( CORE::ord( ${$_[0]} ) ) ); }

sub pad
{
    my $self = shift( @_ );
    my( $n, $str ) = @_;
    $str //= ' ';
    if( !CORE::length( $n ) )
    {
        warn( "No number provided to pad the string object.\n" ) if( $self->_warnings_is_enabled );
    }
    elsif( $n !~ /^\-?\d+$/ )
    {
        warn( "Number provided \"$n\" to pad string is not an integer.\n" ) if( $self->_warnings_is_enabled );
    }
    
    if( $n < 0 )
    {
        $$self .= ( "$str" x CORE::abs( $n ) );
    }
    else
    {
        CORE::substr( $$self, 0, 0 ) = ( "$str" x $n );
    }
    return( $self );
}

sub pos { return( $_[0]->_number( @_ > 1 ? ( CORE::pos( ${$_[0]} ) = $_[1] ) : CORE::pos( ${$_[0]} ) ) ); }

sub quotemeta { return( __PACKAGE__->_new( CORE::quotemeta( ${$_[0]} ) ) ); }

sub right { return( $_[0]->_new( CORE::substr( ${$_[0]}, ( CORE::int( $_[1] ) * -1 ) ) ) ); }

sub replace
{
    my( $self, $re, $replacement ) = @_;
    $re = CORE::defined( $re ) 
        ? ref( $re ) eq 'Regexp'
            ? $re
            : qr/(?:\Q$re\E)+/
        : $re;
    return( $$self =~ s/$re/$replacement/gs );
}

sub reset { ${$_[0]} = ''; return( $_[0] ); }

sub reverse { return( __PACKAGE__->_new( CORE::scalar( CORE::reverse( ${$_[0]} ) ) ) ); }

sub rindex
{
    my $self = shift( @_ );
    my( $substr, $pos ) = @_;
    return( $self->_number( CORE::rindex( ${$self}, $substr, $pos ) ) ) if( CORE::defined( $pos ) );
    return( $self->_number( CORE::rindex( ${$self}, $substr ) ) );
}

sub rtrim
{
    my $self = shift( @_ );
    my $str = shift( @_ );
    $str = CORE::defined( $str ) 
        ? ref( $str ) eq 'Regexp'
            ? $str
            : qr/(?:\Q$str\E)+/
        : qr/[[:blank:]\r\n]*/;
    $$self =~ s/${str}$//g;
    return( $self );
}

sub scalar { return( shift->as_string ); }

sub set
{
    my $self = CORE::shift( @_ );
    my $init;
    if( ref( $_[0] ) eq 'SCALAR' || UNIVERSAL::isa( $_[0], 'SCALAR' ) )
    {
        $init = ${$_[0]};
    }
    elsif( ref( $_[0] ) eq 'ARRAY' || UNIVERSAL::isa( $_[0], 'ARRAY' ) )
    {
        $init = CORE::join( '', @{$_[0]} );
    }
    elsif( ref( $_[0] ) )
    {
        warn( "I do not know what to do with \"", $_[0], "\"\n" ) if( $self->_warnings_is_enabled );
        return;
    }
    else
    {
        $init = shift( @_ );
    }
    $$self = $init;
    return( $self );
}

sub split
{
    my $self = CORE::shift( @_ );
    my( $expr, $limit ) = @_;
    CORE::warn( "No argument was provided to split string in Module::Generic::Scalar::split\n" ) if( !scalar( @_ ) );
    my $ref;
    $limit = "$limit";
    if( CORE::defined( $limit ) && $limit =~ /^\d+$/ )
    {
        $ref = [ CORE::split( $expr, $$self, $limit ) ];
    }
    else
    {
        $ref = [ CORE::split( $expr, $$self ) ];
    }
    if( Want::want( 'OBJECT' ) ||
        Want::want( 'SCALAR' ) )
    {
        rreturn( $self->_array( $ref ) );
    }
    elsif( Want::want( 'LIST' ) )
    {
        rreturn( @$ref );
    }
    return;
}

sub sprintf { return( __PACKAGE__->_new( CORE::sprintf( ${$_[0]}, @_[1..$#_] ) ) ); }

sub substr
{
    my $self = CORE::shift( @_ );
    my( $offset, $length, $replacement ) = @_;
    return( __PACKAGE__->_new( CORE::substr( ${$self}, $offset, $length, $replacement ) ) ) if( CORE::defined( $length ) && CORE::defined( $replacement ) );
    return( __PACKAGE__->_new( CORE::substr( ${$self}, $offset, $length ) ) ) if( CORE::defined( $length ) );
    return( __PACKAGE__->_new( CORE::substr( ${$self}, $offset ) ) );
}

## The 3 dash here are just so my editor does not get confused with colouring
sub tr ###
{
    my $self = CORE::shift( @_ );
    my( $search, $replace, $opts ) = @_;
    eval( "\$\$self =~ CORE::tr/$search/$replace/$opts" );
    return( $self );
}

sub trim
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    $str = CORE::defined( $str ) ? CORE::quotemeta( $str ) : qr/[[:blank:]\r\n]*/;
    $$self =~ s/^$str|$str$//gs;
    return( $self );
}

sub uc { return( __PACKAGE__->_new( CORE::uc( ${$_[0]} ) ) ); }

sub ucfirst { return( __PACKAGE__->_new( CORE::ucfirst( ${$_[0]} ) ) ); }

sub undef
{
    my $self = shift( @_ );
    $$self = undef;
    return( $self );
}

sub _array
{
    my $self = shift( @_ );
    my $arr  = shift( @_ );
    return if( !defined( $arr ) );
    return( $arr ) if( Scalar::Util::reftype( $arr ) ne 'ARRAY' );
    return( Module::Generic::Array->new( $arr ) );
}

sub _number
{
    my $self = shift( @_ );
    my $num = shift( @_ );
    return if( !defined( $num ) );
    return( $num ) if( !CORE::length( $num ) );
    return( Module::Generic::Number->new( $num ) );
}

sub _new { return( shift->Module::Generic::Scalar::new( @_ ) ); }

sub _warnings_is_enabled { return( warnings::enabled( ref( $_[0] ) || $_[0] ) ); }


package Module::Generic::Number;
BEGIN
{
    use strict;
    use parent -norequire, qw( Module::Generic );
    use warnings::register;
    use Number::Format;
    use Nice::Try;
    use Regexp::Common qw( number );
    use POSIX ();
    our( $VERSION ) = 'v0.4.0';
};

use overload (
    ## I know there is the nomethod feature, but I need to provide return_object set to true or false
    ## And I do not necessarily want to catch all the operation.
    '""' => sub { return( shift->{_number} ); },
    '-' => sub { return( shift->compute( @_, { op => '-', return_object => 1 }) ); },
    '+' => sub { return( shift->compute( @_, { op => '+', return_object => 1 }) ); },
    '*' => sub { return( shift->compute( @_, { op => '*', return_object => 1 }) ); },
    '/' => sub { return( shift->compute( @_, { op => '/', return_object => 1 }) ); },
    '%' => sub { return( shift->compute( @_, { op => '%', return_object => 1 }) ); },
    ## Exponent
    '**' => sub { return( shift->compute( @_, { op => '**', return_object => 1 }) ); },
    ## Bitwise AND
    '&' => sub { return( shift->compute( @_, { op => '&', return_object => 1 }) ); },
    ## Bitwise OR
    '|' => sub { return( shift->compute( @_, { op => '|', return_object => 1 }) ); },
    ## Bitwise XOR
    '^' => sub { return( shift->compute( @_, { op => '^', return_object => 1 }) ); },
    ## Bitwise shift left
    '<<' => sub { return( shift->compute( @_, { op => '<<', return_object => 1 }) ); },
    ## Bitwise shift right
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
    ## '.=' => sub { return( shift->compute( @_, { op => '.=', return_object => 1 }) ); },
    '.=' => sub
    {
        my( $self, $other, $swap ) = @_;
        my $op = '.=';
        my $operation = $swap ? "${other} ${op} \$self->{_number}" : "\$self->{_number} ${op} ${other}";
        my $res = eval( $operation );
        warn( "Error with formula \"$operation\": $@" ) if( $@ && $self->_warnings_is_enabled );
        return if( $@ );
        ## Concatenated something. If it still look like a number, we return it as an object
        if( $res =~ /^$RE{num}{real}$/ )
        {
            return( $self->clone( $res ) );
        }
        ## Otherwise we pass it to the scalar module
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

our $SUPPORTED_LOCALES =
{
aa_DJ   => [qw( aa_DJ.UTF-8 aa_DJ.ISO-8859-1 aa_DJ.ISO8859-1 )],
aa_ER   => [qw( aa_ER.UTF-8 )],
aa_ET   => [qw( aa_ET.UTF-8 )],
af_ZA   => [qw( af_ZA.UTF-8 af_ZA.ISO-8859-1 af_ZA.ISO8859-1 )],
ak_GH   => [qw( ak_GH.UTF-8 )],
am_ET   => [qw( am_ET.UTF-8 )],
an_ES   => [qw( an_ES.UTF-8 an_ES.ISO-8859-15 an_ES.ISO8859-15 )],
anp_IN  => [qw( anp_IN.UTF-8 )],
ar_AE   => [qw( ar_AE.UTF-8 ar_AE.ISO-8859-6 ar_AE.ISO8859-6 )],
ar_BH   => [qw( ar_BH.UTF-8 ar_BH.ISO-8859-6 ar_BH.ISO8859-6 )],
ar_DZ   => [qw( ar_DZ.UTF-8 ar_DZ.ISO-8859-6 ar_DZ.ISO8859-6 )],
ar_EG   => [qw( ar_EG.UTF-8 ar_EG.ISO-8859-6 ar_EG.ISO8859-6 )],
ar_IN   => [qw( ar_IN.UTF-8 )],
ar_IQ   => [qw( ar_IQ.UTF-8 ar_IQ.ISO-8859-6 ar_IQ.ISO8859-6 )],
ar_JO   => [qw( ar_JO.UTF-8 ar_JO.ISO-8859-6 ar_JO.ISO8859-6 )],
ar_KW   => [qw( ar_KW.UTF-8 ar_KW.ISO-8859-6 ar_KW.ISO8859-6 )],
ar_LB   => [qw( ar_LB.UTF-8 ar_LB.ISO-8859-6 ar_LB.ISO8859-6 )],
ar_LY   => [qw( ar_LY.UTF-8 ar_LY.ISO-8859-6 ar_LY.ISO8859-6 )],
ar_MA   => [qw( ar_MA.UTF-8 ar_MA.ISO-8859-6 ar_MA.ISO8859-6 )],
ar_OM   => [qw( ar_OM.UTF-8 ar_OM.ISO-8859-6 ar_OM.ISO8859-6 )],
ar_QA   => [qw( ar_QA.UTF-8 ar_QA.ISO-8859-6 ar_QA.ISO8859-6 )],
ar_SA   => [qw( ar_SA.UTF-8 ar_SA.ISO-8859-6 ar_SA.ISO8859-6 )],
ar_SD   => [qw( ar_SD.UTF-8 ar_SD.ISO-8859-6 ar_SD.ISO8859-6 )],
ar_SS   => [qw( ar_SS.UTF-8 )],
ar_SY   => [qw( ar_SY.UTF-8 ar_SY.ISO-8859-6 ar_SY.ISO8859-6 )],
ar_TN   => [qw( ar_TN.UTF-8 ar_TN.ISO-8859-6 ar_TN.ISO8859-6 )],
ar_YE   => [qw( ar_YE.UTF-8 ar_YE.ISO-8859-6 ar_YE.ISO8859-6 )],
as_IN   => [qw( as_IN.UTF-8 )],
ast_ES  => [qw( ast_ES.UTF-8 ast_ES.ISO-8859-15 ast_ES.ISO8859-15 )],
ayc_PE  => [qw( ayc_PE.UTF-8 )],
az_AZ   => [qw( az_AZ.UTF-8 )],
be_BY   => [qw( be_BY.UTF-8 be_BY.CP1251 )],
bem_ZM  => [qw( bem_ZM.UTF-8 )],
ber_DZ  => [qw( ber_DZ.UTF-8 )],
ber_MA  => [qw( ber_MA.UTF-8 )],
bg_BG   => [qw( bg_BG.UTF-8 bg_BG.CP1251 )],
bhb_IN  => [qw( bhb_IN.UTF-8 )],
bho_IN  => [qw( bho_IN.UTF-8 )],
bn_BD   => [qw( bn_BD.UTF-8 )],
bn_IN   => [qw( bn_IN.UTF-8 )],
bo_CN   => [qw( bo_CN.UTF-8 )],
bo_IN   => [qw( bo_IN.UTF-8 )],
br_FR   => [qw( br_FR.UTF-8 br_FR.ISO-8859-1 br_FR.ISO8859-1 br_FR.ISO-8859-15 br_FR.ISO8859-15 )],
brx_IN  => [qw( brx_IN.UTF-8 )],
bs_BA   => [qw( bs_BA.UTF-8 bs_BA.ISO-8859-2 bs_BA.ISO8859-2 )],
byn_ER  => [qw( byn_ER.UTF-8 )],
ca_AD   => [qw( ca_AD.UTF-8 ca_AD.ISO-8859-15 ca_AD.ISO8859-15 )],
ca_ES   => [qw( ca_ES.UTF-8 ca_ES.ISO-8859-1 ca_ES.ISO8859-1 ca_ES.ISO-8859-15 ca_ES.ISO8859-15 )],
ca_FR   => [qw( ca_FR.UTF-8 ca_FR.ISO-8859-15 ca_FR.ISO8859-15 )],
ca_IT   => [qw( ca_IT.UTF-8 ca_IT.ISO-8859-15 ca_IT.ISO8859-15 )],
ce_RU   => [qw( ce_RU.UTF-8 )],
ckb_IQ  => [qw( ckb_IQ.UTF-8 )],
cmn_TW  => [qw( cmn_TW.UTF-8 )],
crh_UA  => [qw( crh_UA.UTF-8 )],
cs_CZ   => [qw( cs_CZ.UTF-8 cs_CZ.ISO-8859-2 cs_CZ.ISO8859-2 )],
csb_PL  => [qw( csb_PL.UTF-8 )],
cv_RU   => [qw( cv_RU.UTF-8 )],
cy_GB   => [qw( cy_GB.UTF-8 cy_GB.ISO-8859-14 cy_GB.ISO8859-14 )],
da_DK   => [qw( da_DK.UTF-8 da_DK.ISO-8859-1 da_DK.ISO8859-1 )],
de_AT   => [qw( de_AT.UTF-8 de_AT.ISO-8859-1 de_AT.ISO8859-1 de_AT.ISO-8859-15 de_AT.ISO8859-15 )],
de_BE   => [qw( de_BE.UTF-8 de_BE.ISO-8859-1 de_BE.ISO8859-1 de_BE.ISO-8859-15 de_BE.ISO8859-15 )],
de_CH   => [qw( de_CH.UTF-8 de_CH.ISO-8859-1 de_CH.ISO8859-1 )],
de_DE   => [qw( de_DE.UTF-8 de_DE.ISO-8859-1 de_DE.ISO8859-1 de_DE.ISO-8859-15 de_DE.ISO8859-15 )],
de_LI   => [qw( de_LI.UTF-8 )],
de_LU   => [qw( de_LU.UTF-8 de_LU.ISO-8859-1 de_LU.ISO8859-1 de_LU.ISO-8859-15 de_LU.ISO8859-15 )],
doi_IN  => [qw( doi_IN.UTF-8 )],
dv_MV   => [qw( dv_MV.UTF-8 )],
dz_BT   => [qw( dz_BT.UTF-8 )],
el_CY   => [qw( el_CY.UTF-8 el_CY.ISO-8859-7 el_CY.ISO8859-7 )],
el_GR   => [qw( el_GR.UTF-8 el_GR.ISO-8859-7 el_GR.ISO8859-7 )],
en_AG   => [qw( en_AG.UTF-8 )],
en_AU   => [qw( en_AU.UTF-8 en_AU.ISO-8859-1 en_AU.ISO8859-1 )],
en_BW   => [qw( en_BW.UTF-8 en_BW.ISO-8859-1 en_BW.ISO8859-1 )],
en_CA   => [qw( en_CA.UTF-8 en_CA.ISO-8859-1 en_CA.ISO8859-1 )],
en_DK   => [qw( en_DK.UTF-8 en_DK.ISO-8859-15 en_DK.ISO8859-15 )],
en_GB   => [qw( en_GB.UTF-8 en_GB.ISO-8859-1 en_GB.ISO8859-1 en_GB.ISO-8859-15 en_GB.ISO8859-15 )],
en_HK   => [qw( en_HK.UTF-8 en_HK.ISO-8859-1 en_HK.ISO8859-1 )],
en_IE   => [qw( en_IE.UTF-8 en_IE.ISO-8859-1 en_IE.ISO8859-1 en_IE.ISO-8859-15 en_IE.ISO8859-15 )],
en_IN   => [qw( en_IN.UTF-8 )],
en_NG   => [qw( en_NG.UTF-8 )],
en_NZ   => [qw( en_NZ.UTF-8 en_NZ.ISO-8859-1 en_NZ.ISO8859-1 )],
en_PH   => [qw( en_PH.UTF-8 en_PH.ISO-8859-1 en_PH.ISO8859-1 )],
en_SG   => [qw( en_SG.UTF-8 en_SG.ISO-8859-1 en_SG.ISO8859-1 )],
en_US   => [qw( en_US.UTF-8 en_US.ISO-8859-1 en_US.ISO8859-1 en_US.ISO-8859-15 en_US.ISO8859-15 )],
en_ZA   => [qw( en_ZA.UTF-8 en_ZA.ISO-8859-1 en_ZA.ISO8859-1 )],
en_ZM   => [qw( en_ZM.UTF-8 )],
en_ZW   => [qw( en_ZW.UTF-8 en_ZW.ISO-8859-1 en_ZW.ISO8859-1 )],
eo      => [qw( eo.UTF-8 eo.ISO-8859-3 eo.ISO8859-3 )],
eo_US   => [qw( eo_US.UTF-8 )],
es_AR   => [qw( es_AR.UTF-8 es_AR.ISO-8859-1 es_AR.ISO8859-1 )],
es_BO   => [qw( es_BO.UTF-8 es_BO.ISO-8859-1 es_BO.ISO8859-1 )],
es_CL   => [qw( es_CL.UTF-8 es_CL.ISO-8859-1 es_CL.ISO8859-1 )],
es_CO   => [qw( es_CO.UTF-8 es_CO.ISO-8859-1 es_CO.ISO8859-1 )],
es_CR   => [qw( es_CR.UTF-8 es_CR.ISO-8859-1 es_CR.ISO8859-1 )],
es_CU   => [qw( es_CU.UTF-8 )],
es_DO   => [qw( es_DO.UTF-8 es_DO.ISO-8859-1 es_DO.ISO8859-1 )],
es_EC   => [qw( es_EC.UTF-8 es_EC.ISO-8859-1 es_EC.ISO8859-1 )],
es_ES   => [qw( es_ES.UTF-8 es_ES.ISO-8859-1 es_ES.ISO8859-1 es_ES.ISO-8859-15 es_ES.ISO8859-15 )],
es_GT   => [qw( es_GT.UTF-8 es_GT.ISO-8859-1 es_GT.ISO8859-1 )],
es_HN   => [qw( es_HN.UTF-8 es_HN.ISO-8859-1 es_HN.ISO8859-1 )],
es_MX   => [qw( es_MX.UTF-8 es_MX.ISO-8859-1 es_MX.ISO8859-1 )],
es_NI   => [qw( es_NI.UTF-8 es_NI.ISO-8859-1 es_NI.ISO8859-1 )],
es_PA   => [qw( es_PA.UTF-8 es_PA.ISO-8859-1 es_PA.ISO8859-1 )],
es_PE   => [qw( es_PE.UTF-8 es_PE.ISO-8859-1 es_PE.ISO8859-1 )],
es_PR   => [qw( es_PR.UTF-8 es_PR.ISO-8859-1 es_PR.ISO8859-1 )],
es_PY   => [qw( es_PY.UTF-8 es_PY.ISO-8859-1 es_PY.ISO8859-1 )],
es_SV   => [qw( es_SV.UTF-8 es_SV.ISO-8859-1 es_SV.ISO8859-1 )],
es_US   => [qw( es_US.UTF-8 es_US.ISO-8859-1 es_US.ISO8859-1 )],
es_UY   => [qw( es_UY.UTF-8 es_UY.ISO-8859-1 es_UY.ISO8859-1 )],
es_VE   => [qw( es_VE.UTF-8 es_VE.ISO-8859-1 es_VE.ISO8859-1 )],
et_EE   => [qw( et_EE.UTF-8 et_EE.ISO-8859-1 et_EE.ISO8859-1 et_EE.ISO-8859-15 et_EE.ISO8859-15 )],
eu_ES   => [qw( eu_ES.UTF-8 eu_ES.ISO-8859-1 eu_ES.ISO8859-1 eu_ES.ISO-8859-15 eu_ES.ISO8859-15 )],
eu_FR   => [qw( eu_FR.UTF-8 eu_FR.ISO-8859-1 eu_FR.ISO8859-1 eu_FR.ISO-8859-15 eu_FR.ISO8859-15 )],
fa_IR   => [qw( fa_IR.UTF-8 )],
ff_SN   => [qw( ff_SN.UTF-8 )],
fi_FI   => [qw( fi_FI.UTF-8 fi_FI.ISO-8859-1 fi_FI.ISO8859-1 fi_FI.ISO-8859-15 fi_FI.ISO8859-15 )],
fil_PH  => [qw( fil_PH.UTF-8 )],
fo_FO   => [qw( fo_FO.UTF-8 fo_FO.ISO-8859-1 fo_FO.ISO8859-1 )],
fr_BE   => [qw( fr_BE.UTF-8 fr_BE.ISO-8859-1 fr_BE.ISO8859-1 fr_BE.ISO-8859-15 fr_BE.ISO8859-15 )],
fr_CA   => [qw( fr_CA.UTF-8 fr_CA.ISO-8859-1 fr_CA.ISO8859-1 )],
fr_CH   => [qw( fr_CH.UTF-8 fr_CH.ISO-8859-1 fr_CH.ISO8859-1 )],
fr_FR   => [qw( fr_FR.UTF-8 fr_FR.ISO-8859-1 fr_FR.ISO8859-1 fr_FR.ISO-8859-15 fr_FR.ISO8859-15 )],
fr_LU   => [qw( fr_LU.UTF-8 fr_LU.ISO-8859-1 fr_LU.ISO8859-1 fr_LU.ISO-8859-15 fr_LU.ISO8859-15 )],
fur_IT  => [qw( fur_IT.UTF-8 )],
fy_DE   => [qw( fy_DE.UTF-8 )],
fy_NL   => [qw( fy_NL.UTF-8 )],
ga_IE   => [qw( ga_IE.UTF-8 ga_IE.ISO-8859-1 ga_IE.ISO8859-1 ga_IE.ISO-8859-15 ga_IE.ISO8859-15 )],
gd_GB   => [qw( gd_GB.UTF-8 gd_GB.ISO-8859-15 gd_GB.ISO8859-15 )],
gez_ER  => [qw( gez_ER.UTF-8 )],
gez_ET  => [qw( gez_ET.UTF-8 )],
gl_ES   => [qw( gl_ES.UTF-8 gl_ES.ISO-8859-1 gl_ES.ISO8859-1 gl_ES.ISO-8859-15 gl_ES.ISO8859-15 )],
gu_IN   => [qw( gu_IN.UTF-8 )],
gv_GB   => [qw( gv_GB.UTF-8 gv_GB.ISO-8859-1 gv_GB.ISO8859-1 )],
ha_NG   => [qw( ha_NG.UTF-8 )],
hak_TW  => [qw( hak_TW.UTF-8 )],
he_IL   => [qw( he_IL.UTF-8 he_IL.ISO-8859-8 he_IL.ISO8859-8 )],
hi_IN   => [qw( hi_IN.UTF-8 )],
hne_IN  => [qw( hne_IN.UTF-8 )],
hr_HR   => [qw( hr_HR.UTF-8 hr_HR.ISO-8859-2 hr_HR.ISO8859-2 )],
hsb_DE  => [qw( hsb_DE.UTF-8 hsb_DE.ISO-8859-2 hsb_DE.ISO8859-2 )],
ht_HT   => [qw( ht_HT.UTF-8 )],
hu_HU   => [qw( hu_HU.UTF-8 hu_HU.ISO-8859-2 hu_HU.ISO8859-2 )],
hy_AM   => [qw( hy_AM.UTF-8 hy_AM.ARMSCII-8 hy_AM.ARMSCII8 )],
ia_FR   => [qw( ia_FR.UTF-8 )],
id_ID   => [qw( id_ID.UTF-8 id_ID.ISO-8859-1 id_ID.ISO8859-1 )],
ig_NG   => [qw( ig_NG.UTF-8 )],
ik_CA   => [qw( ik_CA.UTF-8 )],
is_IS   => [qw( is_IS.UTF-8 is_IS.ISO-8859-1 is_IS.ISO8859-1 )],
it_CH   => [qw( it_CH.UTF-8 it_CH.ISO-8859-1 it_CH.ISO8859-1 )],
it_IT   => [qw( it_IT.UTF-8 it_IT.ISO-8859-1 it_IT.ISO8859-1 it_IT.ISO-8859-15 it_IT.ISO8859-15 )],
iu_CA   => [qw( iu_CA.UTF-8 )],
iw_IL   => [qw( iw_IL.UTF-8 iw_IL.ISO-8859-8 iw_IL.ISO8859-8 )],
ja_JP   => [qw( ja_JP.UTF-8 ja_JP.EUC-JP ja_JP.EUCJP )],
ka_GE   => [qw( ka_GE.UTF-8 ka_GE.GEORGIAN-PS ka_GE.GEORGIANPS )],
kk_KZ   => [qw( kk_KZ.UTF-8 kk_KZ.PT154 kk_KZ.RK1048 )],
kl_GL   => [qw( kl_GL.UTF-8 kl_GL.ISO-8859-1 kl_GL.ISO8859-1 )],
km_KH   => [qw( km_KH.UTF-8 )],
kn_IN   => [qw( kn_IN.UTF-8 )],
ko_KR   => [qw( ko_KR.UTF-8 ko_KR.EUC-KR ko_KR.EUCKR )],
kok_IN  => [qw( kok_IN.UTF-8 )],
ks_IN   => [qw( ks_IN.UTF-8 )],
ku_TR   => [qw( ku_TR.UTF-8 ku_TR.ISO-8859-9 ku_TR.ISO8859-9 )],
kw_GB   => [qw( kw_GB.UTF-8 kw_GB.ISO-8859-1 kw_GB.ISO8859-1 )],
ky_KG   => [qw( ky_KG.UTF-8 )],
lb_LU   => [qw( lb_LU.UTF-8 )],
lg_UG   => [qw( lg_UG.UTF-8 lg_UG.ISO-8859-10 lg_UG.ISO8859-10 )],
li_BE   => [qw( li_BE.UTF-8 )],
li_NL   => [qw( li_NL.UTF-8 )],
lij_IT  => [qw( lij_IT.UTF-8 )],
ln_CD   => [qw( ln_CD.UTF-8 )],
lo_LA   => [qw( lo_LA.UTF-8 )],
lt_LT   => [qw( lt_LT.UTF-8 lt_LT.ISO-8859-13 lt_LT.ISO8859-13 )],
lv_LV   => [qw( lv_LV.UTF-8 lv_LV.ISO-8859-13 lv_LV.ISO8859-13 )],
lzh_TW  => [qw( lzh_TW.UTF-8 )],
mag_IN  => [qw( mag_IN.UTF-8 )],
mai_IN  => [qw( mai_IN.UTF-8 )],
mg_MG   => [qw( mg_MG.UTF-8 mg_MG.ISO-8859-15 mg_MG.ISO8859-15 )],
mhr_RU  => [qw( mhr_RU.UTF-8 )],
mi_NZ   => [qw( mi_NZ.UTF-8 mi_NZ.ISO-8859-13 mi_NZ.ISO8859-13 )],
mk_MK   => [qw( mk_MK.UTF-8 mk_MK.ISO-8859-5 mk_MK.ISO8859-5 )],
ml_IN   => [qw( ml_IN.UTF-8 )],
mn_MN   => [qw( mn_MN.UTF-8 )],
mni_IN  => [qw( mni_IN.UTF-8 )],
mr_IN   => [qw( mr_IN.UTF-8 )],
ms_MY   => [qw( ms_MY.UTF-8 ms_MY.ISO-8859-1 ms_MY.ISO8859-1 )],
mt_MT   => [qw( mt_MT.UTF-8 mt_MT.ISO-8859-3 mt_MT.ISO8859-3 )],
my_MM   => [qw( my_MM.UTF-8 )],
nan_TW  => [qw( nan_TW.UTF-8 )],
nb_NO   => [qw( nb_NO.UTF-8 nb_NO.ISO-8859-1 nb_NO.ISO8859-1 )],
nds_DE  => [qw( nds_DE.UTF-8 )],
nds_NL  => [qw( nds_NL.UTF-8 )],
ne_NP   => [qw( ne_NP.UTF-8 )],
nhn_MX  => [qw( nhn_MX.UTF-8 )],
niu_NU  => [qw( niu_NU.UTF-8 )],
niu_NZ  => [qw( niu_NZ.UTF-8 )],
nl_AW   => [qw( nl_AW.UTF-8 )],
nl_BE   => [qw( nl_BE.UTF-8 nl_BE.ISO-8859-1 nl_BE.ISO8859-1 nl_BE.ISO-8859-15 nl_BE.ISO8859-15 )],
nl_NL   => [qw( nl_NL.UTF-8 nl_NL.ISO-8859-1 nl_NL.ISO8859-1 nl_NL.ISO-8859-15 nl_NL.ISO8859-15 )],
nn_NO   => [qw( nn_NO.UTF-8 nn_NO.ISO-8859-1 nn_NO.ISO8859-1 )],
nr_ZA   => [qw( nr_ZA.UTF-8 )],
nso_ZA  => [qw( nso_ZA.UTF-8 )],
oc_FR   => [qw( oc_FR.UTF-8 oc_FR.ISO-8859-1 oc_FR.ISO8859-1 )],
om_ET   => [qw( om_ET.UTF-8 )],
om_KE   => [qw( om_KE.UTF-8 om_KE.ISO-8859-1 om_KE.ISO8859-1 )],
or_IN   => [qw( or_IN.UTF-8 )],
os_RU   => [qw( os_RU.UTF-8 )],
pa_IN   => [qw( pa_IN.UTF-8 )],
pa_PK   => [qw( pa_PK.UTF-8 )],
pap_AN  => [qw( pap_AN.UTF-8 )],
pap_AW  => [qw( pap_AW.UTF-8 )],
pap_CW  => [qw( pap_CW.UTF-8 )],
pl_PL   => [qw( pl_PL.UTF-8 pl_PL.ISO-8859-2 pl_PL.ISO8859-2 )],
ps_AF   => [qw( ps_AF.UTF-8 )],
pt_BR   => [qw( pt_BR.UTF-8 pt_BR.ISO-8859-1 pt_BR.ISO8859-1 )],
pt_PT   => [qw( pt_PT.UTF-8 pt_PT.ISO-8859-1 pt_PT.ISO8859-1 pt_PT.ISO-8859-15 pt_PT.ISO8859-15 )],
quz_PE  => [qw( quz_PE.UTF-8 )],
raj_IN  => [qw( raj_IN.UTF-8 )],
ro_RO   => [qw( ro_RO.UTF-8 ro_RO.ISO-8859-2 ro_RO.ISO8859-2 )],
ru_RU   => [qw( ru_RU.UTF-8 ru_RU.KOI8-R ru_RU.KOI8R ru_RU.ISO-8859-5 ru_RU.ISO8859-5 ru_RU.CP1251 )],
ru_UA   => [qw( ru_UA.UTF-8 ru_UA.KOI8-U ru_UA.KOI8U )],
rw_RW   => [qw( rw_RW.UTF-8 )],
sa_IN   => [qw( sa_IN.UTF-8 )],
sat_IN  => [qw( sat_IN.UTF-8 )],
sc_IT   => [qw( sc_IT.UTF-8 )],
sd_IN   => [qw( sd_IN.UTF-8 )],
sd_PK   => [qw( sd_PK.UTF-8 )],
se_NO   => [qw( se_NO.UTF-8 )],
shs_CA  => [qw( shs_CA.UTF-8 )],
si_LK   => [qw( si_LK.UTF-8 )],
sid_ET  => [qw( sid_ET.UTF-8 )],
sk_SK   => [qw( sk_SK.UTF-8 sk_SK.ISO-8859-2 sk_SK.ISO8859-2 )],
sl_SI   => [qw( sl_SI.UTF-8 sl_SI.ISO-8859-2 sl_SI.ISO8859-2 )],
so_DJ   => [qw( so_DJ.UTF-8 so_DJ.ISO-8859-1 so_DJ.ISO8859-1 )],
so_ET   => [qw( so_ET.UTF-8 )],
so_KE   => [qw( so_KE.UTF-8 so_KE.ISO-8859-1 so_KE.ISO8859-1 )],
so_SO   => [qw( so_SO.UTF-8 so_SO.ISO-8859-1 so_SO.ISO8859-1 )],
sq_AL   => [qw( sq_AL.UTF-8 sq_AL.ISO-8859-1 sq_AL.ISO8859-1 )],
sq_MK   => [qw( sq_MK.UTF-8 )],
sr_ME   => [qw( sr_ME.UTF-8 )],
sr_RS   => [qw( sr_RS.UTF-8 )],
ss_ZA   => [qw( ss_ZA.UTF-8 )],
st_ZA   => [qw( st_ZA.UTF-8 st_ZA.ISO-8859-1 st_ZA.ISO8859-1 )],
sv_FI   => [qw( sv_FI.UTF-8 sv_FI.ISO-8859-1 sv_FI.ISO8859-1 sv_FI.ISO-8859-15 sv_FI.ISO8859-15 )],
sv_SE   => [qw( sv_SE.UTF-8 sv_SE.ISO-8859-1 sv_SE.ISO8859-1 sv_SE.ISO-8859-15 sv_SE.ISO8859-15 )],
sw_KE   => [qw( sw_KE.UTF-8 )],
sw_TZ   => [qw( sw_TZ.UTF-8 )],
szl_PL  => [qw( szl_PL.UTF-8 )],
ta_IN   => [qw( ta_IN.UTF-8 )],
ta_LK   => [qw( ta_LK.UTF-8 )],
tcy_IN  => [qw( tcy_IN.UTF-8 )],
te_IN   => [qw( te_IN.UTF-8 )],
tg_TJ   => [qw( tg_TJ.UTF-8 tg_TJ.KOI8-T tg_TJ.KOI8T )],
th_TH   => [qw( th_TH.UTF-8 th_TH.TIS-620 th_TH.TIS620 )],
the_NP  => [qw( the_NP.UTF-8 )],
ti_ER   => [qw( ti_ER.UTF-8 )],
ti_ET   => [qw( ti_ET.UTF-8 )],
tig_ER  => [qw( tig_ER.UTF-8 )],
tk_TM   => [qw( tk_TM.UTF-8 )],
tl_PH   => [qw( tl_PH.UTF-8 tl_PH.ISO-8859-1 tl_PH.ISO8859-1 )],
tn_ZA   => [qw( tn_ZA.UTF-8 )],
tr_CY   => [qw( tr_CY.UTF-8 tr_CY.ISO-8859-9 tr_CY.ISO8859-9 )],
tr_TR   => [qw( tr_TR.UTF-8 tr_TR.ISO-8859-9 tr_TR.ISO8859-9 )],
ts_ZA   => [qw( ts_ZA.UTF-8 )],
tt_RU   => [qw( tt_RU.UTF-8 )],
ug_CN   => [qw( ug_CN.UTF-8 )],
uk_UA   => [qw( uk_UA.UTF-8 uk_UA.KOI8-U uk_UA.KOI8U )],
unm_US  => [qw( unm_US.UTF-8 )],
ur_IN   => [qw( ur_IN.UTF-8 )],
ur_PK   => [qw( ur_PK.UTF-8 )],
uz_UZ   => [qw( uz_UZ.UTF-8 uz_UZ.ISO-8859-1 uz_UZ.ISO8859-1 )],
ve_ZA   => [qw( ve_ZA.UTF-8 )],
vi_VN   => [qw( vi_VN.UTF-8 )],
wa_BE   => [qw( wa_BE.UTF-8 wa_BE.ISO-8859-1 wa_BE.ISO8859-1 wa_BE.ISO-8859-15 wa_BE.ISO8859-15 )],
wae_CH  => [qw( wae_CH.UTF-8 )],
wal_ET  => [qw( wal_ET.UTF-8 )],
wo_SN   => [qw( wo_SN.UTF-8 )],
xh_ZA   => [qw( xh_ZA.UTF-8 xh_ZA.ISO-8859-1 xh_ZA.ISO8859-1 )],
yi_US   => [qw( yi_US.UTF-8 yi_US.CP1255 )],
yo_NG   => [qw( yo_NG.UTF-8 )],
yue_HK  => [qw( yue_HK.UTF-8 )],
zh_CN   => [qw( zh_CN.UTF-8 zh_CN.GB18030 zh_CN.GBK zh_CN.GB2312 )],
zh_HK   => [qw( zh_HK.UTF-8 zh_HK.BIG5-HKSCS zh_HK.BIG5HKSCS )],
zh_SG   => [qw( zh_SG.UTF-8 zh_SG.GBK zh_SG.GB2312 )],
zh_TW   => [qw( zh_TW.UTF-8 zh_TW.EUC-TW zh_TW.EUCTW zh_TW.BIG5 )],
zu_ZA   => [qw( zu_ZA.UTF-8 zu_ZA.ISO-8859-1 zu_ZA.ISO8859-1 )],
};

our $DEFAULT =
{
## The local currency symbol.
currency_symbol     => '€',
## The decimal point character, except for currency values, cannot be an empty string
decimal_point       => '.',
## The number of digits after the decimal point in the local style for currency values.
frac_digits         => 2,
## The sizes of the groups of digits, except for currency values. unpack( "C*", $grouping ) will give the number
grouping            => (CORE::chr(3) x 2),
## The standardized international currency symbol.
int_curr_symbol     => '€',
## The number of digits after the decimal point in an international-style currency value.
int_frac_digits     => 2,
## Same as n_cs_precedes, but for internationally formatted monetary quantities.
int_n_cs_precedes   => '',
## Same as n_sep_by_space, but for internationally formatted monetary quantities.
int_n_sep_by_space  => '',
## Same as n_sign_posn, but for internationally formatted monetary quantities.
int_n_sign_posn     => 1,
## Same as p_cs_precedes, but for internationally formatted monetary quantities.
int_p_cs_precedes   => 1,
## Same as p_sep_by_space, but for internationally formatted monetary quantities.
int_p_sep_by_space  => 0,
## Same as p_sign_posn, but for internationally formatted monetary quantities.
int_p_sign_posn     => 1,
## The decimal point character for currency values.
mon_decimal_point   => '.',
## Like grouping but for currency values.
mon_grouping        => (CORE::chr(3) x 2),
## The separator for digit groups in currency values.
mon_thousands_sep   => ',',
## Like p_cs_precedes but for negative values.
n_cs_precedes       => 1,
## Like p_sep_by_space but for negative values.
n_sep_by_space      => 0,
## Like p_sign_posn but for negative currency values.
n_sign_posn         => 1,
## The character used to denote negative currency values, usually a minus sign.
negative_sign       => '-',
## 1 if the currency symbol precedes the currency value for nonnegative values, 0 if it follows.
p_cs_precedes       => 1,
## 1 if a space is inserted between the currency symbol and the currency value for nonnegative values, 0 otherwise.
p_sep_by_space      => 0,
## The location of the positive_sign with respect to a nonnegative quantity and the currency_symbol, coded as follows:
## 0    Parentheses around the entire string.
## 1    Before the string.
## 2    After the string.
## 3    Just before currency_symbol.
## 4    Just after currency_symbol.
p_sign_posn         => 1,
## The character used to denote nonnegative currency values, usually the empty string.
positive_sign       => '',
## The separator between groups of digits before the decimal point, except for currency values
thousands_sep       => ',',
};

my $map =
{
decimal             => [qw( decimal_point mon_decimal_point )],
grouping            => [qw( grouping mon_grouping )],
position_neg        => [qw( n_sign_posn int_n_sign_posn )],
position_pos        => [qw( n_sign_posn int_p_sign_posn )],
precede             => [qw( p_cs_precedes int_p_cs_precedes )],
precede_neg         => [qw( n_cs_precedes int_n_cs_precedes )],
precision           => [qw( frac_digits int_frac_digits )],
sign_neg            => [qw( negative_sign )],
sign_pos            => [qw( positive_sign )],
space_pos           => [qw( p_sep_by_space int_p_sep_by_space )],
space_neg           => [qw( n_sep_by_space int_n_sep_by_space )],
symbol              => [qw( currency_symbol int_curr_symbol )],
thousand            => [qw( thousands_sep mon_thousands_sep )],
};

sub init
{
    my $self = shift( @_ );
    my $num  = shift( @_ );
    return( $self->error( "No number was provided." ) ) if( !CORE::length( $num ) );
    return( Module::Generic::Infinity->new( $num ) ) if( POSIX::isinf( $num ) );
    return( Module::Generic::Nan->new( $num ) ) if( POSIX::isnan( $num ) );
    use utf8;
    my @k = keys( %$map );
    @$self{ @k } = ( '' x scalar( @k ) );
    $self->{lang} = '';
    $self->{default} = $DEFAULT;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    my $default = $self->default;
    # $self->message( 3, "Getting current locale" );
    my $curr_locale = POSIX::setlocale( &POSIX::LC_ALL );
    ## $self->message( 3, "Current locale is '$curr_locale'" );
    if( $self->{lang} )
    {
        # $self->message( 3, "Language requested '$self->{lang}'." );
        try
        {
            # $self->message( 3, "Current locale found is '$curr_locale'" );
            local $try_locale = sub
            {
                my $loc;
                # $self->message( 3, "Checking language '$_[0]'" );
                ## The user provided only a language code such as fr_FR. We try it, and also other known combination like fr_FR.UTF-8 and fr_FR.ISO-8859-1, fr_FR.ISO8859-1
                ## Try several possibilities
                ## RT https://rt.cpan.org/Public/Bug/Display.html?id=132664
                if( index( $_[0], '.' ) == -1 )
                {
                    # $self->message( 3, "Language '$_[0]' is a bareword, check if it works as is." );
                    $loc = POSIX::setlocale( &POSIX::LC_ALL, $_[0] );
                    # $self->message( 3, "Succeeded to set up locale for language '$_[0]'" ) if( $loc );
                    $_[0] =~ s/^(?<locale>[a-z]{2,3})_(?<country>[a-z]{2})$/$+{locale}_\U$+{country}\E/;
                    if( !$loc && CORE::exists( $SUPPORTED_LOCALES->{ $_[0] } ) )
                    {
                        # $self->message( 3, "Language '$_[0]' is supported, let's check for right variation" );
                        foreach my $supported ( @{$SUPPORTED_LOCALES->{ $_[0] }} )
                        {
                            if( ( $loc = POSIX::setlocale( &POSIX::LC_ALL, $supported ) ) )
                            {
                                $_[0] = $supported;
                                # $self->message( "-> Language variation '$supported' found." );
                                last;
                            }
                        }
                    }
                }
                ## We got something like fr_FR.ISO-8859
                ## The user is specific, so we try as is
                else
                {
                    # $self->message( 3, "Language '$_[0]' is specific enough, let's try it." );
                    $loc = POSIX::setlocale( &POSIX::LC_ALL, $_[0] );
                }
                return( $loc );
            };
            
            ## $self->message( 3, "Current locale is: '$curr_locale'" );
            if( my $loc = $try_locale->( $self->{lang} ) )
            {
                # $self->message( 3, "Succeeded in setting locale for language '$self->{lang}'" );
                ## $self->message( 3, "Succeeded in setting locale to '$self->{lang}'." );
                my $lconv = POSIX::localeconv();
                ## Set back the LC_ALL to what it was, because we do not want to disturb the user environment
                POSIX::setlocale( &POSIX::LC_ALL, $curr_locale );
                ## $self->messagef( 3, "POSIX::localeconv() returned %d items", scalar( keys( %$lconv ) ) );
                $default = $lconv if( $lconv && scalar( keys( %$lconv ) ) );
            }
            else
            {
                return( $self->error( "Language \"$self->{lang}\" is not supported by your system." ) );
            }
        }
        catch( $e )
        {
            return( $self->error( "An error occurred while getting the locale information for \"$self->{lang}\": $e" ) );
        }
    }
    elsif( $curr_locale && ( my $lconv = POSIX::localeconv() ) )
    {
        $default = $lconv if( scalar( keys( %$lconv ) ) );
        ## To simulate running on Windows
#         my $fail = [qw(
# frac_digits
# int_frac_digits
# n_cs_precedes
# n_sep_by_space
# n_sign_posn
# p_cs_precedes
# p_sep_by_space
# p_sign_posn
#         )];
#         @$lconv{ @$fail } = ( -1 ) x scalar( @$fail );
        ## $self->message( 3, "No language provided, but current locale '$curr_locale' found" );
        $self->{lang} = $curr_locale;
    }

    ## This serves 2 purposes:
    ## 1) to silence warnings issued from Number::Format when it uses an empty string when evaluating a number, e.g. '' == 1
    ## 2) to ensure that blank numerical values are not interpreted to anything else than equivalent of empty
    ##    For example, an empty frac_digits will default to 2 in Number::Format even if the user does not want any. Of course, said user could also have set it to 0
    ## So here we use this hash reference of numeric properties to ensure the option parameters are set to a numeric value (0) when they are empty.
    my $numerics = 
    {
    grouping => 0,
    frac_digits => 0,
    int_frac_digits => 0,
    int_n_cs_precedes => 0,
    int_p_cs_precedes => 0,
    int_n_sep_by_space => 0,
    int_p_sep_by_space => 0,
    int_n_sign_posn => 1,
    int_p_sign_posn => 1,
    mon_grouping => 0,
    n_cs_precedes => 0,
    n_sep_by_space => 0,
    n_sign_posn => 1,
    p_cs_precedes => 0,
    p_sep_by_space => 0,
    ## Position of positive sign. 1 = before (0 = parentheses)
    p_sign_posn => 1,
    };
    
    foreach my $prop ( keys( %$map ) )
    {
        my $ref = $map->{ $prop };
        ## Already set by user
        next if( CORE::length( $self->{ $prop } ) );
        foreach my $lconv_prop ( @$ref )
        {
            if( CORE::defined( $default->{ $lconv_prop } ) )
            {
                ## Number::Format bug RT #71044 when running on Windows
                ## https://rt.cpan.org/Ticket/Display.html?id=71044
                ## This is a workaround when values are lower than 0 (i.e. -1)
                if( CORE::exists( $numerics->{ $lconv_prop } ) && 
                    CORE::length( $default->{ $lconv_prop } ) && 
                    $default->{ $lconv_prop } < 0 )
                {
                    $default->{ $lconv_prop } = $numerics->{ $lconv_prop };
                }
                $self->$prop( $default->{ $lconv_prop } );
                last;
            }
            else
            {
                $self->$prop( $default->{ $lconv_prop } );
            }
        }
    }
    
    # $Number::Format::DEFAULT_LOCALE->{int_curr_symbol} = 'EUR';
    try
    {
        ## Those are unsupported by Number::Format
        my $skip =
        {
        int_n_cs_precedes => 1,
        int_p_cs_precedes => 1,
        int_n_sep_by_space => 1,
        int_p_sep_by_space => 1,
        int_n_sign_posn => 1,
        int_p_sign_posn => 1,
        };
        my $opts = {};
        foreach my $prop ( CORE::keys( %$map ) )
        {
            ## $self->message( 3, "Checking property \"$prop\" value \"", overload::StrVal( $self->{ $prop } ), "\" (", $self->$prop->defined ? 'defined' : 'undefined', ")." );
            my $prop_val;
            if( $self->$prop->defined )
            {
                $prop_val = $self->$prop;
            }
            ## To prevent Number::Format from defaulting to property values not in sync with ours
            ## Because it seems the POSIX::setlocale only affect one module
            else
            {
                $prop_val = '';
            }
            ## $self->message( 3, "Using property \"$prop\" value \"$prop_val\" (", CORE::defined( $prop_val ) ? 'defined' : 'undefined', ") [ref=", ref( $prop_val ), "]." );
            ## Need to set all the localeconv properties for Number::Format, because it uses mon_thousand_sep intsead of just thousand_sep
            foreach my $lconv_prop ( @{$map->{ $prop }} )
            {
                CORE::next if( CORE::exists( $skip->{ $lconv_prop } ) );
                ## Cannot be undefined, but can be empty string
                $opts->{ $lconv_prop } = "$prop_val";
                if( !CORE::length( $opts->{ $lconv_prop } ) && CORE::exists( $numerics->{ $lconv_prop } ) )
                {
                    $opts->{ $lconv_prop } = $numerics->{ $lconv_prop };
                }
            }
        }
        ## $self->message( 3, "Using following options for Number::Format: ", sub{ $self->dumper( $opts ) } );
        no warnings qw( uninitialized );
        $self->{_fmt} = Number::Format->new( %$opts );
        use warnings;
    }
    catch( $e )
    {
        ## $self->message( 3, "Error trapped in creating a Number::Format object: '$e'" );
        return( $self->error( "Unable to create a Number::Format object: $e" ) );
    }
    $self->{_original} = $num;
    try
    {
        if( $num !~ /^$RE{num}{real}$/ )
        {
            $self->{_number} = $self->{_fmt}->unformat_number( $num );
        }
        else
        {
            $self->{_number} = $num;
        }
        ## $self->message( 3, "Unformatted number is: '$self->{_number}'" );
        return( $self->error( "Invalid number: $num" ) ) if( !defined( $self->{_number} ) );
    }
    catch( $e )
    {
        return( $self->error( "Invalid number: $num" ) );
    }
    return( $self );
}

sub abs { return( shift->_func( 'abs' ) ); }

# sub asin { return( shift->_func( 'asin', { posix => 1 } ) ); }

sub atan { return( shift->_func( 'atan', { posix => 1 } ) ); }

sub atan2 { return( shift->_func( 'atan2', @_ ) ); }

sub as_boolean { return( Module::Generic::Boolean->new( shift->{_number} ? 1 : 0 ) ); }

sub as_string { return( shift->{_number} ) }

sub cbrt { return( shift->_func( 'cbrt', { posix => 1 } ) ); }

sub ceil { return( shift->_func( 'ceil', { posix => 1 } ) ); }

sub chr { return( Module::Generic::Scalar->new( CORE::chr( $_[0]->{_number} ) ) ); }

sub clone
{
    my $self = shift( @_ );
    my $num  = @_ ? shift( @_ ) : $self->{_number};
    return( Module::Generic::Infinity->new( $num ) ) if( POSIX::isinf( $num ) );
    return( Module::Generic::Nan->new( $num ) ) if( POSIX::isnan( $num ) );
    my @keys = keys( %$map );
    push( @keys, qw( lang debug ) );
    my $hash = {};
    @$hash{ @keys } = @$self{ @keys };
    return( $self->new( $num, $hash ) );
}

sub compute
{
    my( $self, $other, $swap, $opts ) = @_;
    my $other_val = Scalar::Util::blessed( $other ) ? $other : "\"$other\"";
    my $operation = $swap ? "${other_val} $opts->{op} \$self->{_number}" : "\$self->{_number} $opts->{op} ${other_val}";
    if( $opts->{return_object} )
    {
        my $res = eval( $operation );
        no overloading;
        warn( "Error with return formula \"$operation\" using object $self having number '$self->{_number}': $@" ) if( $@ && $self->_warnings_is_enabled );
        return if( $@ );
        return( Module::Generic::Scalar->new( $res ) ) if( $opts->{type} eq 'scalar' );
        return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
        return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
        ## undef may be returned for example on platform supporting NaN when using <=>
        return( $self->clone( $res ) ) if( defined( $res ) );
        return;
    }
    elsif( $opts->{boolean} )
    {
        my $res = eval( $operation );
        no overloading;
        warn( "Error with boolean formula \"$operation\" using object $self having number '$self->{_number}': $@" ) if( $@ && $self->_warnings_is_enabled );
        return if( $@ );
        # return( $res ? $self->true : $self->false );
        return( $res );
    }
    else
    {
        return( eval( $operation ) );
    }
}

sub cos { return( shift->_func( 'cos' ) ); }

sub currency { return( shift->_set_get_prop( 'symbol', @_ ) ); }

sub decimal { return( shift->_set_get_prop( 'decimal', @_ ) ); }

sub default { return( shift->_set_get_hash_as_mix_object( 'default', @_ ) ); }

sub exp { return( shift->_func( 'exp' ) ); }

sub floor { return( shift->_func( 'floor', { posix => 1 } ) ); }

sub format
{
    my $self = shift( @_ );
    my $precision = ( @_ && $_[0] =~ /^\d+$/ ) ? shift( @_ ) : $self->precision;
    no overloading;
    my $num  = $self->{_number};
    ## If value provided was undefined, we leave it undefined, otherwise we would be at risk of returning 0, and 0 is very different from undefined
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->{_fmt};
    try
    {
        ## Amazingly enough, when a precision > 0 is provided, format_number will discard it if the number, before formatting, did not have decimals... Then, what is the point of formatting a number then?
        ## To circumvent this, we provide the precision along with the "add trailing zeros" parameter expected by Number::Format
        ## return( $fmt->format_number( $num, $precision, 1 ) );
        my $res = $fmt->format_number( "$num", $precision, 1 );
        return if( !defined( $res ) );
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

sub format_binary { return( Module::Generic::Scalar->new( CORE::sprintf( '%b', shift->{_number} ) ) ); }

sub format_bytes
{
    my $self = shift( @_ );
    # no overloading;
    my $num  = $self->{_number};
    ## See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->{_fmt};
    try
    {
        ## return( $fmt->format_bytes( $num, @_ ) );
        my $res = $fmt->format_bytes( "$num", @_ );
        return if( !defined( $res ) );
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

sub format_hex { return( Module::Generic::Scalar->new( CORE::sprintf( '0x%X', shift->{_number} ) ) ); }

sub format_money
{
    my $self = shift( @_ );
    my $precision = ( @_ && $_[0] =~ /^\d+$/ ) ? shift( @_ ) : $self->precision;
    my $currency_symbol = @_ ? shift( @_ ) : $self->currency;
    # no overloading;
    my $num  = $self->{_number};
    ## See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->{_fmt};
    try
    {
        ## Even though the Number::Format instantiated is set with a currency symbol, 
        ## Number::Format will not respect it, and revert to USD if nothing was provided as argument
        ## This highlights that Number::Format is designed to be used more for exporting function rather than object methods
        ## $self->message( 3, "Passing Number = '$num', precision = '$precision', currency symbol = '$currency_symbol'." );
        ## return( $fmt->format_price( $num, $precision, $currency_symbol ) );
        my $res = $fmt->format_price( "$num", "$precision", "$currency_symbol" );
        return if( !defined( $res ) );
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

sub format_negative
{
    my $self = shift( @_ );
    # no overloading;
    my $num  = $self->{_number};
    ## See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->{_fmt};
    try
    {
        my $new = $self->format;
        ## $self->message( 3, "Formatted number '$self->{_number}' now is '$new'" );
        ## return( $fmt->format_negative( $new, @_ ) );
        my $res = $fmt->format_negative( "$new", @_ );
        ## $self->message( 3, "Result is '$res'" );
        return if( !defined( $res ) );
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

sub format_picture
{
    my $self = shift( @_ );
    no overloading;
    my $num  = $self->{_number};
    ## See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->{_fmt};
    try
    {
        ## return( $fmt->format_picture( $num, @_ ) );
        my $res = $fmt->format_picture( "$num", @_ );
        return if( !defined( $res ) );
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

sub formatter { return( shift->_set_get_object( 'formatter', 'Number::Format', @_ ) ); }

## https://stackoverflow.com/a/483708/4814971
sub from_binary
{
    my $self = shift( @_ );
    my $binary = shift( @_ );
    return if( !defined( $binary ) || !CORE::length( $binary ) );
    try
    {
        ## Nice trick to convert from binary to decimal. See perlfunc -> oct
        my $res = CORE::oct( "0b${binary}" );
        return if( !defined( $res ) );
        return( $self->clone( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while getting number from hexadecimal value \"$hex\": $e" ) );
    }
}

sub from_hex
{
    my $self = shift( @_ );
    my $hex = shift( @_ );
    return if( !defined( $hex ) || !CORE::length( $hex ) );
    try
    {
        my $res = CORE::hex( $hex );
        return if( !defined( $res ) );
        return( $self->clone( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while getting number from hexadecimal value \"$hex\": $e" ) );
    }
}

sub grouping { return( shift->_set_get_prop( 'grouping', @_ ) ); }

sub int { return( shift->_func( 'int' ) ); }

*is_decimal = \&is_float;

sub is_even { return( !( shift->{_number} % 2 ) ); }

sub is_finite { return( shift->_func( 'isfinite', { posix => 1 }) ); }

sub is_float { return( (POSIX::modf( shift->{_number} ))[0] != 0 ); }

# sub is_infinite { return( !(shift->is_finite) ); }
sub is_infinite { return( shift->_func( 'isinf', { posix => 1 }) ); }

sub is_int { return( (POSIX::modf( shift->{_number} ))[0] == 0 ); }

sub is_nan { return( shift->_func( 'isnan', { posix => 1}) ); }

*is_neg = \&is_negative;

sub is_negative { return( shift->_func( 'signbit', { posix => 1 }) != 0 ); }

sub is_normal { return( shift->_func( 'isnormal', { posix => 1}) ); }

sub is_odd { return( shift->{_number} % 2 ); }

*is_pos = \&is_positive;

sub is_positive { return( shift->_func( 'signbit', { posix => 1 }) == 0 ); }

sub lang { return( shift->_set_get_scalar_as_object( 'lang', @_ ) ); }

sub length { return( $_[0]->clone( CORE::length( $_[0]->{_number} ) ) ); }

sub locale { return( shift->_set_get_scalar_as_object( 'lang', @_ ) ); }

sub log { return( shift->_func( 'log' ) ); }

sub log2 { return( shift->_func( 'log2', { posix => 1 } ) ); }

sub log10 { return( shift->_func( 'log10', { posix => 1 } ) ); }

sub max { return( shift->_func( 'fmax', @_, { posix => 1 } ) ); }

sub min { return( shift->_func( 'fmin', @_, { posix => 1 } ) ); }

sub mod { return( shift->_func( 'fmod', @_, { posix => 1 } ) ); }

## This is used so that we can change formatter when the user changes thousand separator, decimal separator, precision or currency
sub new_formatter
{
    my $self = shift( @_ );
    my $hash = {};
    if( @_ )
    {
        if( @_ == 1 && $self->_is_hash( $_[0] ) )
        {
            $hash = shift( @_ );
        }
        elsif( !( @_ % 2 ) )
        {
            $hash = { @_ };
        }
        else
        {
            return( $self->error( "Invalid parameters provided: '", join( "', '", @_ ), "'." ) );
        }
    }
    else
    {
        my @keys = keys( %$map );
        # @$hash{ @keys } = @$self{ @keys };
        for( @keys )
        {
            $hash->{ $_ } = $self->$_();
        }
    }
    try
    {
        my $opts = {};
        foreach my $prop ( keys( %$map ) )
        {
            $opts->{ $map->{ $prop }->[0] } = $hash->{ $prop } if( CORE::defined( $hash->{ $prop } ) );
        }
        return( Number::Format->new( %$opts ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while trying to get a Number::Format object: $e" ) );
    }
}

sub oct { return( shift->_func( 'oct' ) ); }

sub position_neg { return( shift->_set_get_prop( 'position_neg', @_ ) ); }

sub position_pos { return( shift->_set_get_prop( 'position_pos', @_ ) ); }

sub pow { return( shift->_func( 'pow', @_, { posix => 1 } ) ); }

sub precede { return( shift->_set_get_prop( 'precede', @_ ) ); }

sub precede_neg { return( shift->_set_get_prop( 'precede_neg', @_ ) ); }

sub precede_pos { return( shift->_set_get_prop( 'precede', @_ ) ); }

sub precision { return( shift->_set_get_prop( 'precision', @_ ) ); }

sub rand { return( shift->_func( 'rand' ) ); }

sub round { return( $_[0]->clone( CORE::sprintf( '%.*f', CORE::int( CORE::length( $_[1] ) ? $_[1] : 0 ), $_[0]->{_number} ) ) ); }

sub round_zero { return( shift->_func( 'round', @_, { posix => 1 } ) ); }

sub round2
{
    my $self = shift( @_ );
    no overloading;
    my $num  = $self->{_number};
    ## See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->{_fmt};
    try
    {
        ## return( $fmt->round( $num, @_ ) );
        my $res = $fmt->round( $num, @_ );
        return if( !defined( $res ) );
        my $clone = $self->clone;
        $clone->{_number} = $res;
        return( $clone );
    }
    catch( $e )
    {
        return( $self->error( "Error rounding number \"$num\": $e" ) );
    }
}

sub scalar { return( shift->as_string ); }

sub sign_neg { return( shift->_set_get_prop( 'sign_neg', @_ ) ); }

sub sign_pos { return( shift->_set_get_prop( 'sign_pos', @_ ) ); }

sub sin { return( shift->_func( 'sin' ) ); }

*space = \&space_pos;

sub space_neg { return( shift->_set_get_prop( 'space_neg', @_ ) ); }

sub space_pos { return( shift->_set_get_prop( 'space_pos', @_ ) ); }

sub sqrt { return( shift->_func( 'sqrt' ) ); }

sub symbol { return( shift->_set_get_prop( 'symbol', @_ ) ); }

sub tan { return( shift->_func( 'tan', { posix => 1 } ) ); }

sub thousand { return( shift->_set_get_prop( 'thousand', @_ ) ); }

sub unformat
{
    my $self = shift( @_ );
    my $num = shift( @_ );
    return if( !defined( $num ) );
    try
    {
        my $num2 = $self->{_fmt}->unformat_number( $num );
        my $clone = $self->clone;
        $clone->{_original} = $num;
        $clone->{_number} = $num2;
        return( $clone );
    }
    catch( $e )
    {
        return( $self->error( "Unable to unformat the number \"$num\": $e" ) );
    }
}

sub _func
{
    my $self = shift( @_ );
    my $func = shift( @_ ) || return( $self->error( "No function was provided." ) );
    ## $self->message( 3, "Arguments received are: '", join( "', '", @_ ), "'." );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $namespace = $opts->{posix} ? 'POSIX' : 'CORE';
    my $val  = @_ ? shift( @_ ) : undef;
    my $expr = defined( $val ) ? "${namespace}::${func}( \$self->{_number}, $val )" : "${namespace}::${func}( \$self->{_number} )";
    ## $self->message( 3, "Evaluating '$expr'" );
    my $res = eval( $expr );
    ## $self->message( 3, "Result for number '$self->{_number}' is '$res'" );
    $self->message( 3, "Error: $@" ) if( $@ );
    return( $self->pass_error( $@ ) ) if( $@ );
    return if( !defined( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
    return( $self->clone( $res ) );
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        $val = $val->scalar if( $self->_is_object( $val ) && $val->isa( 'Module::Generic::Scalar' ) );
        ## $self->message( 3, "Setting value \"$val\" (", defined( $val ) ? 'defined' : 'undefined', ") for property \"$prop\"." );
        if( $val ne $self->{ $prop } || !CORE::defined( $val ) )
        {
            # $self->{ $prop } = $val;
            $self->_set_get_scalar_as_object( $prop, $val );
            ## If an error was set, we return nothing
            $self->formatter( $self->new_formatter ) || return;
        }
    }
    # return( $self->{ $prop } );
    return( $self->_set_get_scalar_as_object( $prop ) );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ ) || return;
    my $fmt_obj = $self->{_fmt} || return;
    my $code = $fmt_obj->can( $method );
    if( $code )
    {
        try
        {
            return( $code->( $fmt_obj, @_ ) );
        }
        catch( $e )
        {
            CORE::warn( $e );
            return;
        }
    }
    return;
};

package Module::Generic::NumberSpecial;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::Number );
    use overload ('""'      => sub{ $_[0]->{_number} },
                  '+='      => sub{ &_catchall( @_[0..2], '+' ) },
                  '-='      => sub{ &_catchall( @_[0..2], '-' ) },
                  '*='      => sub{ &_catchall( @_[0..2], '*' ) },
                  '/='      => sub{ &_catchall( @_[0..2], '/' ) },
                  '%='      => sub{ &_catchall( @_[0..2], '%' ) },
                  '**='      => sub{ &_catchall( @_[0..2], '**' ) },
                  '<<='      => sub{ &_catchall( @_[0..2], '<<' ) },
                  '>>='      => sub{ &_catchall( @_[0..2], '>>' ) },
                  'x='      => sub{ &_catchall( @_[0..2], 'x' ) },
                  '.='      => sub{ &_catchall( @_[0..2], '.' ) },
                  nomethod  => \&_catchall,
                  fallback  => 1,
                 );
    use Want;
    use POSIX ();
    our( $VERSION ) = '0.1.0';
};

sub new
{
    my $this = shift( @_ );
    return( bless( { _number => CORE::shift( @_ ) } => ( ref( $this ) || $this ) ) );
}

sub clone { return( shift->new( @_ ) ); }

sub is_finite { return( 0 ); }

sub is_float { return( 0 ); }

sub is_infinite { return( 0 ); }

sub is_int { return( 0 ); }

sub is_nan { return( 0 ); }

sub is_normal { return( 0 ); }

sub length { return( CORE::length( $self->{_number} ) ); }

sub _catchall
{
    my( $self, $other, $swap, $op ) = @_;
    my $expr = $swap ? "$other $op $self->{_number}" : "$self->{_number} $op $other";
    my $res = eval( $expr );
    ## print( ref( $self ), "::_catchall: evaluating $expr => $res\n" );
    CORE::warn( "Error evaluating expression \"$expr\": $@" ) if( $@ );
    return if( $@ );
    return( Module::Generic::Number->new( $res ) ) if( POSIX::isnormal( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
    return( $res );
}

sub _func
{
    my $self = shift( @_ );
    my $func = shift( @_ ) || return( $self->error( "No function was provided." ) );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $namespace = $opts->{posix} ? 'POSIX' : 'CORE';
    my $val  = @_ ? shift( @_ ) : undef;
    my $expr = defined( $val ) ? "${namespace}::${func}( $self->{_number}, $val )" : "${namespace}::${func}( $self->{_number} )";
    my $res = eval( $expr );
    ## $self->message( 3, "Error: $@" ) if( $@ );
    ## print( STDERR ref( $self ), "::_func -> evaluating '$expr' -> '$res'\n" );
    CORE::warn( $@ ) if( $@ );
    return if( !defined( $res ) );
    return( Module::Generic::Number->new( $res ) ) if( POSIX::isnormal( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
    return( $res );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    ## print( STDERR "$AUTOLOAD: called for method \"$method\"\n" );
    ## If we are chained, return our null object, so the chain continues to work
    if( want( 'OBJECT' ) )
    {
        ## No, this is NOT a typo. rreturn() is a function of module Want
        print( STDERR "$AUTOLOAD: Returning the object itself (", ref( $_[0] ), ")\n" );
        rreturn( $_[0] );
    }
    ## Otherwise, we return infinity, whether positive or negative or NaN depending on what was set
    ## print( STDERR "$AUTOLOAD: returning '", $_[0]->{_number}, "'\n" );
    return( $_[0]->{_number} );
};

DESTROY {};

## Purpose is to allow chaining of methods when infinity is returned
## At the end of the chain, Inf or -Inf is returned
package Module::Generic::Infinity;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::NumberSpecial );
    our( $VERSION ) = '0.1.0';
};

sub is_infinite { return( 1 ); }

package Module::Generic::Nan;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::NumberSpecial );
    our( $VERSION ) = '0.1.0';
};

sub is_nan { return( 1 ); }


package Module::Generic::Hash;
BEGIN
{
    use strict;
    use warnings::register;
    use parent -norequire, qw( Module::Generic );
    use overload (
        ## '""'    => 'as_string',
        'eq'    => sub { _obj_eq(@_) },
        'ne'    => sub { !_obj_eq(@_) },
        '<'     => sub { _obj_comp( @_, '<') },
        '>'     => sub { _obj_comp( @_, '>') },
        '<='     => sub { _obj_comp( @_, '<=') },
        '>='     => sub { _obj_comp( @_, '>=') },
        '=='     => sub { _obj_comp( @_, '>=') },
        '!='     => sub { _obj_comp( @_, '>=') },
        'lt'     => sub { _obj_comp( @_, 'lt') },
        'gt'     => sub { _obj_comp( @_, 'gt') },
        'le'     => sub { _obj_comp( @_, 'le') },
        'ge'     => sub { _obj_comp( @_, 'ge') },
        fallback => 1,
    );
    use Data::Dumper;
    use JSON;
    use Clone ();
    use Want;
    use Regexp::Common;
};

sub new
{
    my $that = shift( @_ );
    my $class = ref( $that ) || $that;
    ## my $data = shift( @_ ) ||
    ## return( $that->error( "No hash was provided to initiate a $class hash object." ) );
    my $data = {};
    $data = shift( @_ ) if( scalar( @_ ) );
    return( $that->error( "I was expecting an hash, but instead got '$data'." ) ) if( Scalar::Util::reftype( $data ) ne 'HASH' );
    my $tied = tied( %$data );
    return( $that->error( "Hash provided is already tied to ", ref( $tied ), " and our package $class cannot use it, or it would disrupt the tie." ) ) if( $tied );
    my %hash = ();
    ## This enables access to the hash just like a real hash while still the user an call our object methods
    my $obj = tie( %hash, 'Module::Generic::TieHash', {
        disable => ['Module::Generic'],
        debug => 0,
    });
    my $self = bless( \%hash => $class );
    $obj->enable( 1 );
    my @keys = CORE::keys( %$data );
    @hash{ @keys } = @$data{ @keys };
    $obj->enable( 0 );
    $self->SUPER::init( @_ );
    $obj->enable( 1 );
    return( $self );
}

sub as_string { return( shift->dump ); }

sub clone
{
    my $self = shift( @_ );
    $self->_tie_object->enable( 0 );
    my $data = $self->{data};
    my $clone = Clone::clone( $data );
    $self->_tie_object->enable( 1 );
    return( $self->new( $clone ) );
}

sub debug { return( shift->_internal( 'debug', '_set_get_number', @_ ) ); }

sub defined { CORE::defined( $_[0]->{ $_[1] } ); }

sub delete { return( CORE::delete( shift->{ shift( @_ ) } ) ); }

sub dump
{
    my $self = shift( @_ );
    return( $self->_dumper( $self ) );
}

sub each
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No subroutine callback as provided for each" ) );
    return( $self->error( "I was expecting a reference to a subroutine for the callback to each, but got '$code' instead." ) ) if( ref( $code ) ne 'CODE' );
    while( my( $k, $v ) = CORE::each( %$self ) )
    {
        CORE::defined( $code->( $k, $v ) ) || CORE::last;
    }
    return( $self );
}

sub exists { return( CORE::exists( shift->{ shift( @_ ) } ) ); }

sub for { return( shift->foreach( @_ ) ); }

sub foreach
{
    my $self = shift( @_ );
    my $code = shift( @_ ) || return( $self->error( "No subroutine callback as provided for each" ) );
    return( $self->error( "I was expecting a reference to a subroutine for the callback to each, but got '$code' instead." ) ) if( ref( $code ) ne 'CODE' );
    CORE::foreach my $k ( CORE::keys( %$self ) )
    {
        local $_ = $self->{ $k };
        CORE::defined( $code->( $k, $self->{ $k } ) ) || CORE::last;
    }
    return( $self );
}

sub get { return( $_[0]->{ $_[1] } ); }

sub has { return( shift->exists( @_ ) ); }

sub json
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $self->_tie_object->enable( 0 );
    my $data = $self->{data};
    my $json;
    if( $opts->{pretty} )
    {
        $json = JSON->new->pretty->utf8->indent(1)->relaxed(1)->canonical(1)->allow_nonref->encode( $data );
    }
    else
    {
        $json = JSON->new->utf8->canonical(1)->allow_nonref->encode( $data );
    }
    $self->_tie_object->enable( 1 );
    return( Module::Generic::Scalar->new( $json ) );
}

# $h->keys->sort
sub keys { return( Module::Generic::Array->new( [ CORE::keys( %{$_[0]} ) ] ) ); }

sub length { return( Module::Generic::Number->new( CORE::scalar( CORE::keys( %{$_[0]} ) ) ) ); }

sub map
{
    my $self = shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    return( CORE::map( $code->( $_, $self->{ $_ } ), CORE::keys( %$self ) ) );
}

sub map_array
{
    my $self = shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    return( Module::Generic::Array->new( [CORE::map( $code->( $_, $self->{ $_ } ), CORE::keys( %$self ) )] ) );
}

sub map_hash
{
    my $self = shift( @_ );
    my $code = CORE::shift( @_ );
    return if( ref( $code ) ne 'CODE' );
    return( $self->new( {CORE::map( $code->( $_, $self->{ $_ } ), CORE::keys( %$self ) )} ) );
}

sub merge
{
    my $self = shift( @_ );
    my $hash = {};
    $hash = shift( @_ );
    return( $self->error( "No valid hash provided." ) ) if( !$hash || Scalar::Util::reftype( $hash ) ne 'HASH' );
    ## $self->message( 3, "Hash provided is: ", sub{ $self->dumper( $hash ) } );
    my $opts = {};
    $opts = pop( @_ ) if( @_ && ref( $_[-1] ) eq 'HASH' );
    $opts->{overwrite} = 1 unless( CORE::exists( $opts->{overwrite} ) );
    $self->_tie_object->enable( 0 );
    my $data = $self->{data};
    my $seen = {};
    local $copy = sub
    {
        my $this = shift( @_ );
        my $to = shift( @_ );
        my $p  = {};
        $p = shift( @_ ) if( @_ && ref( $_[-1] ) eq 'HASH' );
        ## $self->message( 3, "Merging hash ", sub{ $self->dumper( $this ) }, " to hash ", sub{ $self->dumper( $to ) }, " and with parameters ", sub{ $self->dumper( $p ) } );
        CORE::foreach my $k ( CORE::keys( %$this ) )
        {
            # $self->message( 3, "Skipping existing property '$k'." ) if( CORE::exists( $to->{ $k } ) && !$p->{overwrite} );
            next if( CORE::exists( $to->{ $k } ) && !$p->{overwrite} );
            if( ref( $this->{ $k } ) eq 'HASH' || 
                ( Scalar::Util::blessed( $this->{ $k } ) && $this->{ $k }->isa( 'Module::Generic::Hash' ) ) )
            {
                my $addr = Scalar::Util::refaddr( $this->{ $k } );
                # $self->message( 3, "Checking if hash in property '$k' was already processed with address '$addr'." );
                if( CORE::exists( $seen->{ $addr } ) )
                {
                    $to->{ $k } = $seen->{ $addr };
                    next;
                }
                else
                {
                    $to->{ $k } = {} unless( Scalar::Util::reftype( $to->{ $k } ) eq 'HASH' );
                    $copy->( $this->{ $k }, $to->{ $k } );
                }
                $seen->{ $addr } = $this->{ $k };
            }
            else
            {
                $to->{ $k } = $this->{ $k };
            }
        }
    };
    ## $self->message( 3, "Propagating hash ", sub{ $self->dumper( $hash ) }, " to hash ", sub{ $self->dumper( $data ) } );
    $copy->( $hash, $data, $opts );
    $self->_tie_object->enable( 1 );
    return( $self );
}

sub reset { %{$_[0]} = () };

sub set { $_[0]->{ $_[1] } = $_[2]; }

sub undef { %{$_[0]} = () };

sub values
{
    my $self = shift( @_ );
    my $code;
    $code = shift( @_ ) if( @_ && ref( $_[0] ) eq 'CODE' );
    my $opts = {};
    $opts = pop( @_ ) if( Scalar::Util::reftype( $_[-1] ) eq 'HASH' );
    if( $code )
    {
        if( $opts->{sort} )
        {
            return( Module::Generic::Array->new( [ CORE::map( $code->( $_ ), CORE::sort( CORE::values( %$self ) ) ) ] ) );
        }
        else
        {
            return( Module::Generic::Array->new( [ CORE::map( $code->( $_ ), CORE::values( %$self ) ) ] ) );
        }
    }
    else
    {
        if( $opts->{sort} )
        {
            return( Module::Generic::Array->new( [ CORE::sort( CORE::values( %$self ) ) ] ) );
        }
        else
        {
            return( Module::Generic::Array->new( [ CORE::values( %$self ) ] ) );
        }
    }
}

# sub _dumper
# {
#     my $self = shift( @_ );
#     if( !$self->{_dumper} )
#     {
#         my $d = Data::Dumper->new;
#         $d->Indent( 1 );
#         $d->Useqq( 1 );
#         $d->Terse( 1 );
#         $d->Sortkeys( 1 );
#         $self->{_dumper} = $d;
#     }
#     return( $self->{_dumper}->Dumper( @_ ) );
# }
# 
sub _dumper
{
    my $self = shift( @_ );
    $self->_tie_object->enable( 0 );
    my $data = $self->{data};
    my $d = Data::Dumper->new( [ $data ] );
    $d->Indent( 1 );
    $d->Useqq( 1 );
    $d->Terse( 1 );
    $d->Sortkeys( 1 );
    # $d->Freezer( '' );
    $d->Bless( '' );
    # return( $d->Dump );
    my $str = $d->Dump;
    $self->_tie_object->enable( 1 );
    return( $str );
}

sub _internal
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $meth  = shift( @_ );
    # print( STDERR ref( $self ), "::_internal -> Caling method '$meth' for field '$field' with value '", join( "', '", @_ ), "'\n" );
    $self->_tie_object->enable( 0 );
    my( @resA, $resB );
    if( wantarray )
    {
        @resA = $self->$meth( $field, @_ );
        # $self->message( "Resturn list value is: '@resA'" );
    }
    else
    {
        $resB = $self->$meth( $field, @_ );
        # $self->message( "Resturn scalar value is: '$resB'" );
    }
    $self->_tie_object->enable( 1 );
    return( wantarray ? @resA : $resB );
}

sub _obj_comp
{
    my( $self, $other, $swap, $op ) = @_;
    my( $lA, $lB );
    $lA = $self->length;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Hash' ) )
    {
        $lB = $other->length;
    }
    elsif( $other =~ /^$RE{num}{real}$/ )
    {
        $lB = $other;
    }
    else
    {
        return;
    }
    my $expr = $swap ? "$lB $op $lA" : "$lA $op $lB";
    return( eval( $expr ) );
}

sub _printer { return( shift->printer( @_ ) ); }

sub _obj_eq
{
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $strA = $self->_dumper( $self );
    my $strB;
    if( Scalar::Util::blessed( $other ) && $other->isa( 'Module::Generic::Hash' ) )
    {
        $strB = $other->dump;
    }
    elsif( Scalar::Util::reftype( $other ) eq 'HASH' )
    {
        $strB = $self->_dumper( $other )
    }
    else
    {
        return( 0 );
    }
    return( $strA eq $strB );
}

sub _tie_object
{
    my $self = shift( @_ );
    return( tied( %$self ) );
}

package Module::Generic::TieHash;
BEGIN
{
    use strict;
    use warnings::register;
    use parent -norequire, qw( Module::Generic );
    use Scalar::Util ();
    our( $VERSION ) = '0.1.0';
};

sub TIEHASH
{
    my $self  = shift( @_ );
    my $opts  = {};
    $opts = shift( @_ ) if( @_ );
    if( Scalar::Util::reftype( $opts ) ne 'HASH' )
    {
        warn( "Parameters provided ($opts) is not an hash reference.\n" ) if( $self->_warnings_is_enabled );
        return;
    }
    my $disable = [];
    $disable = $opts->{disable} if( Scalar::Util::reftype( $opts->{disable} ) );
    my $list = {};
    @$list{ @$disable } = ( 1 ) x scalar( @$disable );
    my $hash =
    {
    ## The caller sets this to its class, so we can differentiate calls from inside and outside our caller's package
    disable => $list,
    debug => $opts->{debug},
    ## When disabled, the Tie::Hash system will return hash key values directly under $self instead of $self->{data}
    ## Disabled by default so the new() method can access its setup data directly under $self
    ## Then new() can call enable to active it
    enable => 0,
    ## Where to store the actual hash data
    data  => {},
    };
    my $class = ref( $self ) || $self;
    return( bless( $hash => $class ) );
}

sub CLEAR
{
    my $self = shift( @_ );
    my $data = $self->{data};
    %$data = ();
}

sub DELETE
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    # if( !$self->{enable} )
    {
        CORE::delete( $self->{ $key } );
    }
    else
    {
        CORE::delete( $data->{ $key } );
    }
}

sub EXISTS
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    # if( !$self->{enable} )
    {
        CORE::exists( $self->{ $key } );
    }
    else
    {
        CORE::exists( $data->{ $key } );
    }
}

sub FETCH
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $key  = shift( @_ );
    my $caller = caller;
    ## print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key''\n" );
    if( $self->_exclude( $caller ) || !$self->{enable} )
    # if( !$self->{enable} )
    {
        #print( STDERR "FETCH($caller)[owner calling, enable=$self->{enable}] <- '$key' <- '$self->{$key}'\n" );
        return( $self->{ $key } )
    }
    else
    {
        #print( STDERR "FETCH($caller)[enable=$self->{enable}] <- '$key' <- '$data->{$key}'\n" );
        return( $data->{ $key } );
    }
}

sub FIRSTKEY
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my @keys = ();
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    # if( !$self->{enable} )
    {
        @keys = keys( %$self );
    }
    else
    {
        @keys = keys( %$data );
    }
    $self->{ITERATOR} = \@keys;
    return( shift( @keys ) );
}

sub NEXTKEY
{
    my $self = shift( @_ );
    my $data = $self->{data};
    my $keys = ref( $self->{ITERATOR} ) ? $self->{ITERATOR} : [];
    return( shift( @$keys ) );
}

sub SCALAR
{
    my $self  = shift( @_ );
    my $data = $self->{data};
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    # if( !$self->{enable} )
    {
        return( scalar( keys( %$self ) ) );
    }
    else
    {
        return( scalar( keys( %$data ) ) );
    }
}

sub STORE
{
    my $self  = shift( @_ );
    my $data = $self->{data};
    my( $key, $val ) = @_;
    my $caller = caller;
    if( $self->_exclude( $caller ) || !$self->{enable} )
    # if( !$self->{enable} )
    {
        #print( STDERR "STORE($caller)[owner calling] <- '$key' -> '$val'\n" );
        $self->{ $key } = $val;
    }
    else
    {
        #print( STDERR "STORE($caller)[enable=$self->{enable}] <- '$key' -> '$val'\n" );
        $data->{ $key } = $val;
    }
}

sub enable { return( shift->_set_get_boolean( 'enable', @_ ) ); }

sub _exclude
{
    my $self = shift( @_ );
    my $caller = shift( @_ );
    ## $self->message( 3, "Disable hash contains: ", sub{ $self->dump( $self->{disable} ) });
    return( CORE::exists( $self->{disable}->{ $caller } ) );
}

package Module::Generic::Tie;
BEGIN
{
    use Tie::Hash;
    our( @ISA ) = qw( Tie::Hash );
    our( $VERSION ) = '0.1.0';
};

sub TIEHASH
{
    my $self = shift( @_ );
    my $pkg  = ( caller() )[ 0 ];
    ## print( STDERR __PACKAGE__ . "::TIEHASH() called with following arguments: '", join( ', ', @_ ), "'.\n" );
    my %arg  = ( @_ );
    my $auth = [ $pkg, __PACKAGE__ ];
    if( $arg{ 'pkg' } )
    {
        my $ok = delete( $arg{ 'pkg' } );
        push( @$auth, ref( $ok ) eq 'ARRAY' ? @$ok : $ok );
    }
    my $priv = { 'pkg' => $auth };
    my $data = { '__priv__' => $priv };
    my @keys = keys( %arg );
    @$priv{ @keys } = @arg{ @keys };
    return( bless( $data, ref( $self ) || $self ) );
}

sub CLEAR
{
    my $self = shift( @_ );
    my $pkg = ( caller() )[ 0 ];
    ## print( $err __PACKAGE__ . "::CLEAR() called by package '$pkg'.\n" );
    my $data = $self->{ '__priv__' };
    return() if( $data->{ 'readonly' } && $pkg ne __PACKAGE__ );
    ## if( $data->{ 'readonly' } || $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 2 ) )
    {
        return if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    my $key  = $self->FIRSTKEY( @_ );
    my @keys = ();
    while( defined( $key ) )
    {
        push( @keys, $key );
        $key = $self->NEXTKEY( @_, $key );
    }
    foreach $key ( @keys )
    {
        $self->DELETE( @_, $key );
    }
}

sub DELETE
{
    my $self = shift( @_ );
    my $pkg  = ( caller() )[ 0 ];
    $pkg     = ( caller( 1 ) )[ 0 ] if( $pkg eq 'Module::Generic' );
    ## print( STDERR __PACKAGE__ . "::DELETE() package '$pkg' tries to delete '$_[ 0 ]'\n" );
    my $data = $self->{ '__priv__' };
    return if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    ## if( $data->{ 'readonly' } || $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 2 ) )
    {
        return() if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    return( delete( $self->{ shift( @_ ) } ) );
}

sub EXISTS
{
    my $self = shift( @_ );
    ## print( STDERR __PACKAGE__ . "::EXISTS() called from package '", ( caller() )[ 0 ], "'.\n" );
    return( 0 ) if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    my $data = $self->{ '__priv__' };
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller() )[ 0 ];
        return( 0 ) if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    ## print( STDERR __PACKAGE__ . "::EXISTS() returns: '", exists( $self->{ $_[ 0 ] } ), "'.\n" );
    return( exists( $self->{ shift( @_ ) } ) );
}

sub FETCH
{
    ## return( shift->{ shift( @_ ) } );
    ## print( STDERR __PACKAGE__ . "::FETCH() called with arguments: '", join( ', ', @_ ), "'.\n" );
    my $self = shift( @_ );
    ## This is a hidden entry, we return nothing
    return() if( $_[ 0 ] eq '__priv__' && $pkg ne __PACKAGE__ );
    my $data = $self->{ '__priv__' };
    ## If we have to protect our object, we hide its inner content if our caller is not our creator
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller() )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::FETCH() package '$pkg' wants to fetch the value of '$_[ 0 ]'\n" );
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    return( $self->{ shift( @_ ) } );
}

sub FIRSTKEY
{
    my $self = shift( @_ );
    ## my $a    = scalar( keys( %$hash ) );
    ## return( each( %$hash ) );
    my $data = $self->{ '__priv__' };
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller( 0 ) )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::FIRSTKEY() called by package '$pkg'\n" );
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY(): gathering object's keys.\n" );
    my( @keys ) = grep( !/^__priv__$/, keys( %$self ) );
    $self->{ '__priv__' }->{ 'ITERATOR' } = \@keys;
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY(): keys are: '", join( ', ', @keys ), "'.\n" );
    ## print( STDERR __PACKAGE__ . "::FIRSTKEY() returns '$keys[ 0 ]'.\n" );
    return( shift( @keys ) );
}

sub NEXTKEY
{
    my $self = shift( @_ );
    ## return( each( %$hash ) );
    my $data = $self->{ '__priv__' };
    ## if( $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 4 ) )
    {
        my $pkg = ( caller( 0 ) )[ 0 ];
        ## print( STDERR __PACKAGE__ . "::NEXTKEY() called by package '$pkg'\n" );
        return if( !grep( /^$pkg$/, @{$data->{ 'pkg' }} ) );
    }
    my $keys = $self->{ '__priv__' }->{ 'ITERATOR' };
    ## print( STDERR __PACKAGE__ . "::NEXTKEY() returns '$_[ 0 ]'.\n" );
    return( shift( @$keys ) );
}

sub STORE
{
    my $self = shift( @_ );
    return() if( $_[ 0 ] eq '__priv__' );
    my $data = $self->{ '__priv__' };
    #if( $data->{ 'readonly' } || 
    #    $data->{ 'protect' } )
    if( !( $data->{ 'perms' } & 2 ) )
    {
        my $pkg  = ( caller() )[ 0 ];
        $pkg     = ( caller( 1 ) )[ 0 ] if( $pkg eq 'Module::Generic' );
        ## print( STDERR __PACKAGE__ . "::STORE() package '$pkg' is trying to STORE the value '$_[ 1 ]' to key '$_[ 0 ]'\n" );
        return if( !grep( /^$pkg$/, @{ $data->{ 'pkg' } } ) );
    }
    ## print( STDERR __PACKAGE__ . "::STORE() ", ( caller() )[ 0 ], " is storing value '$_[ 1 ]' for key '$_[ 0 ]'.\n" );
    ## $self->{ shift( @_ ) } = shift( @_ );
    $self->{ $_[ 0 ] } = $_[ 1 ];
    ## print( STDERR __PACKAGE__ . "::STORE(): object '$self' now contains: '", join( ', ', map{ "$_, $self->{ $_ }" } keys( %$self ) ), "'.\n" );
}

1;

__END__

=encoding utf8

=head1 NAME

Module::Generic - Generic Module to inherit from

=head1 SYNOPSIS

    package MyModule;
    BEGIN
    {
        use strict;
        use Module::Generic;
        our( @ISA ) = qw( Module::Generic );
    };

=head1 VERSION

    v0.13.0

=head1 DESCRIPTION

L<Module::Generic> as its name says it all, is a generic module to inherit from.
It is designed to provide a useful framework and speed up coding and debugging.
It contains standard and support methods that may be superseded by your the module using 
L<Module::Generic>.

As an added benefit, it also contains a powerfull AUTOLOAD transforming any hash 
object key into dynamic methods and also recognize the dynamic routine a la AutoLoader
from which I have shamelessly copied in the AUTOLOAD code. The reason is that while
C<AutoLoader> provides the user with a convenient AUTOLOAD, I wanted a way to also
keep the functionnality of L<Module::Generic> AUTOLOAD that were not included in
C<AutoLoader>. So the only solution was a merger.

=head1 METHODS

=head2 import

B<import>() is used for the AutoLoader mechanism and hence is not a public method.
It is just mentionned here for info only.

=head2 new

B<new> will create a new object for the package, pass any argument it might receive
to the special standard routine B<init> that I<must> exist. 
Then it returns what returns L</"init">.

To protect object inner content from sneaking by third party, you can declare the 
package global variable I<OBJECT_PERMS> and give it a Unix permission, but only 1 digit.
It will then work just like Unix permission. That is, if permission is 7, then only the 
module who generated the object may read/write content of the object. However, if
you set 5, the, other may look into the content of the object, but may not modify it.
7, as you would have guessed, allow other to modify the content of an object.
If I<OBJECT_PERMS> is not defined, permissions system is not activated and hence anyone 
may access and possibly modify the content of your object.

If the module runs under mod_perl, it is recognised and a clean up registered routine is 
declared to Apache to clean up the content of the object.

=head2 as_hash

This will recursively transform the object into an hash suitable to be encoded in json.

It does this by calling each method of the object and build an hash reference with the 
method name as the key and the method returned value as the value.

If the method returned value is an object, it will call its L</"as_hash"> method if it supports it.

It returns the hash reference built

=head2 clear_error

Clear all error from the object and from the available global variable C<$ERROR>.

This is a handy method to use at the beginning of other methods of calling package,
so the end user may do a test such as:

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

This way the end user may be sure that if C<$obj->error()> returns true something
wrong has occured.

=head2 clone

Clone the current object if it is of type hash or array reference. It returns an error if the type is neither.

It returns the clone.

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

=head2 dump_print

Provided with a file to write to and some data, this will format the string representation of the data using L<Data::Printer> and save it to the given file.

=head2 dumper

Provided with some data, and optionally an hash reference of parameters as last argument, this will create a string representation of the data using L<Data::Dumper> and return it.

This sets L<Data::Dumper> to be terse, to indent, to use C<qq> and optionally to not exceed a maximum I<depth> if it is provided in the argument hash reference.

=head2 printer

Same as L</"dumper">, but using L<Data::Printer> to format the data.

=head2 dumpto_printer

Same as L</"dump_print"> above that is an alias of this method.

=head2 dumpto_dumper

Same as L</"dumpto_printer"> above, but using L<Data::Dumper>

=head2 error

Set the current error issuing a L<Module::Generic::Exception> object, call L<perlfunc/"warn">, or C<$r->warn> under Apache2 modperl, and returns undef() or an empty list in list context:

    if( $some_condition )
    {
        return( $self->error( "Some error." ) );
    }

Note that you do not have to worry about a trailing line feed sequence.
B<error>() takes care of it.

The script calling your module could write calls to your module methods like this:

    my $cust_name = $object->customer->name ||
        die( "Got an error in file ", $object->error->file, " at line ", $object->error->line, ": ", $object->error->trace, "\n" );
    # or simply:
    my $cust_name = $object->customer->name ||
        die( "Got an error: ", $object->error, "\n" );

Note also that by calling B<error>() it will not clear the current error. For that
you have to call B<clear_error>() explicitly.

Also, when an error is set, the global variable I<ERROR> is set accordingly. This is
especially usefull, when your initiating an object and that an error occured. At that
time, since the object could not be initiated, the end user can not use the object to 
get the error message, and then can get it using the global module variable 
I<ERROR>, for example:

    my $obj = Some::Package->new ||
    die( $Some::Package::ERROR, "\n" );

If the caller has disabled warnings using the pragma C<no warnings>, L</"error"> will 
respect it and not call B<warn>. Calling B<warn> can also be silenced if the object has
a property I<quiet> set to true.

The error message can be split in multiple argument. L</"error"> will concatenate each argument to form a complete string. An argument can even be a reference to a sub routine and will get called to get the resulting string, unless the object property I<_msg_no_exec_sub> is set to false. This can switched off with the method L</"noexec">

If perl runs under Apache2 modperl, and an error handler is set with L</"error_handler">, this will call the error handler with the error string.

If an Apache2 modperl log handler has been set, this will also be called to log the error.

If the object property I<fatal> is set to true, this will call die instead of L<perlfunc/"warn">.

Last, but not least since L</"error"> returns undef in scalar context or an empty list in list context, if the method that triggered the error is chained, it would normally generate a perl error that the following method cannot be called on an undefined value. To solve this, when an object is expected, L</"error"> returns a special object from module L<Module::Generic::Null> that will enable all the chained methods to be performed and return the error when requested to. For example :

    my $o = My::Package->new;
    my $total $o->get_customer(10)->products->total || die( $o->error, "\n" );

Assuming this method here C<get_customer> returns an error, the chaining will continue, but produce nothing and ultimately returns undef.

=head2 errors

Used by B<error>() to store the error sent to him for history.

It returns an array of all error that have occured in lsit context, and the last 
error in scalar context.

=head2 errstr

Set/get the error string, period. It does not produce any warning like B<error> would do.

=head2 get

Uset to get an object data key value:

    $obj->set( 'verbose' => 1, 'debug' => 0 );
    ## ...
    my $verbose = $obj->get( 'verbose' );
    my @vals = $obj->get( qw( verbose debug ) );
    print( $out "Verbose level is $vals[ 0 ] and debug level is $vals[ 1 ]\n" );

This is no more needed, as it has been more conveniently bypassed by the AUTOLOAD
generic routine with chich you may say:

    $obj->verbose( 1 );
    $obj->debug( 0 );
    ## ...
    my $verbose = $obj->verbose();

Much better, no?

=head2 init

This is the L</"new"> package object initializer. It is called by L</"new">
and is used to set up any parameter provided in a hash like fashion:

    my $obj My::Module->new( 'verbose' => 1, 'debug' => 0 );

You may want to superseed L</"init"> to have suit your needs.

L</"init"> needs to returns the object it received in the first place or an error if
something went wrong, such as:

    sub init
    {
        my $self = shift( @_ );
        my $dbh  = DB::Object->connect() ||
        return( $self->error( "Unable to connect to database server." ) );
        $self->{ 'dbh' } = $dbh;
        return( $self );
    }

In this example, using L</"error"> will set the global variable C<$ERROR> that will
contain the error, so user can say:

    my $obj = My::Module->new() || die( $My::Module::ERROR );

If the global variable I<VERBOSE>, I<DEBUG>, I<VERSION> are defined in the module,
and that they do not exist as an object key, they will be set automatically and
accordingly to those global variable.

The supported data type of the object generated by the L</"new"> method may either be
a hash reference or a glob reference. Those supported data types may very well be
extended to an array reference in a near future.

When provided with an hash reference, and when object property I<_init_strict_use_sub> is set to true, L</"init"> will call each method corresponding to the key name and pass it the key value and it will set an error and skip it if the corresponding method does not exist. Otherwise if the object property I<_init_strict> is set to true, it will check the object property matching the hash key for the default value type and set an error and return undef if it does not match. Foe example, L</"init"> in your module could be like this:

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

=head2 log_handler

Provided a reference to a sub routine or an anonymous sub routine, this will set the handler that is called by L</"message">

It returns the current value set.

=head2 message

B<message>() is used to display verbose/debug output. It will display something
to the extend that either I<verbose> or I<debug> are toggled on.

If so, all debugging message will be prepended by C<## > to highlight the fact
that this is a debugging message.

Addionally, if a number is provided as first argument to B<message>(), it will be 
treated as the minimum required level of debugness. So, if the current debug
state level is not equal or superior to the one provided as first argument, the
message will not be displayed.

For example:

    ## Set debugness to 3
    $obj->debug( 3 );
    ## This message will not be printed
    $obj->message( 4, "Some detailed debugging stuff that we might not want." );
    ## This will be displayed
    $obj->message( 2, "Some more common message we want the user to see." );

Now, why debug is used and not verbose level? Well, because mostly, the verbose level
needs only to be true, that is equal to 1 to be efficient. You do not really need to have
a verbose level greater than 1. However, the debug level usually may have various level.

Also, the text provided can be separated by comma, and even be a code reference, such as:

    $self->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

If the object has a property I<_msg_no_exec_sub> set to true, then a code reference will not be called and instead be added to the string as is. This can be done simply like this:

    $self->noexec->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

=head2 message_check

This is called by L</"message">

Provided with a list of arguments, this method will check if the first argument is an integer and find out if a debug message should be printed out or not. It returns the list of arguments as an array reference.

=head2 message_colour

This is the same as L</"message">, except this will check for colour formatting, which
L</"message"> does not do. For example:

    $self->message_colour( 3, "And {bold light white on red}what about{/} {underline green}me again{/} ?" );

L</"message_colour"> can also be called as B<message_color>

See also L</"colour_format"> and L</"colour_parse">

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

=head2 message_switch

Provided with a boolean value, this toggles on or off all the calls to L</"message"> by replacing the message method in your package with a dummy one that will ignore any call. Actually it aliases L</"message"> to L</"message_off">

In reality this is not really needed, because L</"message"> will, at the beginning check if the object has the debug flag on and if not returns undef.

=head2 new_array

Instantiate a new L<Module::Generic::Array> object. If any arguments are provided, it will pass it to L<Module::Generic::Array/new> and return the object.

=head2 new_hash

Instantiate a new L<Module::Generic::Hash> object. If any arguments are provided, it will pass it to L<Module::Generic::Hash/new> and return the object.

=head2 new_number

Instantiate a new L<Module::Generic::Number> object. If any arguments are provided, it will pass it to L<Module::Generic::Number/new> and return the object.

=head2 new_scalar

Instantiate a new L<Module::Generic::Scalar> object. If any arguments are provided, it will pass it to L<Module::Generic::Scalar/new> and return the object.

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

=head1 SPECIAL METHODS

=head2 __instantiate_object

Provided with an object property name, and a class/package name, this will attempt to load the module if it is not already loaded. It does so using L<Class::Load/"load_class">. Once loaded, it will init an object passing it the other arguments received. It returns the object instantiated upon success or undef and sets an L</"error">

This is a support method used by L</"_instantiate_object">

=head2 _instantiate_object

This does the same thing as L</"__instantiate_object"> and the purpose is for this method to be potentially superseded in your own module. In your own module, you would call L</"__instantiate_object">

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

=head2 _is_class_loaded

Provided with a class/package name, this returns true if the module is already loaded or false otherwise.

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

=head2 _is_object

Provided with some data, this checks if the data is an object. It uses L<Scalar::Util/"blessed"> to achieve that purpose.

=head2 _is_scalar

Provided with some data, this checks if the data is of type scalar reference, e.g. C<SCALAR(0x7fc0d3b7cea0)>, even if it is an object.

=head2 _load_class

Provided with a class/package name and this will attempt to load the module. This uses L<Class::Load/"load_class"> to achieve that purpose and return whatever value L<Class::Load/"load_class"> returns.

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

=head2 _set_get_boolean

Provided with an object property name and some data and this will store the data as a boolean value.

If the data provided is a L<JSON::PP::Boolean> or L<Module::Generic::Boolean> object, the data is stored as is.

If the data is a scalar reference, its referenced value is check and L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

If the data is a string with value of C<true> or C<val> L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

Otherwise the data provided is checked if it is a true value or not and L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

If no value is provided, and the object property has already been set, this performs the same checks as above and returns either a L<JSON::PP::Boolean> or a L<Module::Generic::Boolean> object.

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

=head2 _set_get_number_or_object

Provided with an object property name and a number or an object and this call the value using L</"_set_get_number"> or L</"_set_get_object"> respectively

=head2 _set_get_object

Provided with an object property name, a class/package name and some data and this will initiate a new object of the given class passing it the data.

If you pass an undefined value, it will set the property as undefined, removing whatever was set before.

You can also provide an existing object of the given class. L</"_set_get_object"> will check the object provided does belong to the specified class or it will set an error and return undef.

It returns the object currently set, if any.

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

=head2 _set_get_scalar_or_object

Provided with an object property name, and a class/package name and this stores the value as an object calling L</"_set_get_object"> if the value is an object of class I<class> or as a string calling L</"_set_get_scalar">

If no value has been set yet, this returns a L<Module::Generic::Null> object to enable chaining.

=head2 _set_get_uri

Provided with an object property name, and an uri and this creates a L<URI> object and sets the property value accordingly.

It accepts an L<URI> object, an uri or urn string, or an absolute path, i.e. a string starting with C</>.

It returns the current value, if any, so the return value could be undef, thus it cannot be chained. Maybe it should return a L<Module::Generic::Null> object ?

=head2 _to_array_object

Provided with arguments or not, and this will return a L<Module::Generic::Array> object of those data.

    my $array = $self->_to_array_object( qw( Hello world ) ); # Becomes an array object of 'Hello' and 'world'
    my $array = $self->_to_array_object( [qw( Hello world )] ); # Becomes an array object of 'Hello' and 'world'

=head2 __dbh

if your module has the global variables C<DB_DSN>, this will create a database handler using L<DBI>

It will also use the following global variables in your module to set the database object: C<DB_RAISE_ERROR>, C<DB_AUTO_COMMIT>, C<DB_PRINT_ERROR>, C<DB_SHOW_ERROR_STATEMENT>, C<DB_CLIENT_ENCODING>, C<DB_SERVER_PREPARE>

If C<DB_SERVER_PREPARE> is provided and true, C<pg_server_prepare> will be set to true in the database handler.

It returns the database handler object.

=head2 DEBUG

Return the value of your global variable I<DEBUG>, if any.

=head2 VERBOSE

Return the value of your global variable I<VERBOSE>, if any.

=head1 SEE ALSO

L<Module::Generic::Exception>, L<Module::Generic::Array>, L<Module::Generic::Scalar>, L<Module::Generic::Boolean>, L<Module::Generic::Number>, L<Module::Generic::Null>, L<Module::Generic::Dynamic> and L<Module::Generic::Tie>

L<Number::Format>, L<Class::Load>, L<Scalar::Util>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2000-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
