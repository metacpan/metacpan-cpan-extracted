#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use Config;
    use JSON;
    use Test::More qw( no_plan );
    use_ok( 'Module::Generic::Scalar' ) || BAIL_OUT( "Unable to load Module::Generic::Scalar" );
    # use Nice::Try;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

use utf8;
my $str = "Hello world";
my $s = Module::Generic::Scalar->new( $str ) || BAIL_OUT( "Unable to instantiate an object." );
isa_ok( $s, 'Module::Generic::Scalar', 'Scalar object' );
is( "$s", $str, 'Stringification' );

my $s2 = $s->clone;
isa_ok( $s2, 'Module::Generic::Scalar', 'Scalar object' );
is( "$s2", $str, 'Cloning' );

$s .= "\n";
isa_ok( $s, 'Module::Generic::Scalar', 'Object after concatenation' );
is( $s, "$str\n", 'Checking updated string object' );
my $a1 = $s->clone( "Prefix; " );
$a1 .= $s;
my $s3 = Module::Generic::Scalar->new( 'A' );
my $res = $s3 x 12;
# diag( "$s3 x 12 = $res (" . ref( $res ) . ")" );
is( $res, 'AAAAAAAAAAAA', 'Multiplying string' );
isa_ok( $res, 'Module::Generic::Scalar', 'Multiplied string class object' );
# $res =~ s/A{2}$//;
$res->replace( qr/A{2}$/, '' );
# diag( "$s3 now is = $res (" . ref( $res ) . ")" );

isa_ok( Module::Generic::Scalar->new( 'true' )->as_boolean, 'Module::Generic::Boolean', 'Scalar to boolean' );

my $bool_1 = Module::Generic::Scalar->new( 'true' )->as_boolean;
# diag( "\$bool_1 is '$bool_1'" );
ok( $bool_1 == 1, 'Scalar value to true boolean' );
ok( !Module::Generic::Scalar->new( 0 )->as_boolean, 'Scalar value to false boolean' );

# diag( "\$s = '$s'" );
$s->chomp;
is( $s, 'Hello world', 'chomp' );
$s->chop;
is( $s, 'Hello worl', 'chop' );
## OpenBSD does not have des crypt it seems and uses blowfish instead
SKIP:
{
    if( $^O eq 'openbsd' || $Config{libs} !~ /\b\-lcrypt\b/ )
    {
        skip( "crypt unsupported on $^O", 1 );
    }
    is( $s->crypt( 'key' ), 'keqUNAuo7.kCQ', 'crypt' );
};
is( $s->fc( 'Hello worl' ), 1, 'fc' );
is( Module::Generic::Scalar->new( '0xAf' )->hex, 175, 'hex' );
isa_ok( Module::Generic::Scalar->new( '0xAf' )->hex, 'Module::Generic::Number' );
is( $s->index( 'wo' ), 6, 'index' );
is( $s->index( 'world' ), -1, 'index not found' );
ok( !$s->is_alpha, 'Is alpha' );
ok( Module::Generic::Scalar->new( 'Hello' )->is_alpha, 'Is alpha ok' );
ok( Module::Generic::Scalar->new( 'Front242' )->is_alpha_numeric, 'Is alpha numeric' );
ok( !$s->is_empty, 'Is empty' );
my $empty = Module::Generic::Scalar->new( 'Hello' )->undef;
isa_ok( $empty, 'Module::Generic::Scalar' );
ok( !$empty->defined, 'Is undefined' );
ok( !$s->is_lower, 'Is lower (false)' );
ok( lc( $s ), 'Is lower (true)' );
ok( !Module::Generic::Scalar->new( 'Front242' )->is_numeric, 'Looks like a number' );
ok( Module::Generic::Scalar->new( 'Hello' )->uc->is_upper, 'Is all caps' );
is( Module::Generic::Scalar->new( 'Hello' )->lc, 'hello', 'Small caps' );
is( Module::Generic::Scalar->new( 'HELLO' )->lcfirst, 'hELLO', 'lcfirst' );
is( Module::Generic::Scalar->new( 'Hello' )->left( 2 ), 'He', 'left' );
is( $s->length, 10, 'length' );
is( Module::Generic::Scalar->new( '     Hello  ' )->trim, 'Hello', 'trim' );
is( Module::Generic::Scalar->new( '     Hello  ' )->ltrim, 'Hello  ', 'ltrim' );
ok( $s->match( qr/[[:blank:]]+worl/ ), 'Regexp match' );
is( Module::Generic::Scalar->new( 'J' )->ord, 74, 'ord' );
$s->trim;
is( $s->pad( 3, 'x' ), 'xxxHello worl', 'pad at start' );
is( $s->pad( -3, 'z' ), 'xxxHello worlzzz', 'pad at end' );
$s->replace( 'xxx', '' );
is( $s, 'Hello worlzzz', 'Replace' );
my $rv = $s->replace( qr/(z{3})/, '' );
is( $s, 'Hello worl', 'Replace2' );
isa_ok( $rv, 'Module::Generic::RegexpCapture', 'replace returns a Module::Generic::RegexpCapture object' );
is( "$rv", 1, 'replaced 1 occurrence' );
diag( "Capture contains: '", $rv->capture->join( "', '" ), "'." ) if( $DEBUG );
is( $rv->capture->first, 'zzz', 'get capture value No 1' );
my $test_str = Module::Generic::Scalar->new( 'I am John' );
my $re_false;
if( $re_false = $test_str->replace( qr/(Jean)/, 'Paul' ) )
{
    fail( "replace produced false positive. Result object is '$re_false'" );
}
else
{
    pass( "replace with no match returned false" );
}

