# -*- perl -*-
use strict;
use warnings;
use Test::More qw( no_plan );
use Nice::Try;
our $DEBUG = 0;

# Credits to Steve Scaffidi for his test suit

# Proper line reporting
{
    try
    {
        die( "My bad" );
    }
    catch( $e )
    {
        like( $e, qr/^My bad at (\S+) line 14/, 'correct line number' );
    }
}

# try only behaves like an eval, i.e. does not die

{
    my $i = 0;
    try
    {
        die( "My bad" );
    }
    $i++;
    ok( $i, 'try standalone behaves like eval' );
    like( $@, qr/^My bad/, '$@ is accessible' );
}

# Exception class
{
    my $i = 0;
    try
    {
        die( Exception->new( "Oops" ) );
    }
    catch( Exception $e )
    {
        isa_ok( $e, 'Exception', 'assigned exception variable with class' );
        is( "$e", 'Oops', 'assigned exception variable message' );
        is( $e->line, 40, 'assigned exception variable method' );
    }
    catch( $e )
    {
        # should not get here
        $i = 1;
    }
    ok( !$i, 'triggers proper catch block' );
}

# embedded try catch
{
    no warnings;
    try
    {
        my( $e1, $e2 );
        try
        {
            die( "Level 2 try" );
        }
        catch( $e2 )
        {
            like( $e2, qr/^Level 2 try/, 'embedded try' );
            try
            {
                die( "Level 3 try" );
            }
            like( $@, qr/^Level 3 try/, 'deep embedded try' );
            $e1 = $e2;
        }
        ok( !defined( $e2 ), 'out of scope exception variable assignment' );
        die( "Propagating $e1" );
    }
    catch( $e )
    {
        like( $e, qr/^Propagating Level 2 try/, 'embedded catch' );
    }
}

{
    my $should_not_reach;
    my $rc = eval
    {
        try
        {
            die( Exception->new( "Oh no" ) );
        }
        catch( SomeOther::Exception $e )
        {
            # Nope, not for me
        }
        catch( AnotherClass $e )
        {
            # never happens
        }
        $should_not_reach++;
    };
    is( $should_not_reach, undef() );
    isa_ok( $@, 'Exception', 'died with an uncaught exception' );
}

{
    my $should_reach_too;
    my $should_reach;
    my $rc = eval
    {
        try
        {
            die( Exception->new( "Oh no" ) );
        }
        catch( SomeOther::Exception $e )
        {
            # Nope, not for me
        }
        # Default
        catch( $e )
        {
            $should_reach = $e;
        }
        $should_reach_too++;
    };
    ok( $should_reach_too, 'reached outer block after exception was caught' );
    isa_ok( $should_reach, 'Exception', 'caught exception' );
}

