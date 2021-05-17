# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    # use Nice::Try debug => 6, debug_file => './dev/debug_loop.pl', debug_code => 1;
    use Nice::Try;
};

subtest 'next, last, redo in try' => sub
{
    # for
    my $c = 0;
    for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                next;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 9, 'for -> next in try' );
    
    $c = 0;
    for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                last;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 6, 'for -> last in try' );
    
    $c = 0;
    for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                $i++;
                redo;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 9, 'for -> redo in try' );
    
    # foreach
    $c = 0;
    foreach my $i ( 1..10 )
    {
        try
        {
            if( $i == 7 )
            {
                next;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 9, 'foreach -> next in try' );

    $c = 0;
    foreach my $i ( 1..10 )
    {
        try
        {
            if( $i == 7 )
            {
                last;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 6, 'foreach -> last in try' );
    
    # No good idea of test found for foreach and redo.
    # If you got one, please share it with me.
    SKIP:
    {
        skip( 'foreach -> redo in try' );
    };

    # while
    $c = 0;
    my $i = 0;
    while( ++$i <= 10 )
    {
        try
        {
            if( $i == 7 )
            {
                next;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 9, 'while -> next in try' );

    $c = 0;
    $i = 0;
    while( ++$i <= 10 )
    {
        try
        {
            if( $i == 7 )
            {
                last;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 6, 'while -> last in try' );
    
    $c = 0;
    $i = 0;
    while( ++$i <= 10 )
    {
        try
        {
            if( $i == 7 )
            {
                $i++;
                redo;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 9, 'while -> redo in try' );
};

subtest 'next, last, redo in catch' => sub
{
    my $c = 0;
    for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            next;
        }
    }
    is( $c, 9, 'for -> next in catch' );
    
    $c = 0;
    for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            last;
        }
    }
    is( $c, 6, 'for -> last in catch' );
    
    $c = 0;
    for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                $i++;
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            redo;
        }
    }
    is( $c, 9, 'for -> redo in catch' );

    # foreach
    $c = 0;
    foreach my $i ( 1..10 )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            next;
        }
    }
    is( $c, 9, 'foreach -> next in catch' );
    
    $c = 0;
    foreach my $i ( 1..10 )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            last;
        }
    }
    is( $c, 6, 'foreach -> last in catch' );
    
    my @items = ( 'John', 'Paul', '', 'Mark', 'Peter' );
    my @names = ();
    foreach my $n ( @items )
    {
        try
        {
            if( !length( $n ) )
            {
                die( "Nope\n" );
            }
            push( @names, $n );
        }
        catch( $e )
        {
            $n = 'Jack';
            redo;
        }
    }
    is( "@names", 'John Paul Jack Mark Peter', 'foreach -> redo in catch' );

    # while
    $c = 0;
    my $i = 0;
    while( ++$i <= 10 )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            next;
        }
    }
    is( $c, 9, 'while -> next in catch' );

    $c = 0;
    $i = 0;
    while( ++$i <= 10 )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            last;
        }
    }
    is( $c, 6, 'while -> last in catch' );
    
    $c = 0;
    $i = 0;
    while( ++$i <= 10 )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            $i++;
            redo;
        }
    }
    is( $c, 9, 'while -> redo in catch' );
};