# $rv = $test_str->replace( qr/(Jean)/, 'Paul' )->matched;
# diag( "Result is $rv (", overload::StrVal( $rv ), ")" ) if( $DEBUG );
if( !$test_str->replace( qr/(Jean)/, 'Paul' )->matched )
{
    pass( "replace return result object in object context" );
}
else
{
    fail( "replace failed to return object in object context" );
}

# Now trying with named captures
my $test_named = Module::Generic::Scalar->new(q{GET /some/where HTTP/1.1});
diag( "Testing named regexp: ", $test_named =~ /^(?<method>\w+)[[:blank:]\h]+(?<uri>\S+)[[:blank:]\h]+(?<proto>HTTP\/\d+\.\d+)/ ? 'ok' : 'nope' ) if( $DEBUG );
my $re_named;
if( $re_named = $test_named->match( qr/^(?<method>\w+)[[:blank:]\h]+(?<uri>\S+)[[:blank:]\h]+(?<proto>HTTP\/\d+\.\d+)/ ) )
{
    diag( "method is '", $re_named->name->method, "', uri is '", $re_named->name->uri, "' and proto is '", $re_named->name->proto, "'" ) if( $DEBUG );
    ok( $re_named->name->method eq 'GET' && $re_named->name->uri eq '/some/where' && $re_named->name->proto eq 'HTTP/1.1', 'named capture' );
}
else
{
    diag( "Named regular expression failed. Object is '$re_named' (", overload::StrVal( $re_named ), ")" ) if( $DEBUG );
    diag( "method is '", $re_named->name->method, "', uri is '", $re_named->name->uri, "' and proto is '", $re_named->name->proto, "'" ) if( $DEBUG );
    fail( 'named capture' );
}

is( $s->quotemeta, 'Hello\ worl', 'quotemeta' );
is( $s->reset->length, 0, 'reset' );
$s .= 'I disapprove of what you say, but I will defend to the death your right to say it';
isa_ok( $s, 'Module::Generic::Scalar', 'Scalar assignment' );
is( $s->clone->capitalise, 'I Disapprove of What You Say, but I Will Defend to the Death Your Right to Say It', 'Capitalise' );
is( Module::Generic::Scalar->new( 'Hello' )->reverse, 'olleH', 'reverse' );
is( $s->rindex( 'I' ), 34, 'rindex' );
is( $s->rindex( 'I', 40 ), 34, 'rindex with position' );
is( Module::Generic::Scalar->new( 'Hello world%%%%' )->rtrim( '%' ), 'Hello world', 'rtrim' );
is( $s->clone->set( 'Bonjour' ), 'Bonjour', 'set' );
isa_ok( $s->split( qr/[[:blank:]]+/ ), 'Module::Generic::Array', 'split -> array' );
is( Module::Generic::Scalar->new( 'Hello Ms %s.' )->sprintf( 'Jones' ), 'Hello Ms Jones.', 'sprintf' );

is( $s->substr( 2, 13 ), 'disapprove of', 'substr' );
is( $s->substr( 2, 13, 'really do not approve' ), 'disapprove of', 'substr substituted part' );
is( $s, 'I really do not approve what you say, but I will defend to the death your right to say it', 'substr -> substitution' );

