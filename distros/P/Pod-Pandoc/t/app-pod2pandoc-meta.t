use strict;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);
use App::pod2pandoc;
use Pandoc::Elements;

plan skip_all => 'these tests are for release candidate testing'
  unless $ENV{RELEASE_TESTING};

sub pod2meta {
    my ( $fh, $file ) = tempfile;
    pod2pandoc ['script/pod2pandoc'], {@_}, '-t' => 'json', '-o', $file;
    my $json = do { local ( @ARGV, $/ ) = $file; <> };
    pandoc_json($json)->metavalue;
}

my $expect = {
    file     => 'script/pod2pandoc',
    subtitle => 'convert Pod to Pandoc document model',
    title    => 'pod2pandoc'
};

is_deeply pod2meta(), $expect, 'no meta';

throws_ok { pod2meta( meta => 't/examples/missing.json' ) }
qr{^failed to open t/examples/missing\.json}, 'invalid meta';

$expect->{bool} = 0;
$expect->{map} = { list => [ 1, 2 ] };
is_deeply pod2meta( meta => 't/examples/metadata.json' ), $expect,
  'meta from json';

$expect->{bool} = 1;
$expect->{map}{list} = ['a string'];
is_deeply pod2meta( meta => 't/examples/metadata.yaml' ), $expect,
  'meta from YAML';

done_testing;
