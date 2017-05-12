#
# This file is part of POE-Component-SmokeBox-Uploads-Rsync
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Component::SmokeBox::Uploads::Rsync;
# git description: release-1.000-7-g9c6e8f2
$POE::Component::SmokeBox::Uploads::Rsync::VERSION = '1.001';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Obtain uploaded CPAN modules via rsync

# Import what we need from the POE namespace
use POE;
use POE::Component::Generic;
use parent 'POE::Session::AttributeBased'; # TODO do we really need to prereq 0.09?

# The misc stuff we will use
use File::Spec;

# argh, we need to fool Test::Apocalypse::Dependencies!
# Also, this will let dzil autoprereqs pick it up without actually loading it...
if ( 0 ) {
	require File::Rsync;
}

# Set some constants
BEGIN {
	if ( ! defined &DEBUG ) { *DEBUG = sub () { 0 } }
}

#<@BinGOs> that works. I have no FRMRecent files anywhere in *this* particular mirror's tree
#<@BinGOs> I run rrr-client on the 'velvet' host and rsync to two other boxen from there.
#
#bash-4.0# cat exclude.cpan
#/modules/by-module/*
#/modules/by-category/*
#*FRMRecent-RECENT*
#bash-4.0#
#
#/usr/pkg/bin/rsync -av --no-owner --delete --exclude-from /root/exclude.cpan --delete-excluded rsync://velvet.bingosnet.co.uk /cpan /home/ftp/CPAN/ 2>&1 | tee -a /root/cpan.log

