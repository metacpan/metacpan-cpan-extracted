use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Message::PSGI;
use Plack::Builder;
use Plack::Test;

my @tests = (
    ['Content-Type' => 'text/csv']  => ['Content-Type' => 'text/plain'],
    [ ]                             => ['Content-Type' => 'text/plain'],
    ['Content-Type' => 'x-text/my'] => ['Content-Type' => 'text/plain'],
    ['Content-Type' => 'image/png'] => ['Content-Type' => 'image/png']
);

my @when = (
    [
        'Content-Type' => qr{^text/}, 
        'Content-Type' => 'x-text/my',
        'Content-Type' => undef, 
    ],
    sub { 
        my $value = Plack::Util::header_get(\@_, 'Content-Type');
        return !defined $value || $value =~ qr{^text/} || $value eq 'x-text/my';
    }
);

while (my ($has, $want) = splice @tests, 0, 2) {
    foreach my $when (@when) {
        my $app = builder {
            enable 'Headers',
                set  => ['Content-Type' => 'text/plain'],
                when => $when;
            sub { ['200', [ @$has ], []] };
        };

        my $env = HTTP::Request->new(GET => '/')->to_psgi;
        my $res = $app->($env);
        is_deeply $res->[1], $want;

        # Run each test twice to make sure we aren't depending on initial
        # prepare_app() state.
        $res = $app->($env);
        is_deeply $res->[1], $want;
    }
}

done_testing;
