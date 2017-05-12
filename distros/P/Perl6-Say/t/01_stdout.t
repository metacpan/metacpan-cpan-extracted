#  !perl
#$Id: 01_stdout.t 1213 2008-02-09 23:40:34Z jimk $
# 01_stdout.t - basic tests of say()
use strict;
use warnings;
use Test::More tests => 11;
use lib ( qq{./t/lib} );
BEGIN {
    use_ok('Perl6::Say');
    use_ok('Carp');
    use_ok('Perl6::Say::Auxiliary', qw| _validate capture_say $capture_fail_message |);
};

SKIP: {
    skip $capture_fail_message,
        8 if $capture_fail_message;

    my ($str, $say_sub, $msg);

    $say_sub = sub { say $str; };
    $msg = q{correctly printed to STDOUT as default print filehandle};

    $str = qq{Hello World};
    capture_say( {
        data => $str,
        pred => 1,
        eval => $say_sub,
        msg  => $msg,
    } );

    $str = qq{Hello World\n};
    capture_say( {
        data => $str,
        pred => 2,
        eval => $say_sub,
        msg  => $msg,
    } );

    $str = qq{Hello World\nAgain!\n};
    capture_say( {
        data => $str,
        pred => 3,
        eval => $say_sub,
        msg  => $msg,
    } );

    $str = qq{};
    capture_say( {
        data => $str,
        pred => 1,
        eval => $say_sub,
        msg  => $msg,
    } );

    $say_sub = sub { say STDOUT $str; };
    $msg = q{correctly printed to STDOUT as explicitly named print filehandle};

    $str = qq{Hello World};
    capture_say( {
        data => $str,
        pred => 1,
        eval => $say_sub,
        msg  => $msg,
    } );

    $str = qq{Hello World\n};
    capture_say( {
        data => $str,
        pred => 2,
        eval => $say_sub,
        msg  => $msg,
    } );

    $str = qq{Hello World\nAgain!\n};
    capture_say( {
        data => $str,
        pred => 3,
        eval => $say_sub,
        msg  => $msg,
    } );

    $str = qq{};
    capture_say( {
        data => $str,
        pred => 1,
        eval => $say_sub,
        msg  => $msg,
    } );
}

