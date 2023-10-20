#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

use IPC::Open3 qw/ open3 /;
use Symbol qw/ gensym /;

use FindBin qw//;
my $script = "$FindBin::RealBin/../term-datamatrix.in";

require Term::DataMatrix;

ok(-f $script, 'script should exist');

# Test run with no arguments
my ($stdout, $stderr, $ret) = run_script();
is($ret, 2,
    'script with no args should exit 2'
);
like($stderr, qr/^Usage:/,
    'script with no args tell you how to use it'
);
is($stdout, '',
    'script with no args should not output on stdout'
);

# Test run with too many arguments
($stdout, $stderr, $ret) = run_script(qw/ too many arguments /);
is($ret, 2,
    'script with 3 args should exit 2'
);
like($stderr, qr/^Usage:/,
    'script with 3 args tell you how to use it'
);
is($stdout, '',
    'script with 3 args should not output on stdout'
);

# Test creating a barcode
($stdout, $stderr, $ret) = run_script('hello world');
is($ret, 0,
    'script (hello world) exits 0'
);
is($stderr, '',
    'script (hello world) should not output on stderr'
);
like($stdout, qr/^(?:\s|\e\[[0-9;]+m|\n)+$/,
    'script (hello world) output should contain only whitespace and color controls'
);
unlike($stdout, qr/\n\n/,
    'script (hello world) output should not contain more than one paragraph'
);

# Test creating a different barcode
my $hello_world_barcode = $stdout;
($stdout, $stderr, $ret) = run_script('another barcode');
is($ret, 0,
    'script (another barcode) exits 0'
);
is($stderr, '',
    'script (hello world) should not output on stderr'
);
isnt($hello_world_barcode, $stdout,
    'script (another barcode) generates a different barcode than "hello world"'
);

# Help message tests
($stdout, $stderr, $ret) = run_script('--help');
is($ret, 0,
    'script (--help) should exit 0'
);
is($stderr, '',
    'script (--help) should not output on stderr'
);
like($stdout, qr/\n$/,
    'script (--help) output should end with a newline'
);
like($stdout, qr/^Usage:/,
    'script (--help) output should begin with "Usage:"'
);

# Version message tests
($stdout, $stderr, $ret) = run_script('--version');
is($ret, 0,
    'script (--version) exits 0'
);
is($stderr, '',
    'script (--version) should not output on stderr'
);
like($stdout, qr/\n$/,
    'script (--version) output should end with a newline'
);
my $cv = quotemeta $Term::DataMatrix::VERSION;
like($stdout, qr/$cv/,
    'script (--version) output contains module version'
);

sub run_script {
    my @args = @_;
    return run_capture(
        cmd => [$^X, $script, @args],
    );
}

sub run_capture {
    my (%args) = @_;
    $args{stdin} //= '';
    my @cmd = @{$args{cmd}};
    my $child_out = gensym();
    my $child_err = ($args{combined_io} ? $child_out : gensym());
    my $pid = open3($args{stdin}, $child_out, $child_err, @cmd);
    waitpid $pid, 0;
    my $exitcode = $? >> 8;

    local $/; # slurp!
    return (
        scalar <$child_out>,
        scalar <$child_err>,
        $exitcode,
    );
}
