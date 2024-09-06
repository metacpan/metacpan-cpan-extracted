#!perl
use strict;
use warnings;
use lib './lib';
use Test::More;
# plan tests => 14;
our $t = 0;
our $f = 0;
use Nice::Try;
# use Nice::Try debug => 5, debug_file => './dev/debug_return_023.pl', debug_code => 1;
my $should_be_undef;
# try { $i++ } catch { }
my $rv = (sub{ 
    try { return "OK" }catch{$should_be_undef="catch: unreachable code";$t++} finally {$f++;} 
    $t++; # should not be called
})->();
is( $t, 0, 'try-catch return' );
ok( !defined( $should_be_undef ) );
is( $f, 1, 'finally called' );
is( $rv, 'OK', 'return value' );

$t = $f = 0;
# Void context
(sub{ 
    try { return "OK" }catch{$should_be_undef="catch: unreachable code";$t++} finally {$f++;}
    $t++; # should not be called
})->();
is( $t, 0, 'try-catch return' );
ok( !defined( $should_be_undef ) );
is( $f, 1, 'finally called' );

$t = $f = 0;
$_ = (sub{ 
    try { die "OK";$should_be_undef="try: unreachable code"; }catch{return "OK"; $t++;} finally {$f++;} 
    $t++; # should not be called
})->();
is( $t, 0, 'try-catch return' );
ok( !defined( $should_be_undef ) );
is( $f, 1, 'finally called' );
is( $rv, 'OK', 'return value' );

$t = $f = 0;
# Void context
(sub{ 
    try { die "OK";$should_be_undef="try: unreachable code"; }catch{return "OK";$t++;} finally {$f++;}
    $t++; # should not be called
})->();
is( $t, 0, 'try-catch return' );
ok( !defined( $should_be_undef ) );
is( $f, 1, 'finally called' );

sub check_or_return
{
    try
    {
        &check(0) || return( "ok" );
        # &check(1) || $debug++, return;
        &check(2) || diag "Damn.", return "not ok";
        return( "not ok" );
    }
    catch( $e )
    {
        warn( "Something went wrong: $e" );
    }
    return( "nope" );
}

sub check_or_return2
{
    try
    {
        &check(1) || return( "not ok" );
        return( "ok" );
    }
    catch( $e )
    {
        warn( "Something went wrong: $e" );
    }
    return( "nope" );
}

sub check { return($_[0]) }

is( &check_or_return, "ok", "&do_something || return" );

is( &check_or_return2, "ok", "&do_something || return" );

done_testing();

__END__
