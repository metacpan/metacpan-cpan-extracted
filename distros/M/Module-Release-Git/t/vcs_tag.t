#!/usr/bin/perl
use strict;
use vars qw($run_output);

use Test::More;

my $class  = 'Module::Release::Git';

use_ok( 'Module::Release' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
=pod

To test these functions, I want to give them some sample git 
output and ensure they do what I want them to do. Instead of
running git, I override the run() method to return whatever 
is passed to it.

=cut

subtest dummy_releaserc => sub {
	if( -e 'releaserc' ) { return pass( "releaserc exists" ) }
	my $fh;
	unless( open $fh, '>', 'releaserc' ) {
		return fail( "Could not create releaserc: $!" );
		} 	
	print { $fh } "cpan_user ADOPTME\n";
	pass( "Created releaserc" );
	};

my $release = Module::Release->new;
$release->load_mixin( $class );
can_ok( $release, qw(make_vcs_tag vcs_tag) );

{
package Module::Release;
no warnings qw(redefine once);
*run          = sub { $main::run_output = $_[1] };
*remote_file  = sub { $_[0]->{remote_file} };
*dist_version = sub { $_[0]->{dist_version} };
*_warn        = sub { 1 };
*_print       = sub { 1 };
*_get_time    = sub { '137' };
}


# Define our test cases.  'tag' is passed to ->vcs_tag, and 'expect'
# is the tag we expect to get supplied to Git.  If remote_file is
# specified, then this key and its value is inserted into the
# $release object, emulating the release of a distro with that file
# name.
my @cases = (
	{
	desc        => 'an arbitrary tag argument', 
	tag         => 'foo',
	expect      => 'foo',
	version     => undef,
	},
	
	{
	desc        => 'no tag info',
	tag         => undef,
	expect      => 'release-137',
	version     => undef,
	},
	
	{
	desc        => 'two-number version',
	tag         => undef, 
	expect      => 'release-45.98',
	version     => '45.98',
	},
	
	{
	desc        => 'two-number dev version',
	tag         => undef, 
	expect      => 'release-45.98_01',
	version     => '45.98_01',
	},

	{
	desc        => 'two-number dev version',
	tag         => undef, 
	expect      => 'release-v45.98_01',
	version     => 'v45.98_01',
	},
);



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

foreach my $case ( @cases ) {
	$release->{dist_version} = $case->{version};
	
	my $s_version = $case->{version} // '<undef>'; #/
	
	is( eval{ $release->dist_version }, $case->{version}, 
		"dist_version returns the right value for [$s_version}]" );
	ok( $release->make_vcs_tag,
			"$case->{desc}: make_vcs_tag returns true with $s_version" );

	ok( $release->vcs_tag( $case->{tag} ), 'vcs_tag returns true' );

	my $expected_cmd = "git tag $case->{expect}";
	is( $main::run_output, $expected_cmd, "command is [$expected_cmd]" );
	}

done_testing();
