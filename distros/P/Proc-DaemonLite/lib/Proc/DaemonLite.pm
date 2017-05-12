############################################################
#
#   $Id: DaemonLite.pm 946 2007-02-11 15:14:13Z nicolaw $
#   Proc::DaemonLite - Simple server daemonisation module
#
#   Copyright 2006,2007 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package Proc::DaemonLite;
# vim:ts=4:sw=4:tw=78

use strict;
use Exporter;
use Carp qw(croak cluck carp);
use POSIX qw(:signal_h setsid WNOHANG);
use File::Basename qw(basename);
use IO::File;
use Cwd qw(getcwd);
use Sys::Syslog qw(:DEFAULT setlogsock);

use constant PIDPATH  => -d '/var/run' && -w _ ? '/var/run' : '/var/tmp';
use constant FACILITY => 'local0';

use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA
			$DEBUG %CHILDREN $SCRIPT);

BEGIN { use vars qw($SCRIPT); $SCRIPT = $0; }

$VERSION = '0.01' || sprintf('%d', q$Revision: 946 $ =~ /(\d+)/g);
$DEBUG = $ENV{DEBUG} ? 1 : 0;

@ISA = qw(Exporter);
@EXPORT_OK = qw(&init_server &kill_children &launch_child &do_relaunch
		&log_debug &log_notice &log_warn &log_die &log_info %CHILDREN);
@EXPORT = qw(&init_server);
%EXPORT_TAGS = (all => \@EXPORT_OK);

# These are private
my ($pid, $pidfile, $saved_dir, $CWD);

sub init_server {
	TRACE('init_server()');
	my ($user, $group);
	($pidfile, $user, $group) = @_;
	$pidfile ||= _getpidfilename();
	my $fh = _open_pid_file($pidfile);
	_become_daemon();
	print $fh $$;
	close $fh;
	_init_log();
	_change_privileges($user, $group) if defined $user && defined $group;
	return $pid = $$;
}

sub _become_daemon {
	TRACE('_become_daemon()');
	croak "Can't fork" unless defined(my $child = fork);
	exit(0) if $child;   # parent dies;
	POSIX::setsid();     # become session leader
	open(STDIN,  "</dev/null");
	open(STDOUT, ">/dev/null");
	open(STDERR, ">&STDOUT");
	$CWD = Cwd::getcwd;  # remember working directory
	chdir('/');          # change working directory
	umask(0);            # forget file mode creation mask
	$ENV{PATH} = '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin';
	delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
	$SIG{CHLD} = \&_reap_child;
}

sub _change_privileges {
	TRACE('_change_privileges()');
	my ($user, $group) = @_;
	my $uid = getpwnam($user)  or die "Can't get uid for $user\n";
	my $gid = getgrnam($group) or die "Can't get gid for $group\n";
	$) = "$gid $gid";
	$( = $gid;
	$> = $uid;           # change the effective UID (but not the real UID)
}

sub launch_child {
	TRACE('launch_child()');
	my $callback = shift;
	my $home     = shift;

	my $signals  = POSIX::SigSet->new(SIGINT, SIGCHLD, SIGTERM, SIGHUP);
	sigprocmask(SIG_BLOCK, $signals);    # block inconvenient signals
	log_die("Can't fork: $!") unless defined(my $child = fork());

	if ($child) {
		$CHILDREN{$child} = $callback || 1;
	} else {
		$SIG{HUP} = $SIG{INT} = $SIG{CHLD} = $SIG{TERM} = 'DEFAULT';
		_prepare_child($home);
	}
	sigprocmask(SIG_UNBLOCK, $signals);    # unblock signals

	return $child;
}

sub _prepare_child {
	TRACE('_prepare_child()');
	my $home = shift;
	if ($home) {
		local ($>, $<) = ($<, $>);         # become root again (briefly)
		chdir($home)  || croak "chdir(): $!";
		chroot($home) || croak "chroot(): $!";
	}
	$< = $>;                               # set real UID to effective UID
}

sub _reap_child {
	TRACE('_reap_child()');
	while ((my $child = waitpid(-1, WNOHANG)) > 0) {
		$CHILDREN{$child}->($child) if ref $CHILDREN{$child} eq 'CODE';
		delete $CHILDREN{$child};
	}
}

sub kill_children {
	TRACE('kill_children()');
	DUMP('%CHILDREN',\%CHILDREN);
	kill TERM => keys %CHILDREN;

	# wait until all the children die
	sleep while %CHILDREN;
}

sub do_relaunch {
	TRACE('do_relaunch()');
	$> = $<;    # regain privileges
	chdir $1 if $CWD =~ m!([./a-zA-z0-9_-]+)!;
	croak "bad program name" unless $SCRIPT =~ m!([./a-zA-z0-9_-]+)!;
	my $program = $1;
	unlink($pidfile);

	my @perl = ($^X);
	push @perl, '-T' if ${^TAINT} eq 1;
	push @perl, '-t' if ${^TAINT} eq -1;
	push @perl, '-w' if $^W;

	exec(@perl, $program, @ARGV) or croak "Couldn't exec: $!";
}

