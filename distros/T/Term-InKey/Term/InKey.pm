package Term::InKey;

# Ariel Brosh (R.I.P), November 2001, for Raz Information Systems
# Now manitained by Oded S. Resnik Raz Information Systems

require Exporter;
use strict qw(vars subs);
use vars qw(@ISA @EXPORT $VERSION $WIN32CONSOLE $BAD_CLS $BAD_RKEY $TER_CLS);
@ISA = qw(Exporter);
@EXPORT = qw(ReadKey Clear ReadPassword);

$VERSION = '1.04';

sub WinSetConsole {
	return $WIN32CONSOLE if $WIN32CONSOLE;
	require Win32::Console;
	import Win32::Console;
	{
		local *STDERR;
		open STDERR, ">/dev/null";
		$WIN32CONSOLE = Win32::Console->
		new(Win32::Console->STD_INPUT_HANDLE);
	}
	return $WIN32CONSOLE;
}

sub WinReadKey {
my $y;
eval {
	if(&WinSetConsole)
		{
		my $mode = $WIN32CONSOLE->Mode || die $^E;
                my $newmode = $mode;
		$newmode &= ~(&ENABLE_LINE_INPUT | &ENABLE_ECHO_INPUT);
    		$WIN32CONSOLE->Mode($newmode) || die $^E;
		$WIN32CONSOLE->Flush || die $^E;

		$y = $WIN32CONSOLE->InputChar(1);
		$WIN32CONSOLE->Flush || die $^E;
    		$WIN32CONSOLE->Mode($mode) || die $^E;
		die $^E unless defined($y);
		}
	};
	die "Not implemented on $^O: $@" if $@;
$y;
}

sub BadReadKey {
 if ($^O !~ /Win32/i) {
	$BAD_RKEY =1;
	system "stty raw -echo";
	my $ch = getc;
	system "stty -raw echo";
	$ch;
	}
}

sub ReadKey {
	if ($^O =~ /Win32/i) {
		return &WinReadKey;
	};

	my $save;

	&BadReadKey if $BAD_RKEY;

	eval {
                require POSIX; 
		import POSIX;

		$save = new POSIX::Termios;
	};
	return &BadReadKey if $@;

	$save->getattr(0);

	my $x = new POSIX::Termios;

	$x->getattr(0);

	my %flags;

	&getit($x, \%flags);

	# +raw
	{
		$flags{'i'} &= ~(&IGNBRK|&BRKINT|&PARMRK|&ISTRIP
                                   |&INLCR|&IGNCR|&ICRNL|&IXON);
		$flags{'o'} &= ~&OPOST;
		$flags{'l'} &= ~(&ECHO|&ECHONL|&ICANON|&ISIG|&IEXTEN);
		$flags{'c'} &= ~(&CSIZE|&PARENB);
		$flags{'c'} |= &CS8;
	}
	&setit($x, \%flags);

	$x->setattr(0);

	my $ch = getc;

	$save->setattr(0);

	$ch;
}

sub getit {
	my ($x, $flags) = @_;
	foreach (qw(i o c l)) {
		my $meth = $x->can("get${_}flag");
		$flags->{$_} = &$meth($x);
	}
}

sub setit {
	my ($x, $flags) = @_;
	foreach (qw(i o c l)) {
		my $meth = $x->can("set${_}flag");
		&$meth($x, $flags->{$_});
	}
}

sub WinClear {

&BadClear if $BAD_CLS;

eval {
	if(&WinSetConsole)
		{
		local *STDERR;
		open STDERR, ">/dev/null";
		$WIN32CONSOLE->Cls || die $^E;
		$WIN32CONSOLE->Display;
		}
		else {
			&BadClear;
		};
	};
	&BadClear if $@;
}


sub BadClear {
	$BAD_CLS = 1;
	if ($^O =~ /Win/i || $^O =~ /Dos/i) {
		system "cls";
		return;
	}

	system "clear";
}

