# Slauth registration interface using Mailman lists

package Slauth::Register::Mailman;

use strict;
#use warnings FATAL => 'all', NONFATAL => 'redefine';
use Slauth::Config;
use Slauth::Storage::User_DB;
use Slauth::Storage::Session_DB;
use Slauth::Storage::Confirm_DB;
use IO::Pipe;
use CGI::Carp qw(fatalsToBrowser);

# globals
our $VERSION = "0.01";

sub debug { $Slauth::Config::debug; }

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->initialize();
	return $self;
}

sub initialize
{
	my $self = shift;
	$self->{short_name} = "mailman";
	$self->{long_name}
		= "Registration using Mailman mail list subscription info";
	$self->{req_params} = [ qw( addr login ) ];
}

# short-form name for use in URLs
# TODO: move this to a new parent class Slauth::Register
sub short_name { my $self = shift; $self->{short_name} };

# long-form name for use as a one-liner description
# TODO: move this to a new parent class Slauth::Register
sub long_name { my $self = shift; $self->{long_name} };

# list of required form paramaters
# TODO: move this to a new parent class Slauth::Register
sub req_params { my $self = shift; @{$self->{req_params}} };

# HTML registration form 
sub html_form
{
	my ( $self, $web ) = @_;

	$web->tag( "text",
		"<form action=\"%self_url%\" method=\"POST\">\n"
		."Please enter your e-mail address as it's\n"
		."subscribed on our mail lists.\n"
		."<br>\n"
		."(<b>required</b> - this must match your subscription)\n"
		."<br>\n"
		."<input type=text name=addr size=70>\n"
		."<p>\n"
		."Choose a one-word login name.\n"
		."<br>\n"
		."(<b>required</b> - this will be your web login name)\n"
		."<br>\n"
		."<input type=text name=login size=20>\n"
		."<p>\n"
		."Enter your Mailman password from any of our lists "
		."that you're subscribed to\n"
		."<br>\n"
		#."(<b>required</b> - we'll later make this optional\n"
		#."and have it e-mail a confirmation to you if you omit\n"
		#."your password.  But that isn't done yet.)\n"
		."(<b>optional</b> - if you omit your password then a "
		."confirmation will be mailed to you.)\n"
		."<br>\n"
		."<input type=password name=pw size=30>\n"
		."<p>\n"
		."<input type=submit name=submit>\n"
		."</form>\n" );
}

# process form submission
sub process_form
{
	my ( $self, $web ) = @_;
	my ( $text );
	my $realm = $web->get( "realm" );
	my $config = $web->get( "config" );

	debug and print STDERR "process_form: init\n";

	$web->tag( "subtitle", $self->long_name());

	my $login = $web->param("login");
	my $pw = $web->param("pw");
	my $addr = $web->param("addr");
	if (( defined $pw ) and length( $pw ) > 0 ) {
		$self->check_subs( $web, $addr, $pw );
		if (( defined $self->{subs}{"exit-code"})
			and $self->{subs}{"exit-code"} != 0 )
		{
			$text = "An error has occurred.\n";
			$text .= "The verification software has failed.\n";
			$text .= "This may require admin attention.\n";
			$text .= "Please report this and try again later.\n";
		} elsif ( $self->{subs}{status} ne "success" ) {
			$text = "An error has occurred.\n";
			$text .= "A failure occurred during verification.\n";
			$text .= "This may require admin attention.\n";
			$text .= "Please report this and try again later.\n";
		} elsif ( $self->{subs}{"search-status"} ne "success" ) {
			$text = "The software has denied your request.\n";
			$text .= "The info you provided was incorrect.\n";
			$text .= "If you need help, please ask for it.\n";
		} else {
			
			# success - create user and session, set user's cookie

			# create the new user record
			my $user_db = Slauth::Storage::User_DB->new( $config );
			if ( $user_db->error ) {
				$text = "An error has occurred.\n";
				$text .= "The storage subsystem failed.\n";
				$text .= "Your user record wasn't stored.\n";
				$text .= "This may require admin attention.\n";
				$text .= "Please report this and try again.\n";
				goto DONE;
			}
			my $name = "";
			if ( defined $self->{subs}{name}) {
				my @names = split /\n/, $self->{subs}{name};
				$name = $names[0];
			}
			my @groups = split ( /\s+/,
				$self->{subs}{subscriptions});
			$user_db->write_record ( $login, $pw, $name, $addr,
				@groups );
			$web->new_session( $login );
			return;
		}
	} else {
		# handle e-mail verification
		my $confirm_db = Slauth::Storage::Confirm_DB->new( $config );
		my $confirm_hash = $confirm_db->write_record( $login, $addr,
			$config );
		my $admin_addr = $web->get( "admin_addr" );

		if ( !open ( mail_pipe, "| /usr/lib/sendmail $addr" )) {
			$text = "An error has occurred.\n";
			$text .= "The confirmation e-mail could not be sent\n";
			$text .= "to the address due to a local error on\n";
			$text .= "this server ($!).\n";
			goto DONE;
		}
		print mail_pipe "To: $addr\n";
		print mail_pipe "From: $admin_addr\n";
		print mail_pipe "Subject: $realm web access confirmation\n";
		print mail_pipe "\n";
		print mail_pipe "This message was sent to you because "
			."this address was entered in a web form\n";
		print mail_pipe "to request web access at $realm.\n";
		print mail_pipe "We need to confirm that the owner of this "
			."address really made that request.\n";
		print mail_pipe "\n";
		print mail_pipe "If you did not make the request, you may "
			."safely ignore and discard this\n";
		print mail_pipe "message. However, we would like to know "
			."about cases of network abuse.\n";
		print mail_pipe "\n";
		print mail_pipe "In order to complete your web access, "
			."please visit this URL:\n";
		print mail_pipe "   "
			."http://"
			.$web->tag("server_name")
			.$web->tag("script_name")
			.$web->tag("path_info")
			."/confirm/"
			.$web->{cgi}->escape(
				Slauth::Storage::Confirm_DB::md5tourlsafe(
				$confirm_hash))
			."\n";
		if ( ! close mail_pipe ) {
			$text = "An error has occurred.\n";
			$text .= "The confirmation e-mail could not be sent\n";
			$text .= "to the address due to a local error on\n";
			$text .= "this server ($!).\n";
			goto DONE;
		}
		$text .= "Thank you.  A confirmation e-mail has been sent "
			."to your address.\n";
		$text .= "Select the link in the e-mail to activate your "
			."web access.\n";
	}

	DONE:

	#$text .= "parameters received:<br>\n";
	#my @vars = $web->param;
	#foreach my $key ( @vars ) {
	#	$text .= $key." = ".$web->param($key)."<br>\n";
	#}
	#$text .= "<br>pw-check output:<br>\n";
	#$text .= "<blockquote><pre>\n";
	#$text .= join ( "\n", %{$self->{subs}})."\n";
	#$text .= "</pre></blockquote>\n";

	$web->tag("text", $text );
}

