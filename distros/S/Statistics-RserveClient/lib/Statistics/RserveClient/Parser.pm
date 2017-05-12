# * Statistics::RserveClient message Parser
# * @author Djun Kim
# * Based on Clément Turbelin's PHP client
# * Licensed under GPL v2 or at your option v3

package Statistics::RserveClient::Parser;

our $VERSION = '0.12'; #VERSION

#use strict;
#use warnings;
#use diagnostics;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(parse);

use Data::Dumper;

#use Statistics::RserveClient;
#use Statistics::RserveClient::ParserException;

use Statistics::RserveClient::Funclib;
use Statistics::RserveClient qw( TRUE FALSE :xt_types );

use Statistics::RserveClient::REXP;

#use Statistics::RserveClient::REXP::Null;
#use Statistics::RserveClient::REXP::GenericVector;

#use Statistics::RserveClient::REXP::Symbol;
#use Statistics::RserveClient::REXP::List;
#use Statistics::RserveClient::REXP::Language;
#use Statistics::RserveClient::REXP::Integer;
#use Statistics::RserveClient::REXP::Double;
#use Statistics::RserveClient::REXP::String;
#use Statistics::RserveClient::REXP::Raw;
#use Statistics::RserveClient::REXP::Logical;

# * Global parameters to parse() function
# * If true, use Statistics::RserveClient_RNative wrapper instead of native array to
#   handle attributes

#public static $use_array_object = FALSE;
my $_use_array_object = FALSE;

#forward definition to avoid warnings pragma complaints
sub use_array_object();

sub use_array_object() {
    my $value = shift;
    if ( defined($value) ) {
        $_use_array_object = $value;
    }
    return $_use_array_object;
}

# * Transform factor to native strings, only for parse() method
# * If false, factors are parsed as integers
#public static $factor_as_string = TRUE;
my $_factor_as_string = TRUE;

sub factor_as_string() {
    my $value = shift;
    if ( defined($value) ) {
        $_factor_as_string = $value;
    }
    return $_factor_as_string;
}

# * parse SEXP results -- limited implementation for now (large
#   packets and some data types are not supported)
# * @param string $buf
# * @param int $offset
# * @param unknown_type $attr
#public static function parse($buf, $offset, $attr = NULL) {

