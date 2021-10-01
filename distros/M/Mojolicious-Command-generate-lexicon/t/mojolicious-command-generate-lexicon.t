#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'once';

use FindBin;

use Test::More tests => 3;

use lib "$FindBin::Bin/lib";
use TestEnv;
my $te = TestEnv->new;

use_ok 'Mojolicious::Command::generate::lexicon';

subtest "Generate Skeleton", sub {
  $te->setup_i18n_tempdir();
  my $l = new_ok 'Mojolicious::Command::generate::lexicon';

  my $app = Mojo::Server->new->build_app('Lexemes');
  $l->app($app);

  $l->run(undef, $te->i18n_tempdir . "/templates/test.html.ep");

  require_ok $te->i18n_tempdir . "/lib/Lexemes/I18N/Skeleton.pm";

  is_deeply \%Lexemes::I18N::Skeleton::Lexicon, {
      'lexemes'             => '',
      "hard\ntest"          => '',
      link_to               => '',
      'variables test [_1]' => ''
    },
    'correct lexemes';
}; 

subtest "Overwrite existing language lexemes" => sub {
  $te->setup_i18n_tempdir(qw(es orig));
  my $l = new_ok 'Mojolicious::Command::generate::lexicon';

  my $app = Mojo::Server->new->build_app('Lexemes');
  $l->app($app);

  $l->run('es', $te->i18n_tempdir . "/templates/test.html.ep", '-b=reset');

  my $content = do {
    my $file = $te->i18n_tempdir . "/lib/Lexemes/I18N/es.pm";
    open my $fh, '<', $file or die $!;
    local $/ = undef;
    <$fh>;
  };

    my $file = $te->i18n_tempdir . "/lib/Lexemes/I18N/es.pm";

  require_ok $te->i18n_tempdir . "/lib/Lexemes/I18N/es.pm";

  is_deeply \%Lexemes::I18N::es::Lexicon, {
      'lexemes'             => '',
      "hard\ntest"          => '',
      link_to               => '',
      'variables test [_1]' => ''
    },
    'correct lexemes';
};
