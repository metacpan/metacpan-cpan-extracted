use lib 't', 'lib';
use strict;
use warnings;
use Test::More tests => 11;

use Spoon;
Spoon->debug;

my %classes = (
    test_class => 'TestHook',
);

{
    my $hub = Spoon->new->load_hub(\%classes);
    is($hub->test->number, 42);
    $hub->add_hook('test:number' => post => sub { 43 });
    is($hub->test->number, 43);
    my $h1 = $hub->add_hook('test:number' => post => sub { 44 });
    is($hub->test->number, 44);
    $h1->unhook;
    is($hub->test->number, 43);
}

{
    my $hub = Spoon->new->load_hub(\%classes);
    is($hub->test->number, 42);
    my $h1 = $hub->add_hook('test:number' => post => 'test:other');
    is($hub->test->number, 45);
    my $h2 = $hub->add_hook('test:number' => pre => 'Tweak::two');
    is($hub->test->number, 48);
    $h2->unhook;
    my $h3 = $hub->add_hook('test:number' => pre => 'Tweak::one');
    is($hub->test->number, 45);
    my $h4 = $hub->add_hook('test:number' => post => 'Tweak::one');
    is($hub->test->number, 47);
    $h4->unhook;
    $h3->unhook;
    is($hub->test->number, 45);
}

{
    my $main = Spoon->new;
    my $hub = $main->load_hub(\%classes);
    is($hub->test->number, 42);
}
