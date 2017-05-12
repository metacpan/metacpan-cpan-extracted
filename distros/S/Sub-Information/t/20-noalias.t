#!/usr/bin/perl -w

use strict;
use Test::More tests => 20;

use lib 'lib';
my $CLASS;

BEGIN {
    $CLASS = 'Sub::Information';
    use_ok $CLASS
      or die;
}

ok defined &inspect, 'inspect() should be exported to our namespace';
ok my $info = inspect( \&inspect ),
  '... and calling it with a valid sub reference should succeed';
isa_ok $info, $CLASS, '... and the object it returns';

can_ok $info, 'name';

ok !exists $INC{'Sub/Identify.pm'},
    '... and its helper module should not be loaded before it is needed';
is $info->name, "inspect",
  '... and it should return the original name of the subroutine';

ok exists $INC{'Sub/Identify.pm'},
    '... and its helper module should be loaded after it is needed';

can_ok $info, 'package';
is $info->package, $CLASS,
  '... and it should tell us the package the sub is from';

can_ok $info, 'fullname';
is $info->fullname, "$CLASS\::inspect",
  '... and it should give us the fully qualified sub name';

can_ok $info, 'code';
like $info->code, qr/sub {.*_croak.*}/s,
  '... and it should return the source code';

can_ok $info, 'address';
like $info->address, qr/^\d+$/, '... and it should return the address';

sub foo { my $x = 3; my @y = ( 4, 5 ) }
can_ok $info, 'variables';
is_deeply inspect( \&foo )->variables, { '$x' => \undef, '@y' => [] },
  '... and the variable values should be undef if the sub is not in use';

my $bar = inspect( \&bar );
bar();

sub bar {
    my $x = 3;
    my @y = ( 4, 5 );

    # we need to do this since all 'my' variables present in a subroutine are
    # returned by 'variables'.
    $::variables = $bar->variables;
    delete $::variables->{'$bar'};
    is_deeply $::variables, { '$x' => \3, '@y' => [ 4, 5 ] },
      '... and the variable values should be defined if the sub is in use';
}
my $vars = $bar->variables;
delete $vars->{'$bar'};
is_deeply $vars, { '$x' => \undef, '@y' => [] },
  '... but variable values should not be cached';
