package Term::GnuScreen;

use Moo;
use File::Temp qw(tmpnam);
use autodie qw(:all);
use File::Which;
use IO::CaptureOutput qw(capture);

our $VERSION = '0.05';

BEGIN {

	no strict 'refs';

	my @commands = ( qw( acladd aclchg acldel aclgrp aclumask activity addacl allpartial
	altscreen at attrcolor autodetach autonuke backtick bce bell_msg 
	bindkey blanker blankerprg break breaktype bufferfile c1 caption chacl
	charset clear colon command compacthist console copy copy_reg
	crlf debug defautonuke defbce defbreaktype defc1 defcharset defencoding
	defescape defflow defgr defhstatus deflog deflogin defmode defmonitor
	defnonblock defobuflimit defscrollback defshell defsilence defslowpaste
	defutf8 defwrap defwritelock defzombie detach digraph dinfo displays
	dumptermcap echo encoding escape eval fit flow focus gr 
	hardcopy_append hardcopydir hardstatus height help history hstatus idle
	ignorecase info ins_reg lastmsg license lockscreen log logfile login
	logtstamp mapdefault mapnotnext maptimeout markkeys maxwin monitor
	msgminwait msgwait multiuser nethack next nonblock number obuflimit only
	other partial password paste pastefont pow_break pow_detach pow_detach_msg
	prev printcmd process quit readbuf readreg redisplay register remove
	removebuf reset resize screen scrollback select sessionname setenv setsid
	shell shelltitle silence silencewait sleep slowpaste source sorendition
	split startup_message stuff su suspend term termcap terminfo termcapinfo
	time title unsetenv utf8 vbell vbell_msg vbellwait version wall
	width windowlist windows wrap writebuf writelock xoff xon zmodem zombie ) );

	for my $name (@commands) {
		*{__PACKAGE__ . "::$name"} = sub { shift->send_command($name,@_) }
	}

	my @rcommands = ( qw( bind kill meta chdir exec umask) );

	for my $name (@rcommands) {
		*{__PACKAGE__ . "::s$name"} = sub { shift->send_command($name,@_) }
	}
}

has session    => (is => 'rw'  );
has window     => (is => 'rw', default => sub { 0 } );
has executable => (is => 'rw', default => sub { which("screen") } );
has create     => (is => 'ro', default => sub { 0 } );
has debugging  => (is => 'rw', default => sub { 0 } );

sub BUILD {
	my ($self) = @_;
	if ($self->create) {
		if (!$self->session) {
			$self->session("term_gnuscreen.$$" . int(rand(10000)));
		}
		$self->call_screen('-m','-d');
	}
	return;
}

sub send_command {
	my ($self,$cmd,@args) = @_;
	die "No command supplied while trying to call screen via -X."
		if !$cmd;
	return $self->call_screen('-X', $cmd, @args) if $cmd;
}

sub call_screen {
	my ($self,@parameter) = @_;
	my @screencmd = ( $self->executable );
	push @screencmd, '-S', $self->session if defined $self->session;
	push @screencmd, '-p', $self->window  if defined $self->window;
	push @screencmd, @parameter;

	if ($self->debugging) {
		print STDERR "Command: " . join(" ",@screencmd) . "\n";
	}

	my ($stdout,$stderr);
	eval { 
		capture { system(@screencmd) } \$stdout, \$stderr;
		1;
	} or do {
		my $err;# = $!;
		$err = $stderr if defined $stderr;
		$err = $stdout if defined $stdout; # '*err*, stdout seems to be actual more helpful
		die "$err";
	};
	return 1;
}

sub hardcopy {
	my ($self,$file) = @_;
	if (!$file) {
		$file = tmpnam();
	}
	$self->send_command('hardcopy',$file);
	return $file;
}

1;

__END__

=head1 NAME

Term::GnuScreen - control GNU screen

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

Term::GnuScreen provides a simple interface to control a GNU screen
session via its command line interface.

    use Term::GnuScreen;

    my $screen = Term::GnuScreen->new();
    $screen->windowlist;
    $screen->hardcopy('/tmp/my_hardcopy');

=head1 CONSTRUCTION

=over 4

=item session

Sets the name of the screen session to which commands are send. If you
also set C<create> to a true value, this will become the new name of your
screen session. See I<-S> option for screen for a further discussion of
this argument.

=item create

If create is set to a true value, a new screen session is created
and detached automatically. If you do not provide a session name via
I<session>, this module generates one by calling C<"term_gnuscreen" . $$
. int(rand(10000))>. Settings this value after object creation has no
effect at the moment.

The newly created session will not be terminated after program execution.

=item window

Preselects a window. Defaults to 0. See I<-p> option of screen for a
further discussion of this argument.

=item executable

Return or set the screen binary to call. Defaults to the binary found
by C<File::Which::which("screen")>.

=item debugging

If debugging is set to a true value, all commands are printed to STDERR.

=back

=head1 METHODS

Term::GnuScreen implements all commands as stated in the texinfo document
shipped with GNU screen. Whenever you call a command it is send via GNU
screens -X parameter to the first running screen session and its current
window. You can change session and window with the according object
methods and construction parameters. Unless listed here, all remaining
arguments are handed over to screen without further modification.

The five commands bind, kill, meta, chdir, exec and umask are prefixed
with a I<s> (sbind, smeta, schdir, sexec and sumask) to distinguish them
from the built-ins with the same name.

=head2 call_screen

This command is the working horse of Term::GnuScreen. It simply builds
the command line to call and execute it.

=head2 send_command

Calls call_screen with the I<-X> and all supplied parameters. Most
functions are implemented by this method.

=head2 hardcopy

Write a hardcopy of the current window to a temporary file and returns
the filename unless the filename is supplied as first argument. If
the supplied filename is not absolute, the file is written relative to
C<hardcopydir>.

=head1 ERROR HANDLING

Simple dies in case screen -X did not return with a return value of
zero. Either $!, STDERR or STDOUT (which seems to be more helpful
most times) are provided as error message for further investigation.

=head1 AUTHOR

Mario Domgoergen E<lt>mdom@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

It seems not to be possible to question a specific screen session
about its state, so this module basically just sends commands to a
screen session without knowing if the command succeeded or was even
syntactically correct.

This module needs a lot more testing.

Please report any bugs or feature requests to
C<bug-term-gnuscreen at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-GnuScreen>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::GnuScreen

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-GnuScreen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Term-GnuScreen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Term-GnuScreen>

=item * Search CPAN

L<http://search.cpan.org/dist/Term-GnuScreen>

=back


=head1 ACKNOWLEDGEMENTS

L<screen>

=head1 COPYRIGHT & LICENSE

Copyright 2013 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
