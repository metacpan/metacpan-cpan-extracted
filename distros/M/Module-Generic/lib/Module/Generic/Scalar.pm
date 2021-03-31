##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Scalar.pm
## Version v0.2.4
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2021/03/20
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
    our( $VERSION ) = 'v0.2.4';
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

1;

__END__