sub parse {
    Statistics::RserveClient::debug "parse()\n";
    my $n = @_;
    Statistics::RserveClient::debug "num args = $n\n";
    Statistics::RserveClient::debug Dumper(@_);

    my $buf    = $_[0];
    my $offset = 0;
    my %attr   = ();

    if ( $n == 3 ) {
        $offset = $_[1];
        %attr   = $_[2];
    }
    elsif ( $n == 2 ) {
        $offset = $_[1];
    }
    elsif ( @_ == 1 ) {
        die "Statistics::RserveClient::Parser::parse(): too few arguments.\n";
    }

    Statistics::RserveClient::debug "buf = $buf\n";
    Statistics::RserveClient::debug "offset = $offset\n";

    my @a = ();

    my @names = ();
    my @na    = ();
    my @r     = split '', $buf;

    # foreach (@r) {print "[" . ord($_). ":". $_ . "]"};  print "\n";
    Statistics::RserveClient::debug Statistics::RserveClient::buf2str(\@r);

    my $i = $offset;
    my $eoa;

    Statistics::RserveClient::debug "i = $i\n";

    # some simple parsing - just skip attributes and assume short responses
    my $ra = Statistics::RserveClient::Funclib::int8( \@r, $i );
    my $rl = Statistics::RserveClient::Funclib::int24( \@r, $i + 1 );

    Statistics::RserveClient::debug "ra = $ra\n";
    Statistics::RserveClient::debug "rl = $rl\n";

    my $al;

    $i += 4;

    $offset = $eoa = $i + $rl;
# Statistics::RserveClient::debug '[ '.Statistics::RserveClient::Parser::xtName($ra & 63).', length '.$rl.' ['.$i.' - '.$eoa."]\n";
    if ( ( $ra & 64 ) == 64 ) {
        die('Fatal error: long packets are not supported (yet).');
    }
    if ( $ra > Statistics::RserveClient::XT_HAS_ATTR ) {
        # Statistics::RserveClient::debug '(ATTR*[';
        $ra &= ~Statistics::RserveClient::XT_HAS_ATTR;
        $al = Statistics::RserveClient::Funclib::int24( \@r, $i + 1 );
        %attr = parse( $buf, $i );
        # Statistics::RserveClient::debug '])';
        $i += $al + 4;
    }

    for ($ra) {
        if ( $ra == Statistics::RserveClient::XT_NULL ) {
            Statistics::RserveClient::debug "Null\n";
            @a = undef;
            # break;
        }
        elsif ( $ra == Statistics::RserveClient::XT_VECTOR ) {    # generic vector
            Statistics::RserveClient::debug "Vector\n";
            @a = ();
            while ( $i < $eoa ) {
                Statistics::RserveClient::debug "******* i = $i\n";
                #$a[] = parse($buf, &$i);
                Statistics::RserveClient::debug("recursive call to parse($buf, $i)\n");
                my $sub_ra = Statistics::RserveClient::Funclib::int8( \@r, $i );
                my @parse_result = parse( $buf, $i );
                #print "*{" . Dumper(@parse_result) . "}*\n";

                ## lists and arrays are added as references
                if ($sub_ra == Statistics::RserveClient::XT_VECTOR ||
                    scalar(@parse_result) > 1) {
                    push( @a, \@parse_result );
                } else {
                    ## otherwise it's an R "scalar" (one-element array)
                    push( @a, @parse_result );
                }
                #print Dumper(@a) . "\n";
            }
            Statistics::RserveClient::debug Dumper(@a);
         # if the 'names' attribute is set, convert the plain array into a map
            if ( defined( $attr{'names'} ) ) {
                @names = $attr{'names'};
                @na    = ();
                my $n = length($a);
                for ( my $k = 0; $k < $n; $k++ ) {
                    $na[ $names[$k] ] = $a[$k];
                }
                @a = @na;
            }
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_INT ) {
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_INT\n";
            @a = Statistics::RserveClient::Funclib::int32( \@r, $i );
            $i += 4;
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_DOUBLE ) {
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_DOUBLE\n";
            @a = Statistics::RserveClient::Funclib::flt64( \@r, $i );
            $i += 8;
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_BOOL ) {
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_BOOL\n";
            my $v = Statistics::RserveClient::Funclib::int8( \@r, $i++ );
            @a
                = ( $v == 1 )
                ? TRUE
                : ( ( $v == 0 ) ? FALSE : undef );
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_SYMNAME ) {    # symbol
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_SYMNAME\n";
            my $oi = $i;
            while ( $i < $eoa && ord( $r[$i] ) != 0 ) {
                $i++;
            }
            @a = split '', substr( $buf, $oi, $i - $oi );
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_LANG_NOTAG or $ra == Statistics::RserveClient::XT_LIST_NOTAG )
        {                                        # pairlist w/o tags
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_LANG_NOTAG or Statistics::RserveClient::XT_LIST_NOTAG\n";
            @a = ();
            while ( $i < $eoa ) {
                # $a[] = self::parse($buf, &$i);
                push( @a, parse( $buf, $i, %attr ) );
            }
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_LIST_TAG or $ra == Statistics::RserveClient::XT_LANG_TAG )
        {                                        # pairlist with tags
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_LIST_TAG or Statistics::RserveClient::XT_LANG_TAG\n";
            @a = ();

            Statistics::RserveClient::debug "eoa = $eoa\n";

            while ( $i < $eoa ) {
                Statistics::RserveClient::debug "before parse: i = $i\n";
                my $val = parse( $buf, $i );
                Statistics::RserveClient::debug "after first parse: i = $i\n";
                my $tag = parse( $buf, $i );
                Statistics::RserveClient::debug "after second parse: i = $i\n";
                $a[$tag] = $val;
            }
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_INT ) {    # integer array
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_INT\n";
            @a = ();
            while ( $i < $eoa ) {
                # $a[] = int32(@r, $i);
                push( @a, Statistics::RserveClient::Funclib::int32( \@r, $i ) );
                $i += 4;
            }
            if ( scalar(@a) == 1 ) {
                @a = $a[0];
            }
            # If factor, then transform to characters
            #if (self::$factor_as_string and isset($attr['class'])) {
            if ( factor_as_string() and defined( $attr{'class'} ) ) {
                my $c = $attr{'class'};
                if ( $c eq 'factor' ) {
                    my $n      = scalar(@a);
                    my @levels = $attr{'levels'};
                    for ( my $k = 0; $k < $n; ++$k ) {
                        $i = $a[$k];
                        if ( $i < 0 ) {
                            $a[$k] = undef;
                        }
                        else {
                            $a[$k] = $levels[ $i - 1 ];
                        }
                    }
                }
            }
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_DOUBLE ) {    # double array
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_DOUBLE\n";
            @a = ();
            while ( $i < $eoa ) {
                #$a[] = flt64(@r, $i);
                push( @a, Statistics::RserveClient::Funclib::flt64( \@r, $i ) );
                $i += 8;
            }
            if ( scalar(@a) == 1 ) {
                @a = $a[0];
            }
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_STR ) {    # string array
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_STR\n";
            @a = ();
            my $oi = $i;

            while ( $i < $eoa ) {
                if ( ord( $r[$i] ) == 0 ) {
                    #$a[] = substr($r, $oi, $i - $oi);
                    push( @a, join( '', @r[ $oi .. $i - 1 ] ) );
                    $oi = $i + 1;
                }
                $i++;
            }
            if ( scalar(@a) == 1 ) {
                @a = $a[0];
            }
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_BOOL ) {    # boolean vector
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_BOOL\n";
            my $n = Statistics::RserveClient::Funclib::int32( \@r, $i );
            $i += 4;
            my $k = 0;
            @a = ();
            while ( $k < $n ) {
                my $v = Statistics::RserveClient::Funclib::int8( \@r, $i++ );
                $a[ $k++ ]
                    = ( $v == 1 )
                    ? TRUE
                    : ( ( $v == 0 ) ? FALSE : undef );
            }
            if ( $n == 1 ) {
                @a = $a[0];
            }
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_RAW ) {    # raw vector
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_RAW\n";
            my $len = Statistics::RserveClient::Funclib::int32( \@r, $i );
            $i += 4;
            @a = splice( @r, $i, $len );
            # break;
        }

        #  elsif ($ra == Statistics::RserveClient::XT_ARRAY_CPLX) {
        #   break;
        # }

        elsif ( $ra == 48 ) {    # unimplemented type in Statistics::RserveClient
            my $uit = Statistics::RserveClient::Funclib::int32( \@r, $i );
            warn "Note: result contains type #$uit unsupported by Statistics::RserveClient.<br/>";
            @a = undef;
            # break;
        }

        else {
            warn(     'Warning: type '
                    . $ra
                    . ' is currently not implemented in the Perl client.' );
            @a = undef;
        }
    }    # end switch

    Statistics::RserveClient::debug "after parse: offset = $offset\n";
    Statistics::RserveClient::debug "after parse: \$_[1] = " . $_[1] . "\n";
    $_[1] = $offset;

    #if (self::$use_array_object) {
    if ( use_array_object() ) {
        # if ( is_array(@a) & @attr ) {
        if ( ( ref(@a) == 'ARRAY' ) & %attr ) {
            return new Statistics::RserveClient::RNative( @a, %attr );
        }
    }
    return @a;
}

