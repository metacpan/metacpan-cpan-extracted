use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Nephia::Core;
use utf8;
use Encode;
use File::Spec;

subtest normal => sub {
    my $v = Nephia::Core->new(
        plugins => [
            'View::Xslate' => {
                syntax => 'Kolon',
                path   => [File::Spec->catdir(qw/t tmpl/)],
            }, 
        ],
        app => sub { 
            my $content = render('foo.html', {name => 'とんきち'});
            [200, [], $content];
        },
    );
    
    test_psgi $v->run, sub {
        my $cb     = shift;
        my $res    = $cb->(GET '/');
        my $expect = Encode::encode_utf8('Hello, とんきち!'."\n");
        is $res->content, $expect, 'output with template';
    };
};

done_testing;