# process additional path info as menu selections
sub process_path
{
	my ( $self, $web, @subpath ) = @_;
	my ( $text );
	my $config = $web->get( "config" );

	if ( $subpath[0] eq "confirm" ) {
		my $path_hash =
			Slauth::Storage::Confirm_DB::urlsafetomd5($subpath[1]);
		my ( $confirm_login, $confirm_hash, $confirm_salt,
			$confirm_email, $confirm_time )
			= Slauth::Storage::Confirm_DB::get_confirm($path_hash,
				$config );
		if ( ! defined $confirm_login ) {
			$text = "No confirmation record was found.\n";
			goto DONE;
		}
		my $now = time;
		if ( $confirm_time > $now + 60*10
			or $now > $confirm_time + 60*60*24*2 )
		{
			$text = "This confirmation has expired.\n";
			$text .= "You will need to register again.\n";
			Slauth::Storage::Confirm_DB::delete_confirm($path_hash,
				$config );
			goto DONE;
		}
		$self->check_subs( $web, $confirm_email,
			"***unauthenticated query***" );
		if (( defined $self->{subs}{"exit-code"})
			and $self->{subs}{"exit-code"} != 0 )
		{
			$text = "An error has occurred.\n";
			$text .= "The verification software has failed.\n";
			$text .= "This may require admin attention.\n";
			$text .= "Please report this and try again later.\n";
		} elsif ( $self->{subs}{status} ne "success" ) {
			$text = "An error has occurred.\n";
			$text .= "A failure occurred during verification.\n";
			$text .= "This may require admin attention.\n";
			$text .= "Please report this and try again later.\n";
		} elsif ( $self->{subs}{"search-status"}
			ne "unauthenticated success" )
		{
			$text = "The software has denied your request.\n";
			$text .= "The info you provided was incorrect.\n";
			$text .= "If you need help, please ask for it.\n";
		} else {
			my $new_pw = `/usr/local/bin/pwrand --length=8 --allalpha`;
			chomp $new_pw;
			my $user_db = Slauth::Storage::User_DB->new( $config );
			my @groups = split ( /\s+/,
				$self->{subs}{subscriptions});
			$user_db->write_record($confirm_login, $new_pw,
				"", $confirm_email, @groups );
			Slauth::Storage::Confirm_DB::delete_confirm($path_hash,
				$config );
			$web->tag("text",
				"A web password has been auto-generated "
					."for you: $new_pw<p><br>\n" );
			$web->new_session( $confirm_login );
			return;
		}
	} else {
		$text = "The function '".$subpath[0]."' was not recognized.\n";
	}
	DONE:
	$web->tag("text", $text );
}