# starts the component!
sub spawn {
	my $class = shift;
	$class = $class; # TODO shutup UnusedVars

	# The options hash
	my %opt;

	# Support passing in a hash ref or a regular hash
	if ( scalar @_ == 1 and ref $_[0] and ref( $_[0] ) eq 'HASH' ) {
		%opt = %{ $_[0] };
	} else {
		# Sanity checking
		if ( @_ % 2 ) {
			warn __PACKAGE__ . ' requires an even number of options passed to spawn()';
			return 0;
		}

		%opt = @_;
	}

	# lowercase keys
	%opt = map { lc($_) => $opt{$_} } keys %opt;

	# Should we rsync the entire CPAN or just the authors directory?
	if ( ! exists $opt{'rsync_all'} or ! defined $opt{'rsync_all'} ) {
		if ( DEBUG ) {
			warn 'Using default RSYNC_ALL = 0';
		}

		$opt{'rsync_all'} = 0;
	} else {
		# booleanize it
		$opt{'rsync_all'} = $opt{'rsync_all'} ? 1 : 0;
	}

	# setup the rsync server
	if ( ! exists $opt{'rsync_src'} or ! defined $opt{'rsync_src'} ) {
		if ( DEBUG ) {
			warn 'The argument RSYNC_SRC is missing!';
		}
		return 0;
	} else {
		# TODO should we verify it's a valid rsync path?
		# i.e. 'cpan.cpantesters.org::cpan'

		# Append the authors/id directory
		if ( ! $opt{'rsync_all'} ) {
			if ( $opt{'rsync_src'} !~ m|authors/id$| ) {
				if ( $opt{'rsync_src'} =~ m|/$| ) {
					$opt{'rsync_src'} .= 'authors/id';
				} else {
					$opt{'rsync_src'} .= '/authors/id';
				}
			}
		}
	}

	# Setup the rsync local destination
	# Append the authors directory ( rsync will sync into id automatically )
	# If we appended "authors/id" then rsync will create a local authors/id/id directory!$!@%#$
	if ( ! exists $opt{'rsync_dst'} or ! defined $opt{'rsync_dst'} ) {
		my $dir = File::Spec->catdir( $ENV{HOME}, 'CPAN' );
		if ( ! $opt{'rsync_all'} ) {
			$dir = File::Spec->catdir( $dir, 'authors' );
		}

		if ( DEBUG ) {
			warn 'Using default RSYNC_DST = ' . $dir;
		}

		# Set the default
		$opt{'rsync_dst'} = $dir;
	} else {
		if ( ! $opt{'rsync_all'} ) {
			if ( $opt{'rsync_dst'} !~ /authors$/ ) {
				$opt{'rsync_dst'} = File::Spec->catdir( $opt{'rsync_dst'}, 'authors' );
			}
		}
	}

	# validate the dst path
	if ( ! -d $opt{'rsync_dst'} ) {
		warn "The RSYNC_DST path does not exist ($opt{'rsync_dst'}), please make sure it is a writable directory!";
		return 0;
	}

	# setup the RSYNC opts
	if ( ! exists $opt{'rsync'} or ! defined $opt{'rsync'} ) {
		if ( DEBUG ) {
			warn 'Using default RSYNC = { archive=>1, compress=>1, omit-dir-times=>1, itemize-changes=>1, timeout=>600, contimeout=>120, literal=[ --no-motd ] }';
		}

		# Set the default
		$opt{'rsync'} = {};
	} else {
		if ( ref( $opt{'rsync'} ) ne 'HASH' ) {
			warn "The RSYNC argument is not a valid HASH reference!";
			return 0;
		}
	}

	# Cleanup the rsync opts
	$opt{'rsync'} = {
		'omit-dir-times'	=> 1,
		'archive'		=> 1,
		'compress'		=> 1,
		'itemize-changes'	=> 1,
		'timeout'		=> 10 * 60,	# 10min
		'contimeout'		=> 2 * 60,	# 2min

		# skip the motd, which just consumes bandwidth ;)
		'literal'		=> [ '--no-motd', ],

		# if we rsync the entire CPAN, we delete files too!
		( $opt{'rsync_all'} ? ( 'delete' => 1 ) : () ),

		# use the provided options
		%{ $opt{'rsync'} },
		( DEBUG ? ( 'debug' => 1 ) : () ),
	};

	# merge rsync_src/dst
	$opt{'rsync'}->{'src'} = delete $opt{'rsync_src'};
	$opt{'rsync'}->{'dst'} = delete $opt{'rsync_dst'};

	# TODO File::Rsync doesn't support contimeout!
	# Ticket here: https://rt.cpan.org/Ticket/Display.html?id=67076
	push( @{ $opt{'rsync'}{'literal'} }, "--contimeout=" . delete $opt{'rsync'}{'contimeout'} );

	# setup the alias
	if ( ! exists $opt{'alias'} or ! defined $opt{'alias'} ) {
		if ( DEBUG ) {
			warn 'Using default ALIAS = SmokeBox-Rsync';
		}

		# Set the default
		$opt{'alias'} = 'SmokeBox-Rsync';
	}

	# Setup the interval in seconds
	if ( ! exists $opt{'interval'} or ! defined $opt{'interval'} ) {
		if ( DEBUG ) {
			warn 'Using default INTERVAL = 3600';
		}

		# set the default
		$opt{'interval'} = 3600;
	} else {
		# verify it's a valid numeric amount
		if ( $opt{'interval'} !~ /^\d+$/ or $opt{'interval'} < 1 ) {
			warn "The INTERVAL argument is not a valid number!";
			return 0;
		}
	}

	# Setup the event
	if ( ! exists $opt{'event'} or ! defined $opt{'event'} ) {
		if ( DEBUG ) {
			warn 'Using default EVENT = upload';
		}

		# set the default
		$opt{'event'} = 'upload';
	}

	# Setup the rsyncdone event
	if ( ! exists $opt{'rsyncdone'} or ! defined $opt{'rsyncdone'} ) {
		if ( DEBUG ) {
			warn 'Using default RSYNCDONE = undef';
		}

		# set the default
		$opt{'rsyncdone'} = undef;
	}

	# Setup the session
	if ( ! exists $opt{'session'} or ! defined $opt{'session'} ) {
		if ( DEBUG ) {
			warn 'Using default SESSION = caller';
		}

		# set the default
		$opt{'session'} = undef;
	} else {
		# eval it because it might already be a regular scalar...
		eval {
			# Convert it to an ID
			if ( $opt{'session'}->isa( 'POE::Session' ) ) {
				$opt{'session'} = $opt{'session'}->ID;
			}
		};
	}

	# Create our session
	POE::Session->create(
		__PACKAGE__->inline_states(),
		'heap'	=>	{
			'ALIAS'		=> $opt{'alias'},
			'RSYNC_OPT'	=> $opt{'rsync'},
			'RSYNC_ALL'	=> $opt{'rsync_all'},
			'INTERVAL'	=> $opt{'interval'},

			'SESSION'	=> $opt{'session'},
			'EVENT'		=> $opt{'event'},
			'RSYNCDONE'	=> $opt{'rsyncdone'},
		},
	);

	# return success
	return 1;
}

