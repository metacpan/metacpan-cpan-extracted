use strict;
use Test::More 0.98;
use FindBin;
use Plift;


my $engine = Plift->new(
    paths => ["$FindBin::Bin/templates"]
);

my $ctx = $engine->template('meta');
$ctx->render;

# use Data::Printer;
# p $ctx->data;

is_deeply $ctx->metadata, {
    title => 'the title',
    subtitle => 'new subtitle',
    foo => 'foo',
    bar => 'bar',
    baz => 'BAZ'
};

is $ctx->document->find('x-meta')->size, 0;
is $ctx->document->find('title')->text, $ctx->metadata->{title};

done_testing;
