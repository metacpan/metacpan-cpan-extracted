use Test::More;
use Pandoc::Elements;
use Pandoc::Filter::ImagesFromCode qw(read_file write_file);
use File::Temp 'tempdir';
use File::Spec::Functions 'catfile';
use File::stat;

my $dir = tempdir( CLEANUP => 1 );

my $perlcode = 'binmode STDOUT, ":utf8";print "hello \x{1F4A9}";';
my $attr = {
    id => 'x',
    title => 'a title',
    class => 'perl',
    caption => 'a caption',
};
my $doc = Document {}, [ CodeBlock attributes $attr, $perlcode ];

my $filter = Pandoc::Filter::ImagesFromCode->new(
    dir  => $dir,
    from => 'pl',
    to   => 'txt',
    capture => 1,
    run => ['perl', '$infile$'],
);

$filter->apply($doc);

my $infile  = catfile($dir, 'x.pl');
ok -f $infile, 'created input file';
is read_file($infile, ':utf8'), $perlcode, 'written input file';

my $outfile = catfile($dir, 'x.txt');
ok -f $outfile, 'created output file';
is read_file($outfile, ':utf8'), "hello \x{1F4A9}", 'written output file';
my $outdate = stat($outfile)->mtime;

is_deeply $doc->content, [
    Plain [
        Image attributes { id => x, class => 'perl' },
            [ Str 'a caption' ], [$outfile, 'a title']
    ]
], 'transformed document';

if ($ENV{RELEASE_TESTING}) { # skip because of sleep
    sleep 1;
    $doc = Document {}, [ CodeBlock attributes $attr, $perlcode ];
    $filter->apply($doc);
    is stat($outfile)->mtime, $outdate, 'output file not modified';
}

done_testing;
