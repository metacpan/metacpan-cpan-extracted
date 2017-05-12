#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'once';

use FindBin;

use Test::More tests => 6;

use lib "$FindBin::Bin/lib";
use TestEnv;
my $te = TestEnv->new;

$te->setup_i18n_tempdir();
use_ok 'Mojolicious::Command::generate::lexicon';

my $l = new_ok 'Mojolicious::Command::generate::lexicon';

$l->app(sub { Mojo::Server->new->build_app('Lexemes') });

$l->run(undef, $te->i18n_tempdir . "/templates/test-quote.html.ep");

require_ok $te->i18n_tempdir . "/lib/Lexemes/I18N/Skeleton.pm";

is_deeply \%Lexemes::I18N::Skeleton::Lexicon, {'Can\'t fix' => ''},
  'correct lexemes';

# Save option test
$te->setup_i18n_tempdir(qw(es quote));

$l->run('es', $te->i18n_tempdir . "/templates/test-quote.html.ep", '-b=save');

require_ok $te->i18n_tempdir . "/lib/Lexemes/I18N/es.pm";

is_deeply \%Lexemes::I18N::es::Lexicon,
  { 'lexemes'    => 'lexemas',
    "hard\ntest" => "prueba\ndifícil",
    'Can\'t fix' => 'No puede arreglarse'
  },
  'correct lexemes';
