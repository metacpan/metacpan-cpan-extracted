package MyCPAN::App::DPAN::SVNPostFlight;
use strict;
use warnings;
use utf8;

use vars qw( $logger );

use Data::Dumper;
use IPC::Cmd;
use IPC::Run qw();
use IPC::System::Simple qw(capturex systemx);
use Log::Log4perl;
use XML::Simple;

=encoding utf8

=head1 NAME

MyCPAN::App::DPAN::SVNPostFlight - A No-op reports processor

=head1 SYNOPSIS

Use this from C<dpan> by specifying it as the C<postflight_class> class:

	# in dpan.conf
	postflight_class  MyCPAN::App::DPAN::SVNPostFlight
	postflight_dry_run 1

=head1 DESCRIPTION

This class is an example for a user-defined class to run at the end of
C<dpan>'s normal processing. The class only needs to provide a C<run>
method, which is automatically called by C<dpan>. Be careful that you
don't import anything called C<run> (looking at you, C<IPC::Run>)!

This example checks that the DPAN directory is under source control,
invokes an svn update, checks the svn status to see what's changes,
and creates a list of svn commands to run. It adds any new files it
finds and removes any missing miles. If it detects a conflict, it
stops the process before anything happens.

If you've set the C<postflight_dry_run> configuration variable, this
class merely prints the svn adds and removes that it would run, but it
doesn't actually run them. That gives you a chance to see what it
would do without doing it.

At the end of the run, this prints the URL you need to use to access the
repository.

=head2 Logging

This module uses the C<PostFlight> logging category in the C<Log::Log4perl>
setup.

=head2 Writing your own

If you want to maek your own class, check out the source for C<run>. The
code comments explain what you should be doing. However, most of the
code in this example isn't specific to the post flight processing.

=head2 Methods

=over 4

=cut

# Log::Log4perl should already be set up. The
BEGIN {
$logger = Log::Log4perl->get_logger( 'PostFlight' );
}

BEGIN {
my $svn = IPC::Cmd::can_run( 'svn' );
$logger->debug( "svn commmand is [$svn]" );

=item svn

Returns the path to the svn binary.

=cut

sub svn { $svn }

=item dry_run

Returns the value of the postflight_dry_run configuration directive.

=cut

sub dry_run { $_[0]->{postflight_dry_run} }

=item run_svn

Runs an svn command. During a dry run it merely prints the command to
standard output. Otherwise, it actually runs the svn command.

=cut

sub run_svn
	{
	my( $self, @commands ) = @_;

	if( $self->dry_run )
		{
		print "dry run: $svn @commands\n";
		}
	else
		{
		$logger->debug( "$svn @commands" );
		print capturex( $self->svn, @commands );
		}
	}

}

=item run( $application )

Makes the hamsters go. This is called automatically from dpan. It gets
the application object as its argument.

=cut

sub run
	{
	# dpan calls this as a class method after it runs
	# $application->cleanup. All of dpan's work is done and it's removed
	# most of its mess. You're picking up control just before it would
	# normally exit.
	#
	# The only argument is the $application object.
	my( $class, $application ) = @_;

	# The coordinator object has references to all of the other components
	# and the application notes. See MyCPAN::Indexer::Tutorial and
	# MyCPAN::Indexer::Coordinator for more information
	my $coordinator = $application->get_coordinator;

	# The Coordinator knows how to get the configuration object
	my $config      = $coordinator->get_config;

	# You are probably already in this directory, but it's nice to be
	# sure.
	my $dpan_dir = $config->get( 'dpan_dir' );
	chdir $dpan_dir;

	# If there isn't a .svn directory, there's not much that we can do
	unless( -e '.svn' )
		{
		$logger->logdie( "There isn't an .svn directory in [$dpan_dir]! I can't continue!" );
		return;
		}

	# Construct an object, although it's not necessary. We're going to
	# use it to adjust some configuration, etc, that we can pass around.
	# In this case, we just transfer the postflight_dry_run value.
	#
	# You can add any configuration directive that you like. You might
	# want to give it a prefix that won't conflict with the standard
	# dpan directives.
	#
	# In case we need the application object for something else, we'll
	# store a a reference to that too.
	my $self = bless
		{
		postflight_dry_run => $config->get( 'postflight_dry_run' ),
		application        => $application,
		}, $class;

	# Now we're past all of the special parts. It's whatever you want to
	# do now.
	$logger->info( "Checking the svn status" );
	my $commands = $self->_get_commands;

	$logger->info( "Handling svn additions and deletions" );
	$self->_handle_commands( $commands );

	$logger->info( "All done. Have a nice day!" );
	$self->_report_repo_url;
	}

BEGIN {
my %Commands = (
	'unversioned' => 'add',
	'deleted'     => 'rm',
	);

sub _get_commands
	{
	my( $self ) = @_;
	my $xml = $self->_get_svn_status_xml;

	my $ref = XMLin( $xml );

	my( @commands, @conflicts );
	foreach my $entry ( @{ $ref->{target}{entry} } )
		{
		my $status = $entry->{'wc-status'}{item};
		my $path   = $entry->{path};
		$logger->debug( "svn status for $path: $status" );

		if( exists $Commands{ $status } )
			{
			push @commands, [ $Commands{ $status }, $path ];
			}
		if( $status eq 'conflicted' )
			{
			push @conflicts, $path;
			}
		}

	if( @conflicts )
		{
		my $list = join "\n\t", @conflicts;

		$logger->logdie( "I can't continue. There are conflicts in svn:\n\t$list\n" );
		return;
		}

	\@commands;
	}
}

sub _svn_update
	{
	my( $self ) = @_;
	# don't use run_svn because we have to still run for dry run
	my $output = capturex( $self->svn, 'update' );
	$logger->debug( "svn status output: $output" );
	$output;
	}

sub _get_svn_status_xml
	{
	my( $self ) = @_;
	# don't use run_svn because we have to still run for dry run
	my $status = capturex( $self->svn, 'status', '--xml' );
	$logger->debug( "svn status output: $status" );
	$status;
	}

sub _handle_commands
	{
	my( $self, $commands ) = @_;

	my $svn = $self->svn;

	$self->_svn_update;

	foreach my $command ( @$commands )
		{
		$self->run_svn( @$command );
		}

	$logger->info( "Committing work to svn" );
	my @commit_command = (  $svn, 'commit', '-m', 'DPAN PostFlight commit' );

	my( $in, $output ) = ( '' );

	IPC::Run::run( \@commit_command, \$in, \$output, \$output )
		or do {
			$logger->debug( "svn commit output: $output" );
			$logger->logdie( "Could not commit to svn!" );
			return;
			};
	$logger->debug( "Output from commit: $output" );

	return 1;
	}

sub _report_repo_url
	{
	my( $self ) = @_;

	# don't use run_svn because we have to still run for dry run
	my $xml = capturex( $self->svn, 'info', '--xml' );
	$logger->debug( "svn info output: $xml" );

	my $ref  = XMLin( $xml );
	my $repo = $ref->{entry}{url};
	print "To use this DPAN, point your CPAN tool to:\n\n\t$repo\n\n";
	}

=back

=head1 SEE ALSO

MyCPAN::App::DPAN, dpan

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-app-dpan.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
