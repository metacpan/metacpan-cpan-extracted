#  !perl
#$Id: 08_iohandle_say.t 1213 2008-02-09 23:40:34Z jimk $
# 08_iohandle_say.t - test say() vs. IO::Handle::say()
use strict;
use warnings;
use Test::More tests => 14;
use lib ( qq{./t/lib} );
BEGIN {
    use_ok('IO::Handle');
    use_ok('Carp');
    use_ok('Perl6::Say::Auxiliary', qw| _validate capture_say |);
};

my $iohandleversion;
SKIP: {
    my $skipped_tests = (14 - 3);
    eval { $iohandleversion = $IO::Handle::VERSION; };
    skip "tests require $IO::Handle::VERSION",
    $skipped_tests
    if $@;

    SKIP: {
        skip "tests require IO::Handle module version 1.27 or greater",
        $skipped_tests
        unless $iohandleversion >= 1.27;

        # real tests go here

        can_ok( q{IO::Handle}, qw( say ) );
        undef &IO::Handle::say;
        eval { say STDOUT "Gotcha!"; };
        like($@, qr/^Undefined subroutine &IO::Handle::say called/,
            "IO::Handle::say() is now undefined");

        require_ok('Perl6::Say');

        SKIP: {
            eval qq{ require IO::Capture::Stdout; };;
            skip "tests require IO::Capture::Stdout", 
                8 if $@;
        
            my ($str, $say_sub, $msg);
        
            $say_sub = sub { say STDOUT $str; };
            $msg = q{correctly printed to STDOUT as named print filehandle};
        
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

            $say_sub = sub { IO::Handle::say STDOUT $str; };
            $msg = q{Perl6::Say::say() now IO::Handle::say()};
        
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
    }
}

