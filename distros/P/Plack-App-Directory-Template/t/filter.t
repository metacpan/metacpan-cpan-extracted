use Test::More;
use Plack::Test;
use HTTP::Request;
use Plack::Builder;

use Plack::App::Directory::Template;

my $app1 = Plack::App::Directory::Template->new(
    root      => 't/dir',
    templates => 't/templates',
    filter    => sub {
         $_[0]->{name} !~ qr{hidden$} ? $_[0] : undef;
    }
);

my $app2 = builder {
    mount '/foo' => $app1;
    mount '/' => sub { [404,[],[]] };
};

my %tests = ('' => $app1, '/foo' => $app2);

while (my ($base, $app) = each %tests) {
  test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(HTTP::Request->new(GET => "$base/subdir/"));
    is $res->code, 200, 'ok';
    is $res->content, "./\n../\n#foo.txt\n", 'subdir';

    $res = $cb->(HTTP::Request->new(GET => "$base/"));
    is $res->code, 200, 'ok';
    is $res->content, "./\n#foo\nsubdir/\n", 'base dir';
  };
}

done_testing;
