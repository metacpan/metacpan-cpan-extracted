##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Scalar.pm
## Version v1.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2021/12/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Scalar;
BEGIN
{
    use common::sense;
    use warnings;
    use warnings::register;
    use Module::Generic::Array;
    use Module::Generic::Boolean;
    use Module::Generic::Number;
    use Module::Generic::Scalar;
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
    our $DEBUG = 0;
    our( $VERSION ) = 'v1.1.0';
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
    return( bless( \$init => ( ref( $this ) || $this ) ) );
}

sub append { ${$_[0]} .= $_[1]; return( $_[0] ); }

sub as_array { return( Module::Generic::Array->new( [ ${$_[0]} ] ) ); }

sub as_boolean { return( Module::Generic::Boolean->new( ${$_[0]} ? 1 : 0 ) ); }

sub as_number { return( $_[0]->_number( ${$_[0]} ) ); }

## sub as_string { CORE::defined( ${$_[0]} ) ? return( ${$_[0]} ) : return; }

sub as_string { return( ${$_[0]} ); }

sub callback
{
    my $self = CORE::shift( @_ );
    my( $what, $code ) = @_;
    if( !defined( $what ) )
    {
        warnings::warn( "No callback type was provided.\n" ) if( warnings::enabled( 'Module::Generic::Scalar' ) );
        return;
    }
    elsif( $what ne 'add' && $what ne 'remove' )
    {
        warnings::warn( "Callback type provided ($what) is unsupported. Use 'add' or 'remove'.\n" ) if( warnings::enabled( 'Module::Generic::Scalar' ) );
        return;
    }
    elsif( scalar( @_ ) == 1 )
    {
        warnings::warn( "No callback code was provided. Provide an anonymous subroutine, or reference to existing subroutine.\n" ) if( warnings::enabled( 'Module::Generic::Scalar' ) );
        return;
    }
    elsif( defined( $code ) && ref( $code ) ne 'CODE' )
    {
        warnings::warn( "Callback provided is not a code reference. Provide an anonymous subroutine, or reference to existing subroutine." ) if( warnings::enabled( 'Module::Generic::Scalar' ) );
        return;
    }
    
    if( !defined( $code ) )
    {
        # undef is passed as an argument, so we remove the callback
        if( scalar( @_ ) >= 2 )
        {
            # The array is not tied, so there is nothing to remove.
            my $tie = tied( $$self );
            return(1) if( !$tie );
            my $rv = $tie->unset_callback( $what );
            print( STDERR ref( $self ), "::callback: Any callback left? ", ( $rv ? 'yes' : 'no' ), "\n" ) if( $DEBUG );
            untie( $$self ) if( !$tie->has_callback );
            return( $rv );
        }
        # Only 1 argument: get mode only
        else
        {
            my $tie = tied( $$self );
            return if( !$tie );
            return( $tie->get_callback( $what ) );
        }
    }
    # $code is defined, so we have something to set
    else
    {
        my $tie = tied( $$self );
        # Not tied yet
        if( !$tie )
        {
            $tie = tie( $$self => 'Module::Generic::Scalar::Tie',
            {
                data  => $self,
                debug => $DEBUG,
                $what => $code,
            }) || return;
            return(1);
        }
        $tie->set_callback( $what => $code ) || return;
        return(1);
    }
}