my $sz = Module::Generic::Scalar->new( "I am not so sure" );
is( $sz->tr( '[a-j]', '[0-9]' ), 'I 0m not so sur4', 'tr' );

ok( $s->like( qr/\bapprove[[:blank:]\h]+what\b/ ), 'like' );

my $undef = Module::Generic::Scalar->new( undef() );
ok( defined( $undef ), 'Undefined variable object -> defined' );
no warnings 'uninitialized';
## my $res = scalar( $undef );
## diag( "\$res = ", defined( $res ) ? 'defined' : 'undefined' );
is( $undef->scalar, undef(), 'Undefined variable object using stringification -> undefined' );
ok( !$undef->defined, 'Object value is undefined using method -> undefined' );
my $var = 'test';
$var = $s;
isa_ok( $var, 'Module::Generic::Scalar', 'Regular var assigned becomes object' );
my $var2 = "Je n'approuve rien";
$s = $var2;
ok( !ref( $s ), 'Object lose class after assignment' );
my $obj = MyObject->new({ name => 'Dave', type => undef() });
#$obj->name( 'Dave' );
#$obj->type( undef() );
# diag( "\$obj->name has value '" . $obj->name . "' (" . overload::StrVal( $obj->name ) . ")" );
isa_ok( $obj->name, 'Module::Generic::Scalar', 'object field is a Module::Generic::Scalar object' );
# diag( "\$obj->type is ref " . ref( $obj->type ) );
# isa_ok( $obj->type, 'Module::Generic::Scalar', 'undef object field is also a Module::Generic::Scalar object' );
# diag( "\$obj->type value is '" . $obj->type . "' (" . overload::StrVal( $obj->type ) . ") ref(" . ref( $obj->type ) . "). Defined ? " . ( defined( $obj->type ) ? 'yes' : 'no' ) );
is( $obj->type, undef(), 'Test object type property is undef()' );
is( $obj->name->uc, 'DAVE', 'Object chain method ok' );
is( $obj->type->length, undef(), 'Chained, but eventually undef' );
is( $obj->name, 'Dave', 'Overloaded scalar object in scalar context' );

my $s4 = Module::Generic::Scalar->new( '10' );
isa_ok( $s4->as_number, 'Module::Generic::Number', 'as_number' );
ok( $s4->as_number == 10, 'number value' );
my $s5 = Module::Generic::Scalar->new( '+10' );
isa_ok( $s5->as_number, 'Module::Generic::Number', 'as_number (2)' );
ok( $s5->as_number == 10, 'number value (2)' );

my $s6 = Module::Generic::Scalar->new( 'world' );
$s6->prepend( 'Hello ' );
is( "$s6", 'Hello world', 'prepend' );

my $a6 = $s6->as_array;
isa_ok( $a6, 'Module::Generic::Array', 'as_array => Module::Generic::Array' );
is( $a6->[0], 'Hello world', 'as_array' );

my $s7 = Module::Generic::Scalar->new( 'Jack John Paul Peter' );
my $j = JSON->new->convert_blessed;
eval
{
    my $json = $j->encode( $s7 );
    is( $json, '"Jack John Paul Peter"', 'TO_JSON' );
};
if( $@ )
{
    # diag( "Error encoding: $e" );
    fail( 'TO_JSON' );
}

# Takes the string, split it by space (now an array), join it by comma (now a scalar) and rejoin it with more strings
my $res8 = $s7->split( qr/[[:blank:]]+/ )->join( ', ' )->join( ', ', qw( Gabriel Raphael Emmanuel ) );
is( "$res8", 'Jack, John, Paul, Peter, Gabriel, Raphael, Emmanuel', 'join' );

my $s8 = Module::Generic::Scalar->new( 'Hello' );
my $s9 = Module::Generic::Scalar->new( 'world' );
is( $s8->join( ' ', $s9 ), 'Hello world', 'join (2)' );

