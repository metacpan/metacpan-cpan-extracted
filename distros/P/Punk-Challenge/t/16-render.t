#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;

# `render`: a coderef or a context method replaces the shipped page and
# receives the same values in a hashref.

my @seen;
{
    package RenderCode;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => {
        secret => 'k', bits => 8,
        render => sub {
            my ($c, $v) = @_;
            push @seen, $v;
            return $c->html("<p>mine $v->{bits} $v->{to}</p>", 503);
        },
    };
    challenge for => '/x', always => 1;
    get '/x' => sub { $_[0]->text('x') };
}

{
    package RenderMethod;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8, render => 'my_page' };
    helper my_page => sub {
        my ($c, $v) = @_;
        return $c->html("<p>method $v->{puzzle}</p>", 503);
    };
    challenge for => '/x', always => 1;
    get '/x' => sub { $_[0]->text('x') };
}

my $A = { REMOTE_ADDR => '192.0.2.7' };
my $HTML = { Accept => 'text/html' };

my $t = Punk::Test->new('RenderCode');
$t->get_ok('/x?q=1', env => $A, headers => $HTML)
  ->status_is(503)
  ->content_is('<p>mine 8 /x?q=1</p>', 'the coderef renders the page')
  ->header_is('Cache-Control', 'no-store', '  and the headers are still set');
is(scalar @seen, 1, 'called once');
is_deeply([ sort keys %{ $seen[0] } ], [ qw(bits puzzle script to verify) ], '  with the values a page needs');
like($seen[0]{puzzle}, qr/^v1\.\d+\.8\./, '  the puzzle');
is($seen[0]{verify}, '/challenge/verify', '  the verify route');
is($seen[0]{to}, '/x?q=1', '  the return path, unescaped: the renderer escapes for its own context');

$t->get_ok('/x', env => $A)->status_is(403, 'JSON is not affected by render')
  ->json_is('/error', 'challenge');

my $m = Punk::Test->new('RenderMethod');
$m->get_ok('/x', env => $A, headers => $HTML)
  ->status_is(503)
  ->content_like(qr{^<p>method v1\.\d+\.8\.}, 'a context method renders the page');

done_testing;
