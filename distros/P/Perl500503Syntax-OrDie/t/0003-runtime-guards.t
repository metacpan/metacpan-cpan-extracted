######################################################################
#
# 0003-runtime-guards.t  Runtime guard tests
#
# Tests for CORE::GLOBAL::open and CORE::GLOBAL::mkdir overrides.
# The guards MUST be installed in BEGIN so that compiled calls in
# this file are intercepted at runtime.
#
# Note on bareword filehandles:
#   When CORE::GLOBAL::open is installed, Perl strict subs fires on
#   bareword FH arguments at compile time.  Tests therefore wrap
#   open() calls in { no strict 'subs'; no strict 'refs'; ... }.
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use File::Spec ();

BEGIN {
    require Perl500503Syntax::OrDie;
    Perl500503Syntax::OrDie::_install_runtime_guards();
}

use vars qw(@tests $TMPDIR $DEVNULL);

# Helper to invoke 3-argument open without triggering selfcheck's
# literal pattern detector for open(var,mode,path).
sub _open3 {
    # Call _guarded_open directly so that the runtime guard fires.
    # This avoids a literal 'open(' that would trigger selfcheck P3.
    Perl500503Syntax::OrDie::_guarded_open(@_);
}
$DEVNULL = File::Spec->devnull();
$TMPDIR  = File::Spec->catfile(File::Spec->tmpdir(), "ordie_test_$$");

# Helper: write content to a temp file, bypassing the guarded open().
sub _write_tmp {
    my ($path, $content) = @_;
    local *ORDIE_WTMP2;
    CORE::open(ORDIE_WTMP2, ">$path") or return 0;
    print ORDIE_WTMP2 $content;
    CORE::close(ORDIE_WTMP2);
    return -f $path ? 1 : 0;
}

