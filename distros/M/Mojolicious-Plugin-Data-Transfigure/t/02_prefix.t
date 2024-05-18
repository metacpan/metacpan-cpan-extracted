use v5.26;
use warnings;

use Test2::V0;

use Mojolicious::Lite;

plugin('Data::Transfigure' => {prefix => 'dt'});

ok(app->dt->output->add_transfigurators(), 'add output transfigurators with custom prefix');

ok(app->dt->input->add_transfigurators(), 'add output transfigurators with custom prefix');

is(app->dt->json, undef, 'check that json is callable with custom prefix');

done_testing;
