# -*- perl -*-

use strict;
use warnings;

use Test::More qw( no_plan );

use Nice::Try;

# Credits to Steve Scaffidi for his test suit

# Proper line reporting
{
    try
    {
        die( "My bad" );
    }
    catch( $e )
    {
        like( $e, qr/^My bad at (\S+) line 16/, 'correct line number' );
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
        is( $e->line, 42, 'assigned exception variable method' );
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
    my $msg = join( '', @_ );
    my( $p, $f, $l ) = caller;
    my $sub = (caller(1))[3];
    my $hash = 
    {
    message => $msg,
    package => $p,
    file => $f,
    line => $l,
    subroutine => $sub,
    };
    return( bless( $hash => ( ref( $that ) || $that ) ) );
}

sub as_string { $_[0]->{message} };

sub file { $_[0]->{file} };

sub line { $_[0]->{line} };

sub message { $_[0]->{message} };

sub package { $_[0]->{package} };

sub subroutine { $_[0]->{subroutine} };