# * parse SEXP to Debug array(type, length,offset, contents, n)
# * @param string $buf
# * @param int $offset
# * @param unknown_type $attr

sub parseDebug(@);

sub parseDebug(@) {
    Statistics::RserveClient::debug "parseDebug()\n";

    my $buf;
    my $offset;
    my @attr = undef;

    if ( @_ == 3 ) {
        $buf    = shift;
        $offset = shift;
        @attr   = shift;
    }
    elsif ( @_ == 2 ) {
        ( $buf, $offset ) = shift;
    }
    elsif ( @_ == 1 ) {
        die "Statistics::RserveClient::Parser::parse(): too few arguments.\n";
    }

    Statistics::RserveClient::debug "buf = $buf\n";
    Statistics::RserveClient::debug "offset = $offset\n";

    my @r = split '', $buf;

    my $i = $offset;

    my @a = ();

    # some simple parsing - just skip attributes and assume short responses
    my $ra = Statistics::RserveClient::Funclib::int8( \@r, $i );
    my $rl = Statistics::RserveClient::Funclib::int24( \@r, $i + 1 );

    Statistics::RserveClient::debug "ra = $ra\n";
    Statistics::RserveClient::debug "rl = $ra\n";

    $i += 4;

    my $eoa;
    $offset = $eoa = $i + $rl;

    my %result = ();

    $result{'type'}   = Statistics::RserveClient::Parser::xtName( $ra & 63 );
    $result{'length'} = $rl;
    $result{'offset'} = $i;
    $result{'eoa'}    = $eoa;
    if ( ( $ra & 64 ) == 64 ) {
        $result{'long'} = TRUE;
        return %result;
    }
    if ( $ra > Statistics::RserveClient::XT_HAS_ATTR ) {

        $ra &= ~Statistics::RserveClient::XT_HAS_ATTR;
        my $al = Statistics::RserveClient::Funclib::int24( \@r, $i + 1 );
        @attr = parseDebug( $buf, $i );
        $result{'attr'} = @attr;
        $i += $al + 4;
    }
    if ( $ra == Statistics::RserveClient::XT_NULL ) {
        return %result;
    }
    if ( $ra == Statistics::RserveClient::XT_VECTOR ) {    # generic vector
        @a = ();
        while ( $i < $eoa ) {
            #$a[] = self::parseDebug($buf, &$i);
            push( @a, parseDebug( $buf, $i ) );
        }
        $result{'contents'} = $a;
    }
    if ( $ra == Statistics::RserveClient::XT_SYMNAME ) {    # symbol
        my $oi = $i;
        while ( $i < $eoa && ord( $r[$i] ) != 0 ) {
            $i++;
        }
        $result{'contents'} = substr( $buf, $oi, $i - $oi );
    }
    if ( $ra == Statistics::RserveClient::XT_LIST_NOTAG || $ra == Statistics::RserveClient::XT_LANG_NOTAG )
    {                                     # pairlist w/o tags
        @a = ();
        while ( $i < $eoa ) {
            #$a[] = self::parseDebug($buf, &$i);
            push( @a, parseDebug( $buf, $i ) );
        }
        $result{'contents'} = $a;
    }
    if ( $ra == Statistics::RserveClient::XT_LIST_TAG || $ra == Statistics::RserveClient::XT_LANG_TAG )
    {                                     # pairlist with tags
        @a = ();
        while ( $i < $eoa ) {
            my $val = parseDebug( $buf, $i );
            my $tag = parse( $buf, $i );
            $a[$tag] = $val;
        }
        $result{'contents'} = $a;
    }
    if ( $ra == Statistics::RserveClient::XT_ARRAY_INT ) {    # integer array
        @a = ();
        while ( $i < $eoa ) {
            #$a[] = int32(@r, $i);
            push( @a, Statistics::RserveClient::Funclib::int32( \@r, $i ) );
            $i += 4;
        }
        if ( length($a) == 1 ) {
            $result{'contents'} = $a[0];
        }
        $result{'contents'} = $a;
    }
    if ( $ra == Statistics::RserveClient::XT_ARRAY_DOUBLE ) {    # double array
        @a = ();
        while ( $i < $eoa ) {
            push( @a, Statistics::RserveClient::Funclib::flt64( \@r, $i ) );
            $i += 8;
        }
        if ( length($a) == 1 ) {
            $result{'contents'} = $a[0];
        }
        $result{'contents'} = $a;
    }
    if ( $ra == Statistics::RserveClient::XT_ARRAY_STR ) {       # string array
        @a = ();
        my $oi = $i;
        while ( $i < $eoa ) {
            if ( ord( $r[$i] ) == 0 ) {
                # $a[] = substr($r, $oi, $i - $oi);
                push( @a, splice( @r, $oi, $i - $oi ) );
                $oi = $i + 1;
            }
            $i++;
        }
        if ( length($a) == 1 ) {
            $result{'contents'} = $a[0];
        }
        $result{'contents'} = $a;
    }
    if ( $ra == Statistics::RserveClient::XT_ARRAY_BOOL ) {    # boolean vector
        my $n = Statistics::RserveClient::Funclib::int32( \@r, $i );
        $result{'size'} = $n;
        $i += 4;
        my $k = 0;
        @a = ();
        while ( $k < $n ) {
            my $v = Statistics::RserveClient::Funclib::int8( \@r, $i++ );
  # $a[$k] = ($v === 1) ? TRUE : (($v === 0) ? FALSE : undef);
            $a[$k]
                = ( ( $v == 1 ) && is_number($v) )
                ? TRUE
                : (
                ( ( $v == 0 ) && is_number($v) ) ? FALSE : undef );
            ++$k;
        }
        if ( length($a) == 1 ) {
            $result{'contents'} = $a[0];
        }
        $result{'contents'} = $a;
    }
    if ( $ra == Statistics::RserveClient::XT_RAW ) {    # raw vector
        my $len = Statistics::RserveClient::Funclib::int32( \@r, $i );
        $i += 4;
        $result{'size'} = $len;
        my $contents = join( '', substr( @r, $i, $len ) );
        $result{'contents'} = $contents;
    }
    if ( $ra == Statistics::RserveClient::XT_ARRAY_CPLX ) {
        $result{'not_implemented'} = TRUE;
        # TODO: complex
    }
    if ( $ra == 48 ) {                # unimplemented type in Statistics::RserveClient
        my $uit = Statistics::RserveClient::Funclib::int32( \@r, $i );
        $result{'unknownType'} = $uit;
    }
    return %result;
}

