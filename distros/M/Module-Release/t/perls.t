#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
	use File::Spec;
	my $file = File::Spec->catfile( qw(t lib setup_common.pl) );
	require $file;
	}

use Data::Dumper;

my $class = 'Module::Release';

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Are the subroutines defined?
{
my @subs = qw(
	set_perl
	perls
	add_a_perl
	remove_a_perl
	reset_perls
	get_perl
	_looks_like_perl
	);
	
can_ok( $class, @subs );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test _looks_like_perl
{
my $mock = bless { perl => $^X }, $class;
ok(   $mock->_looks_like_perl( $^X ), "\$^X looks like perl" );
ok( ! $mock->_looks_like_perl( 'blib' ), "blib doesn't look like perl" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test the main perl
{
my $mock = bless { perl => $^X }, $class;
is( $mock->get_perl, $^X, "main perl is the one in \$^X" );
}

{
my $foo = 'foo';

my $mock = bless { perl => $foo }, $class;
is( $mock->get_perl, $foo, "main perl is '$foo' to start" );

# set it to a real perl
{
my $old_perl = $mock->set_perl( $^X );
is( $old_perl, $foo, "old perl is '$foo'" );
is( $mock->get_perl, $^X, "main perl is the one in \$^X" );
}

# try setting it to a non-perl
{
my $r = eval { $mock->set_perl( $foo ); 1 };
ok( ! defined $r, "Trying to set to non-perl croaks" );
is( $mock->get_perl, $^X, "main perl is still \$^X" );
}

}

(my $pX = $^X) =~ s,.*/,,;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test the perls
{
my $mock = bless { perls => { $^X => $] } }, $class;

{
my @perls = $mock->perls;
is( scalar @perls, 1, "There is only one perl" );
}

{
$mock->remove_a_perl( $^X );
my @perls = $mock->perls;
is( scalar @perls, 0, "There are no perls" );
}

{
$mock->add_a_perl( $^X );
my @perls = $mock->perls;
is( scalar @perls, 1, "There are no perls" );
(my $p0 = $perls[0]) =~ s,.*/,,;
is( $p0, $pX, "The reset perl is the one in \$^X" );

# Adding the same thing shouldn't do anything
$mock->add_a_perl( $^X );
@perls = $mock->perls;
is( scalar @perls, 1, "There are no perls" );
($p0 = $perls[0]) =~ s,.*/,,;
is( $p0, $pX, "The reset perl is the one in \$^X" );

# Adding something not executable shouldn't do anything
$mock->turn_quiet_on;
$mock->add_a_perl( 'README' );
@perls = $mock->perls;
is( scalar @perls, 1, "There are no perls" );
($p0 = $perls[0]) =~ s,.*/,,;
is( $p0, $pX, "The reset perl is the one in \$^X" );

# Adding something is executable but not perl shouldn't do anything
{
my $trial_file = 'exe';

open my($fh), ">", $trial_file;
close $fh;
ok( -e $trial_file, "Trail exe file exists" );

chmod 0755, $trial_file;

SKIP: {
	skip "Couldn't make executable file: $!", 2 unless -x $trial_file;
	$mock->add_a_perl( $trial_file );
	@perls = $mock->perls;
	is( scalar @perls, 1, "There are no perls" );
	($p0 = $perls[0]) =~ s,.*/,,;
	is( $p0, $pX, "The reset perl is the one in \$^X" );
	}

unlink $trial_file;
}
}

{
$mock->remove_a_perl( $^X );
my @perls = $mock->perls;
is( scalar @perls, 0, "There are no perls" );
}

{
my @perls = $mock->perls;
is( scalar @perls, 0, "There are no perls" );

$mock->reset_perls;
@perls = $mock->perls;
is( scalar @perls, 1, "There is one perls" );
(my $p0 = $perls[0]) =~ s,.*/,,;
is( $p0, $pX, "The reset perl is the one in \$^X" );
}

}
