#!/usr/bin/env perl

# Re RT#58715 and the claim in the documentation:
#   If you have Getopt::Long::Descriptive the usage param is also passed to new.

# This tests the fix (that fulfills the documentation claim).

use strict; use warnings;
use Test::More tests => 3;

{
    package MyClass;
    use strict; use warnings;
    use Mouse;
    with 'MouseX::Getopt';
}

Mouse::Meta::Class->create('MyClassWithBasic',
    superclasses => ['MyClass'],
    roles => [ 'MouseX::Getopt::Basic' ],
);

my $basic_obj = MyClassWithBasic->new_with_options();
ok(!$basic_obj->meta->has_attribute('usage'), 'basic class has no usage attribute');

Mouse::Meta::Class->create('MyClassWithGLD',
    superclasses => ['MyClass'],
    roles => [ 'MouseX::Getopt' ],
);

my $gld_obj = MyClassWithGLD->new_with_options();

ok($gld_obj->meta->has_attribute('usage'), 'class has usage attribute');
isa_ok($gld_obj->usage, 'Getopt::Long::Descriptive::Usage');