# This starts the component
sub _start : State {
	if ( DEBUG ) {
		warn 'Starting alias "' . $_[HEAP]->{'ALIAS'} . '"';
	}

	# Set up the alias for ourself
	$_[KERNEL]->alias_set( $_[HEAP]->{'ALIAS'} );

	# Setup the session
	if ( ! defined $_[HEAP]->{'SESSION'} ) {
		# Use the sender
		if ( $_[KERNEL] == $_[SENDER] ) {
			warn 'Not called from another POE session and SESSION was not set!';
			$_[KERNEL]->yield( 'shutdown' );
			return;
		} else {
			$_[HEAP]->{'SESSION'} = $_[SENDER]->ID;
		}
	}

	# Give it a refcount
	$_[KERNEL]->refcount_increment( $_[HEAP]->{'SESSION'}, __PACKAGE__ );

	# Do the first rsync!
	$_[KERNEL]->yield( '_rsync_start' );

	return;
}

sub _rsync_start : State {
	if ( DEBUG ) {
		warn 'Starting rsync run...';
	}

	$_[HEAP]->{'STARTTIME'} = time;

	# spawn poco-generic
	$_[HEAP]->{'RSYNC'} = POE::Component::Generic->spawn(
		'alt_fork'		=> 1,	# conserve memory by using exec
		'package'		=> 'File::Rsync',
		'methods'		=> [ qw( exec status out err ) ],

		'object_options'	=> [ %{ $_[HEAP]->{'RSYNC_OPT'} } ],
		'alias'			=> $_[HEAP]->{'ALIAS'} . '-' . 'Generic',

		( DEBUG ? ( 'debug' => 1, 'error' => '_rsync_generic_error' ) : () ),
	);

	# tell poco-generic to do it!
	$_[HEAP]->{'RSYNC'}->exec( { 'event' => '_rsync_exec_result' } );

	return;
}

sub _rsync_exec_result : State {
	my $result = $_[ARG1];

	if ( DEBUG ) {
		warn "Rsync exec result: $result";
	}

	# Was it successful?
	if ( $result ) {
		# Get the stdout listing so we can parse it for uploaded files
		$_[HEAP]->{'RSYNC'}->out( { 'event' => '_rsync_out_result' } );
	} else {
		# Get the exit code
		$_[HEAP]->{'RSYNC'}->status( { 'event' => '_rsync_status_result' } );
	}

	return;
}

sub _rsync_status_result : State {
	my $result = $_[ARG1];

	# We ignore status 23/24 errors, it happens occassionally...
	if ( $result == 23 or $result == 24 ) {
		if ( DEBUG ) {
			warn "Ignoring Rsync status $result error...";
		}

		# Get the stdout listing so we can parse it for uploaded files
		$_[HEAP]->{'RSYNC'}->out( { 'event' => '_rsync_out_result' } );
	} else {
		if ( DEBUG ) {
			warn "Rsync exec error - status: $result";
			$_[HEAP]->{'RSYNC'}->err( { 'event' => '_rsync_err_result' } );
		} else {
			# We're done with the rsync subprocess, shut it down!
			$_[KERNEL]->post( $_[HEAP]->{'RSYNC'}->session_id, 'shutdown' );
			undef $_[HEAP]->{'RSYNC'};
		}

		# Let the session know the run is done
		if ( defined $_[HEAP]->{'RSYNCDONE'} ) {
			$_[KERNEL]->post( $_[HEAP]->{'SESSION'}, $_[HEAP]->{'RSYNCDONE'}, {
				'status'	=> 0,
				'exit'		=> $result,
				'exit_str'	=> rsync_exit_string( $result ),
				'starttime'	=> $_[HEAP]->{'STARTTIME'},
				'stoptime'	=> time,
				'dists'		=> 0,
			} );
		}

		# Do another run in INTERVAL
		$_[KERNEL]->delay_set( '_rsync_start' => $_[HEAP]->{'INTERVAL'} );
	}

	return;
}