{
    my $should_reach;
    try
    {
        die( Exception->new( "Arghhh" => 401 ) );
    }
    catch( Exception $oopsie where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    {
        diag( "Should not reach here." ) if( $DEBUG );
    }
    catch( Exception $oopsie where { $_->message =~ /Arghhh/ && $_->code == 401 } )
    {
        $should_reach++;
    }
    catch( Exception $oh_well )
    {
        diag( "Reached default. Failed." ) if( $DEBUG );
    }
    catch( $default )
    {
        diag( "Reached default, failed." ) if( $DEBUG );
    }
    is( $should_reach, 1, 'class exception with where clause' );
}

{
    my $should_reach;
    try
    {
        die( Exception->new( "Arghhh" => 401 ) );
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    {
        diag( "Should not reach here." ) if( $DEBUG );
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 401 } )
    {
        $should_reach++;
    }
    catch( Exception $oh_well )
    {
        diag( "Should not reach here either." ) if( $DEBUG );
    }
    catch( $default )
    {
        diag( "Reached default, failed." ) if( $DEBUG );
    }
    is( $should_reach, 1, 'class exception using isa with where clause' );
}

{
    my $should_reach;
    try
    {
        die( Exception->new( "Arghhh" => 404 ) );
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    {
        diag( "Should not reach here." ) if( $DEBUG );
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 401 } )
    {
        diag( "Should not reach here either." ) if( $DEBUG );
    }
    catch( $oh_well isa Exception )
    {
        $should_reach++;
    }
    catch( $default )
    {
        diag( "Reached default, failed." ) if( $DEBUG );
    }
    is( $should_reach, 1, 'class exception using isa without where clause' );
}

{
    my $should_reach;
    try
    {
        die( Exception->new( "Arghhh" => 404 ) );
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    {
        diag( "Should not reach here." ) if( $DEBUG );
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 401 } )
    {
        diag( "Should not reach here either." ) if( $DEBUG );
    }
    catch( $oh_well isa( 'Exception' ) )
    {
        $should_reach++;
    }
    catch( $default )
    {
        diag( "Reached default, failed." ) if( $DEBUG );
    }
    is( $should_reach, 1, 'class exception using isa, single quotes without where clause' );
}

{
    my $should_reach;
    try
    {
        die( Exception->new( "Arghhh" => 404 ) );
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    {
        diag( "Should not reach here." ) if( $DEBUG );
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 401 } )
    {
        diag( "Should not reach here either." ) if( $DEBUG );
    }
    catch( $oh_well isa("Exception") )
    {
        $should_reach++;
    }
    catch( $default )
    {
        diag( "Reached default, failed." ) if( $DEBUG );
    }
    is( $should_reach, 1, 'class exception using isa, double quotes without where clause' );
}

{
    my $should_reach;
    try
    {
        die( "Oh no!\n" );
    }
    catch( Exception $oopsie where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    {
        diag( "Should not reach here." ) if( $DEBUG );
    }
    catch( Exception $oopsie where { $_->message =~ /Arghhh/ && $_->code == 401 } )
    {
        diag( "Should not reach here either." ) if( $DEBUG );
    }
    catch( Exception $oh_well )
    {
        diag( "Should not reach here either." ) if( $DEBUG );
    }
    catch( $oopsie where { /Oh no/ } )
    {
        $should_reach++;
    }
    catch( $default )
    {
        diag( "Reached default, failed." ) if( $DEBUG );
    }
    is( $should_reach, 1, 'error caught with where clause' );
}

# Bug report 2021-06-18
{
    {
      package MyException;
      use overload '""' => 'message';
      sub message { $_[0]->{message} }
      sub new { my $class = shift; bless { @_ }, $class }
      sub throw { my $class = shift; die $class->new(message => shift) }
    }

    my $check;
    try {
      MyException->throw("hi\n");
    }
    catch (MyException $e) {
      # warn "working catch: $e";
      $check = 1;
    }
    catch ($e) {
      # warn "broken catch: $e";
      $check = 2;
    }
    is( $check, 1, 'overloaded exception' );
}

done_testing;

package Exception;
BEGIN
{
    use strict;
    use warnings;
    use overload ('""' => 'as_string', fallback => 1);
};

sub new
{
    my $that = shift( @_ );
    my( $msg, $code );
    if( scalar( @_ ) == 2 && $_[1] =~ /^\d+$/ )
    {
        ( $msg, $code ) = @_;
    }
    else
    {
        $msg = join( '', @_ );
    }
    my( $p, $f, $l ) = caller;
    my $sub = (caller(1))[3];
    my $hash = 
    {
    message => $msg,
    code    => $code,
    package => $p,
    file => $f,
    line => $l,
    subroutine => $sub,
    };
    return( bless( $hash => ( ref( $that ) || $that ) ) );
}

sub as_string { $_[0]->{message} };

sub code { $_[0]->{code} };

sub file { $_[0]->{file} };

sub line { $_[0]->{line} };

sub message { $_[0]->{message} };

sub package { $_[0]->{package} };

sub subroutine { $_[0]->{subroutine} };
