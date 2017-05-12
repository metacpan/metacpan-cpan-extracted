use strict;
use warnings;

use Test::More;
use Nephia::Core;
use t::Util 'mock_env';

my $env = mock_env;

my $app = sub {
    my ($self, $context) = @_;
    redirect('/hoge');
};

subtest redirect => sub {
    my $v = Nephia::Core->new(app => $app);
    my $res = $v->run->($env);
    is_deeply( $res, [303, [Location => '/hoge'], []] );
};

done_testing;