# NOTE: scalar io
subtest 'scalar io' => sub
{
    use utf8;
    my $text = <<EOT;
Mignonne, allons voir si la rose
Qui ce matin avoit desclose
Sa robe de pourpre au Soleil,
A point perdu cette vesprée
Les plis de sa robe pourprée,
Et son teint au vostre pareil.
EOT
    my $s = Module::Generic::Scalar->new;
    my $io = $s->open( { debug => $DEBUG, fatal => 0 } ) || die( $s->error );
    isa_ok( $io, 'Module::Generic::Scalar::IO', 'open' );
    diag( "File handle is: '$io'" ) if( $DEBUG );
    ok( $io->opened, 'opened' );
    is( $io->fileno, -1, 'fileno' );
    ok( $io->flush, 'flush' );
    my $rv = $io->print( $text );
    diag( "Error printing to scalar: ", $io->error ) if( $DEBUG && !defined( $rv ) );
    # diag( "String (", overload::StrVal( $s ), ") is now: $s" ) if( $DEBUG );
    # diag( "String (", overload::StrVal( $io ), ") is now: $io" ) if( $DEBUG );
    is( "$s", $text, 'print' );
    $io->printf( "Author: %s\n", 'Pierre de Ronsard' );
    {
        no warnings;
        is( $io->getc, undef(), 'getc' );
    }
    ok( $io->eof, 'eof' );
    $text .= sprintf( "Author: %s\n", 'Pierre de Ronsard' );
    is( $io->tell, length( $text ), 'tell -> end of text' );
    # diag( "Text is now: $io" ) if( $DEBUG );
    ok( $io->seek(0,0), 'seek' );
    is( $io->tell, 0, 'tell -> start of text' );
    is( $io->getc, 'M', 'getc' );
    is( $io->getline, "ignonne, allons voir si la rose\n", 'getline' );
    my $buff;
    my $n = $io->read( $buff, length( [split(/\n/, $text)]->[1] ) + 1 );
    is( $buff, [split(/\n/, $text)]->[1] . "\n", 'read buffer check' );
    my @lines = $io->getlines;
    is( join( '', @lines ), join( "\n", (split(/\n/, $text, -1))[2..7] ), 'getlines' );
    # diag( "Total size is: ", $io->length ) if( $DEBUG );
    $io->seek( $io->length - 1, 0 );
    my $pos = $io->tell;
    # diag( "Current position is: $pos" ) if( $DEBUG );
    # diag( "I am here: ", substr( "$io", $pos - 10, 10 ), "[", substr( "$io", $pos, 1 ), "]" ) if( $DEBUG );
    # diag( "I am here: ", substr( $text, $pos - 10, 10 ), "[", substr( $text, $pos, 1 ), "]", substr( $text, $pos + 1 ) );
    # diag( "$io" );
    $n = $io->write( ', Les Odes', 10 );
    # $io->printf( "%s", ', Les Odes' );
    is( $n, 10, 'write' );
    substr( $text, -1, 0, ', Les Odes' );
    # diag( "Text is now:\n$io" );
    $io->seek(0,0);
    @lines = $io->getlines;
    is( $lines[-1], "Author: Pierre de Ronsard, Les Odes", 'write resulting value' );
    $io->seek( $io->length - length( $lines[-1] ), 0 );
    my $len = $io->truncate( $io->tell );
    diag( "Error trying to truncate: ", $io->error ) if( $DEBUG && !defined( $len ) );
    is( $len, length( $lines[-1] ), 'truncate returned length' );
    $io->seek(0,0);
    @lines = $io->getlines;
    is( scalar( @lines ), 6, 'truncate' );
    diag( "String now is:\n$io" ) if( $DEBUG );
    
    ok( $io->close, 'close' );
    ok( !tied( $io ), 'untied' );
    ok( !$io->opened, 'opened' );
    
    my $s2 = Module::Generic::Scalar->new( \$text );
    $io = $s2->open( '<' );
    isa_ok( $io => 'Module::Generic::Scalar::IO' );
    {
        no warnings;
        $rv = $io->print( "print should not work\n" );
    }
    ok( !$rv, 'cannot print in read-only mode' );
    $rv = $io->write( "write should not work either\n" );
    ok( !$rv, 'cannot write in read-only mode' );
    $rv = $io->syswrite( "syswrite should not work either\n" );
    ok( !$rv, 'cannot syswrite in read-only mode' );
    SKIP:
    {
        eval
        {
            # require Fcntl;
            # Fcntl->import;
            use Fcntl;
            skip( "Fcntl constants not loaded.", 1 ) if( !defined( &F_GETFL ) || !defined( &F_SETFL ) );
            diag( "F_GETFL is '", F_GETFL, "' and F_SETFL is '", F_SETFL, "'" ) if( $DEBUG );
            my $bit = $io->fcntl( F_GETFL, 0 );
            diag( "Bit value returned is '$bit' and O_RDONLY is '", O_RDONLY, "'" ) if( $DEBUG );
            if( !defined( $bit ) )
            {
                diag( "Error getting bitwise value: ", $io->error ) if( $DEBUG );
                skip( 'failed getting bitwise value', 1 );
            }
            elsif( $bit !~ /^\d+$/ )
            {
                diag( "Bit value returned is not an integer -> '$bit'" ) if( $DEBUG );
            }
            ok( ( ( $bit > 0 && $bit & O_RDONLY ) || $bit == O_RDONLY ), 'scalar io has read-only bit' );
            ok( !( $bit & O_RDWR ), 'scalar io does not have write bit' );
        };
        if( $@ )
        {
            skip( "Fcntl is not available on $^O", 1 );
        }
    };
};

