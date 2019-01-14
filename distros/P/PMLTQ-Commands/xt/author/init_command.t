#!/usr/bin/env perl
# Run this like so: `perl init_command.t'
#   Michal Sedlak <sedlakmichal@gmail.com>     2014/05/07 15:13:00

use Test::Most;
use File::Spec;
use File::Basename 'dirname';
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), 'lib' ) );

BEGIN {
  require 'bootstrap.pl'; ## no critic
}

use List::Util 'first';
use File::Temp;
use YAML::Tiny;

use PMLTQ::Command::init;
use Test::MockObject::Extends;

my %test_treebanks = (
  pdt_test => [qw/adata_30_schema.xml tdata_30_schema.xml/],
  treex_test => [qw/treex_schema.xml/]
);

sub mock_cmd {
  my $prompt_answers = shift;
  my $cmd = Test::MockObject::Extends->new(PMLTQ::Command::init->new(config => {}));

  my $mocked = sub {
    my ($self, $prompt, $args) = @_;

    my $answer = $prompt_answers->{$prompt} || $args->{default};
    my $check = $args->{check} || sub { defined $_[0] and length $_[0] };

    die "Unexpected prompt: $prompt" unless $answer;
    die "Prompt check failed $prompt => $answer" unless $check->($answer);
    return $answer;
  };

  $cmd->mock(prompt_str => $mocked);
  $cmd->mock(prompt_yn => $mocked);

  return $cmd;
}

sub test_treebank {
  my ($tb, $schemas) = @_;

  my $tmp = File::Temp->new();
  my $cmd = mock_cmd({
    'Full treebank title' => 'my ' . $tb->{name},
    'Treebank ID (can only contain lowercase letters, numbers and underscores)' => 'mtb',
    'Save?' => 1,
    'Save as' => $tmp->filename
  });

  $cmd->run(map { File::Spec->catfile($tb->{dir}, 'resources', $_) } @$schemas);

  my ($got, $expected);
  lives_ok {
    $got = YAML::Tiny->read($tmp->filename)->[0];
    $expected = YAML::Tiny->read(File::Spec->catfile($tb->{dir}, 'pmltq.yml'))->[0];
  } 'loaded configuration';

  is($got->{resources}, File::Spec->catdir($tb->{dir}, 'resources'), 'resources dir is set correctly');

  for my $layer (@{$got->{layers}}) {
    my $expected_layer = first { $_->{name} eq $layer->{name} } @{$expected->{layers}};

    cmp_deeply($layer->{references}, $expected_layer->{references}, 'matching references');
    cmp_deeply($layer->{'related-schema'}, $expected_layer->{'related-schema'}, 'matching related schemas');
  }
}

for my $tb (treebanks()) {
  my $name = $tb->{name};
  fail "Treebank $name is not in the list" unless $test_treebanks{$name};
  subtest "Init config for $name" => sub {
    test_treebank($tb, $test_treebanks{$name});
  };
}

done_testing();
