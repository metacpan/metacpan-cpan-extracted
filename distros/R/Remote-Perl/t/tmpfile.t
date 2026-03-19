# Tests for __DATA__ section handling across tmpfile strategies (auto/linux/perl/named).
use v5.36;
use Test::More;

use lib 'lib';
use Remote::Perl;

sub make_r(%args) { Remote::Perl->new(cmd => [$^X], %args) }

my $DATA_SCRIPT = <<'PERL';
my $data = do { local $/; readline *main::DATA };
print "data:$data";
__DATA__
hello from data
PERL

my $END_SCRIPT = <<'PERL';
print "before end\n";
__END__
this should not execute
PERL

# -- __DATA__ with each strategy -----------------------------------------------

for my $strategy (qw(auto linux perl named)) {
    SKIP: {
        skip("linux tmpfile strategy requires Linux", 2)
            if $strategy eq 'linux' && $^O ne 'linux';

        my $r   = make_r(tmpfile => $strategy);
        my $out = '';
        my $rc;
        eval { $rc = $r->run_code($DATA_SCRIPT, on_stdout => sub { $out .= $_[0] }) };
        if ($@ =~ /unavailable/) {
            $r->disconnect;
            pass("$strategy: skipped (not available on this system)");
            pass("$strategy: skipped");
            next;
        }
        is($rc,  0,                       "$strategy: exit 0");
        is($out, "data:hello from data\n", "$strategy: __DATA__ readable");
        $r->disconnect;
    }
}

# -- Per-run tmpfile override --------------------------------------------------

{
    my $r   = make_r();   # no object-level tmpfile
    my $out = '';
    my $rc  = $r->run_code($DATA_SCRIPT,
        on_stdout => sub { $out .= $_[0] },
        tmpfile   => 'auto',
    );
    is($rc,  0,                       'per-run tmpfile: exit 0');
    is($out, "data:hello from data\n", 'per-run tmpfile: __DATA__ readable');
    $r->disconnect;
}

# -- __END__ works regardless of tmpfile mode ----------------------------------

{
    my $r   = make_r();
    my $out = '';
    my $rc  = $r->run_code($END_SCRIPT, on_stdout => sub { $out .= $_[0] });
    is($rc,  0,              '__END__: exit 0');
    is($out, "before end\n", '__END__: stops parsing, code before it runs');
    $r->disconnect;
}

# -- __DATA__ warning emitted when data_warn => 1 ------------------------------

{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };

    my $r  = make_r(data_warn => 1);
    my $rc = $r->run_code($DATA_SCRIPT, on_stdout => sub {});
    is(scalar @warns, 1,          'warning: emitted when data_warn => 1 and no tmpfile');
    like($warns[0], qr/__DATA__/, 'warning: mentions __DATA__');
    $r->disconnect;
}

# -- No warning by default (data_warn => 0) ------------------------------------

{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };

    my $r  = make_r();   # data_warn => 0 by default
    my $rc = $r->run_code($DATA_SCRIPT, on_stdout => sub {});
    my @data_warns = grep { /DATA/ } @warns;
    is(scalar @data_warns, 0, 'no warning by default (data_warn => 0)');
    $r->disconnect;
}

# -- No warning when tmpfile is enabled ----------------------------------------

{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };

    my $r  = make_r(tmpfile => 'auto', data_warn => 1);
    my $rc = $r->run_code($DATA_SCRIPT, on_stdout => sub {});
    my @data_warns = grep { /DATA/ } @warns;
    is(scalar @data_warns, 0, 'no warning when tmpfile enabled');
    $r->disconnect;
}

# -- No __DATA__ warning for __END__ -------------------------------------------

{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };

    my $r  = make_r();
    my $rc = $r->run_code($END_SCRIPT, on_stdout => sub {});
    my @data_warns = grep { /DATA/ } @warns;
    is(scalar @data_warns, 0, '__END__: no __DATA__ warning emitted');
    $r->disconnect;
}

# -- Multiple runs with __DATA__ on same connection ----------------------------

{
    my $r = make_r(tmpfile => 'auto');
    my @outs;
    for my $i (1, 2, 3) {
        my $src = "print 'run$i\n'; __DATA__\ndata$i\n";
        my $out = '';
        $r->run_code($src, on_stdout => sub { $out .= $_[0] });
        push @outs, $out;
    }
    is($outs[0], "run1\n", 'multi: first run output');
    is($outs[1], "run2\n", 'multi: second run output');
    is($outs[2], "run3\n", 'multi: third run output');
    $r->disconnect;
}

done_testing;
