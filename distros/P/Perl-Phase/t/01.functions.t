use Test::Spec;
use Perl::Phase;

diag("Testing Perl::Phase $Perl::Phase::VERSION");

describe "Perl::Phase" => sub {
    describe "constant" => sub {
        it "PERL_PHASE_CONSTRUCT has correct value" => sub { is Perl::Phase::PERL_PHASE_CONSTRUCT, 0 };
        it "PERL_PHASE_START has correct value"     => sub { is Perl::Phase::PERL_PHASE_START,     1 };
        it "PERL_PHASE_CHECK has correct value"     => sub { is Perl::Phase::PERL_PHASE_CHECK,     2 };
        it "PERL_PHASE_INIT has correct value"      => sub { is Perl::Phase::PERL_PHASE_INIT,      3 };
        it "PERL_PHASE_RUN has correct value"       => sub { is Perl::Phase::PERL_PHASE_RUN,       4 };
        it "PERL_PHASE_END has correct value"       => sub { is Perl::Phase::PERL_PHASE_END,       5 };
        it "PERL_PHASE_DESTRUCT has correct value"  => sub { is Perl::Phase::PERL_PHASE_DESTRUCT,  6 };
    };

    describe "run time function" => sub {
        describe "is_run_time()" => sub {
            it "should be true during INIT" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_INIT };
                ok Perl::Phase::is_run_time();
            };

            it "should be true during RUN" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_RUN };
                ok Perl::Phase::is_run_time();
            };

            it "should be true during END" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_END };
                ok Perl::Phase::is_run_time();
            };

            it "should be true during DESTRUCT" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_DESTRUCT };
                ok Perl::Phase::is_run_time();
            };

            it "should be false during CONSTRUCT" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_CONSTRUCT };
                ok !Perl::Phase::is_run_time();
            };

            it "should be false during START" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_START };
                ok !Perl::Phase::is_run_time();
            };
            it "should be false during CHECK" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_CHECK };
                ok !Perl::Phase::is_run_time();
            };
        };

        describe "assert_is_run_time()" => sub {
            it "should not die during run time" => sub {
                no warnings "redefine";
                local *Perl::Phase::is_run_time = sub { 1 };
                trap { Perl::Phase::assert_is_run_time() };
                is $trap->die, undef;

            };
            it "should die during compile time" => sub {
                no warnings "redefine";
                local *Perl::Phase::is_run_time = sub { 0 };
                trap { Perl::Phase::assert_is_run_time() };
                like $trap->die, qr/at compile time/;
            };
        };
    };

    describe "compile time function" => sub {
        describe "is_compile_time()" => sub {
            it "should be true during CONSTRUCT" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_CONSTRUCT };
                ok Perl::Phase::is_compile_time();
            };

            it "should be true during START" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_START };
                ok Perl::Phase::is_compile_time();
            };
            it "should be true during CHECK" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_CHECK };
                ok Perl::Phase::is_compile_time();
            };

            it "should be false during INIT" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_INIT };
                ok !Perl::Phase::is_compile_time();
            };

            it "should be false during RUN" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_RUN };
                ok !Perl::Phase::is_compile_time();
            };

            it "should be false during END" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_END };
                ok !Perl::Phase::is_compile_time();
            };

            it "should be true during DESTRUCT" => sub {
                no warnings "redefine";
                local *Perl::Phase::current_phase = sub { Perl::Phase::PERL_PHASE_DESTRUCT };
                ok !Perl::Phase::is_compile_time();
            };
        };

        describe "assert_is_compile_time()" => sub {
            it "should not die during compile time" => sub {
                no warnings "redefine";
                local *Perl::Phase::is_compile_time = sub { 1 };
                trap { Perl::Phase::assert_is_compile_time() };
                is $trap->die, undef;

            };
            it "should die during compile time" => sub {
                no warnings "redefine";
                local *Perl::Phase::is_compile_time = sub { 0 };
                trap { Perl::Phase::assert_is_compile_time() };
                like $trap->die, qr/at run time/;
            };
        };
    };
};

runtests unless caller;
