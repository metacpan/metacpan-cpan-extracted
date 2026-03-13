# Tests for module serving and path-traversal security.
use v5.36;
use Test::More;
use lib 'lib';
use Remote::Perl;

# Helper: connect via local perl, serving modules from t/lib.
sub make_r() {
    return Remote::Perl->new(
        cmd     => [$^X],
        timeout => 10,
        window  => 65_536,
        serve   => 1,
        inc     => ['t/lib'],
    );
}

# -- Basic module transfer -----------------------------------------------------
# Remote::Perl::Test::Greeter exists in t/lib but not in the standard @INC.
# With served-first strategy it should be fetched from the local side.

{
    my $r   = make_r();
    my $out = '';
    my $rc  = $r->run_code(
        'use Remote::Perl::Test::Greeter; print Remote::Perl::Test::Greeter::greet("world"), "\n";',
        on_stdout => sub { $out .= $_[0] },
    );
    is($rc,  0,                 'module: exit 0');
    is($out, "Hello, world!\n", 'module: executed correctly');
    $r->disconnect;
}

# -- __DATA__ in a served module -----------------------------------------------

{
    my $r   = make_r();
    my $out = '';
    my $rc  = $r->run_code(
        'use Remote::Perl::Test::Greeter; print Remote::Perl::Test::Greeter::tagline(), "\n";',
        on_stdout => sub { $out .= $_[0] },
    );
    is($rc,  0,                                    'module __DATA__: exit 0');
    is($out, "Spreading greetings since 1987.\n",  'module __DATA__: read correctly');
    $r->disconnect;
}

# -- MOD_MISSING for truly absent module ---------------------------------------

{
    my $r  = make_r();
    my ($rc, $msg) = $r->run_code('use No::Such::Module::XYZ;');
    isnt($rc, 0,                       'missing module: non-zero exit');
    like($msg, qr/No::Such::Module/,   'missing module: error mentions module name');
    $r->disconnect;
}

# -- serving disabled (default): module not served -----------------------------

{
    my $r = Remote::Perl->new(
        cmd     => [$^X],
        timeout => 10,
        window  => 65_536,
        inc     => ['t/lib'],
    );
    my ($rc, $msg) = $r->run_code('use Remote::Perl::Test::Greeter;');
    isnt($rc, 0,                     'serving off: non-zero exit');
    like($msg, qr/Remote.Perl.Test/,     'serving off: error mentions module name');
    $r->disconnect;
}

# -- Path traversal rejected ---------------------------------------------------
# The remote @INC hook sends the filename as-is; a filename with '..' components
# must be rejected by the local ModuleServer regardless of what files exist.

{
    my $r = make_r();
    my ($rc, $msg) = $r->run_code('require "Foo/../../etc/passwd";');
    isnt($rc, 0,              'path traversal: non-zero exit');
    like($msg, qr/Can't locate/, 'path traversal: MOD_MISSING returned, module not loaded');
    $r->disconnect;
}

# -- Local-side enforcement: MOD_REQ rejected even if remote sends one ---------
# Bootstrap with serve => 1 so the remote @INC hook IS installed (simulating a
# rogue remote that ignores REMOTE_PERL_SERVE=0), then disable local serving to
# verify the local dispatcher enforces the restriction independently.

{
    my $r = Remote::Perl->new(
        cmd     => [$^X],
        timeout => 10,
        window  => 65_536,
        serve   => 1,
        inc     => ['t/lib'],
    );
    $r->{serve}    = 0;
    $r->{_mod_srv} = bless {}, 'MockModuleServer';
    my ($rc, $msg) = $r->run_code('use Remote::Perl::Test::Greeter;');
    isnt($rc, 0,                 'local enforcement: MOD_REQ refused when serve => 0');
    like($msg, qr/Remote.Perl.Test/, 'local enforcement: error mentions module name');
    $r->disconnect;
}

# -- serve_filter: deny all ----------------------------------------------------

{
    my $r = Remote::Perl->new(
        cmd          => [$^X],
        serve        => 1,
        inc          => ['t/lib'],
        serve_filter => sub { 0 },
    );
    my ($rc, $msg) = $r->run_code('use Remote::Perl::Test::Greeter;');
    isnt($rc, 0,                         'serve_filter deny: non-zero exit');
    like($msg, qr/Remote.Perl.Test/,     'serve_filter deny: error mentions module');
    $r->disconnect;
}

# -- serve_filter: allow by path -----------------------------------------------

{
    require Cwd;
    my $allowed = Cwd::realpath('t/lib');
    my $r = Remote::Perl->new(
        cmd          => [$^X],
        serve        => 1,
        inc          => ['t/lib'],
        serve_filter => sub($path) {
            my $real = Cwd::realpath($path) // return 0;
            return index($real, "$allowed/") == 0 ? 1 : 0;
        },
    );
    my $out = '';
    my $rc = $r->run_code(
        'use Remote::Perl::Test::Greeter; print Remote::Perl::Test::Greeter::greet("filter"), "\n";',
        on_stdout => sub { $out .= $_[0] },
    );
    is($rc,  0,                    'serve_filter allow: exit 0');
    is($out, "Hello, filter!\n",   'serve_filter allow: module served correctly');
    $r->disconnect;
}

done_testing;

package MockModuleServer;
sub find {
    print STDERR "MockModuleServer::find called -- local side must not serve modules when serve => 0\n";
    Test::More::fail('local enforcement: ModuleServer::find must not be called when serve => 0');
    return undef;
}
