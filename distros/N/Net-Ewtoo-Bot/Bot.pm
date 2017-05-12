#!/usr/bin/perl
# $Id: Bot.pm,v 1.14 2002/04/27 19:25:32 jodrell Exp $
# Copyright (c) 2002 Gavin Brown. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself. 

use IO::Socket;
use IO::Handle;
use strict;

package Net::Ewtoo::Bot;
use vars qw($VERSION);
$VERSION = '0.16';

=pod

=head1 NAME

Net::Ewtoo::Bot - a Ewtoo-compatible talker robot client module

=head1 SYNOPSIS

	use Net::Ewtoo::Bot;

	my $NAME = 'jodbot';

	my $bot = new Net::Ewtoo::Bot;

	$bot->add_trigger("(.+?) says '$NAME, (.+?)'", \&handle_say);
	$bot->set_delay('range', 0, 5);

	$bot->login($host, $port, $user, $pass);
	$bot->say("Hi! I'm the $NAME robot!");

	$bot->listen();

	$bot->logout();

	exit;

	sub handle_say {
		my ($sayer, $said) = @_;
		if ($said eq 'hello') {
			$bot->say("Why hello $sayer!");
		} elsif ($said eq 'please go away') {
			$bot->say("OK, bye!");
			$bot->logout();
		}
		return;
	}

=head1 DESCRIPTION

Net::Ewtoo::Bot provides an object-oriented interface to Ewtoo (I<http://www.ewtoo.org/>) type talker systems. The module provides support for the most common Ewtoo talker commands, as well as input pattern matching and callback triggers and timers.

=head1 INSTALLATION

To install this package, just change to the directory which you created by untarring the package, and type the following:

	perl Makefile.PL
	make test
	make
	make install

This will copy Bot.pm to your perl library directory for use by all perl scripts. You probably must be root to do this, unless you have installed a personal copy of perl.

=head1 METHODS

	$bot->login($host, $port, $user, $pass);

This logs the bot into the $host:$port talker using $user and $pass. The bot will send extra carriage returns to bypass MOTDs and saved messages.

Any defined login subroutines are executed at this point.

	$bot->logout($message);

Sends the "QUIT" command (in capitals for compatability with MBA4), and closes the socket. Any defined logout subroutines are executed beforehand. If $message is defined, the bot calls the "mquit" command with $message as its argument.

	$bot->set_delay($type, $lower, $upper);

This method sets the delay between between the calling of a method and its execution. This is useful for adding a realistic delay during communications with another user. $type can be either 'fixed', in which case the delay is always $lower (in seconds) and $upper is ignored, or 'range', in which case the delay will be a random number of seconds between $lower and $upper.

	$bot->add_trigger($pattern, $callback);

This method adds a trigger used by the listen() method. When a line of input is received that matches $pattern, $callback is executed. The arguments to $callback are any captured substrings you define in your pattern, which is a regular perl regexp (without the trailing and leading slashes).

	$bot->delete_trigger($pattern);

Removes the trigger associated with $pattern from the trigger list.

	$bot->def_login($callback);

Specifies a subroutine with $callback that will be executed after the bot logs in.

	$bot->def_logout($callback);

Specifies a subroutine with $callback that will be executed before the bot logs out.

	$bot->listen($verbose);

listen() reads input from the talker and executes triggers as necessary. If $verbose is set to 1, then any input received is printed to STDOUT.

	$bot->break();

$break() sets a flag that tells the listen() method to finish and return.

	$bot->say($str);

A convenience function that makes the bot say $str.

	$bot->think($str);

A convenience function that makes the bot think $str.

	$bot->shout($str);

A convenience function that makes the bot shout $str.

	$bot->tell($user, $str);

A convenience function that makes the bot tell $str to $user.

	$bot->command($cmd);

Allows the calling of an arbitrary talker command.

	$bot->getline();

Reads a single line of input from the talker.

=head1 COPYRIGHT

This module is (c) 2001,2002 Gavin Brown (I<gavin.brown@uk.com>), with additional input and advice from Richard Lawrence (I<richard@fourteenminutes.com>).

This module is licensed under the same terms as Perl itself.

=head1 TO DO

Implement a timing mechanism for scheduled stuff.

=head1 SEE ALSO

The Ewtoo website at I<http://www.ewtoo.org>, and the PlayGround Plus website at I<http://pgplus.ewtoo.org/>.

=cut

my $socket = new IO::Handle;
$socket->autoflush(1);

sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	return $self;
}