sub Clear {

	&BadClear if $BAD_CLS;

	if ($^O =~ /Win32/i || $^O =~ /Dos/i) {
		&WinClear;
		return;
	}
	

	unless ($TER_CLS) {

		my $speed = 9600;

		eval {
                        require POSIX;
			import POSIX;

			my $x = new POSIX::Termios;
			POSIX::Termios::getattr($x, 0);
			$speed = $x->getospeed;
		};

		eval {
                        require Term::Cap;
			my $emu = $ENV{'TERM'} || 'vt100';
		        my $term = Term::Cap->Tgetent({'TERM' => $emu,
				'OSPEED' => $speed});
		        $TER_CLS = $term->Tputs('cl');
		};
	}

	unless ($TER_CLS) {
		&BadClear;
		return;
	}

	my $desc = select;
	select STDOUT;
	my $pipe = $|;
	$| = 1;
	print $TER_CLS;

	$| = $pipe;
	select $desc;
}

sub ReadPassword {
	my ($opt) = @_;
	my $bullet = "*";
	my ($bs, $ws, $nl) = ("\b", " ", "\n");
	if ($opt) {
	$bullet = $opt if length($opt) == 1;
  	($bs, $ws, $nl, $bullet)
                        = () if ($opt =~ /-\d+/);
	}
	my $save = $|;
	$| = 1;
	my $pass = '';
	for (;;) {
		my $ch = &ReadKey;
		if ($ch eq "\3") {
			$pass = "";
			$ch = "\n";
		}
		if ($ch =~ /[\r\n]/) {
			$| = $save;
			print $nl if $nl;
			return $pass;
		}
		if ($ch =~ /[\b\x7F]/) {
			next unless $pass;
			chop $pass;
			print "$bs$ws$bs" if $bs;
			next;
		}
		if ($ch eq "\025") {
			my $len = length($pass);
			if ($ws) {
				my $res =  ($bs x $len) . ($ws x $len) . 
					($bs x $len);
				print "$res";
			}
			$pass = '';
		}
		if (ord($ch) < 32) {
			print "\7";
			next;
		}
		$pass .= $ch;
		print $bullet if $bullet;
	}
}


1;
__END__

=head1 NAME

Term::InKey - Perl extension for clearing the screen and receiving a keystroke.

=head1 SYNOPSIS

        use Term::InKey;

        print "Press any key to clear the screen: ";
        $x = &ReadKey;
        &Clear;
        print "You pressed $x\n";

=head1 DESCRIPTION

This module implements Clear() to clear screen and ReadKey() to receive
a keystroke, on UNIX and Win32 platforms. As opposed to B<Term::ReadKey>,
it does not contain XSUB code and can be easily installed on Windows boxes.

=head1 FUNCTIONS

=over 4

=item *

Clear

Clear the screen.

=item *

ReadKey

Read one keystroke.

=item *

ReadPassword

Read a password, displaying asterisk instead of the characters readed.
Deleting one character back (DEL) and erasing the buffer (^U) are
supported.
This function accepts one argument. It can be an alternate char
for displaying other than an asterisk, or if a negative number,
suppresses output to the screen and only receives input.

=back

=head1 TODO

Write a function to receive a keystroke with time out. Easy with select()
on UNIX.

=head1 COMPLIANCE

This module works only on UNIX systems and Win32 systems.

=head1 AUTHOR

This module was written by Ariel Brosh (R.I.P), 
November 2001, for RAZ Information Systems.

Now maintained by Oded S. Resnik B<razinf@cpan.org> 

=head1 COPYRIGHT

Copyright (c) 2001, 2002, 2003, 2004 RAZ Information Systems Ltd.
http://www.raz.co.il/

This package is distributed under the same terms as Perl itself, see the
Artistic License on Perl's home page.

=head1 SEE ALSO

L<stty>, L<tcsetattr>, L<termcap>, L<Term::Cap>, L<POSIX>, L<Term::ReadKey>, L<Term::ReadPassword>.

=cut