# Credits: John Gruber, Aristotle Pagaltzis
# https://gist.github.com/gruber/9f9e8650d68b13ce4d78
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
        (?<! -)                 # Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (in-flight)
        ( $small_re )
        (?= -[[:alpha:]]+)      # lookahead for "-someword"
    }{\u\L$1}xig;

    ## # e.g. "Stand-in" -> "Stand-In" (Stand is already capped at this point)
    $copy =~ s{
        \b
        (?<!…)                  # Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (stand-in)
        ( [[:alpha:]]+- )       # $1 = first word and hyphen, should already be properly capped
        ( $small_re )           # ... followed by small word
        (?! - )                 # Negative lookahead for another '-'
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

sub empty { return( shift->reset( @_ ) ); }

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

sub join { return( __PACKAGE__->new( CORE::join( CORE::splice( @_, 1, 1 ), ${ shift( @_ ) }, @_ ) ) ); }

sub lc { return( __PACKAGE__->_new( CORE::lc( ${$_[0]} ) ) ); }

sub lcfirst { return( __PACKAGE__->_new( CORE::lcfirst( ${$_[0]} ) ) ); }

sub left { return( $_[0]->_new( CORE::substr( ${$_[0]}, 0, CORE::int( $_[1] ) ) ) ); }

sub length { return( $_[0]->_number( CORE::length( ${$_[0]} ) ) ); }

sub like
{
    my $self = shift( @_ );
    my $str = shift( @_ );
    local @matches = ();
    local @rv = ();
    $str = CORE::defined( $str ) 
        ? ref( $str ) eq 'Regexp'
            ? $str
            : qr/(?:\Q$str\E)+/
        : qr/[[:blank:]\r\n]*/;
    @rv = $$self =~ /$str/;
    if( scalar( @{^CAPTURE} ) )
    {
        for( my $i = 0; $i < scalar( @{^CAPTURE} ); $i++ )
        {
            push( @matches, ${^CAPTURE}[$i] );
        }
    }
    # For named captures
    my $names = { %+ };
    unless( want( 'OBJECT' ) || want( 'SCALAR' ) || want( 'LIST' ) || scalar( @matches ) )
    {
        return(0);
    }
    return( Module::Generic::RegexpCapture->new( result => \@rv, capture => \@matches, name => $names ) );
}

sub lower { return( shift->lc ); }

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
    local @matches = ();
    local @rv = ();
    $re = CORE::defined( $re ) 
        ? ref( $re ) eq 'Regexp'
            ? $re
            : qr/(?:\Q$re\E)+/
        : $re;
    @rv = $$self =~ /$re/;
    # print( STDERR ref( $self ), "::match: \@rv is: @rv, has ", scalar( @rv ), " element(s): ", Module::Generic->dump( \@rv ), "\n" );
    if( scalar( @{^CAPTURE} ) )
    {
        for( my $i = 0; $i < scalar( @{^CAPTURE} ); $i++ )
        {
            push( @matches, ${^CAPTURE}[$i] );
        }
    }
    # For named captures
    my $names = { %+ };
    unless( want( 'OBJECT' ) || want( 'SCALAR' ) || want( 'LIST' ) || scalar( @matches ) )
    {
        return(0);
    }
    return( Module::Generic::RegexpCapture->new( result => \@rv, capture => \@matches, name => $names ) );
}

sub object { return( $_[0] ); }

sub open
{
    my $self = shift( @_ );
    my $io = Module::Generic::Scalar::IO->new( $self ) || do
    {
        $! = Module::Generic::Scalar::IO->error;
        return;
    };
    return( $io );
}

sub ord { return( $_[0]->_number( CORE::ord( ${$_[0]} ) ) ); }

sub pack { return( __PACKAGE__->_new( CORE::pack( $_[1], ${$_[0]} ) ) ); }

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

sub prepend { return( shift->substr( 0, 0, shift( @_ ) ) ); }

sub quotemeta { return( __PACKAGE__->_new( CORE::quotemeta( ${$_[0]} ) ) ); }

sub right { return( $_[0]->_new( CORE::substr( ${$_[0]}, ( CORE::int( $_[1] ) * -1 ) ) ) ); }