sub _rsync_err_result : State {
	my $result = $_[ARG1];

	warn "Got rsync STDERR:";
	warn $_ for @$result;

	# We're done with the rsync subprocess, shut it down!
	$_[KERNEL]->post( $_[HEAP]->{'RSYNC'}->session_id, 'shutdown' );
	undef $_[HEAP]->{'RSYNC'};

	return;
}

sub _rsync_out_result : State {
	my $result = $_[ARG1];

	# We're done with the rsync subprocess, shut it down!
	$_[KERNEL]->post( $_[HEAP]->{'RSYNC'}->session_id, 'shutdown' );
	undef $_[HEAP]->{'RSYNC'};

	# Parse the result, and inform the session of new uploads!
	# Look at the rsync man page for details on the itemize-changes format
	# >f.st...... id/R/RC/RCAPUTO/CHECKSUMS
	# >f.st...... id/R/RD/RDB/CHECKSUMS
	# >f+++++++++ id/R/RD/RDB/POE-Component-SNMP-1.1004.meta
	# >f+++++++++ id/R/RD/RDB/POE-Component-SNMP-1.1004.readme
	# >f+++++++++ id/R/RD/RDB/POE-Component-SNMP-1.1004.tar.gz
	# >f+++++++++ id/R/RD/RDB/POE-Component-SNMP-1.1005.meta
	# >f+++++++++ id/R/RD/RDB/POE-Component-SNMP-1.1005.readme
	# >f+++++++++ id/R/RD/RDB/POE-Component-SNMP-1.1005.tar.gz
	# >f.st...... id/R/RE/REDICAPS/CHECKSUMS
	my @modules;
	foreach my $l ( @$result ) {
		# file regex taken from POE::Component::SmokeBox::Uploads::NNTP, thanks BinGOs!
		# if RSYNC_ALL is enabled, we rsync from the root - otherwise the id directory
		if ( $l =~ /^\>f\+{9}\s+(?:authors\/)?id\/(\w+\/\w+\/\w+\/.+\.(?:tar\.(?:gz|bz2)|tgz|zip))$/ ) {
			push( @modules, $1 );
		}
	}

	# Let the session know the run is done
	if ( defined $_[HEAP]->{'RSYNCDONE'} ) {
		$_[KERNEL]->post( $_[HEAP]->{'SESSION'}, $_[HEAP]->{'RSYNCDONE'}, {
			'status'	=> 1,
			'exit'		=> 0,
			'exit_str'	=> rsync_exit_string( 0 ),
			'starttime'	=> $_[HEAP]->{'STARTTIME'},
			'stoptime'	=> time,
			'dists'		=> scalar @modules,
		} );
	}

	# send off the modules
	foreach my $m ( @modules ) {
		$_[KERNEL]->post( $_[HEAP]->{'SESSION'}, $_[HEAP]->{'EVENT'}, $m );
	}

	# Do another run in INTERVAL
	$_[KERNEL]->delay_set( '_rsync_start' => $_[HEAP]->{'INTERVAL'} );

	return;
}

sub _rsync_generic_error : State {
	my $err = $_[ARG0];

	if( $err->{stderr} ) {
		# $err->{stderr} is a line that was printed to the
		# sub-processes' STDERR.  99% of the time that means from
		# your code.
		warn "Got stderr: $err->{stderr}";
	} else {
		# Wheel error.  See L<POE::Wheel::Run/ErrorEvent>
		# $err->{operation}
		# $err->{errnum}
		# $err->{errstr}
		warn "Got wheel error: $err->{operation} ($err->{errnum}): $err->{errstr}";
	}

	return;
}

# POE Handlers
sub _stop : State {
	if ( DEBUG ) {
		warn 'Stopping alias "' . $_[HEAP]->{'ALIAS'} . '"';
	}

	return;
}

sub _child : State {
	return;
}

