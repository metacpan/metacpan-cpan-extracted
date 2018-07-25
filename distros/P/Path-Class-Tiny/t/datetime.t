use Test::Most 0.25;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use Test::PathClassTiny::Utils;

use Path::Class::Tiny;

use Path::Tiny ();


my $dir = path(Path::Tiny->tempdir)->child('dates');
$dir->mkpath or die("can't make dir: $dir");

my $a = $dir->child('a');
$a->touch;

loads_ok { $a->mtime } mtime => 'Date::Easy::Datetime';

my $dt = Date::Easy::Datetime->new(2001, 2, 3, 4, 5, 6);
warning_is { $a->touch($dt) } undef, "can send `touch` a datetime object";
isa_ok $a->mtime, 'Date::Easy::Datetime' => 'return from mtime';
is $a->mtime, $dt, "`mtime` returns same datetime sent to `touch`";


done_testing;