sub replace
{
    my( $self, $re, $replacement ) = @_;
    ## Only to test if this was a regular expression. If it was the array will contain successful match, other it will be empty
    ## @rv will contain the regexp matches or the result of the eval
    local @matches = ();
    local @rv = ();
    $re = CORE::defined( $re ) 
        ? ref( $re ) eq 'Regexp'
            ? $re
            : qr/(?:\Q$re\E)+/
        : $re;
    # return( $$self =~ s/$re/$replacement/gs );
    @rv = $$self =~ s/$re/$replacement/gs;
    if( scalar( @{^CAPTURE} ) )
    {
        for( my $i = 0; $i < scalar( @{^CAPTURE} ); $i++ )
        {
            push( @matches, ${^CAPTURE}[$i] );
        }
    }
    # For named captures
    my $names = { %+ };
    # print( STDERR ref( $self ), "::replace: \@rv contains ", scalar( @rv ), " element(s) and is ", Module::Generic->dump( \@rv ), " and \@matches is ", Module::Generic->dump( \@matches ), "\n" );
    # print( STDERR ref( $self ), "::replace: Does caller want an object? ", want('OBJECT') ? 'yes' : 'no', "\n" );
    unless( want( 'OBJECT' ) || want( 'SCALAR' ) || want( 'LIST' ) || scalar( @matches ) )
    {
        return(0);
    }
    return( Module::Generic::RegexpCapture->new( result => \@rv, capture => \@matches, name => $names ) );
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
    unless( ref( $expr ) eq 'Regexp' )
    {
        if( ref( $expr ) )
        {
            CORE::warn( "Expression provided is a reference of type '", ref( $expr ), "', but I was expecting either a regular expression or a simple string.\n" );
            return;
        }
        $expr = qr/\Q$expr\E/;
    }
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

sub TO_JSON { CORE::return( ${$_[0]} ); }

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

sub unpack
{
    my( $self, $tmpl ) = @_;
    my $ref = [CORE::unpack( $tmpl, $$self )];
    # In scalar context, return the first element, as per the original unpack behaviour
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( $self->_array( $ref ) );
    }
    elsif( Want::want( 'LIST' ) )
    {
        rreturn( @$ref );
    }
    elsif( Want::want( 'SCALAR' ) )
    {
        rreturn( $ref->[0] );
    }
    return;
}

sub upper { return( shift->uc ); }

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

# XXX Module::Generic::Scalar::IO class
{
    package
        Module::Generic::Scalar::IO;
    use parent qw( IO::Scalar );
    use Module::Generic::Exception ();
    use Scalar::Util ();
    use overload (
        '""' => sub{ ${ *{$_[0]}->{SR} } },
        # '""' => 'as_string',
        fallback => 1,
    );
    our $ERROR = '';
    our $VERSION = 'v0.1.0';

#     sub as_string
#     {
#         my $self = shift( @_ );
#         print( STDERR __PACKAGE__, "::as_string: Scalar ref object is: ", overload::StrVal( *$self->{SR} ), "\n" );
#         return( ${ *$self->{SR} } );
#     }
    
    sub close
    {
        my $self = CORE::shift( @_ );
        untie( *$self );
        return( 1 );
    }
    
    sub error
    {
        my $self = shift( @_ );
        if( @_ )
        {
            my $opts = {};
            if( ref( $_[0] ) eq 'HASH' )
            {
                $opts = shift( @_ );
            }
            else
            {
                $opts->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
                # http server error
                $opts->{code} = 500;
            }
            $opts->{skip_frames} = 1;
            *$self->{error} = $ERROR = Module::Generic::Exception->new( $opts );
            return;
        }
        else
        {
            return( ref( $self ) ? *$self->{error} : $ERROR );
        }
    }

    sub length
    {
        my $self = CORE::shift( @_ );
        return( CORE::length( ${ *$self->{SR} } ) );
    }
    
    sub line
    {
        my $self = shift( @_ );
        my $code = shift( @_ );
        return( $self->error( "No callback code was provided for line()" ) ) if( !defined( $code ) || ref( $code ) ne 'CODE' );
        my $opts = ref( $_[0] ) eq 'HASH' ? shift( @_ ) : { @_ };
        $opts->{chomp} //= 0;
        $opts->{auto_next} //= 0;
        my $l;
        while( defined( $l = $self->getline ) )
        {
            chomp( $l ) if( $opts->{chomp} );
            local $_ = $l;
            my $rv = $code->( $l );
            if( !defined( $rv ) && !$opts->{auto_next} )
            {
                last;
            }
        }
        return( $self );
    }
    
    sub object { return( *{ $_[0] }->{SR} ) }

    sub open
    {
        my( $self, $ref ) = @_;
        # print( STDERR __PACKAGE__, "::open: scalar ref provded is: ", overload::StrVal( $ref ), " (", defined( $$sref ) ? 'undefined' : $$sref, ")\n" );
        unless( Scalar::Util::blessed( $ref ) && $ref->isa( 'Module::Generic::Scalar' ) )
        {
            return( $self->error( "Value provided for ", ref( $self ), " is not an Module::Generic::Scalar object." ) );
        }

        # Setup:
        *$self->{Pos} = 0;          # seek position
        *$self->{SR}  = $ref;      # scalar reference
        # print( STDERR __PACKAGE__, "::open: Scalar ref object is: ", overload::StrVal( *$self->{SR} ), "\n" );
        return( $self );
    }
    
    sub opened { return( tied( *{$_[0]} ) ); }
    
    sub print
    {
        my $self = CORE::shift( @_ );
        my $len  = CORE::length( ${*$self->{SR}} );
        substr( ${*$self->{SR}}, *$self->{Pos}, 0, CORE::join( '', @_ ) . (CORE::defined( $\ ) ? $\ : "" ) );
        *$self->{Pos} += ( CORE::length( ${*$self->{SR}} ) - $len );
        # print( STDERR __PACKAGE__, "::print: Position is ", *$self->{Pos}, " and length is: ", length( ${*$self->{SR}} ), "\n" );
        1;
    }
    
    sub truncate
    {
        my $self = CORE::shift( @_ );
        my $removed = CORE::substr( ${*$self->{SR}}, *$self->{Pos}, CORE::length( ${*$self->{SR}} ) - *$self->{Pos}, '' );
        return( CORE::length( $removed ) );
    }
}

