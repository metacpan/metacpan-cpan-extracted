use Test::Most tests => 3;
use Capture::Tiny qw[ capture_stderr ];

sub get_warnings {
    my ($code) = @_;
    my $stderr = capture_stderr { system $^X, -e => $code };
    return grep { /\AOpenTracing::WrapScope/ } split /\n/, $stderr;
}

my @warnings_normal = get_warnings(<<'EOF');
use OpenTracing::Implementation 'Test';
use OpenTracing::WrapScope qw[ foo bar ];
sub foo { }
EOF
cmp_deeply \@warnings_normal, [ re(qr/couldn't find sub: main::bar/) ],
    'missing sub shows up in warnings'
    or diag explain \@warnings_normal;

my @warnings_quiet = get_warnings(<<'EOF');
use OpenTracing::Implementation 'Test';
use OpenTracing::WrapScope qw[ -quiet foo bar ];
sub foo { }
EOF
cmp_deeply \@warnings_quiet, [], 'no warnings in -quiet mode'
    or diag explain \@warnings_quiet;

my @warnings_mixed = get_warnings(<<'EOF');
use OpenTracing::Implementation 'Test';
use OpenTracing::WrapScope qw[ foo bar ];
use OpenTracing::WrapScope qw[ -quiet foo1 bar1 ];
sub foo  { }
sub foo1 { }
EOF
cmp_deeply \@warnings_mixed, [ re(qr/couldn't find sub: main::bar/) ],
    'only the non-quiet mode sub shows up in warnings'
    or diag explain \@warnings_mixed;
