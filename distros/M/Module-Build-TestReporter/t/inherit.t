#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib', 'lib';
}

use strict;
use File::Path;

use Test::More tests => 3;

my $module;

# must happen here for the import() magic to work later
BEGIN 
{ 
	$module = 'Module::Build::TestReporter';
	use_ok( $module ) or exit;
}

package My::Build;

use base 'Module::Build::TestReporter';

sub new
{
	my $class = shift;
	$class->SUPER::new( @_, my_build => 1 );
}

package main;

{
	my $new_called = 0;

	local *Module::Build::new;
	*Module::Build::new = sub
	{
		$new_called++;

		my ($self, %args) = @_;
		$args{properties}{config_dir} = '.';
		bless \%args, $self;
	};

	my $mb = My::Build->new( some_arg => 'some_val' );
	is( $new_called, 1,
		'new() call inheriting from MBTR should end up in Module::Build' );
	is( $mb->{my_build}, 1, '... passing arguments from subclass' );
}

END
{
	rmtree( '_build' );
}
