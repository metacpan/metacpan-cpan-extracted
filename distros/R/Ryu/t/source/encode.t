use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

subtest base64 => sub {
    eval { require MIME::Base64 } or plan skip_all => 'needs MIME::Base64';
    my $src = Ryu::Source->new;
    my @actual;
    $src->encode('base64')->each(sub { push @actual, $_ });
    $src->emit('test');
    cmp_deeply(\@actual, [ 'dGVzdA==' ], 'base64 operation was performed');
    done_testing;
};
subtest json => sub {
    eval { require JSON::MaybeXS } or plan skip_all => 'needs JSON::MaybeXS';
    my $src = Ryu::Source->new;
    my @actual;
    $src->encode('json')->each(sub { push @actual, $_ });
    $src->emit({ x => 123 });
    cmp_deeply(\@actual, [ '{"x":123}' ], 'json operation was performed');
    done_testing;
};
done_testing;

