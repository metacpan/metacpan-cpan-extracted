#!perl -T
use 5.020;
use warnings;
use Test::More tests => 49;

BEGIN {
    if ($ENV{AUTHOR_TESTING}) {
        require Devel::Cover;
        import Devel::Cover -db => 'cover_db', -coverage => qw(branch condition statement subroutine), -silent => 1, '+ignore' => qr'^t/';
    }
}

my $warned;
$SIG{__WARN__} = sub {
    $warned = 1;
    goto &diag;
};
sub warnings_are(&$;$) {
    my($sub, $exp, $out) = @_;
    my @got;
    local $SIG{__WARN__} = sub {
        push @got, join '', @_;
    };
    $sub->();
    my $ok = @got == @$exp;
    $ok &&= $got[$_] =~ $$exp[$_] for 0..$#got;
    ok $ok, $out
        or do {
        diag "found warning: $_" for @got;
        diag "found no warnings" unless @got;
        diag "expected warning: $_" for @$exp;
        diag "expected no warnings" unless @$exp;
    };
}

use Plate;

sub temp_files {qw(t/data/faulty.pl t/data/inner.pl t/data/outer.pl t/data/test.pl t/data/utf8.pl t/data/tmp.pl t/data/tmp.plate)}

use utf8;
binmode Test::More->builder->failure_output, ':utf8';

unlink $_ for temp_files;
END { unlink $_ for temp_files }
utime 946684800, 946684800, 't/data/test.plate'; # Set mtime to 2000-01-01

my $output = <<'OUTPUT';
[
$var = "Tom, Dick &amp; Harry"
Some <inner args="this &amp; that">between</inner> line.
]
this & that
this &amp; that
this &amp;amp; that
OUTPUT
chomp $output;

is Plate::_path(''), '', 'Empty path remains empty';

my $plate = new Plate path => 't', cache_path => '';
like $$plate{cache_path}, qr/^\./, 'Empty cache_path set to relative path';

$plate->set(cache_path => 't/tmp_dir', umask => 027, cache_suffix => '.plate.pl');
ok -d 't/tmp_dir', 'Created cache_path directory';

ok $plate->does_exist('data/test'), "Plate 'data/test' does exist";
ok $plate->can_serve('data/test'), "Plate 'data/test' can be served";

$plate->set(suffix => '.nope');
ok !$plate->does_exist('data/test'), "Plate 'data/test' does not exist (wrong suffix)";
ok !$plate->can_serve('data/test'), "Plate 'data/test' can not be served (wrong suffix)";

ok -d 't/tmp_dir/data', 'Created cache file path';
ok -f 't/tmp_dir/data/test.plate.pl', 'Created cache file';
unlink 't/tmp_dir/data/test.plate.pl' or diag "Can't delete t/tmp_dir/data/test.plate.pl: $!";
rmdir or diag "Can't delete $_: $!" for qw(t/tmp_dir/data t/tmp_dir);

$plate = new Plate path => 't/data', cache_path => 't/data', cache_code => undef;

ok !$plate->does_exist('missing'), "Plate 'missing' doesn't exist";
ok !$plate->can_serve('missing'), "Plate 'missing' can't be served";

ok $plate->does_exist('faulty'), "Plate 'faulty' does exist";
ok !$plate->can_serve('faulty'), "Plate 'faulty' can't be served";
like $@, qr/\ABareword "This" not allowed .*
Plate compilation failed /s, 'Expected compilation error';

$plate->define(defined => 'defined');
ok $plate->does_exist('defined'), "Defined plate does exist";
ok $plate->can_serve('defined'), "Defined plate can be served";

$plate->undefine('defined');
ok !$plate->does_exist('defined'), "Undefined plate doesn't exist";
ok !$plate->can_serve('defined'), "Undefined plate can't be served";

my $test_warnings = [
    qr"^inner-2-warn at t.data.inner\.plate line 2\.$",
    qr"^test-6-warn at t.data.test\.plate line 6\.$",
];

warnings_are {
    is $plate->serve('test', qw(this & that)), $output, 'Expected ouput';
} $test_warnings, 'Expected warnings';

