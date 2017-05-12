#!perl -T

use Scope::OnExit;
use Test::More tests => 4;

my $counter = 0;

on_scope_exit { is($counter++, 3, "Counter should be three") };

{

on_scope_exit { is($counter++, 1, "Counter should be one") };
on_scope_exit { is($counter++, 0, "Counter should be zero") };

}

is($counter++, 2, "Counter should be two");
