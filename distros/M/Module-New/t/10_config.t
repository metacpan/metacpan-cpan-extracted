use strict;
use warnings;
use Test::More;
use Module::New::Config;
use Path::Tiny;

subtest first_time => sub {
  my $file = path('t/sample.yaml');
  ok !$file->exists, 'sample file does not exist';

  my $config = Module::New::Config->new(
    file      => $file,
    no_prompt => 1,
  );

  ok $config->file eq $file, 'config file is the sample';
  ok $file->exists, 'config file is created';

  $file->remove;
};

subtest from_file => sub {
  my $file = path('t/sample.yaml');
  $file->spew(<<'YAML');
author: me
email: me@localhost
YAML

  ok $file->exists, 'sample file exists';

  my $config = Module::New::Config->new(
    file      => $file,
    no_prompt => 1,
  );

  ok $config->file eq $file, 'config file is the sample';

  ok $config->get('author') eq 'me', 'author is correct';
  ok $config->get('email')  eq 'me@localhost', 'email is correct';

  $file->remove;
};

subtest from_argv => sub {
  my $file = path('t/sample.yaml');
  ok !$file->exists, 'sample file does not exist';

  my $config = Module::New::Config->new(
    file      => $file,
    no_prompt => 1,
  );

  ok $config->file eq $file, 'config file is the sample';

  local @ARGV = qw( --author=me --email=me@localhost );
  $config->get_options(qw( author=s email=s ));

  ok $config->get('author') eq 'me', 'author is correct';
  ok $config->get('email')  eq 'me@localhost', 'email is correct';

  $file->remove;
};

subtest from_mixed_source => sub {
  my $file = path('t/sample.yaml');
  $file->spew(<<'YAML');
author: me
email: me@localhost
YAML

  ok $file->exists, 'sample file exists';

  my $config = Module::New::Config->new(
    file      => $file,
    no_prompt => 1,
  );

  ok $config->file eq $file, 'config file is the sample';

  local @ARGV = qw( --email=foo@localhost );
  $config->get_options(qw( author=s email=s ));

  ok $config->get('author') eq 'me', 'author is correct';
  ok $config->get('email')  eq 'foo@localhost', 'email is correct';

  $file->remove;
};

subtest set_and_save => sub {
  my $file = path('t/sample.yaml');
  $file->spew(<<'YAML');
author: me
email: me@localhost
YAML

  ok $file->exists, 'sample file exists';

  my $config = Module::New::Config->new(
    file      => $file,
    no_prompt => 1,
  );

  ok $config->file eq $file, 'config file is the sample';

  ok $config->get('author') eq 'me', 'author is correct';
  ok $config->get('email')  eq 'me@localhost', 'email is correct';

  $config->set( email => 'foo@localhost' );
  ok $config->get('email') eq 'foo@localhost', 'new email is set';

  $config->load( force => 1 );
  ok $config->get('email')  eq 'me@localhost', 'new email is gone with reload';

  $config->save( email => 'foo@localhost' );
  ok $config->get('email') eq 'foo@localhost', 'new email is set and saved';

  $config->load( force => 1 );
  ok $config->get('email')  eq 'foo@localhost', 'new email is kept with reload';

  $file->remove;
};

subtest merge => sub {
  my $config = Module::New::Config->new( no_prompt => 1 );

  local @ARGV = qw(--first=first --second=second);

  $config->get_options('first=s');
  $config->get_options('second=s');

  ok $config->get('first') eq 'first', 'first option';
  ok $config->get('second') eq 'second', 'second option';
};

done_testing;