#public static function parseREXP($buf, $offset, $attr = NULL) {
sub parseREXP(@);

sub parseREXP(@) {

    Statistics::RserveClient::debug "parseREXP()\n";

    my $buf;
    my $offset;
    my @attr = undef;

    if ( @_ == 3 ) {
        $buf    = shift;
        $offset = shift;
        @attr   = shift;
    }
    elsif ( @_ == 2 ) {
        ( $buf, $offset ) = shift;
    }
    elsif ( @_ == 1 ) {
        die "Statistics::RserveClient::Parser::parse(): too few arguments.\n";
    }

    #Statistics::RserveClient::debug "buf = $buf\n";
    #Statistics::RserveClient::debug "offset = $offset\n";

    my @r = split '', $buf;
    my $i = $offset;

    my @v = ();

    # some simple parsing - just skip attributes and assume short responses
    my $ra = Statistics::RserveClient::Funclib::int8( \@r, $i );
    my $rl = Statistics::RserveClient::Funclib::int24( \@r, $i + 1 );

    Statistics::RserveClient::debug "ra = $ra\n";
    Statistics::RserveClient::debug "rl = $ra\n";

    # Statistics::RserveClient::debug Dumper($rl);

    #my $eoa = int24(0);
    my $eoa = 0;

    my $al, $i += 4;

    $offset = $eoa = $i + $rl;
    if ( ( $ra & 64 ) == 64 ) {
        die('Fatal error: long packets are not supported (yet).');
    }

    if ( $ra > Statistics::RserveClient::XT_HAS_ATTR ) {
        $ra &= ~Statistics::RserveClient::XT_HAS_ATTR;
        $al = Statistics::RserveClient::Funclib::int24( \@r, $i + 1 );
        @attr = parseREXP( $buf, $i );
        $i += $al + 4;
    }
    for ($ra) {
        if ( $ra == Statistics::RserveClient::XT_NULL ) {
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_NULL\n";
            $a = new Statistics::RserveClient::REXP::Null();
            # break;
        }
        elsif ( $ra == Statistics::RserveClient::XT_VECTOR ) {    # generic vector
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_VECTOR\n";
            @v = ();
            while ( $i < $eoa ) {
                # $v[] = self::parseREXP($buf, &$i);
                push( @v, parseREXP( $buf, $i ) );
            }
            $a = new Statistics::RserveClient::REXP::GenericVector();
            $a->setValues(@v);
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_SYMNAME ) {    # symbol
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_SYMNAME\n";
            my $oi = $i;
            while ( $i < $eoa && ord( $r[$i] ) != 0 ) {
                $i++;
            }
            my $v = substr( $buf, $oi, $i - $oi );
            my $a = new Statistics::RserveClient::REXP::Symbol();
            $a->setValue($v);
            # break;
        }
        elsif ( $ra == Statistics::RserveClient::XT_LIST_NOTAG or $ra == Statistics::RserveClient::XT_LANG_NOTAG )
        {                                        # pairlist w/o tags
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_LIST_NOTAG or Statistics::RserveClient::XT_LANG_NOTAG\n";
            @v = ();
            while ( $i < $eoa ) {
                #$v[] = self::parseREXP($buf, &$i);
                push( @v, parseREXP( $buf, $i ) );
            }
            my $clasz
                = ( $ra == Statistics::RserveClient::XT_LIST_NOTAG )
                ? 'Statistics::RserveClient::REXP::List'
                : 'Statistics::RserveClient::REXP::Language';
            $a = new $$clasz();
            $a->setValues($a);
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_LIST_TAG or $ra == Statistics::RserveClient::XT_LANG_TAG )
        {    # pairlist with tags
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_LIST_TAG or Statistics::RserveClient::XT_LANG_TAG\n";
            my $clasz
                = ( $ra == Statistics::RserveClient::XT_LIST_TAG )
                ? 'Statistics::RserveClient::REXP::List'
                : 'Statistics::RserveClient::REXP::Language';
            my @v     = ();
            my @names = ();
            while ( $i < $eoa ) {
                #$v[] = self::parseREXP($buf, &$i);
                push( @v, parseREXP( $buf, $i ) );
                # $names[] = self::parseREXP($buf, &$i);
                push( @names, parseREXP( $buf, $i ) );
            }
            $a = new $$clasz();
            $a->setValues(@v);
            $a->setNames(@names);
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_INT ) {    # integer array
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_INT\n";
            my @v = ();
            while ( my $i < $eoa ) {
                #$v[] = int32(@r, $i);
                push( @v, Statistics::RserveClient::Funclib::int32( \@r, $i ) );
                $i += 4;
            }
            $a = new Statistics::RserveClient::REXP::Integer();
            $a->setValues(@v);
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_DOUBLE ) {    # double array
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_DOUBLE\n";
            @v = ();
            while ( my $i < $eoa ) {
                # $v[] = flt64($r, $i);
                push( @v, Statistics::RserveClient::Funclib::flt64( \@r, $i ) );
                $i += 8;
            }
            $a = new Statistics::RserveClient::REXP::Double();
            $a->setValues(@v);
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_STR ) {    # string array
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_STR\n";
            @v = ();
            my $oi = $i;
            while ( my $i < $eoa ) {
                if ( ord( $r[$i] ) == 0 ) {
                    # $v[] = substr($r, $oi, $i - $oi);
                    push( @v, substr( @r, $oi, $i - $oi ) );
                    $oi = $i + 1;
                }
                $i++;
            }
            $a = new Statistics::RserveClient::REXP::String();
            $a->setValues(@v);
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_BOOL ) {    # boolean vector
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_BOOL\n";
            my $n = Statistics::RserveClient::Funclib::int32( \@r, $i );
            $i += 4;
            my $k  = 0;
            my @vv = ();
            while ( $k < $n ) {
                my $v = Statistics::RserveClient::Funclib::int8( \@r, $i++ );
                $vv[$k]
                    = ( $v == 1 )
                    ? TRUE
                    : ( ( $v == 0 ) ? FALSE : undef );
                $k++;
            }
            $a = new Statistics::RserveClient::REXP::Logical();
            $a->setValues(@vv);
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_RAW ) {    # raw vector
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_RAW\n";
            my $len = Statistics::RserveClient::Funclib::int32( \@r, $i );
            $i += 4;
            my @v = substr( @r, $i, $len );
            my $a = new Statistics::RserveClient::REXP::Raw();
            $a->setValue(@v);
            # break;
        }

        elsif ( $ra == Statistics::RserveClient::XT_ARRAY_CPLX ) {
            Statistics::RserveClient::debug "Statistics::RserveClient::XT_ARRAY_CPLX\n";
            $a = FALSE;
            # break;
        }

        elsif ( $ra == 48 ) {    # unimplemented type in Statistics::RserveClient
            Statistics::RserveClient::debug "48\n";
            my $uit = Statistics::RserveClient::Funclib::int32( \@r, $i );
        # echo "Note: result contains type #$uit unsupported by Statistics::RserveClient.<br/>";
            @a = undef;
            # break;
        }

        else {
            warn(     'Warning: type '
                    . $ra
                    . ' is currently not implemented in the Perl client.' );
            @a = FALSE;
        }
    }

    Statistics::RserveClient::debug "dumping a:\n";
    Statistics::RserveClient::debug Dumper(@a);
    Statistics::RserveClient::debug "done\n";

    #if ( scalar(@attr) && is_object(@a) ) {
    if ( scalar(@attr) && @a ) {
        @a->setAttributes(@attr);
    }

    return @a;
}

