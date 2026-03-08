use v5.36;
use Test::More;
use IPC::Open3 qw(open3);
use IO::Select;
use Symbol qw(gensym);
use File::Temp qw(tempfile);

use lib 'lib';
use Remote::Perl;

# Run a snippet with plain perl and return (stdout, stderr, exit_code).
sub perl_e($code) {
    my $err_fh = gensym();
    my $pid    = open3(my $in, my $out_fh, $err_fh, $^X, '-e', $code);
    close $in;
    my ($out, $err) = ('', '');
    my $sel = IO::Select->new($out_fh, $err_fh);
    while ($sel->count) {
        for my $fh ($sel->can_read(5)) {
            my $n = sysread($fh, my $buf, 65536);
            if (!$n) { $sel->remove($fh); next }
            fileno($fh) == fileno($out_fh) ? ($out .= $buf) : ($err .= $buf);
        }
    }
    waitpid($pid, 0);
    return ($out, $err, $? >> 8);
}

# Run a snippet with remperl and return (stdout, stderr, exit_code).
# method: 'code' (run_code), 'file' (run_file), 'file_tmpfile' (run_file + tmpfile)
sub remperl_e($code, $method) {
    my ($out, $err) = ('', '');
    my $r = Remote::Perl->new(
        cmd     => [$^X],
        tmpfile => ($method eq 'file_tmpfile' ? 'auto' : 0),
    );
    my $rc;
    if ($method eq 'code') {
        $rc = $r->run_code($code,
            on_stdout => sub { $out .= $_[0] },
            on_stderr => sub { $err .= $_[0] },
        );
    } else {
        my ($fh, $filename) = tempfile(SUFFIX => '.pl', UNLINK => 1);
        print $fh $code;
        close $fh;
        $rc = $r->run_file($filename,
            on_stdout => sub { $out .= $_[0] },
            on_stderr => sub { $err .= $_[0] },
        );
    }
    $r->disconnect;
    return ($out, $err, $rc);
}

my @configs = (
    ['run_code',         'code'        ],
    ['run_file',         'file'        ],
    ['run_file+tmpfile', 'file_tmpfile'],
);

# For each snippet: perl and remperl should produce the same exit code,
# stdout, and stderr (modulo the script path in error messages).

# -- Snippets that should succeed in both --------------------------------------

for my $case (
    ['bareword as string',    'print asdf'           ],
    ['print hello',           'print "hello\n"'      ],
    ['arithmetic',            'print 6*7, "\n"'      ],
) {
    my ($label, $code) = @$case;
    my (undef, undef, $perl_rc) = perl_e($code);
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my (undef, undef, $rc) = remperl_e($code, $method);
        is($rc, $perl_rc, "$label ($name): exit code matches perl");
    }
}

# -- Snippets that should fail in both -----------------------------------------

for my $case (
    ['strict violation',      'use strict; print STDOUT foo'                 ],
    ['syntax error',          'this is not; valid perl!!!'                   ],
    ['die',                   'die "boom\n"'                                  ],
) {
    my ($label, $code) = @$case;
    my (undef, undef, $perl_rc) = perl_e($code);
    isnt($perl_rc, 0, "$label: perl exits non-zero");
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my (undef, undef, $rc) = remperl_e($code, $method);
        is($rc, $perl_rc, "$label ($name): exit code matches perl");
    }
}

# -- Feature parity: things perl -e cannot do without explicit `use` -----------
# These test that remperl does NOT silently enable features that plain perl
# requires an explicit `use feature` or `use vX.Y` for.

{
    my $code = 'sub f($x) { $x }; print f(1)';
    my (undef, undef, $perl_rc) = perl_e($code);
    isnt($perl_rc, 0, 'signatures: perl -e fails without use feature');
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my (undef, undef, $rc) = remperl_e($code, $method);
        is($rc, $perl_rc, "signatures ($name): remperl matches perl (fails without use feature)");
    }
}