# NOTE: unpack and pack
# From perlpacktut
subtest 'unpack and pack' => sub
{
    my $unpack_data = Module::Generic::Scalar->new( q{2021/09/19 Camel rides to tourists      €235.00} );
    my( $date, $desc, $income, $expense ) = $unpack_data->unpack( "A10xA28xA8A*" );
    is( $date, '2021/09/19', 'unpack -> date' );
    is( $desc, 'Camel rides to tourists', 'unpack -> description' );
    is( $income, '€235.00', 'unpack -> income' );
    is( $expense, '', 'unpack -> expense' );
    # Need to set the object context by calling ->object, or else unpack will return its first element
    my $unpack = $unpack_data->unpack( "A10xA28xA8A*" )->object;
    isa_ok( $unpack, 'Module::Generic::Array', 'unpack returns Module::Generic::Array in scalar context' );
    is( $unpack->length, 4, 'has 4 elements' );
    is( $unpack->first, '2021/09/19', 'unpack -> date' );
    is( $unpack->second, 'Camel rides to tourists', 'unpack -> description' );
    is( $unpack->third, '€235.00', 'unpack -> income' );
    is( $unpack->fourth, '', 'unpack -> expense' );
    # In object context
    is( $unpack_data->unpack( "A10xA28xA8A*" )->third, '€235.00', 'object context' );
    my $str2pack = Module::Generic::Scalar->new( 0x20AC );
    my $pack_data = $str2pack->pack( 'U' );
    is( $pack_data, '€', 'pack' );
};

# NOTE: callback
subtest 'callback' => sub
{
    use utf8;
    local $Module::Generic::Scalar::DEBUG = $DEBUG;
    diag( "Setting \$Module::Generic::Scalar::DEBUG to '$Module::Generic::Scalar::DEBUG'" ) if( $DEBUG );
    my $test = Module::Generic::Scalar->new( q{Allons enfants de la Patrie !} );
    is( $test->length, 29, 'init' );
    ok( !tied( $$test ), 'not tied' );
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my $new = $this->{added};
        diag( "Adding ", length( $$new ), " bytes of data ('$$new')" ) if( $DEBUG );
        is( length( $$new ), 59, 'append' );
        return(1);
    });
    $test->append( "\nLe jour de gloire est arrivé." );
    diag( "String is: '", $test->scalar, "'" ) if( $DEBUG );
    is( $test->substr( -7, 6 ), 'arrivé', 'append (2)' );
    
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my $new = $this->{added};
        diag( "Adding ", length( $$new ), " bytes of data ('$$new')" ) if( $DEBUG );
        is( length( $$new ), 62, 'substr' );
        return(1);
    });
    $test->substr( 31, 6, 'a journée' );
    is( $test->scalar, "Allons enfants de la Patrie !\nLa journée de gloire est arrivé.", 'substr (2)' );
    my $copy = $$test;
    
    diag( "Blocking modification." ) if( $DEBUG );
    my $try = 0;
    $test->callback( add => sub
    {
        my $this = shift( @_ );
        my $new = $this->{added};
        diag( "Attempting to add ", length( $$new ), " bytes of data ('$$new') " ) if( $DEBUG );
        $try++;
        return;
    });
    $test->append( "Contre nous de la tyrannie,\nL’étendard sanglant est levé !\n" );
    is( $try, 1, 'addition rejected' );
    is( $$test, $copy, 'addition rejected' );
    $try = 0;
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $old, $new ) = @$this{qw( removed added )};
        diag( "Attempting to remove ", length( $$old ), " bytes of data ('$$old')" ) if( $DEBUG );
        $try++;
        return;
    });
    $test->reset;
    is( $try, 1, 'removal rejected' );
    is( $$test, $copy, 'removal rejected' );
    
    $test->callback( remove => sub
    {
        my $this = shift( @_ );
        my( $old, $new ) = @$this{qw( removed added )};
        diag( "Removing data from ", length( $$old ), " bytes to ", length( $$new ), " bytes: '", $$old, "' -> '", $$new, "'" ) if( $DEBUG );
        is( length( $$old ), 62, 'undef' );
        is( length( $$new ), 0, 'undef (1)' );
        return(1);
    });
    $test->reset;

    diag( "Removing callbacks" ) if( $DEBUG );
    $test->callback( add => undef );
    $test->callback( remove => undef );
    ok( !tied( $$test ), 'callbacks removed' );
};

