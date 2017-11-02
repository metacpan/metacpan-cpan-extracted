use strict;
use warnings;
use Test::More;
use Test::Applify 'applify_ok', 'applify_subcommands_ok';

my $check = eval "use Applify; app {};" or die "$@";

plan skip_all => 'Requires a version of Applify with subcommand'
  unless $check->_script->can('subcommand');

my $code = <<'HERE';
use Applify;
option str  => mode => 'basic or expert', default => 'basic';
option file => input => 'file to read', required => 1;
subcommand list => 'list everything' => sub {
  option flag => long => 'long listing';
};
subcommand create => 'new object' => sub {
  option str => name => 'object name', required => 1;
};
documentation 'Test::Applify';
version '1.0.999';
sub command_create {
  my $self = shift;
  warn $self->_script->subcommand, "\n";
  0;
}
app {
  my $self = shift;
  warn $self->_script->subcommand || 'none', "\n";
  warn $self->input, "\n";
  warn "@_\n";
  0;
};
HERE

## Further tests for @ARGV passing for applify_ok
my $list_app   = applify_ok $code, ['list'], 'list app';
my $create_app = applify_ok $code, ['create'], 'create app';
my $null_app   = applify_ok $code, [], 'null app';

my $app_list   = applify_subcommands_ok $code;

foreach my $app(@$app_list){
  Test::Applify->new($app)->help_ok
    ->documentation_ok(qr/Test\:\:Applify/)
    ->version_ok('1.0.999')
    ->is_required_option('input')
    ->is_option('mode')
}

my $t = new_ok('Test::Applify', [$list_app]);
isa_ok $t->app_script, 'Applify', 'type is Applify';

$t->can_ok(qw{mode input long});
$t->documentation_ok;
my $help = $t->help_ok;
$t->is_option($_) for qw{mode input long};
$t->is_required_option($_) for qw{input};
$t->version_ok('1.0.999');
$t->subcommand_ok('list');

## app instance
my $inst = $t->app_instance(qw{--long});
is $inst->mode, 'basic', 'default';
is $inst->input, undef, 'default';

## with arguments
$inst = $t->app_instance(qw{--mode expert --input test.txt});
is $inst->mode, 'expert', 'set';
is $inst->input, 'test.txt', 'also set';

#
# create app
#
$t = new_ok('Test::Applify', [$create_app]);
isa_ok $t->app_script, 'Applify', 'type is Applify';

$t->can_ok(qw{mode input name});
$t->documentation_ok;
$help = $t->help_ok;
$t->is_option($_) for qw{mode input name};
$t->is_required_option($_) for qw{input};
$t->version_ok('1.0.999');
$t->subcommand_ok('create');

#
# null app
#
$t = new_ok('Test::Applify', [$null_app]);
isa_ok $t->app_script, 'Applify', 'type is Applify';

$t->can_ok(qw{mode input});
$t->documentation_ok;
$help = $t->help_ok;
$t->is_option($_) for qw{mode input};
$t->is_required_option($_) for qw{input};
$t->version_ok('1.0.999');
$t->subcommand_ok(undef);

my ($app) = $t->app_instance(qw{--input test.t});

#$app->run(qw{run args});

done_testing;