# verify Mailman subscription info
#
# Note: for security design purposes, it was considered too great a risk
# to store Mailman password information within mod_perl/Apache.  Therefore
# the model in use here is to contact an external program which runs under
# the Mailman group ID.  The parameters piped (not via the command line or
# environment, which can be exposed via /proc) to that program are only the
# subscription address and password.  If the password is correct for any
# list subscription in that domain, then it responds affirmatively and
# with the list of subscriptions for use in access group memberships.

sub check_subs
{
	my ( $self, $web, $addr, $pw ) = @_;
	my $mailman_bin = $web->get( "mailman_bin" );
	my $realm = $web->get( "realm" );

	debug and print STDERR "check_subs: init\n";

	my $pipe_to_script = new IO::Pipe;
	my $pipe_from_script = new IO::Pipe;

	if ( my $pid = fork ) {

		# Parent process - we are still running inside the web server
		debug and print STDERR "check_subs: in parent\n";
		$pipe_to_script->writer();
		$pipe_to_script->autoflush(1);
		$pipe_from_script->reader();

		debug and print STDERR "check_subs: output to script\n";
		print $pipe_to_script $realm."\n";
		print $pipe_to_script $addr."\n";
		print $pipe_to_script $pw."\n";
		close $pipe_to_script;
		
		# gulp the response
		debug and print STDERR "check_subs: read from script\n";
		my %response;
		while ( <$pipe_from_script> ) {
			chomp;
			debug and print STDERR "check_subs: got '$_'\n";
			if ( /^([a-z0-9_-]+):\s*(.*)/i ) {
				if ( !defined $response{$1}) {
					$response{$1} = $2;
				} else {
					$response{$1} .= "\n".$2;
				}
			}
		}
		close $pipe_from_script;
		$response{date} = localtime;

		waitpid ( $pid, 0 );
		debug and print STDERR "check_subs: result code ".($? >> 8)."\n";
		if ( $? >> 8 != 0 ) {
			$response{"exit-code"} = ($? >> 8);
		}
		$self->{subs} = \%response;

	} elsif( defined $pid ) {

		# Child process - we are in a disposable copy of the web server
		# We must circumvent any defenses mod_perl has made to core
		# functions to defend the web server from being undermined by
		# Perl code.  So we use CORE::* functions in order to access
		# the original Perl functions.  Since we just forked, we must
		# finish exec'ing this process or exit so that there isn't
		# an unwanted copy of Apache running around.
		debug and print STDERR "check_subs: entering child\n";

		# prepare Apache for upcoming exec
		# (This is in an eval so commsnd-line testing still works.)
		eval "require Apache::RequestUtil; "
			."require Apache::SubProcess; "
			."my \$r = Apache->Request; "
			."\$r->cleanup_for_exec()";

		# replace STDIN with the pipe to the script
		# so that we can write to its input
		$pipe_to_script->reader;
		untie *main::STDIN;
		my $stdin = *main::STDIN{IO};
		open ( $stdin, "<&=", $pipe_to_script )
			or CORE::die "failed to reopen STDIN in child: $!\n";
		debug and print STDERR "check_subs: STDIN fileno ="
			.$stdin->fileno."\n";

		# replace STDOUT with the pipe from the script
		# so that we can read from its output
		$pipe_from_script->writer;
		untie *main::STDOUT;
		my $stdout = *main::STDOUT{IO};
		open ( $stdout, ">&=", $pipe_from_script )
			or CORE::die "failed to reopen STDOUT in child: $!\n";
		debug and print STDERR "check_subs: STDOUT fileno ="
			.$stdout->fileno."\n";

		# Make sure file descriptors  will stay open across exec()
		# Clear the close-on-exec flag from the pipes
		require Fcntl;
		fcntl( $stdin, Fcntl::F_SETFD(), 0 );
		fcntl( $stdout, Fcntl::F_SETFD(), 0 );

		# exec the program or bust
		debug and print STDERR "check_subs: filenos ="
			.$stdin->fileno." "
			.$stdout->fileno."\n";
		{
			CORE::exec "$mailman_bin/check-pw-wrapper",
				$stdin->fileno, $stdout->fileno;
		}
		debug and print STDERR "check_subs: exec failed\n";
		print STDERR "failed to execute check-pw script: $!\n";
		CORE::exit(1);
		# never gets here
		# croak will work because exit() isn't shooting blanks
	} else {
		# fork failed
		croak "fork failed - system process table may be full "
			."or another resource constraint has been reached\n";
	}
}

1;

__END__

=head1 NAME

Slauth::Register::Mailman - Slauth module for user self-registration from Mailman list data

=head1 SYNOPSIS

in Slauth configuration:

%config = (
        "global" => {
		[...]
                "register" => "Slauth::Register::Mailman",
                "mailman_bin" => "/home/mailman/slauth-bin",
		[...]
	}
};

=head1 DESCRIPTION

TBA

=head1 SEE ALSO

Slauth

See the Slauth project web site at http://www.slauth.org/

Project mail lists are at http://www.slauth.org/mailman/listinfo

=head1 AUTHOR

Ian Kluft, E<lt>ikluft@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Ian Kluft

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