{
    my $code = 'say "hello"';
    my (undef, undef, $perl_rc) = perl_e($code);
    isnt($perl_rc, 0, 'say: perl -e fails without use feature');
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my (undef, undef, $rc) = remperl_e($code, $method);
        is($rc, $perl_rc, "say ($name): remperl matches perl (fails without use feature)");
    }
}

{
    my $code = 'use feature "state"; my $f = sub { state $n = 0; ++$n }; print $f->(), $f->()';
    my ($perl_out, undef, $perl_rc) = perl_e($code);
    is($perl_rc, 0, 'state: perl -e succeeds with explicit use feature');
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my ($out, undef, $rc) = remperl_e($code, $method);
        is($rc,  $perl_rc,  "state ($name): exit code matches perl");
        is($out, $perl_out, "state ($name): output matches perl");
    }
}

# -- With explicit use v5.36: both should succeed ------------------------------

{
    my $code = 'use v5.36; sub f($x) { $x * 2 }; print f(21), "\n"';
    my ($perl_out, undef, $perl_rc) = perl_e($code);
    is($perl_rc, 0, 'use v5.36 + signatures: perl succeeds');
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my ($out, undef, $rc) = remperl_e($code, $method);
        is($rc,  $perl_rc,  "use v5.36 + signatures ($name): exit code matches perl");
        is($out, $perl_out, "use v5.36 + signatures ($name): output matches");
    }
}

# -- Client.pm imports are not visible to user code ----------------------------

{
    my $code = 'print defined(&WNOHANG) ? "defined" : "undef", "\n"';
    my ($perl_out) = perl_e($code);
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my ($out) = remperl_e($code, $method);
        is($out, $perl_out, "WNOHANG ($name): not visible to user code");
    }
}

# -- Enabled feature set matches plain perl ------------------------------------
# features_enabled(0) inspects the caller's own hint hash.  A sub wrapper is
# required because caller() has no frame to inspect at the top level of -e.

{
    my $code = 'require feature; '
             . 'sub _f { join(",", sort(feature::features_enabled(0))) } '
             . 'print _f(), "\n"';
    my ($perl_out, undef, $perl_rc) = perl_e($code);
    is($perl_rc, 0, 'feature set: perl exits 0');
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my ($out, undef, $rc) = remperl_e($code, $method);
        is($rc,  0,         "feature set ($name): remperl exits 0");
        is($out, $perl_out, "feature set ($name): enabled features match perl");
    }
}

# -- Same, but with explicit use v5.36 in the code -----------------------------

{
    my $code = 'use v5.36; require feature; '
             . 'sub _f { join(",", sort(feature::features_enabled(0))) } '
             . 'print _f(), "\n"';
    my ($perl_out, undef, $perl_rc) = perl_e($code);
    is($perl_rc, 0, 'feature set v5.36: perl exits 0');
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my ($out, undef, $rc) = remperl_e($code, $method);
        is($rc,  0,         "feature set v5.36 ($name): remperl exits 0");
        is($out, $perl_out, "feature set v5.36 ($name): enabled features match perl");
    }
}

# -- Explicitly enabled feature appears in the list ----------------------------

{
    my $code = 'use feature "say"; '
             . 'sub _f { join(",", sort(feature::features_enabled(0))) } '
             . 'print _f(), "\n"';
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my ($out, undef, $rc) = remperl_e($code, $method);
        is($rc, 0, "feature enabled ($name): exit 0");
        like($out, qr/\bsay\b/, "feature enabled ($name): say appears in feature list");
    }
}

# -- Feature absent from the list when not enabled -----------------------------

{
    my $code = 'require feature; '
             . 'sub _f { join(",", sort(feature::features_enabled(0))) } '
             . 'print _f(), "\n"';
    for my $cfg (@configs) {
        my ($name, $method) = @$cfg;
        my ($out, undef, $rc) = remperl_e($code, $method);
        is($rc, 0, "feature not enabled ($name): exit 0");
        unlike($out, qr/\bsay\b/, "feature not enabled ($name): say absent from feature list");
    }
}

done_testing;