sub _init_log {
	TRACE('_init_log()');
	Sys::Syslog::setlogsock('unix');
	my $basename = File::Basename::basename($SCRIPT);
	openlog($basename, 'pid', FACILITY);
	$SIG{__WARN__} = \&log_warn;
	$SIG{__DIE__}  = \&log_die;
}

sub log_debug  { TRACE('log_debug()');  syslog('debug',   _msg(@_)) }
sub log_notice { TRACE('log_notice()'); syslog('notice',  _msg(@_)) }
sub log_warn   { TRACE('log_warn()');   syslog('warning', _msg(@_)) }
sub log_info   { TRACE('log_info()');   syslog('info',    _msg(@_)) }

sub log_die {
	TRACE('log_die()');
	Sys::Syslog::syslog('crit', _msg(@_)) unless $^S;
	die @_;
}

sub _msg {
	TRACE('_msg()');
	my $msg = join('', @_) || "Something's wrong";
	my ($pack, $filename, $line) = caller(1);
	$msg .= " at $filename line $line\n" unless $msg =~ /\n$/;
	$msg;
}

sub _getpidfilename {
	TRACE('_getpidfilename()');
	my $basename = File::Basename::basename($SCRIPT, '.pl');
	return PIDPATH . "/$basename.pid";
}

sub _open_pid_file {
	TRACE('_open_pid_file()');
	my $file = shift;

	if (-e $file) {    # oops.  pid file already exists
		my $fh = IO::File->new($file) || return;
		my $pid = <$fh>;
		croak "Invalid PID file" unless $pid =~ /^(\d+)$/;
		croak "Server already running with PID $1" if kill 0 => $1;
		cluck "Removing PID file for defunct server process $pid.\n";
		croak "Can't unlink PID file $file" unless -w $file && unlink $file;
	}

	return IO::File->new($file, O_WRONLY | O_CREAT | O_EXCL, 0644)
		or die "Can't create $file: $!\n";
}

END {
	$> = $<;    # regain privileges
	unlink $pidfile if defined $pid and $$ == $pid;
}

sub TRACE {
	return unless $DEBUG;
	log_debug($_[0]);
	warn(shift());
}

sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		my $msg = shift().': '.Data::Dumper::Dumper(shift());
		log_debug($msg);
		warn($msg);
	}
}

1;

=pod

=head1 NAME

Proc::DaemonLite - Simple server daemonisation module

=head1 SYNOPSIS

 use strict;
 use Proc::DaemonLite qw(:all);
 
 my $pid = init_server();
 log_warn("Forked in to background PID $pid");
 
 $SIG{__WARN__} = \&log_warn;
 $SIG{__DIE__} = \&log_die;
 
 for my $cid (1..4) {
     my $child = launch_child();
     if ($child == 0) {
         log_warn("I am child PID $$") while sleep 2;
         exit;
     } else {
         log_warn("Spawned child number $cid, PID $child");
     }
 }
 
 sleep 20;
 kill_children();

=head1 DESCRIPTION

Proc::DaemonLite is a basic server daemonisation module that trys
to cater for most basic Perl daemon requirements.

The POD for this module is incomplete, as is some of the tidying
of the code. It is however fully functional. This is a pre-release
in order to reserve the namespace before it becomes unavailable.

=head1 EXPORTS

By default only I<init_server()> is exported. The export tag I<all> will export
the following: I<init_server()>, I<kill_children()>,
I<launch_child()>, I<do_relaunch()>, I<log_debug()>, I<log_notice()>,
I<log_warn()>, I<log_info()>, I<log_die()> and I<%CHILDREN>.

=head2 init_server()

 my $pid = init_server($pidfile, $user, $group);

=head2 launch_child()

 my $child_pid = launch_child($callback, $home);

=head2 kill_children()

 kill_children();

Terminate all children with a I<TERM> signal.

=head2 do_relaunch()

 do_relaunch()

Attempt to start a new incovation of the current script.

=head2 log_debug()

 log_debug(@messages);

=head2 log_info()

 log_info(@messages);

=head2 log_notice()

 log_notice(@messages);

=head2 log_warn()

 log_warn(@messages);

=head2 log_die()

 log_die(@messages);

=head2 %CHILDREN

I<%CHILDREN> is a hash of all child processes keyed by PID. Children
with registered callbacks will contain a reference to their callback
in this hash.

=head1 SEE ALSO

L<Proc::Deamon>, L<Proc::Fork>, L<Proc::Application::Daemon>,
L<Proc::Forking>, L<Proc::Background>, L<Net::Daemon>,
L<POE::Component::Daemon>, L<http://www.modperl.com/perl_networking/>,
L<perlfork>

=head1 VERSION

$Id: DaemonLite.pm 946 2007-02-11 15:14:13Z nicolaw $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

If you like this software, why not show your appreciation by sending the
author something nice from her
L<Amazon wishlist|http://www.amazon.co.uk/gp/registry/1VZXC59ESWYK0?sort=priority>? 
( http://www.amazon.co.uk/gp/registry/1VZXC59ESWYK0?sort=priority )

Original code written by Lincoln D. Stein, featured in "Network Programming
with Perl". L<http://www.modperl.com/perl_networking/>

Released with permission of Lincoln D. Stein.

=head1 COPYRIGHT

Copyright 2006,2007 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut


__END__



