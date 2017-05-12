use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'MoreUtilHelpers', 
    maxwords => { max => 1, omit => '!' },
    sanitize => { tags  => ['a'], attr => ['href'] };

get '/maxwords' => sub {
    my $self = shift;
    $self->render(text => $self->maxwords('a, b, c'));
};

get '/maxwords_overrides' => sub {
    my $self = shift;
    $self->render(text => $self->maxwords('a, b, c', 2, 'xxx'));
};

my $html = q{<p class="x">say <a href="#">hi</a></p>};
get '/sanitize' => sub {
    my $self = shift;
    $self->render(text => $self->sanitize($html));
};

get '/sanitize_overrides' => sub {
    my $self = shift;
    $self->render(text => $self->sanitize($html, tags => ['p'], attr => ['class']));
};

my $t = Test::Mojo->new;
$t->get_ok('/maxwords')->content_is('a!');
$t->get_ok('/maxwords_overrides')->content_is('a, bxxx');

$t->get_ok('/sanitize')->content_is(q{say <a href="#">hi</a>});
$t->get_ok('/sanitize_overrides')->content_is(q{<p class="x">say hi</p>});

done_testing();
