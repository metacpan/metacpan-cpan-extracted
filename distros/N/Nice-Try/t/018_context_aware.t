# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    use Nice::Try;
    use Want;
    our $DEBUG = 0;
};

local $check_type = sub{ is( $_[1], $_[0], "context returned type -> $_[0]" ); };
my $val = try_me( 'Coucou !', $check_type => 'scalar' );
is( $val, 'Coucou !', 'scalar context' );

my $this = try_me( $check_type => 'object' )->callmore();
isa_ok( $this, 'My::Object', 'object context' );
is( "@{$this->{val}}", 'Hello world', 'object value stored' );

$val = try_me( 'Peter', $check_type => 'code' )->();
is( $val, 'Peter', 'code context' );

$val = try_me( $check_type => 'hash' )->{name};
is( $val, 'John Doe', 'hash context' );

$val = try_me( $check_type => 'array' )->[2];
is( $val, 'Paul', 'array context' );

my $fh = \*{try_me( $check_type => 'glob' )};
is( ref( $fh ), 'GLOB', 'glob context' );

$val = ${try_me( $check_type => 'scalar ref' )};
is( $val, 'Jack', 'scalar ref context' );

# $val = try_me() ? 1 : 0;
$val = !!try_me( $check_type => 'boolean' );
is( $val, 1, 'boolean context' );

# Same, but in catch block
$val = catch_me( 'Coucou !', $check_type => 'scalar' );
is( $val, 'Coucou !', 'scalar context' );

$this = catch_me( $check_type => 'object' )->callmore();
isa_ok( $this, 'My::Object', 'object context' );
is( "@{$this->{val}}", 'Hello world', 'object value stored' );

$val = catch_me( 'Peter', $check_type => 'code' )->();
is( $val, 'Peter', 'code context' );

$val = catch_me( $check_type => 'hash' )->{name};
is( $val, 'John Doe', 'hash context' );

$val = catch_me( $check_type => 'array' )->[2];
is( $val, 'Paul', 'array context' );

$fh = \*{catch_me( $check_type => 'glob' )};
is( ref( $fh ), 'GLOB', 'glob context' );

$val = ${catch_me( $check_type => 'scalar ref' )};
is( $val, 'Jack', 'scalar ref context' );

# $val = catch_me() ? 1 : 0;
$val = !!catch_me( $check_type => 'boolean' );
is( $val, '', 'boolean context' );

sub try_me
{
    my $expect = pop( @_ );
    my $cb = pop( @_ );
    my @args = @_;
    try
    {
        if( Want::want( 'OBJECT' ) )
        {
            diag( "Called in object context" ) if( $DEBUG );
            $cb->( $expect => 'object' );
            # return( main, [qw( Hello world )] );
            return( My::Object->new( qw( Hello world ) ) );
        }
        elsif( Want::want( 'HASH' ) )
        {
            diag( "Called in hash context" ) if( $DEBUG );
            $cb->( $expect => 'hash' );
            return( { name => 'John Doe' } );
        }
        elsif( Want::want( 'ARRAY' ) )
        {
            diag( "Called in array context" ) if( $DEBUG );
            $cb->( $expect => 'array' );
            return( [qw( Jack John Paul Mark Peter )] );
        }
        elsif( Want::want( 'CODE' ) )
        {
            diag( "Called in code context" ) if( $DEBUG );
            $cb->( $expect => 'code' );
            return( sub{ $args[0] } );
        }
        elsif( Want::want( 'GLOB' ) )
        {
            diag( "Called in glob context" ) if( $DEBUG );
            $cb->( $expect => 'glob' );
            my $ref;
            open( my $fh, '>', \$ref );
            return( $fh );
        }
        elsif( Want::want( 'SCALAR REF' ) )
        {
            diag( "Called in scalar ref context" ) if( $DEBUG );
            $cb->( $expect => 'scalar ref' );
            return( \"Jack" );
        }
        elsif( Want::want( 'BOOLEAN' ) )
        {
            diag( "Called in boolean context" ) if( $DEBUG );
            $cb->( $expect => 'boolean' );
            return( 1 );
        }
        elsif( Want::want( 'SCALAR' ) )
        {
            diag( "Called in scalar context" ) if( $DEBUG );
            $cb->( $expect => 'scalar' );
            return( $_[0] );
        }
        # Should not get here: fail
        else
        {
            print( STDERR "Oops, should not get here\n" );
            $cb->( undef() );
            return;
        }
    }
    catch( $e )
    {
        print( STDERR "An unexpected error has occurred: $e\n" );
        return;
    }
}

sub catch_me
{
    my $expect = pop( @_ );
    my $cb = pop( @_ );
    my @args = @_;
    try
    {
        die( "Argh...\n" );
    }
    catch( $e )
    {
        if( Want::want( 'OBJECT' ) )
        {
            diag( "Called in object context" ) if( $DEBUG );
            $cb->( $expect => 'object' );
            # return( main, [qw( Hello world )] );
            return( My::Object->new( qw( Hello world ) ) );
        }
        elsif( Want::want( 'HASH' ) )
        {
            diag( "Called in hash context" ) if( $DEBUG );
            $cb->( $expect => 'hash' );
            return( { name => 'John Doe' } );
        }
        elsif( Want::want( 'ARRAY' ) )
        {
            diag( "Called in array context" ) if( $DEBUG );
            $cb->( $expect => 'array' );
            return( [qw( Jack John Paul Mark Peter )] );
        }
        elsif( Want::want( 'CODE' ) )
        {
            diag( "Called in code context" ) if( $DEBUG );
            $cb->( $expect => 'code' );
            return( sub{ $args[0] } );
        }
        elsif( Want::want( 'GLOB' ) )
        {
            diag( "Called in glob context" ) if( $DEBUG );
            $cb->( $expect => 'glob' );
            my $ref;
            open( my $fh, '>', \$ref );
            return( $fh );
        }
        elsif( Want::want( 'SCALAR REF' ) )
        {
            diag( "Called in scalar ref context" ) if( $DEBUG );
            $cb->( $expect => 'scalar ref' );
            return( \"Jack" );
        }
        elsif( Want::want( 'BOOLEAN' ) )
        {
            diag( "Called in boolean context" ) if( $DEBUG );
            $cb->( $expect => 'boolean' );
            return( 0 );
        }
        elsif( Want::want( 'SCALAR' ) )
        {
            diag( "Called in scalar context" ) if( $DEBUG );
            $cb->( $expect => 'scalar' );
            return( $_[0] );
        }
        # Should not get here: fail
        else
        {
            print( STDERR "Oops, should not get here\n" );
            $cb->( undef() );
            return;
        }
    }
}

done_testing;

{
    package
        My::Object;
    
    # sub new { return( bless( {} => shift( @_ ) ) ); }
    sub new
    {
        my $that = shift( @_ );
        # print( STDERR "Got here in My::Object->new with args '", join( "', '", @_ ), "'\n" );
        return( bless( { val => [@_] } => ( ref( $that ) || $that ) ) );
    }
    
    sub callmore
    {
        my $self = shift( @_ );
        # print( "My::Object stored args are: '", join( "', '", @{$self->{val}} ), "'\n" );
        return( $self );
    }
}

__END__

