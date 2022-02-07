use Mojo::Base -strict;

use Test::More;

use Mojo::File qw(curfile);
use lib curfile->sibling('lib')->to_string;


subtest 'update' => sub {
  require Telebot::Task::Update;
  my $update = Telebot::Task::Update->new;
  isa_ok $update, 'Minion::Job', 'right class';
};

subtest 'update_field' => sub {
  require Telebot::Task::UpdateField;
  my $update_field = Telebot::Task::UpdateField->new;
  isa_ok $update_field, 'Minion::Job', 'right class';
};

done_testing();
