use File::Temp;
use Test::Most tests => 9;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope;

sub foo        { }
sub Bar::foo   { }
sub secret     { }
sub non_secret { }
sub with_sig   { }

my $sample_unqualified = _make_tmp_file(<<'EOF');
foo
EOF

throws_ok {
    OpenTracing::WrapScope::wrap_from_file($sample_unqualified->filename);
} qr/Unqualified subroutine/, 'unqualified sub name';


my $sample_quote_sig = _make_tmp_file(<<'EOF');
foo(%args{'user'})
EOF
throws_ok {
    OpenTracing::WrapScope::wrap_from_file($sample_quote_sig->filename);
} qr/Unqualified subroutine/, 'unqualified sub name with quotes in signature';

my $sample_pkg_sig = _make_tmp_file(<<'EOF');
foo(%args{"Package::Name"})
EOF
throws_ok {
    OpenTracing::WrapScope::wrap_from_file($sample_pkg_sig->filename);
} qr/Unqualified subroutine/, 'unqualified sub name with a package name in signature';

my $sample_qualified = _make_tmp_file(<<'EOF');
main::foo
Bar::foo
EOF

lives_ok {
    OpenTracing::WrapScope::wrap_from_file($sample_qualified->filename);
} 'all sub names fully qualified';

foo();
Bar::foo();

global_tracer_cmp_easy([
    { operation_name => 'main::foo' },
    { operation_name => 'Bar::foo' },
], 'spans created');


reset_spans();

my $sample_commented = _make_tmp_file(<<'EOF');
#main::secret
main::non_secret # this is fine
EOF

OpenTracing::WrapScope::wrap_from_file($sample_commented->filename);

secret();
non_secret();

global_tracer_cmp_deeply([
    superhashof({ operation_name => 'main::non_secret' }),
], 'commented sub is not touched');

my $sample_empty = _make_tmp_file('');
lives_ok {
    OpenTracing::WrapScope::wrap_from_file($sample_empty->filename)
} 'reading an empty file works';

my $sample_empty_lines = _make_tmp_file(<<'EOF');

# test

EOF

lives_ok {
    OpenTracing::WrapScope::wrap_from_file($sample_empty_lines->filename)
} 'reading a file with empty lines';

reset_spans();

my $sample_signatures = _make_tmp_file(<<'EOF');
main::with_sig($x, $y, @rest)
EOF

OpenTracing::WrapScope::wrap_from_file($sample_signatures->filename);

with_sig(1, 2, 3, 4);

global_tracer_cmp_deeply([
    superhashof({
        operation_name => 'main::with_sig',
        tags           => superhashof(
            {
                'arguments.x'      => 1,
                'arguments.y'      => 2,
                'arguments.rest.0' => 3,
                'arguments.rest.1' => 4
            }
        )
    }),
    ], 'commented sub is not touched'
);

sub _make_tmp_file {
    my ($content) = @_;
    my $file = File::Temp->new(UNLINK => 1);
    $file->autoflush(1);
    print {$file} $content;
    return $file;
}
