#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Test::More tests => 4;

use lib "$FindBin::Bin/lib";
use TestEnv;
my $te = TestEnv->new;

use_ok 'Mojolicious::Command::generate::lexicon';

$te->setup_i18n_tempdir(qw(es orig));
my $l = new_ok 'Mojolicious::Command::generate::lexicon';

$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

$l->run('es', $te->i18n_tempdir . "/templates/test.html.ep", '-b=save', '--verbose');

require_ok( $te->i18n_tempdir . "/lib/Lexemes/I18N/es.pm" );

is_deeply eval {
    my $l = \%{Lexemes::I18N::es::Lexicon};
    \%{Lexemes::I18N::es::Lexicon};    # Mencioned again for avoid warn
}, {
    'lexemes'             => 'lexemas',
    "hard\ntest"          => "prueba\ndifícil",
    link_to               => '',
    'variables test [_1]' => ''
  },
  'correct lexemes';
