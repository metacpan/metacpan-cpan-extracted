use File::Temp;
use Test::Most tests => 3;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope;

sub foo      { }
sub Bar::foo { }

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


sub _make_tmp_file {
    my ($content) = @_;
    my $file = File::Temp->new(UNLINK => 1);
    $file->autoflush(1);
    print {$file} $content;
    return $file;
}
