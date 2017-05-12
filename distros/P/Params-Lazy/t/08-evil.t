use strict;
use warnings;

use Test::More;

use Params::Lazy lazy_run => '^$;$';

sub lazy_run {
    no warnings 'exiting';
    FOO: {
        eval { force $_[0] };
        like($@, $_[1], $_[2]);
        return;
    }
    fail("Should not get here");
}


sub empty      {}
sub noreturn   { 1 }
sub withreturn { return 1 }

my $cant_goto = qr/\QCan't goto subroutine \E(?:\Qfrom a sort sub (or similar callback)\E|outside a subroutine)/;  #'
lazy_run goto &empty, $cant_goto, "a delayed goto &emptysub dies";
lazy_run goto &noreturn, $cant_goto, "delayed goto &noexplicitreturn dies";
lazy_run goto &withreturn, $cant_goto, "delayed goto &explicitreturn dies";
    
sub {
    lazy_run goto &empty, $cant_goto, "inside a sub, a delayed goto &emptysub dies";
    lazy_run goto &noreturn, $cant_goto, "inside a sub, delayed goto &noexplicitreturn dies";
    lazy_run goto &withreturn, $cant_goto, "inside a sub, delayed goto &explicitreturn dies";
}->();

my $return = $] < 5.008009
           ? qr/\QCan't return outside a subroutine/
           : qr/\A\z/;
lazy_run return, $return, "a delayed return dies";
FOO: {
    no warnings 'exiting';
    lazy_run last FOO,
    qr/\QLabel not found for "last FOO"/,
    "a delayed last dies"
};
FOO: { lazy_run goto FOO, qr/\QCan't "goto" out of a pseudo block/, "a delayed goto LABEL dies" };


{
no Params::Lazy 'caller_args';
use Params::Lazy modify_params_list => '^;@';
sub modify_params_list {
    my ($delay) = @_;
    is(force($delay), $delay);
    return @_;
}
}
my @ret = modify_params_list(shift(@_), 1..10);
is_deeply(\@ret, [1..10], "can modify \@_ from a lazy arg");

use Params::Lazy run_evil => '^';
sub run_evil { force($_[0]); fail("Should never reach here") }

SKIP: {
    skip("No open -| on windows", 2) if $^O eq 'MSWin32';

    my $pid = open my $pipe, '-|';

    if (defined $pid) {    
        if ( $pid ) {
            my @out = <$pipe>;
            waitpid $pid, 0;
            my $exit_status = $? >> 8;
            is($exit_status, 150, "lazy_run exit()");
            is(join("", @out), "", "..doesn't produce unexpected output");
        }
        else {
            open(STDERR, ">&", STDOUT);
            run_evil exit(150);
            die "Should never reach here";
        }
    }
}


SKIP: {
    skip("Broken on 5.8", 1) if $] < 5.010;
    eval {
        no warnings 'deprecated';
        run_evil do { goto DOO; };
        NOPE: {
            last NOPE;
            DOO:
            {
                fail("should never reach here");
            }
        }
    };
    like($@, qr/\QCan't "goto" out of a pseudo block at/, "delay goto LABEL is disallowed");
}


use Params::Lazy with_private_var => '^';
sub with_private_var {
    my ($f)     = @_;
    my $private = 10;
    return force $f;
}

my $ret = with_private_var(eval '$private');
my $e   = $@;
ok(
    !$ret,
    "a delayed eval STRING *can't* peek at the lexicals of the delayer"
);

like(
    $e,
    qr/Global symbol "\$private" requires explicit package name/,
    "...and gives the right error message"
);
    
done_testing;