{
    package
        Module::Generic::RegexpCapture;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        use overload (
            '""' => sub{ $_[0]->matched },
            '0+' => sub{ $_[0]->matched },
            fallback => 1,
        );
        our $ERROR = '';
        our $VERSION = 'v0.1.0';
    };
    
    sub init
    {
        my $self = shift( @_ );
        $self->{capture}    = [];
        $self->{name}       = {};
        $self->{result}     = 0;
        $self->{_init_strict_use_sub} = 1;
        return( $self->SUPER::init( @_ ) );
    }
    
    sub capture { return( shift->_set_get_array_as_object( 'capture', @_ ) ); }
    
    sub matched
    {
        my $res = shift->result;
        # There may be one entry of empty value when there is no match, so we check for length
        return( $res->length->scalar ) if( $res->length && length( $res->get(0) ) );
        return(0);
    }
    
    sub name { return( shift->_set_get_hash_as_object( 'name', @_ ) ); }
    
    sub result { return( shift->_set_get_array_as_object( 'result', @_ ) ); }
}

{
    package
        Module::Generic::Scalar::Tie;
    BEGIN
    {
        use strict;
        use warnings;
        use Scalar::Util ();
        our $dummy_callback = sub{1};
    };
    
    sub TIESCALAR
    {
        my( $class, $opts ) = @_;
        $opts //= {};
        if( Scalar::Util::reftype( $opts ) ne 'HASH' )
        {
            warn( "Options provided (", overload::StrVal( $opts ), ") is not an hash reference\n" );
            $opts = {};
        }
        $opts->{data} //= '';
        $opts->{debug} //= 0;
        if( CORE::length( $opts->{add} ) && ref( $opts->{add} ) ne 'CODE' )
        {
            warnings::warn( "Code provided for the scalar add callback is not a code reference.\n" ) if( warnings::enabled( 'Module::Generic::Sscalar' ) || $opts->{debug} );
            return;
        }
        if( CORE::length( $opts->{remove} ) && ref( $opts->{remove} ) ne 'CODE' )
        {
            warnings::warn( "Code provided for the scalar remove callback is not a code reference.\n" ) if( warnings::enabled( 'Module::Generic::Sscalar' ) || $opts->{debug} );
            return;
        }
        
        my $ref =
        {
        callback_add => $opts->{add},
        callback_remove => $opts->{remove},
        data => ( Scalar::Util::reftype( $opts->{data} ) eq 'SCALAR' ? \"${$opts->{data}}" : \undef ),
        debug => $opts->{debug},
        };
        print( STDERR ( ref( $class ) || $class ), "::TIESCALAR: Using ", CORE::length( ${$ref->{data}} ), " bytes of data in scalar vs ", CORE::length( ${$opts->{data}} ), " bytes received via opts->data.\n" ) if( $ref->{debug} );
        return( bless( $ref => ( ref( $class ) || $class ) ) );
    }
    
    sub FETCH
    {
        my $self = shift( @_ );
        return( ${$self->{data}} );
    }

    sub STORE
    {
        my( $self, $value ) = @_;
        my $index = 0;
        my $rv;
        # New value is smaller than our current, so this is a removal. It could be partial or total
        if( CORE::length( "$value" ) < CORE::length( ${$self->{data}} ) )
        {
            my $cb = $self->{callback_remove} || $dummy_callback;
            if( !$cb )
            {
                warnings::warn( "No callback remove found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Scalar' ) || $self->{debug} );
                $rv = 1;
            }
            else
            {
                $rv = $cb->({ type => 'remove', removed => \"${$self->{data}}", added => \$value });
            }
        }
        else
        {
            my $cb = $self->{callback_add} || $dummy_callback;
            if( !$cb )
            {
                warnings::warn( "No callback add found. This should not happen.\n" ) if( warnings::enabled( 'Module::Generic::Scalar' ) || $self->{debug} );
                $rv = 1;
            }
            else
            {
                $rv = $cb->({ type => 'add', added => \$value });
            }
        }
        
        print( STDERR ref( $self ), "::STORE: adding ", CORE::length( "$value" ), " bytes of data ($value) at position $index with current data of ", CORE::length( ${$self->{data}} ), " bytes (", ${$self->{data}}, ") -> callback returned ", ( defined( $rv ) ? 'true' : 'undef' ), "\n" ) if( $self->{debug} );
        return if( !defined( $rv ) );
        ${$self->{data}} = $value;
    }

    sub has_callback
    {
        my $self = shift( @_ );
        return(1) if( ref( $self->{callback_add} ) eq 'CODE' || ref( $self->{callback_remove} ) eq 'CODE' );
        return(0);
    }
    
    sub set_callback
    {
        my( $self, $what, $code ) = @_;
        if( !defined( $what ) )
        {
            warn( "No callback type was provided. Use \"add\" or \"remove\".\n" );
            return;
        }
        elsif( $what ne 'add' && $what ne 'remove' )
        {
            warn( "Unknown callback type was provided: '$what'. Use \"add\" or \"remove\".\n" );
            return;
        }
        elsif( !defined( $code ) )
        {
            warn( "No callback anonymous subroutine or subroutine reference was provided.\n" );
            return;
        }
        elsif( ref( $code ) ne 'CODE' )
        {
            warn( "Callback provided (", overload::StrVal( $code ), ") is not a code reference.\n" );
            return;
        }
        $self->{ "callback_${what}" } = $code;
        return(1);
    }
    
    sub unset_callback
    {
        my( $self, $what ) = @_;
        if( !defined( $what ) )
        {
            warn( "No callback type was provided. Use \"add\" or \"remove\".\n" );
            return;
        }
        elsif( $what ne 'add' && $what ne 'remove' )
        {
            warn( "Unknown callback type was provided: '$what'. Use \"add\" or \"remove\".\n" );
            return;
        }
        $self->{ "callback_${what}" } = undef;
        return(1);
    }
}

1;

__END__
