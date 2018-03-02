#!/usr/bin/perl
use strict;
use warnings;

use Test::More 1.0 'no_plan';

my $class = 'Module::Release';

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Are the subroutines defined?
{
my @subs = qw(
	load_mixin
	loaded_mixins
	mixin_loaded
	);

can_ok( $class, @subs );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Does it work with an existing module?
{
my $module = 'File::Basename'; # everyone should have this

ok( ! $class->mixin_loaded( $module ), "$module mixin has not loaded" );
ok( $class->load_mixin( $module ), "$module mixin loaded" );
ok( $class->mixin_loaded( $module ), "$module mixin has loaded" );

# try it with same module
ok( $class->load_mixin( $module ), "$module mixin already loaded" );

my @mixins = $class->loaded_mixins;
is( scalar @mixins, 1, "There is only one mixin" );
is( $mixins[0], $module, "The one mixin is $module" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Does it fail with an non-existing module?
{
my $module = '123:456'; # no one should have this

ok( ! $class->mixin_loaded( $module ), "$module mixin has not loaded" );
ok( ! eval { $class->load_mixin( $module ) }, "$module mixin not loaded (good)" );
ok( ! $class->mixin_loaded( $module ), "$module mixin was not loaded" );
}