# NOTE: basic operations
subtest 'basic operations' => sub
{
    my $str = "Hello world";
    my $s = Module::Generic::Scalar->new( $str ) || BAIL_OUT( "Unable to instantiate an object." );
    isa_ok( $s, 'Module::Generic::Scalar', 'Scalar object' );
    is( "$s", $str, 'Stringification' );

    my $s2 = $s->clone;
    isa_ok( $s2, 'Module::Generic::Scalar', 'Clone object' );
    is( "$s2", $str, 'Cloning' );

    $s .= "\n";
    isa_ok( $s, 'Module::Generic::Scalar', 'Object after concatenation' );
    is( $s, "$str\n", 'Concatenation' );

    my $s3 = Module::Generic::Scalar->new( 'A' );
    my $res = $s3 x 12;
    is( $res, 'AAAAAAAAAAAA', 'String multiplication' );
    isa_ok( $res, 'Module::Generic::Scalar', 'Multiplied string object' );
    $res->replace( qr/A{2}$/, '' );
    is( $res, 'AAAAAAAAAA', 'Replace after multiplication' );
};

# NOTE: conversions
subtest 'conversions' => sub
{
    my $bool = Module::Generic::Scalar->new( 'true' )->as_boolean;
    isa_ok( $bool, 'Module::Generic::Boolean', 'Scalar to boolean' );
    ok( $bool == 1, 'True boolean' );
    ok( !Module::Generic::Scalar->new( 0 )->as_boolean, 'False boolean' );

    my $num = Module::Generic::Scalar->new( '10' )->as_number;
    isa_ok( $num, 'Module::Generic::Number', 'Scalar to number' );
    ok( $num == 10, 'Number value' );

    my $arr = Module::Generic::Scalar->new( 'world' )->as_array;
    isa_ok( $arr, 'Module::Generic::Array', 'Scalar to array' );
    is( $arr->[0], 'world', 'Array content' );
};

# NOTE: string operations
subtest 'string operations' => sub
{
    my $s = Module::Generic::Scalar->new( "Hello world\n" );
    $s->chomp;
    is( $s, 'Hello world', 'chomp' );
    $s->chop;
    is( $s, 'Hello worl', 'chop' );

    is( Module::Generic::Scalar->new( 'Hello' )->lc, 'hello', 'lc' );
    is( Module::Generic::Scalar->new( 'HELLO' )->lcfirst, 'hELLO', 'lcfirst' );
    is( Module::Generic::Scalar->new( 'hello' )->uc, 'HELLO', 'uc' );
    is( Module::Generic::Scalar->new( 'hello' )->ucfirst, 'Hello', 'ucfirst' );

    is( Module::Generic::Scalar->new( 'Hello' )->left( 2 ), 'He', 'left' );
    is( Module::Generic::Scalar->new( 'Hello' )->right( 2 ), 'lo', 'right' );
    is( Module::Generic::Scalar->new( 'Hello world%%%%' )->rtrim( '%' ), 'Hello world', 'rtrim' );
    is( Module::Generic::Scalar->new( '     Hello  ' )->ltrim, 'Hello  ', 'ltrim' );
    is( Module::Generic::Scalar->new( '     Hello  ' )->trim, 'Hello', 'trim' );

    is( Module::Generic::Scalar->new( 'Bonjour' )->set( 'Hello' ), 'Hello', 'set' );
    is( Module::Generic::Scalar->new( 'Hello' )->reset->length, 0, 'reset' );
    is( Module::Generic::Scalar->new( 'Hello' )->undef->defined, 0, 'undef' );
};

