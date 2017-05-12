use lib 't', 'lib';
use strict;
use warnings;
use Test::More;

eval "use Encode";
my $enc = ! $@;

use Spoon::CGI;
use URI::Escape;

plan tests => 10;

{
    package Test1;
    use Spoon::CGI -base;

    cgi 'param1';
    cgi 'param2' => '-utf8';
    cgi 'trimmed' => '-trim';
    cgi 'nl' => '-newlines';
}

$ENV{REQUEST_METHOD} = 'GET';

{
    $ENV{QUERY_STRING} = "param1=2;foo=bar";

    my $test1 = Test1->new;
    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8($test1->param1), 'param1 is marked as utf8' );
    }

    is( $test1->param1, 2, 'param1 value is 2' );
}

{
    CGI->_reset_globals;

    $ENV{QUERY_STRING} = 'param1=%E1%9A%A0%E1%9B%87%E1%9A%BB;foo=bar';

    my $test1 = Test1->new;
    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8($test1->param1), 'param1 is marked as utf8' );
    }

    is( $test1->param1, "\x{16A0}\x{16C7}\x{16BB}",
        'param1 value is \x{16A0}\x{16C7}\x{16BB}' );
}

{
    CGI->_reset_globals;

    $ENV{QUERY_STRING} = 'param2=%E1%9A%A0%E1%9B%87%E1%9A%BB;foo=bar';

    my $test1 = Test1->new;
    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8($test1->param2), 'param2 is marked as utf8' );
    }

    is( $test1->param2, "\x{16A0}\x{16C7}\x{16BB}",
        'param2 value is \x{16A0}\x{16C7}\x{16BB}' );
}

{
    CGI->_reset_globals;

    $ENV{QUERY_STRING} = 'trimmed=%20%20trim%20me%20%20;foo=bar';

    my $test1 = Test1->new;
    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8($test1->trimmed), 'trimmed is marked as utf8' );
    }

    is( $test1->trimmed, "trim me",
        'trimmed value is "trim me"' );
}

{
    CGI->_reset_globals;

    $ENV{QUERY_STRING} = 'nl=line1%0d%0aline2%0dline3;foo=bar';

    my $test1 = Test1->new;
    SKIP: {
        skip "Encode not installed", 1  unless($enc);
        ok( Encode::is_utf8($test1->nl), 'nl is marked as utf8' );
    }

    is( $test1->nl, "line1\nline2\nline3\n",
        'nl only contains unix newlines' );
}