subtest 'try-catch in continue with next, last, redo' => sub
{
    my @items = ( 'John', 'Paul', '', 'Mark', 'Peter' );
    my @names = ();
    foreach my $n ( @items )
    {
        # Nothing meaningful
    }
    continue
    {
        try
        {
            if( !length( $n ) )
            {
                die( "Nope\n" );
            }
            push( @names, $n );
        }
        catch( $e )
        {
            pop( @names );
            $n = 'Jack';
            next;
        }
    }
    is( "@names", 'John Jack Mark Peter', 'foreach continue -> next in catch' );
    
    $c = 0;
    foreach my $i ( 1..10 )
    {
        # Nothing here
    }
    continue
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            last;
        }
    }
    is( $c, 6, 'foreach continue -> last in catch' );
    
    my @items = ( 'John', 'Paul', '', 'Mark', 'Peter' );
    my @names = ();
    foreach my $n ( @items )
    {
        # Nothing meaningful
    }
    continue
    {
        try
        {
            if( !length( $n ) )
            {
                die( "Nope\n" );
            }
            push( @names, $n );
        }
        catch( $e )
        {
            $n = 'Jack';
            redo;
        }
    }    
    is( "@names", 'John Paul Jack Mark Peter', 'foreach continue -> redo in catch' );
    
    # while
    @items = ( 'John', 'Paul', '', 'Mark', 'Peter' );
    @names = ();
    $i = -1;
    while( ++$i <= $#items )
    {
        # Checking item $i
    }
    continue
    {
        try
        {
            die( "Nope\n" ) if( !length( $items[$i] ) );
            push( @names, $items[$i] );
        }
        catch( $e )
        {
            $items[$i] = 'Jack';
            next;
        }
    }
    is( "@names", 'John Paul Jack Mark Peter', 'while continue -> next in catch' );
    
    @items = ( 'John', 'Paul', '', 'Mark', 'Peter' );
    @names = ();
    $i = -1;
    while( ++$i <= $#items )
    {
        # Checking item $i
    }
    continue
    {
        try
        {
            die( "Nope\n" ) if( !length( $items[$i] ) );
            push( @names, $items[$i] );
        }
        catch( $e )
        {
            last;
        }
    }
    is( "@names", 'John Paul', 'while continue -> last in catch' );

    @items = ( 'Ichiro', 'Jiro', '', 'Shiro', 'Goro' );
    @names = ();
    $i = -1;
    while( ++$i <= $#items )
    {
        # Checking item $i
    }
    continue
    {
        try
        {
            die( "Nope\n" ) if( !length( $items[$i] ) );
            push( @names, $items[$i] );
        }
        catch( $e )
        {
            $items[$i] = 'Saburo';
            redo;
        }
    }
    is( "@names", 'Ichiro Jiro Saburo Shiro Goro', 'while continue -> redo in catch' );
};

subtest 'next, last, redo with flow control statement in try' => sub
{
    my @items = ( 'Ichiro', 'Jiro', '', 'Shiro', 'Goro' );
    my @names = ();
    my $i = 0;
    while( defined( my $n = $items[$i] ) )
    {
        try
        {
            # diag( "Checking \"$n\". \@names is: '", join( "', '", @names ), "'." );
            die( "Oh no\n" ) if( !length( $n ) );
            push( @names, $n );
            $i++;
        }
        catch
        {
            $i++;
            next if( scalar( @names ) < 3 );
        }
    }
    is( "@names", 'Ichiro Jiro Shiro Goro', 'conditional next in catch' );

    @names = ();
    my $i = 0;
    while( defined( my $n = $items[$i] ) )
    {
        try
        {
            die( "Oh no\n" ) if( !length( $n ) );
            push( @names, $n );
            $i++;
        }
        catch
        {
            $i++;
            last if( scalar( @names ) ); # dummy condition
        }
    }
    is( "@names", 'Ichiro Jiro', 'conditional last in catch' );

    @items = ( 'Ichiro', 'Jiro', '', 'Shiro', 'Goro' );
    @names = ();
    my $i = 0;
    while( defined( my $n = $items[$i] ) )
    {
        try
        {
            die( "Oh no\n" ) if( !length( $n ) );
            push( @names, $n );
            $i++;
        }
        catch
        {
            $n = 'Saburo';
            redo if( $i == 2 ); # dummy condition
        }
    }
    is( "@names", 'Ichiro Jiro Saburo Shiro Goro', 'conditional redo in catch' );
};

subtest 'next, last, redo with label in try' => sub
{
    my $c = 0;
    ROUND: for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                next ROUND;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 9, 'next in try' );
    
    $c = 0;
    ROUND: for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                last ROUND;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 6, 'last in try' );
    
    $c = 0;
    ROUND: for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                $i++;
                redo ROUND;
            }
            $c++;
        }
        catch( $e )
        {
            print( "Caught exception: $e\n" );
        }
    }
    is( $c, 9, 'redo in try' );
};

subtest 'next, last, redo with label in catch' => sub
{
    my $c = 0;
    ROUND: for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            next ROUND;
        }
    }
    is( $c, 9, 'next in try' );
    
    $c = 0;
    ROUND: for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            last ROUND;
        }
    }
    is( $c, 6, 'last in try' );
    
    $c = 0;
    ROUND: for( my $i = 1; $i <= 10; $i++ )
    {
        try
        {
            if( $i == 7 )
            {
                $i++;
                die( "Nope\n" );
            }
            $c++;
        }
        catch( $e )
        {
            redo ROUND;
        }
    }
    is( $c, 9, 'redo in try' );
};

subtest 'foreach next in list context' => sub
{
    local $process = sub
    {
        my @res = ();
        foreach my $n ( qw( John Jack Peter ) )
        {
            try
            {
                push( @res, $n );
                next;
            }
            catch( $e )
            {
                print( "Oops: $e\n" );
            }
        }
        return( \@res );
    };
    my $list = $process->();
    is( "@$list", 'John Jack Peter', 'foreach next -> list context' );
};

done_testing;

__END__