ok -f 't/data/inner.pl' && -f 't/data/outer.pl' && -f 't/data/test.pl', 'Cache files created';
utime 946684800, 946684800, 't/data/test.pl'; # Set mtime to 2000-01-01

$plate->undefine;

warnings_are {
    is $plate->serve('test', qw(this & that)), $output, 'Same output from disk cache';
} $test_warnings, 'Same warnings from disk cache';

is +(stat 't/data/test.pl')[9], 946684800, "Cache wasn't updated";
utime 946684800, 946684800, 't/data/test.pl'; # Set mtime to 2000-01-01
utime undef, undef, 't/data/test.plate'; # Touch t/data/test.plate

$plate->define(test => 'defined');
is $plate->serve('test'), 'defined', 'Redefined plate';
is ref $plate->undefine('test'), 'CODE', 'Undefine returns the CODE ref';

warnings_are {
    is $plate->serve('test', qw(this & that)), $output, 'Same output after undefine';
} $test_warnings, 'Same warnings after undefine';

isnt +(stat 't/data/test.pl')[9], 946684800, 'Cache was updated';

$plate->set(cache_code => 1);
is $plate->serve_with('outer', 'outer'), "[\n[\n\n]\n]", 'Serve with a layout';

$plate = new Plate path => undef, cache_path => 't/data';
is $$plate{static}, 'auto', 'Static mode is automatic whithout path';
ok $plate->does_exist('test'), "Disk cached plate 'data/test' does exist";

warnings_are {
    is $plate->serve('test', qw(this & that)), $output, 'Same output from disk cache only';
} $test_warnings, 'Same warnings from disk cache only';

$plate = new Plate path => 't/data', cache_code => undef;
is $$plate{static}, 'auto', 'Static mode is automatic whithout cache_path or cache_code';
is $$plate{io_layers}, ':encoding(UTF-8)', 'Default encoding is UTF-8';

$plate->set(encoding => 'utf8');
is $$plate{io_layers}, ':utf8', "Encoding 'utf8' sets the IO layer to ':utf8'";

$plate->set(encoding => 'UTF-8');
is $plate->serve('utf8'),
'ῌȇɭɭо Ẇöŗld‼',
'Render as UTF-8';

$plate->set(encoding => 'latin9');
is $plate->serve('utf8'),
"á¿\214È\207É­É­ÐŸ áº\206Ã¶Å\227ldâ\200Œ",
'Render as Latin-9';

$plate->set(io_layers => ':raw');
is $plate->serve('utf8'),
"á¿\214È\207É­É­Ð¾ áº\206Ã¶Å\227ldâ\200¼",
'Render as binary';

$plate->set(encoding => undef);
is $plate->serve('utf8'),
"á¿\214È\207É­É­Ð¾ áº\206Ã¶Å\227ldâ\200¼",
'Render without encoding';

if (open my $fh, '>', 't/data/tmp.plate') {
    print $fh 'abc';
    close $fh;
}
$plate = new Plate path => './t', cache_path => './t', static => 1;
is $plate->serve('data/tmp'), 'abc', 'Serve plate cached in memory';

unlink 't/data/tmp.plate';
is $plate->serve('data/tmp'), 'abc', 'Serve plate from memory cache without modification check';

$plate = new Plate path => 't/data';

my $mod = time - 100;
if (open my $fh, '>', 't/data/tmp.plate') {
    print $fh 'abc';
    close $fh;
    utime $mod, $mod, 't/data/tmp.plate';
}

ok $plate->does_exist('tmp'), "Create 'tmp' template";
$plate->can_serve('tmp'); # Cache in memory

if (open my $fh, '>', 't/data/tmp.plate') {
    print $fh 'xyz';
    close $fh;
    utime $mod, $mod, 't/data/tmp.plate';
}
is $plate->serve('tmp'),
'abc',
'Serve plate from memory cache with modification check';

$plate->set(cache_path => 't/data');

utime undef, undef, 't/data/tmp.plate';
is $plate->serve('tmp'),
'xyz',
'Serve reloaded plate';

unlink 't/data/tmp.plate';
ok !$plate->does_exist('tmp'), "Delete 'tmp' template";
ok !eval { $plate->serve('tmp') }, "Don't serve deleted plate";

ok !$warned, 'No unexpected warnings';
