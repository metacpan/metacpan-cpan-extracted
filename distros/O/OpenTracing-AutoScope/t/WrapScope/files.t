use File::Temp;
use Test::Most tests => 4;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope;

sub foo        { }
sub Bar::foo   { }
sub secret     { }
sub non_secret { }

my $sample_unqualified = _make_tmp_file(<<'EOF');
foo
EOF

throws_ok {
    OpenTracing::WrapScope::wrap_from_file($sample_unqualified->filename);
} qr/Unqualified subroutine/, 'unqualified sub name';


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

sub _make_tmp_file {
    my ($content) = @_;
    my $file = File::Temp->new(UNLINK => 1);
    $file->autoflush(1);
    print {$file} $content;
    return $file;
}