#public static function  xtName($xt) {

sub xtName($) {
    my $xt = shift;

    if    ( $xt == Statistics::RserveClient::XT_NULL )         { return ('null'); }
    elsif ( $xt == Statistics::RserveClient::XT_INT )          { return 'int'; }
    elsif ( $xt == Statistics::RserveClient::XT_STR )          { return 'string'; }
    elsif ( $xt == Statistics::RserveClient::XT_DOUBLE )       { return 'real'; }
    elsif ( $xt == Statistics::RserveClient::XT_BOOL )         { return 'logical'; }
    elsif ( $xt == Statistics::RserveClient::XT_ARRAY_INT )    { return 'int*'; }
    elsif ( $xt == Statistics::RserveClient::XT_ARRAY_STR )    { return 'string*'; }
    elsif ( $xt == Statistics::RserveClient::XT_ARRAY_DOUBLE ) { return 'real*'; }
    elsif ( $xt == Statistics::RserveClient::XT_ARRAY_BOOL )   { return 'logical*'; }
    elsif ( $xt == Statistics::RserveClient::XT_ARRAY_CPLX )   { return 'complex*'; }
    elsif ( $xt == Statistics::RserveClient::XT_SYM )          { return 'symbol'; }
    elsif ( $xt == Statistics::RserveClient::XT_SYMNAME )      { return 'symname'; }
    elsif ( $xt == Statistics::RserveClient::XT_LANG )         { return 'lang'; }
    elsif ( $xt == Statistics::RserveClient::XT_LIST )         { return 'list'; }
    elsif ( $xt == Statistics::RserveClient::XT_LIST_TAG )     { return 'list+T'; }
    elsif ( $xt == Statistics::RserveClient::XT_LIST_NOTAG )   { return 'list/T'; }
    elsif ( $xt == Statistics::RserveClient::XT_LANG_TAG )     { return 'lang+T'; }
    elsif ( $xt == Statistics::RserveClient::XT_LANG_NOTAG )   { return 'lang/T'; }
    elsif ( $xt == Statistics::RserveClient::XT_CLOS )         { return 'clos'; }
    elsif ( $xt == Statistics::RserveClient::XT_RAW )          { return 'raw'; }
    elsif ( $xt == Statistics::RserveClient::XT_S4 )           { return 'S4'; }
    elsif ( $xt == Statistics::RserveClient::XT_VECTOR )       { return 'vector'; }
    elsif ( $xt == Statistics::RserveClient::XT_VECTOR_STR )   { return 'string[]'; }
    elsif ( $xt == Statistics::RserveClient::XT_VECTOR_EXP )   { return 'expr[]'; }
    elsif ( $xt == Statistics::RserveClient::XT_FACTOR )       { return 'factor'; }
    elsif ( $xt == Statistics::RserveClient::XT_UNKNOWN )      { return 'unknown'; }
    else {
        # unknown type
        return '<? ' . $xt . '>';
    }
}