# NOTE: regular expressions
subtest 'regular expressions' => sub
{
    my $s = Module::Generic::Scalar->new( 'Hello world' );
    ok( $s->match( qr/[[:blank:]]+worl/ ), 'match' );
    ok( $s->like( qr/\bworld\b/ ), 'like' );

    my $test_named = Module::Generic::Scalar->new( 'GET /some/where HTTP/1.1' );
    my $re_named = $test_named->match( qr/^(?<method>\w+)[[:blank:]\h]+(?<uri>\S+)[[:blank:]\h]+(?<proto>HTTP\/\d+\.\d+)/ );
    ok( $re_named->name->method eq 'GET' && $re_named->name->uri eq '/some/where' && $re_named->name->proto eq 'HTTP/1.1', 'named capture' );

    my $rv = $s->replace( qr/(world)/, 'earth' );
    is( $s, 'Hello earth', 'replace' );
    isa_ok( $rv, 'Module::Generic::RegexpCapture', 'replace returns RegexpCapture' );
    is( $rv->capture->first, 'world', 'replace capture' );
};

# NOTE: thread safety
subtest 'thread safety' => sub
{
    SKIP:
    {
        skip "Threads not supported on this system", 4 unless $Config{useithreads};
        require threads;
        require threads::shared;
        my $s = Module::Generic::Scalar->new( 'test' );
        my $error_count = 0;
        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid;
                eval
                {
                    no warnings;
                    $s->error( "Error from thread $tid" );
                    my $err = $s->error;
                    if( $err && $err->message =~ /Error from thread $tid/ )
                    {
                        diag( "Thread $tid: Error handling ok" );
                    }
                    else
                    {
                        $error_count++;
                        diag( "Thread $tid: Error handling failed" );
                    }
                };
                if( $@ )
                {
                    $error_count++;
                    diag( "Thread $tid: Error: $@" );
                }
            })
        } 1..5;
        $_->join for( @threads );
        is( $error_count, 0, 'Thread-safe error handling' );

        # Test tied scalar thread-safety
        my $s2 = Module::Generic::Scalar->new( 'initial' );
        $s2->callback( add => sub
        {
            my $this = shift;
            my $new = $this->{added};
            diag( "Thread ", threads->tid, ": Adding $$new" );
            return(1);
        });
        $error_count = 0;
        @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid;
                eval
                {
                    $s2->append( " from thread $tid" );
                    if( $s2->scalar =~ /from thread $tid/ )
                    {
                        diag( "Thread $tid: Append ok" );
                    }
                    else
                    {
                        $error_count++;
                        diag( "Thread $tid: Append failed" );
                    }
                };
                if( $@ )
                {
                    $error_count++;
                    diag( "Thread $tid: Error: $@" );
                }
            })
        } 1..5;
        $_->join for( @threads );
        is( $error_count, 0, 'Thread-safe tied scalar append' );
    }
};

# NOTE: want context
subtest 'want context' => sub
{
    my $s = Module::Generic::Scalar->new( 'a b c' );
    my $arr = $s->split( qr/[[:blank:]]+/ );
    isa_ok( $arr, 'Module::Generic::Array', 'split in object context' );
    my @list = $s->split( qr/[[:blank:]]+/ );
    is_deeply( \@list, ['a', 'b', 'c'], 'split in list context' );

    local $@;
    eval
    {
        my $val = $s->unpack( 'A1xA1xA1' )->[0];
    };
    diag( "Error getting unpack in array context: $@" ) if( $@ );
    ok( !$@, 'unpack in object context' );
    my @unpack_list = $s->unpack( 'A1xA1xA1' );
    is_deeply( \@unpack_list, ['a', 'b', 'c'], 'unpack in list context' );
};

# NOTE: regexp capture
subtest 'regexp capture' => sub
{
    my $rc = Module::Generic::Scalar->new( 'test' )->match( qr/(es)/ );
    isa_ok( $rc, 'Module::Generic::RegexpCapture', 'RegexpCapture object' );
    is( $rc->capture->first, 'es', 'capture' );
    is( $rc->matched, 1, 'matched' );
    is( $rc->result->first, 'es', 'result' );
};

done_testing();

package
    MyObject;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
};

sub new
{
    my $this = shift( @_ );
    my $hash = {};
    $hash = shift( @_ );
    return( bless( $hash => ( ref( $this ) || $this ) ) );
}

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

sub AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ ) || return;
    return( $self->{ $method } );
}

