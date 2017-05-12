#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'once';

use FindBin;

use Test::More tests => 6;

use lib "$FindBin::Bin/lib";
use TestEnv;
my $te = TestEnv->new;

use_ok 'Mojolicious::Command::generate::lexicon';

$te->setup_i18n_tempdir();
my $l = new_ok 'Mojolicious::Command::generate::lexicon';

$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

$l->run(undef, $te->i18n_tempdir . "/templates/test.html.ep");

require_ok $te->i18n_tempdir . "/lib/Lexemes/I18N/Skeleton.pm";

is_deeply \%Lexemes::I18N::Skeleton::Lexicon, {
    'lexemes'             => '',
    "hard\ntest"          => '',
    link_to               => '',
    'variables test [_1]' => ''
  },
  'correct lexemes';

$te->setup_i18n_tempdir(qw(es orig));
$l->run('es', $te->i18n_tempdir . "/templates/test.html.ep", '-b=reset');

require_ok $te->i18n_tempdir . "/lib/Lexemes/I18N/es.pm";

is_deeply \%Lexemes::I18N::es::Lexicon, {
    'lexemes'             => '',
    "hard\ntest"          => '',
    link_to               => '',
    'variables test [_1]' => ''
  },
  'correct lexemes';