sub shutdown : State {
	if ( DEBUG ) {
		warn "Shutting down alias '" . $_[HEAP]->{'ALIAS'} . "'";
	}

	# cleanup some stuff
	$_[KERNEL]->alias_remove( $_[HEAP]->{'ALIAS'} );

	# tell poco-generic to shutdown
	if ( defined $_[HEAP]->{'RSYNC'} ) {
		$_[KERNEL]->call( $_[HEAP]->{'RSYNC'}->session_id, 'shutdown' );
		undef $_[HEAP]->{'RSYNC'};
	}

	# decrement the refcount
	if ( defined $_[HEAP]->{'SESSION'} ) {
		$_[KERNEL]->refcount_decrement( $_[HEAP]->{'SESSION'}, __PACKAGE__ );
	}

	return;
}

{
	# Taken from the rsync v3.0.8 manpage
	my %exitcodes = (
		0  => 'Success',
		1  => 'Syntax or usage error',
		2  => 'Protocol incompatibility',
		3  => 'Errors selecting input/output files, dirs',
		4  => 'Requested action not supported: an attempt was made to manipulate 64-bit files on a platform that cannot support them; or an option was specified that is supported by the client and not by the server.',
		5  => 'Error starting client-server protocol',
		6  => 'Daemon unable to append to log-file',
		10 => 'Error in socket I/O',
		11 => 'Error in file I/O',
		12 => 'Error in rsync protocol data stream',
		13 => 'Errors with program diagnostics',
		14 => 'Error in IPC code',
		20 => 'Received SIGUSR1 or SIGINT',
		21 => 'Some error returned by waitpid()',
		22 => 'Error allocating core memory buffers',
		23 => 'Partial transfer due to error',
		24 => 'Partial transfer due to vanished source files',
		25 => 'The --max-delete limit stopped deletions',
		30 => 'Timeout in data send/receive',
		35 => 'Timeout waiting for daemon connection',
	);

	sub rsync_exit_string {
		return $exitcodes{ $_[0] };
	}
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan ARG admin crontabbed dists
rsyncdone BinGOs

=for Pod::Coverage DEBUG rsync_exit_string

=head1 NAME

POE::Component::SmokeBox::Uploads::Rsync - Obtain uploaded CPAN modules via rsync

=head1 VERSION

  This document describes v1.001 of POE::Component::SmokeBox::Uploads::Rsync - released November 03, 2014 as part of POE-Component-SmokeBox-Uploads-Rsync.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;

	use POE;
	use POE::Component::SmokeBox::Uploads::Rsync;

	# Create our session to receive events from rsync
	POE::Session->create(
		package_states => [
			'main' => [qw(_start upload)],
		],
	);

	sub _start {
		# Tell the poco to start it's stuff!
		POE::Component::SmokeBox::Uploads::Rsync->spawn(
			'rsync_src'	=> 'mirrors.kernel.org::mirrors/CPAN/',
		) or die "Unable to spawn the poco-rsync!";

		return;
	}

	sub upload {
		print $_[ARG0], "\n";
		return;
	}

	POE::Kernel->run;

=head1 DESCRIPTION

POE::Component::SmokeBox::Uploads::Rsync is a POE component that alerts newly uploaded CPAN distributions. It obtains this information by
running rsync against a CPAN mirror. This is only for the C<CPAN/authors/id> directory, to make it easier on the rsync process. If you
want to keep your entire mirror up-to-date, you can enable the L</rsync_all> option.

Really, all you have to do is load the module and call it's spawn() method:

	use POE::Component::SmokeBox::Uploads::Rsync;
	POE::Component::SmokeBox::Uploads::Rsync->spawn( ... );

This method will return failure on errors or return success. Normally you just need to set the rsync server. ( rsync_src )

=head2 spawn()

This constructor accepts either a hashref or a hash, valid options are:

=head3 alias

This sets the alias of the session.

The default is: SmokeBox-Rsync

=head3 rsync_src

This sets the rsync source ( the server you will be mirroring from ) and it is a mandatory parameter. For a list of valid rsync mirrors, please
consult the L<http://www.cpan.org/SITES.html> mirror list.

An example is: mirrors.kernel.org::mirrors/CPAN/

The default is: undefined

=head3 rsync_dst

This sets the local rsync destination ( where your local CPAN mirror resides )

The default is: $ENV{HOME}/CPAN

=head3 rsync_all

If this is a true value, this module will rsync the entire CPAN. Useful for lazy people who don't want to run a separate rsync process
for the rest of CPAN. If it is false, this module will rsync only the authors/id directory to make the rsync run faster.

Additionally, if this is true the option C<--delete> will be passed to the rsync process. This keeps your local copy exactly the same as it
is on CPAN. If you want to override this just pass a delete=0 option to the L</rsync> hash.

The default is: false

=head3 rsync

This sets the rsync options. Normally you do not need to touch this, but if you do - please be aware that your options clobbers the default
values! Please look at the L<File::Rsync> manpage for the options. Again, touch this if you know what you are doing!

The default is:

	{
		archive 	=> 1,
		compress 	=> 1,
		omit-dir-times	=> 1,
		itemize-changes	=> 1,
		timeout		=> 10 * 60,	# 10min
		contimeout	=> 2 * 60,	# 2min
		literal 	=> [ qw( --no-motd ) ],
	}

NOTE: The usage of "omit-dir-times/itemize-changes/contimeout" means you need a rsync newer than v3.0.0!

=head3 interval

This sets the seconds between rsync mirror executions. Please don't set it to a low value unless you have permission from the mirror admin!

The default is: 3600 ( 1 hour )

=head3 event

This sets the event which will receive notification about uploaded dists. It will receive one argument in ARG0, which is a single string. An
example is:

	V/VP/VPIT/CPANPLUS-Dist-Gentoo-0.07.tar.gz

The default is: upload

=head3 session

This sets the session which will receive the notification event. You can either use a POE session id, alias, or reference. You can just spawn
the component inside another session and it will automatically receive the notifications.

The default is: undef ( caller session )

=head3 rsyncdone

This sets an additional event when the rsync process is done executing. It will receive a hashref in ARG0 which details some information. An
example is:

	{
		'status'	=> 1,		# boolean value whether the rsync run was successful or not
		'exit'		=> 0,		# exit code of the rsync process, useful to look up rsync errors ( already bit-shifted! )
		'exit_str'	=> 'Success',	# stringified exit code of the rsync process
		'starttime'	=> 1260432932,	# self-explanatory
		'stoptime'	=> 1260432965,	# self-explanatory
		'dists'		=> 7,		# number of new distributions uploaded to CPAN
	}

NOTE: In my testing sometimes rsync throws an exit code of 23 ( Partial transfer due to error ) or 24 ( Partial transfer due to vanished source
files ), this module automatically treats them as "success" and sets the exit code to 0. This is caused by the intricacies of rsync trying to
mirror some forbidden files and deletions on the host. See L<https://bugzilla.samba.org/show_bug.cgi?id=3653> for more info.

The default is: undef ( not enabled )

=head2 Commands

There is only one command you can use, as this is a very simple module.

=head3 shutdown

Tells this module to shut down the underlying rsync session and terminate itself.

	$_[KERNEL]->post( 'SmokeBox-Rsync', 'shutdown' );

=head2 Module Notes

You can enable debugging mode by doing this:

	sub POE::Component::SmokeBox::Uploads::Rsync::DEBUG () { 1 }
	use POE::Component::SmokeBox::Uploads::Rsync;

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<POE::Component::SmokeBox|POE::Component::SmokeBox>

=item *

L<File::Rsync|File::Rsync>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc POE::Component::SmokeBox::Uploads::Rsync

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/POE-Component-SmokeBox-Uploads-Rsync>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/POE-Component-SmokeBox-Uploads-Rsync>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-SmokeBox-Uploads-Rsync>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/POE-Component-SmokeBox-Uploads-Rsync>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/POE-Component-SmokeBox-Uploads-Rsync>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/POE-Component-SmokeBox-Uploads-Rsync>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/POE-Component-SmokeBox-Uploads-Rsync>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/POE-Component-SmokeBox-Uploads-Rsync>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=POE-Component-SmokeBox-Uploads-Rsync>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=POE::Component::SmokeBox::Uploads::Rsync>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-poe-component-smokebox-uploads-rsync at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-SmokeBox-Uploads-Rsync>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-poe-smokebox-uploads-rsync>

  git clone https://github.com/apocalypse/perl-poe-smokebox-uploads-rsync.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
