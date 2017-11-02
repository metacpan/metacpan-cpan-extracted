use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Test::Applify', 'applify_ok'); }

my $app = applify_ok(<<"HERE");
use Applify;
option str  => mode => 'basic or expert', default => 'basic';
option file => input => 'file to read', required => 1;
documentation 'Test::Applify';
version '1.0.999';
app {};
HERE

my $t = new_ok('Test::Applify');
can_ok $t, qw{app app_script app_instance can_ok documentation_ok help_ok};
can_ok $t, qw{is_option is_required_option version_ok};

$t->app($app);

isa_ok $t->app_script, 'Applify', 'type is Applify';

$t->can_ok(qw{mode input})
  ->documentation_ok
  ->help_ok
  ->version_ok('1.0.999');
$t->is_option($_) for qw{mode input};
$t->is_required_option($_) for qw{input};

## again.
$t = new_ok('Test::Applify', [$app]);
is $t->app, $app, 'set in new.';

## app instance
my $inst = $t->app_instance;
is $inst->mode, 'basic', 'default';
is $inst->input, undef, 'default';

## with arguments
$inst = $t->app_instance(qw{--mode expert --input test.txt});
is $inst->mode, 'expert', 'set';
is $inst->input, 'test.txt', 'also set';

{
  local %ENV = %ENV;
  $ENV{TMPDIR} = undef;
  $ENV{PERL_USE_UNSAFE_INC} = 0;
  my $app = applify_ok(<<"HERE");
use Applify;
option str  => mode => 'basic or expert', default => 'basic';
option file => input => 'file to read', required => 1;
documentation 'Test::Applify';
version '1.0.999';
app {};
HERE

}
done_testing;
