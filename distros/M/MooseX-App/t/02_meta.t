# -*- perl -*-

# t/02_meta.t - MOP tests

use Test::Most tests => 28+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test01;

my $meta = Test01->meta;

my $commands = $meta->app_commands;
is(join(',',sort keys %{$commands}),'command_a,command_b,command_c1,command_d','Commands found');
is(join(',',sort values %{$commands}),'Test01::CommandA,Test01::CommandB,Test01::CommandC1,Test01::CommandD','Commands found');

cmp_deeply($meta->app_namespace,[qw(Test01)],'Command namespace ok');
is($meta->app_base,'02_meta.t','Command base ok');
is($meta->app_messageclass,'MooseX::App::Message::Block','Message class');

ok(Test01->can('new_with_command'),'Role applied to base class');
ok(Test01->can('initialize_command_class'),'Role applied to base class');

is(scalar keys %{$commands},4,'Found three commands');
is($commands->{command_a},'Test01::CommandA','Command A found');
is($meta->command_find('COMMAND_a'),'command_a','Command A matched');
cmp_deeply($meta->command_candidates('COmmand'),['command_a','command_b','command_c1','command_d'],'Command A,B,C1 and D matched');
cmp_deeply($meta->command_candidates('command_C'),['command_c1'],'Command C1 matched fuzzy');
is($meta->command_candidates('command_c1'),'command_c1','Command C1 matched exactly');

my @attributes = $meta->command_usage_attributes;
is(scalar(@attributes),3,'Has three attributes');
is($attributes[0]->cmd_usage_name,'--global','Usage name ok');
is($attributes[0]->cmd_usage_description,'test [Required; Integer; Important!]','Usage description ok');
is($attributes[1]->cmd_usage_name,'--config','Usage name ok');
is($attributes[2]->cmd_usage_name,'--help -h --usage -?','Usage name ok');
is($attributes[2]->cmd_usage_description,'Prints this usage information. [Flag]','Usage description ok');

my $meta_attribute = $meta->find_attribute_by_name('global');
is(join(',',$meta_attribute->cmd_tags_list($meta_attribute)),'Required,Integer,Important!','Tags ok');
$meta_attribute->cmd_tags(['Use with care']);
is(join(',',$meta_attribute->cmd_tags_list()),'Required,Integer,Use with care','Changed tags ok');

require Test01::CommandA;
my $description = $meta->command_usage_description(Test01::CommandA->meta);

isa_ok($description,'MooseX::App::Message::Block');
like($description->body,qr/varius nec iaculis vitae/,'Description body ok');

require Test01::CommandB;
is(Test01::CommandB->meta->command_short_description,'Test class command B for test 01','Pod short description parsed ok');
is(Test01::CommandB->meta->command_long_description,'Some description of *command B*

 some code
 some code

SUB HEADLINE

some more desc

* item 1
* item 2
  * item 2.1
  * item 2.2

hase ist so super and this is a very long sentence witch breaks after i have written some bla bla.

another interesting paragraph.','Pod long description parsed ok');

require Test01::CommandC1;
is(Test01::CommandB->meta->command_usage,'use with care','Command usage parsed ok');
is(Test01::CommandC1->meta->find_attribute_by_name('param_internal_name')->cmd_name_primary,'external_name','Attribute name ok');

is(join(',',Test01::CommandB->meta->find_attribute_by_name('param_b')->cmd_tags_list),'Required,Possible values: aaa, bbb, ccc, ddd, eee, fff','Check attributes tags');