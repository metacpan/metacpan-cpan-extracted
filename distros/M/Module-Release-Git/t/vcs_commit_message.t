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
can_ok( $release, qw(vcs_commit_message_template vcs_commit_message) );

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

subtest vcs_commit_message_template => sub {
	no warnings qw(redefine);
	can_ok( $release, qw(vcs_commit_message vcs_commit_message_template) );

	subtest no_config => sub {
		my $config_hash = {};
		my $config = Local::Config->new( $config_hash );
		no strict 'refs';
		local *{'Module::Release::config'} = sub { $config };
		can_ok( $release, 'config' );
		isa_ok( $release->config, 'Local::Config' );

		ok( ! defined $release->config->commit_message_format, 'commit_message_format is not defined' );
		is( $release->vcs_commit_message_template, '* for version %s', "commit_message_format is the default" );
		};

	subtest config => sub {
		my $config_hash = {
			commit_message_format => 'nonsense foo bar %s'
			};
		my $config = Local::Config->new( $config_hash );
		no strict 'refs';
		local *{'Module::Release::config'} = sub { $config };
		can_ok( $release, 'config' );
		isa_ok( $release->config, 'Local::Config' );

		is( $release->config->commit_message_format, $config_hash->{commit_message_format}, "commit_message_format is right <$config_hash->{commit_message_format}>" );
		};

	};

BEGIN { # syntax for v5.10
	package Local::Config;
	sub new { bless $_[1], $_[0] }
	sub DESTROY { 1 }
	sub AUTOLOAD {
		our $AUTOLOAD;
		( my $method = $AUTOLOAD ) =~ s/.*:://;
		exists $_[0]{$method} ? $_[0]{$method} : ()
		}
	}

done_testing();
