#!perl
use warnings FATAL => 'all';
use strict;

use Scope::OnExit::Wrap;
use Test::More tests => 4;
 
my $counter = 0;
 
my $guard_0 = on_scope_exit { is($counter++, 3, "Counter should be three") };
 
{
 
my $guard_1 = on_scope_exit { is($counter++, 1, "Counter should be one") };
my $guard_2 = on_scope_exit { is($counter++, 0, "Counter should be zero") };
 
(); # ???
}
 
is($counter++, 2, "Counter should be two");
