# Remote-side compatibility tests with older Perls (5.10+) via perlbrew.
use v5.36;
use Test::More;
use File::Temp qw(tempfile);
use IPC::Open3 qw(open3);
use IO::Select;
use Symbol qw(gensym);

use lib 'lib';

# -- Target interpreters -------------------------------------------------------

my @candidates = map { [$_, (glob("~/perl5/perlbrew/perls/$_/bin/perl"))[0]] }
    qw(perl-5.36.3 perl-5.34.3 perl-5.32.1 perl-5.30.3 perl-5.28.3 perl-5.26.3
       perl-5.24.4 perl-5.22.4 perl-5.20.3 perl-5.18.4 perl-5.16.3 perl-5.14.4
       perl-5.12.5 perl-5.10.1);

my @targets = grep { defined $_->[1] && -x $_->[1] } @candidates;

plan skip_all => 'no target interpreters found'
    unless @targets;

warn "old-perl.t: only " . scalar(@targets) . " target(s) found; install more via perlbrew for better coverage\n"
    if @targets < 3;

# -- Helpers -------------------------------------------------------------------

sub script($source) {
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh $source;
    close $fh;
    return $path;
}

sub run_remperl($stdin_data, @args) {
    my ($in_fh, $out_fh, $err_fh);
    $err_fh = gensym();
    my $pid = open3($in_fh, $out_fh, $err_fh,
        $^X, '-It/lib', 'bin/remperl', @args);
    binmode($in_fh); binmode($out_fh); binmode($err_fh);

    if (defined $stdin_data) {
        print $in_fh $stdin_data;
    }
    close $in_fh;

    my ($stdout, $stderr) = ('', '');
    my $sel = IO::Select->new($out_fh, $err_fh);
    while ($sel->count) {
        for my $fh ($sel->can_read(15)) {
            my $buf;
            my $n = sysread($fh, $buf, 65536);
            if (!$n) { $sel->remove($fh); next }
            if (fileno($fh) == fileno($out_fh)) { $stdout .= $buf }
            else                                 { $stderr .= $buf }
        }
    }

    waitpid($pid, 0);
    return ($stdout, $stderr, $? >> 8);
}

# -- Tests (run for each available target) -------------------------------------

for my $target (@targets) {
    my ($label, $interp) = @$target;

    # Devel::Cover is not available for perls older than 5.20.  Strip
    # -MDevel::Cover=... from PERL5OPT so the remote interpreter doesn't try
    # to load it and die from module loading failure.
    my ($minor) = ($label =~ /perl-\d+\.(\d+)/);
    local $ENV{PERL5OPT} = do {
        my $opt = $ENV{PERL5OPT} // '';
        $opt =~ s/-MDevel::Cover\S*//g if defined $minor && $minor < 20;
        $opt;
    };

    # stdout
    {
        my ($out, $err, $rc) = run_remperl(undef,
            '--pipe-cmd', $interp, script('print "hello\n";'));
        is($rc,  0,         "$label stdout: exit 0");
        is($out, "hello\n", "$label stdout: correct");
        is($err, '',        "$label stdout: no stderr");
    }

    # stderr
    {
        my ($out, $err, $rc) = run_remperl(undef,
            '--pipe-cmd', $interp, script('print STDERR "err\n";'));
        is($rc,  0,        "$label stderr: exit 0");
        is($out, '',       "$label stderr: no stdout");
        is($err, "err\n",  "$label stderr: correct");
    }

    # exit code
    {
        my ($out, $err, $rc) = run_remperl(undef,
            '--pipe-cmd', $interp, script('exit 42;'));
        is($rc, 42, "$label exit code: passed through");
    }

    # die
    {
        my ($out, $err, $rc) = run_remperl(undef,
            '--pipe-cmd', $interp, script('die "boom\n";'));
        is($rc, 255, "$label die: exit 255");
        like($err, qr/boom/, "$label die: message in stderr");
    }

    # stdin forwarding
    {
        my ($out, $err, $rc) = run_remperl("hello\n",
            '--pipe-cmd', $interp, script('my $l = <STDIN>; print "got: $l";'));
        is($rc,  0,              "$label stdin: exit 0");
        is($out, "got: hello\n", "$label stdin: echoed correctly");
    }

    # -e flag
    {
        my ($out, $err, $rc) = run_remperl(undef,
            '--pipe-cmd', $interp,
            '-e', 'print "result: " . (6 * 7) . "\n";');
        is($rc,  0,              "$label -e: exit 0");
        is($out, "result: 42\n", "$label -e: expression evaluated correctly");
    }

    # module serving
    {
        my ($out, $err, $rc) = run_remperl(undef,
            '--pipe-cmd', $interp, '--serve-modules',
            script('use Remote::Perl::Test::Greeter;'
                 . 'print Remote::Perl::Test::Greeter::greet("World"), "\n";'));
        is($rc,  0,                "$label module serving: exit 0");
        is($out, "Hello, World!\n", "$label module serving: module loaded and used");
        is($err, '',               "$label module serving: no stderr");
    }
}

done_testing;
