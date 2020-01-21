use Test::Spec;
use Test::MockModule;

our @qx_calls;
our @qx_ret = ("CLEAR SEQUENCE $^O $$\n");
our $current_qx = sub { push @qx_calls, [@_]; return @qx_ret > 1 ? @qx_ret : $qx_ret[0] };
use Test::Mock::Cmd qx => sub { $current_qx->(@_) };

use Term::Clear;

describe "Term::Clear" => sub {
    around {
        local @qx_calls                = ();
        local $Term::Clear::_clear_str = undef;
        local $Term::Clear::POSIX      = 0;

        yield;
    };

    describe "imports" => sub {
        it "should enable POSIX when given the string POSIX" => sub {
            Term::Clear->import("POSIX");
            is $Term::Clear::POSIX, 1;
        };

        it "should not enable POSIX by default" => sub {
            Term::Clear->import();
            is $Term::Clear::POSIX, 0;
        };
    };

    describe "system command fallbacks" => sub {
        it "should call the right thing under Windows" => sub {
            local $^O = "MSWin32";
            Term::Clear::_get_from_system_call();
            is_deeply \@qx_calls, [ ["cls"] ];
        };

        it "should call the right thing under non-Windows" => sub {
            local $^O = "not-windows";
            Term::Clear::_get_from_system_call();
            is_deeply \@qx_calls, [ ["/usr/bin/clear"] ];
        };
    };

    describe "\b’s clear() function" => sub {
        it "should memoize itself - variable set" => sub {
            trap { Term::Clear::clear() };
            is $trap->stdout, $Term::Clear::_clear_str;
        };

        it "should memoize itself - variable used" => sub {
            local $Term::Clear::_clear_str = "I am cached $$";
            no warnings "redefine";
            local *Term::Clear::_get_clear_str = sub { "I am calculated $$" };
            trap { Term::Clear::clear() };
            is $trap->stdout, "I am cached $$";
        };

        it "should do system call if Term::Cap can’t be loaded" => sub {
            local @INC = ( sub { die "no Term::Cap for you\n" } );
            trap { Term::Clear::clear() };
            is $trap->stdout, $qx_ret[0];

        };

        it "should try to do POSIX if POSIX was enabled" => sub {
            $Term::Clear::POSIX = 1;
            my ( $termcap, $posix ) = _get_mocked_modules();
            trap { Term::Clear::clear() };
            is $termcap->{_Tgetent_arg}{OSPEED}, $$ + 42;
        };

        it "should try to do POSIX if POSIX.pm is loadded" => sub {
            local $INC{"POSIX.pm"} = "1";
            my ( $termcap, $posix ) = _get_mocked_modules();
            trap { Term::Clear::clear() };
            is $termcap->{_Tgetent_arg}{OSPEED}, $$ + 42;
        };

        it "should use Term::Cap’s result" => sub {
            my ( $termcap, $posix ) = _get_mocked_modules();
            trap { Term::Clear::clear() };
            is $trap->stdout, "term cap result";
        };

        it "should do system call if Term::Cap’s result is empty" => sub {
            my ( $termcap, $posix ) = _get_mocked_modules();
            $termcap->redefine( Tputs => sub { return "" } );
            trap { Term::Clear::clear() };
            is $trap->stdout, $qx_ret[0];
        };
    };
};

runtests unless caller;

###############
#### helpers ##
###############

sub _get_mocked_modules {

    # do not want to load so we mock instead of redefine (in case its not loaded) or define (in case it is loaded)
    local $INC{"POSIX/Termios.pm"} = 1;
    local $INC{"POSIX.pm"}         = 1;
    local $INC{"Term/Cap.pm"}      = 1;

    my $termcap = Test::MockModule->new("Term::Cap");

    $termcap->mock( Tgetent => sub { shift; $termcap->{_Tgetent_arg} = shift; return bless $termcap->{_Tgetent_arg}, "Term::Cap" } )
        ->mock( Trequire => sub { } )
        ->mock( Tputs => sub { return "term cap result" } );

    my $posix = Test::MockModule->new("POSIX::Termios")
        ->mock( new => sub { bless {}, "POSIX::Termios" } )
        ->mock( getattr => sub { } )
        ->mock( getospeed => sub { return $$ + 42 } );

    return ( $termcap, $posix );
}