sub login {
	my ($self, $host, $port, $user, $pass) = @_;
	$socket = IO::Socket::INET->new(	PeerAddr	=> $host,
						PeerPort	=> $port,
						Proto		=> 'tcp',
						Timeout		=> 10 ) or warn("$host:$port: $@") and return undef;
	print $socket "$user\n$pass\n\n";
	if (defined($self->{_login_subs}) && scalar(@{$self->{_login_subs}}) > 0) {
		foreach my $sub(@{$self->{_login_subs}}) {
			&{$sub}();
		}
	}
	return;
}

sub logout {
	my ($self, $message) = @_;
	if (defined($self->{_logout_subs}) && scalar(@{$self->{_logout_subs}}) > 0) {
		foreach my $sub(@{$self->{_logout_subs}}) {
			&{$sub}();
		}
	}
	if ($message ne '') {
		print $socket "mquit $message\n";
	} else {
		print $socket "QUIT\n";
	}
	close($socket);
	return;
}

sub set_delay {
	my ($self, $mode, $lower, $upper) = @_;
	if ($mode =~ /^(fixed|range)$/i) {
		$self->{_mode} = lc($mode);
		$self->{_range} = [$lower, $upper];
	} else {
		die("Invalid delay mode");
	}
	return;
}

sub add_trigger {
	my ($self, $pattern, $sub) = @_;
	$self->{_patterns}{$pattern} = $sub;
	return;
}

sub delete_trigger {
	my ($self, $pattern) = @_;
	delete $self->{_patterns}{$pattern};
	return;
}

### these two methods are kept in but don't work - i haven't come up with a neat
### way to add a timing system that doesn't interrupt the program's flow and
### doesn't use threads.

sub add_timer {
	my ($self, $interval, $sub) = @_;
	push(@{$self->{_timers}}, { interval => $interval, sub => $sub, init => time() });
	return scalar(@{$self->{_timers}}) - 1;
}

sub delete_timer {
	my ($self, $timer_no) = @_;
	if (${$self->{_timers}}[$timer_no]) {
		undef ${$self->{_timers}}[$timer_no];
	} else {
		die("Invalid timer ID '$timer_no'");
	}
	return;
}

sub def_login {
	my ($self, $sub) = shift;
	push(@{$self->{_login_subs}}, $sub);
	return;
}

sub def_logout {
	my ($self, $sub) = shift;
	push(@{$self->{_logout_subs}}, $sub);
	return;
}

sub listen {
	my ($self, $print) = @_;
	$self->{_listen} = 1;
	while (<$socket>) {
		$_ = $self->_clean_input($_);
		print if ($print == 1);
		return if $self->{_listen} != 1;
		foreach my $pattern(sort keys %{$self->{_patterns}}) {
			if (my @matches = (/$pattern/i)) {
				&{$self->{_patterns}{$pattern}}(@matches);
			}
		}
	}
	return;
}

sub break {
	my $self = shift;
	$self->{_listen} = 0;
	return;
}

sub say {
	my ($self, $str) = @_;
	$self->command("say $str");
	return;
}

sub think {
	my ($self, $str) = @_;
	$self->command("think $str");
	return;
}

sub shout {
	my ($self, $str) = @_;
	$self->command("shout $str");
	return;
}

sub tell {
	my ($self, $target, $str) = @_;
	$self->command("tell $target $str");
	return;
}

sub command {
	my ($self, $str) = @_;
	$self->_delay();
	print $socket "$str\n";
	return;
}

sub getline {
	my $self = shift;
	return $self->_clean_input(<$socket>);
}

sub _delay {
	my $self = shift;
	if ($self->{_mode} eq 'fixed') {
		sleep(${$self->{_range}}[0]);
	} elsif ($self->{_mode} eq 'range') {
		sleep(${$self->{_range}}[0] + int(rand(${$self->{_range}}[1])));
	}
	return;
}

# this kills any ANSI escape characters and colour codes in the supplied string:
sub _clean_input {
	my ($self, $str) = @_;
	$str =~ s/\[(.+?)m//ig;
	return $str;
}

1;