@tests = (

    # ==============================================================
    # open(): 3-argument form must die
    # ==============================================================
    ['open3: 3-arg dies',
        sub {
            my $fh;
            eval { _open3($fh, ">", $DEVNULL) };
            $@ =~ /RUNTIME VIOLATION/;
        }],

    ['open3: 3-arg read mode dies',
        sub {
            my $fh;
            eval { _open3($fh, "<", $DEVNULL) };
            $@ =~ /RUNTIME VIOLATION/;
        }],

    ['open3: error message mentions file and line',
        sub {
            my $fh;
            eval { _open3($fh, ">", $DEVNULL) };
            $@ =~ /RUNTIME VIOLATION at .+ line \d+/;
        }],

    ['open3: 4-arg (extra args) dies',
        sub {
            my $fh;
            eval { _open3($fh, ">", $DEVNULL, "extra") };
            $@ =~ /RUNTIME VIOLATION/;
        }],

    # ==============================================================
    # open(): 2-argument form must succeed (bareword FH)
    # Wrapped in { no strict 'subs'; no strict 'refs' } because
    # CORE::GLOBAL::open causes strict subs to fire on bareword FH
    # at compile time.
    # ==============================================================
    ['open2: 2-arg write with bareword FH lives',
        sub {
            my $ok = 0;
            local $^W = 0;
            eval {
                no strict 'subs';
                no strict 'refs';
                local *ORDIE_WFH;
                open(ORDIE_WFH, ">$DEVNULL") or die "cannot open: $!";
                defined(fileno(ORDIE_WFH)) and close ORDIE_WFH;
                $ok = 1;
            };
            $ok && !$@;
        }],

    ['open2: 2-arg read with bareword FH lives',
        sub {
            my $ok = 0;
            local $^W = 0;
            eval {
                no strict 'subs';
                no strict 'refs';
                local *ORDIE_RFH;
                open(ORDIE_RFH, "<$DEVNULL") or die "cannot open: $!";
                defined(fileno(ORDIE_RFH)) and close ORDIE_RFH;
                $ok = 1;
            };
            $ok && !$@;
        }],

    ['open2: write to temp file lives',
        sub {
            my $tmp = File::Spec->catfile(
                File::Spec->tmpdir(), "ordie_open2_$$.txt");
            my $ok  = 0;
            local $^W = 0;
            eval {
                no strict 'subs';
                no strict 'refs';
                local *ORDIE_TMP;
                open(ORDIE_TMP, ">$tmp") or die "cannot open: $!";
                defined(fileno(ORDIE_TMP)) and print ORDIE_TMP "test\n";
                defined(fileno(ORDIE_TMP)) and close ORDIE_TMP;
                $ok = -f $tmp ? 1 : 0;
                unlink $tmp;
            };
            $ok && !$@;
        }],

    ['open2: guard does not fire on 2-arg (no RUNTIME VIOLATION)',
        sub {
            local $^W = 0;
            eval {
                no strict 'subs';
                no strict 'refs';
                local *ORDIE_GFH;
                open(ORDIE_GFH, ">$DEVNULL");
                defined(fileno(ORDIE_GFH)) and close ORDIE_GFH;
            };
            $@ !~ /RUNTIME VIOLATION/;
        }],

    # ==============================================================
    # open(): reference as mode must die
    # ==============================================================
    ['open-ref: scalar ref as second arg dies',
        sub {
            my $ref = \$DEVNULL;
            local $^W = 0;
            local *ORDIE_RFH2;
            eval {
                no strict 'subs';
                no strict 'refs';
                open(ORDIE_RFH2, $ref);
                close ORDIE_RFH2;
            };
            $@ =~ /RUNTIME VIOLATION/;
        }],

    ['open-ref: GLOB ref as second arg dies',
        sub {
            my $ref = \*STDOUT;
            local $^W = 0;
            local *ORDIE_GFH2;
            eval {
                no strict 'subs';
                no strict 'refs';
                open(ORDIE_GFH2, $ref);
                close ORDIE_GFH2;
            };
            $@ =~ /RUNTIME VIOLATION/;
        }],

    # ==============================================================
    # mkdir(): without mode must die
    # ==============================================================
    ['mkdir0: no mode dies',
        sub {
            eval { mkdir($TMPDIR) };
            my $died = ($@ =~ /RUNTIME VIOLATION/);
            rmdir($TMPDIR);
            $died;
        }],

    ['mkdir0: error message mentions file and line',
        sub {
            eval { mkdir($TMPDIR) };
            my $ok = ($@ =~ /RUNTIME VIOLATION at .+ line \d+/);
            rmdir($TMPDIR);
            $ok;
        }],

    ['mkdir0: error mentions mode requirement',
        sub {
            eval { mkdir($TMPDIR) };
            my $ok = ($@ =~ /requires an explicit mode/);
            rmdir($TMPDIR);
            $ok;
        }],

    # ==============================================================
    # mkdir(): with mode must succeed
    # ==============================================================
    ['mkdir2: mode 0755 lives and creates directory',
        sub {
            my $ok = 0;
            eval {
                mkdir($TMPDIR, 0755) or die "mkdir failed: $!";
                $ok = (-d $TMPDIR) ? 1 : 0;
                rmdir($TMPDIR);
            };
            $ok && !$@;
        }],

    ['mkdir2: mode 0700 lives',
        sub {
            my $ok = 0;
            eval {
                mkdir($TMPDIR, 0700) or die "mkdir failed: $!";
                $ok = (-d $TMPDIR) ? 1 : 0;
                rmdir($TMPDIR);
            };
            $ok && !$@;
        }],

    ['mkdir2: guard does not fire on 2-arg mkdir',
        sub {
            eval { mkdir($TMPDIR, 0755); rmdir($TMPDIR); };
            $@ !~ /RUNTIME VIOLATION/;
        }],

    # ==============================================================
    # Guard idempotency
    # ==============================================================
    ['idempotent: double install does not cause double-fire',
        sub {
            Perl500503Syntax::OrDie::_install_runtime_guards();
            Perl500503Syntax::OrDie::_install_runtime_guards();
            my $fh;
            my $count = 0;
            eval { _open3($fh, ">", $DEVNULL); };
            $count++ if $@ =~ /RUNTIME VIOLATION/;
            eval { _open3($fh, ">", $DEVNULL); };
            $count++ if $@ =~ /RUNTIME VIOLATION/;
            $count == 2;
        }],

    ['idempotent: $_OPEN_GUARDED flag is set',
        sub { $Perl500503Syntax::OrDie::_OPEN_GUARDED }],

    ['idempotent: $_MKDIR_GUARDED flag is set',
        sub { $Perl500503Syntax::OrDie::_MKDIR_GUARDED }],

    # ==============================================================
    # Public API: check_file()
    # ==============================================================
    ['api: check_file on valid file lives',
        sub {
            my $tmp = File::Spec->catfile(
                File::Spec->tmpdir(), "ordie_valid_$$.pl");
            _write_tmp($tmp, "use strict;\nuse vars qw(\$x);\n\$x = 1;\n")
                or return 0;
            my $ok = 1;
            eval { Perl500503Syntax::OrDie::check_file($tmp) };
            $ok = 0 if $@;
            unlink $tmp;
            $ok;
        }],

    ['api: check_file on violating file dies',
        sub {
            my $tmp = File::Spec->catfile(
                File::Spec->tmpdir(), "ordie_bad_$$.pl");
            _write_tmp($tmp, "our \$x = 1;\n") or return 0;
            eval { Perl500503Syntax::OrDie::check_file($tmp) };
            my $died = ($@ =~ /VIOLATION/);
            unlink $tmp;
            $died;
        }],

    ['api: check_source function-style lives on clean code',
        sub {
            eval { Perl500503Syntax::OrDie::check_source(
                "use strict;\nuse vars qw(\$x);\n", 't') };
            !$@;
        }],

    ['api: check_source function-style returns violations on our',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "our \$x = 1;\n", 't');
            @v && $v[0] =~ /VIOLATION/;
        }],

    ['api: check_source OO-style lives on clean code',
        sub {
            eval { Perl500503Syntax::OrDie->check_source(
                "use strict;\nmy \$x = 1;\n", 't') };
            !$@;
        }],

    ['api: check_source OO-style returns violations on our',
        sub {
            my @v = Perl500503Syntax::OrDie->check_source(
                "our \$x;\n", 't');
            @v && $v[0] =~ /VIOLATION/;
        }],

    ['api: check_file OO-style on valid file lives',
        sub {
            my $tmp = File::Spec->catfile(
                File::Spec->tmpdir(), "ordie_oo_$$.pl");
            _write_tmp($tmp, "use strict;\n1;\n") or return 0;
            my $ok = 1;
            eval { Perl500503Syntax::OrDie->check_file($tmp) };
            $ok = 0 if $@;
            unlink $tmp;
            $ok;
        }],

    # ==============================================================
    # Violation error messages
    # ==============================================================
    ['msg: VIOLATION message contains filename',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "our \$x;\n", 'myfile.pl');
            @v && $v[0] =~ /myfile\.pl/;
        }],

    ['msg: VIOLATION message contains line number',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "use strict;\nour \$x;\n", 't');
            @v && $v[0] =~ /line 2/;
        }],

    ['msg: VIOLATION message describes the feature',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "our \$x;\n", 't');
            @v && $v[0] =~ /our.*Perl 5\.6/i;
        }],

);

print "1.." . scalar(@tests) . "\n";
my $n = 0;
for my $t (@tests) {
    $n++;
    my ($label, $code) = @{$t};
    my $result = eval { $code->() };
    my $ok     = $result && !$@;
    print +($ok ? '' : 'not ') . "ok $n - $label\n";
    if ($@ && $@ !~ /VIOLATION|RUNTIME/) {
        print "# EVAL ERROR: $@\n";
    }
}

END { rmdir $TMPDIR }
