use Test::More 'no_plan';
use Test::Deep;
use lib '../lib';
use NG;

my $f = new File;

isa_ok $f, 'File';

my $log = 't/log.txt';
my $got = File::read_file($log);
is $got, "line1 123&abc\nline2 321&abc";

File::read_file($log, sub {
    my ($line) = @_;
    cmp_deeply $line, Array->new( 'line1 123&abc', 'line2 321&abc' );
});

my $list = File::read_dir('/');
isa_ok $list, 'Array';

File::read_dir('.', sub {
    my ($dir, $file) = @_;
    ok $file, 'is file' if -f $dir.$file;
});