# * @param Statistics::RserveClient::REXP $value
#  * This function is not functional. Please use it only for testing
#public static function createBinary(Statistics::RserveClient::REXP $value) {
sub createBinary($);

sub createBinary($) {

    my $value = shift;
    # Current offset
    my $o        = 0;                   # Init with header size
    my $contents = '';
    my $type     = $value->getType();

    for ($type) {
        if ( $type == Statistics::RserveClient::XT_S4 || $type == Statistics::RserveClient::XT_NULL ) {
            # break;
        }
        elsif ( $type == Statistics::RserveClient::XT_INT ) {
            my $v = 0 + $value->at(0);
            $contents .= Statistics::RserveClient::Funclib::mkint32($v);
            $o += 4;
            # break;
        }
        elsif ( $type == Statistics::RserveClient::XT_DOUBLE ) {
            my $v = 0.0 + $value->at(0);
            $contents .= Statistics::RserveClient::Funclib::mkfloat64($v);
            $o += 8;
            # break;
        }
        elsif ( $type == Statistics::RserveClient::XT_ARRAY_INT ) {
            my @vv = $value->getValues();
            my $n  = scalar(@vv);
            my $v;
            for ( my $i = 0; $i < $n; ++$i ) {
                $v = $vv[$i];
                $contents .= Statistics::RserveClient::Funclib::mkint32($v);
                $o += 4;
            }
            # break;
        }
        elsif ( $type == Statistics::RserveClient::XT_ARRAY_BOOL ) {
            my @vv = $value->getValues();
            my $n  = scalar(@vv);
            my $v;
            $contents .= Statistics::RserveClient::Funclib::mkint32($n);
            $o += 4;
            if ($n) {
                for ( my $i = 0; $i < $n; ++$i ) {
                    $v = $vv[$i];
                    if ( !defined($v) ) {
                        $v = 2;
                    }
                    else {
                        $v = 0 + $v;
                    }
                    if ( $v != 0 and $v != 1 ) {
                        $v = 2;
                    }
                    $contents .= chr($v);
                    ++$o;
                }
                while ( ( $o & 3 ) != 0 ) {
                    $contents .= chr(3);
                    ++$o;
                }
            }
            # break;
        }
        elsif ( $type == Statistics::RserveClient::XT_ARRAY_DOUBLE ) {
            my @vv = $value->getValues();
            my $n  = scalar(@vv);
            my $v;
            for ( my $i = 0; $i < $n; ++$i ) {
                $v = 0.0 + $vv[$i];
                $contents .= Statistics::RserveClient::Funclib::mkfloat64($v);
                $o += 8;
            }
            # break;
        }
        elsif ( $type == Statistics::RserveClient::XT_RAW ) {
            my $v = $value->getValue();
            my $n = $value->length();
            $contents .= Statistics::RserveClient::Funclib::mkint32($n);
            $o += 4;
            $contents .= $v;
            # break;
        }
        elsif ( $type == Statistics::RserveClient::XT_ARRAY_STR ) {
            my @vv = $value->getValues();
            my $n  = scalar(@vv);
            my $v;
            for ( my $i = 0; $i < $n; ++$i ) {
                $v = $vv[$i];
                if ($v) {
                    if ( ord( substr( $v, 0, 1 ) ) == 255 ) {
                        $contents .= chr(255);
                        ++$o;
                    }
                    $contents .= $v . chr(0);
                    $o += length($v) + 1;
                }
                else {
                    $contents .= chr(255) . chr(0);
                    $o += 2;
                }
            }
            while ( ( $o & 3 ) != 0 ) {
                $contents .= chr(1);
                ++$o;
            }
            # break;
        }
        elsif ($type == Statistics::RserveClient::XT_LIST_TAG
            || $type == Statistics::RserveClient::XT_LIST_NOTAG
            || $type == Statistics::RserveClient::XT_LANG_TAG
            || $type == Statistics::RserveClient::XT_LANG_NOTAG
            || $type == Statistics::RserveClient::XT_LIST
            || $type == Statistics::RserveClient::XT_VECTOR
            || $type == Statistics::RserveClient::XT_VECTOR_EXP )
        {
            my @l     = $value->getValues();
            my @names = ();
            if (   $type == Statistics::RserveClient::XT_LIST_TAG
                || $type == Statistics::RserveClient::XT_LANG_TAG )
            {
                @names = $value->getNames();
            }
            my $i = 0;
            my $n = scalar(@l);
            while ( $i < $n ) {
                my $x = $l[$i];
                if ( defined($x) ) {
                    $x = new Statistics::RserveClient::REXP::Null();
                }
                my $iof = strlen($contents);
                $contents .= createBinary($x);
                if (   $type == Statistics::RserveClient::XT_LIST_TAG
                    || $type == Statistics::RserveClient::XT_LANG_TAG )
                {
                    my $sym = new Statistics::RserveClient::REXP::Symbol();
                    $sym->setValue( $names[$i] );
                    $contents .= createBinary($sym);
                }
                ++$i;
            }
            # break;
        }

        elsif ( $type == Statistics::RserveClient::XT_SYMNAME or $type == Statistics::RserveClient::XT_STR ) {
            my $s = '' . $value->getValue();
            $contents .= $s;
            $o += strlen($s);
            $contents .= chr(0);
            ++$o;
            #padding if necessary
            while ( ( $o & 3 ) != 0 ) {
                $contents .= chr(0);
                ++$o;
            }
            # break;
        }

        else {
            # default for switch - handle this?
            die "unknown type";
        }
    }

    #
    # TODO: handling attr
    #  $attr = $value->attr();
    #  $attr_bin = '';
    #  if (defined($attr) ) {
    #    $attr_off = self::createBinary($attr, $attr_bin, 0);
    #    $attr_flag = Statistics::RserveClient::XT_HAS_ATTR;
    #   }
    #   else {
    #     $attr_off = 0;
    #     $attr_flag = 0;
    #   }
    # [0]   (4) header SEXP: len=4+m+n, XT_HAS_ATTR is set
    # [4]   (4) header attribute SEXP: len=n
    # [8]   (n) data attribute SEXP
    # [8+n] (m) data SEXP

    my $attr_flag = 0;
    my $length    = $o;
    my $isLarge   = ( $length > 0xfffff0 );
    my $code      = $type | $attr_flag;

    # SEXP Header (without ATTR)
    # [0]  (byte) eXpression Type
    # [1]  (24-bit int) length
    my @r;
    push( @r, chr( $code & 255 ) );
    push( @r, Statistics::RserveClient::Funclib::mkint24($length) );
    push( @r, $contents );
    return @r;
}

sub is_object($$) {
    # blessed $_[1] && $_[1]->isa($_[0]);
    my ( $obj, $name );
    if ( defined($obj) ) {
        return isa $obj, $name;
    }
    else {
        return FALSE;
    }
}

1;
