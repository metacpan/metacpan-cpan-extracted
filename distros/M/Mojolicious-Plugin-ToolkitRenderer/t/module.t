use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use Mojolicious::Lite;

plugin ToolkitRenderer => {
    settings => {
        inline_template => 'inline',
        controller      => 'c',
    },
    config => {
        RELATIVE  => 1,
        EVAL_PERL => 0,
        FILTERS   => { upper => sub { return uc shift } },
    },
    context => sub { shift->define_vmethod( 'scalar', 'upper', sub { return uc shift } ) },
};

get '/simple' => sub {
    my ($self) = @_;

    $self->render_tt(
        inline => 'The answer to life, the [% universe | upper %], and [% everything.upper %] is [% answer %].',
        answer => 42, everything => 'everything', universe => 'universe',
    );
};

my $t = Test::Mojo->new;

$t
    ->get_ok('/simple')
    ->status_is(200)
    ->content_is('The answer to life, the UNIVERSE, and EVERYTHING is 42.')
;

done_testing;
