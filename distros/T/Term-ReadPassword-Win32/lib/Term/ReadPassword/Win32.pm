package Term::ReadPassword::Win32;

use strict;

require Exporter;

use vars qw(
	$VERSION @ISA @EXPORT @EXPORT_OK
	$SUPPRESS_NEWLINE $INPUT_LIMIT
	$USE_STARS $STAR_STRING $UNSTAR_STRING
);

@ISA = qw(Exporter);
@EXPORT = qw(read_password);
@EXPORT_OK = qw(ReadPasswd read_passwd);

$VERSION = '0.05';

if (IsWin32()) {
	eval('use Win32');
	eval('use Win32::Console');
	eval('use Win32API::File');
} else {
	eval('require Term::ReadPassword');
}

# The maximum amount of data for the input buffer to hold
$INPUT_LIMIT = 1000;

sub ReadPasswd {
	read_password(@_);
}
sub read_passwd {
	read_password(@_);
}

sub read_password {
	my ($prompt, $idle_limit, $interruptmode) = @_;
	$prompt = ''	unless defined $prompt;
	$idle_limit = 0	unless defined $idle_limit;
	$interruptmode = 0	unless defined $interruptmode;
	
	if (!IsWin32()) {
		my $interruptable = ($interruptmode > 0) ? 1 : 0;
		
		$Term::ReadPassword::SUPPRESS_NEWLINE = $SUPPRESS_NEWLINE;
		$Term::ReadPassword::INPUT_LIMIT = $INPUT_LIMIT;
		$Term::ReadPassword::USE_STARS = $USE_STARS;
		$Term::ReadPassword::STAR_STRING = $STAR_STRING;
		$Term::ReadPassword::UNSTAR_STRING = $UNSTAR_STRING;
		
		return Term::ReadPassword::read_password($prompt, $idle_limit,
				$interruptable);
	}
	
	$idle_limit *= 1000;	# sec -> msec
	
	my $CONIN = new Win32::Console(Win32::Console::STD_INPUT_HANDLE());
	my $CONOUT = new Win32::Console(Win32::Console::STD_ERROR_HANDLE());
	
	# make sure that input and output are not redirected
	my $hStdin = $CONIN->{'handle'};
	$CONIN->{'handle'} = Win32API::File::createFile('CONIN$', 'rw');
	my $hStderr = $CONOUT->{'handle'};
	$CONOUT->{'handle'} = Win32API::File::createFile('CONOUT$', 'rw');
	
	$CONOUT->Write($prompt);
	
	$CONIN->Flush();
	
	my $conmode = $CONIN->Mode();
	if ($interruptmode <= 1) {
		# disable the system for processing Ctrl+C
		$CONIN->Mode($conmode & ~Win32::Console::ENABLE_PROCESSED_INPUT());
	}
	
	# Optionally echo stars in place of password characters. 
	my $star_string = $USE_STARS ? ($STAR_STRING || '*') : '';
	my $unstar_string = $USE_STARS ? ($UNSTAR_STRING || "\b \b") : '';
	
	# the input buffer
	my $input = '';
	
	my $tick = Win32::GetTickCount();
	my $tick2 = $tick;
keyin:
	while (1) {
		while ($CONIN->GetEvents() == 0) {
			Win32::Sleep(10);
			$tick2 = Win32::GetTickCount();
			if ($idle_limit && (DiffTick($tick2, $tick) > $idle_limit)) {
				# timeout
				undef $input;
				last keyin;
			}
		}
		$tick = $tick2;
		
		# read console
		my ($evtype, $keydown, undef, $keycode, undef, $ch, undef)
				= $CONIN->Input();
		
		# next if not a keydown event
		next	if ($evtype != 1 || !$keydown);
		
		$ch = 0x7f	if ($keycode == 0x2e);		# Del
		next	if ($ch == 0x00);				# Special Keys
		$ch &= 0xff;	# for multibyte chars
		
		if ($ch == 0x0d || $ch == 0x0a) {			# Enter
			# end
			last;
		} elsif ($ch == 0x08 || $ch == 0x7f) {		# BS, Del
			if (length($input) > 0) {
				# delete the last char
				#
				# BUG: If the last char is multibyte character,
				#      this doesn't work well.
				chop $input;
				
				$CONOUT->Write($unstar_string);
			}
		} elsif ($ch == 0x15) {						# Ctrl+U
			$CONOUT->Write($unstar_string x length($input));
			$input = '';			# clear all
		} elsif (($interruptmode > 0)
				&& ($ch == 0x1b || $ch == 0x03)) {	# Esc, Ctrl+C
			# cancel
			undef $input;
			last;
		} else {
			# normal chars
			$input .= chr($ch);
			$CONOUT->Write($star_string);
		}
		if (length($input) > $INPUT_LIMIT) {
			$input = substr($input, 0, $INPUT_LIMIT);
		}
	}
	
	$CONOUT->Write("\n")	 unless $SUPPRESS_NEWLINE;
	
	# restore console mode
	$CONIN->Mode($conmode);
	
	# restore console handles
	Win32API::File::CloseHandle($CONIN->{'handle'});
	$CONIN->{'handle'} = $hStdin;
	Win32API::File::CloseHandle($CONOUT->{'handle'});
	$CONOUT->{'handle'} = $hStderr;
	
	$CONIN = undef;
	close STDIN;
	open STDIN, '+<CONIN$';
	return $input;
}

sub DiffTick {
	my ($tick1, $tick2) = @_;
	$tick1 &= 0xFFFFFFFF;
	$tick2 &= 0xFFFFFFFF;
	
	if ($tick1 >= $tick2) {
		return $tick1 - $tick2;
	} else {
		return 0xFFFFFFFF + 1 + $tick1 - $tick2;
	}
}

sub IsWin32 {
	return ($^O eq 'MSWin32');
}

1;

__END__

=head1 NAME

Term::ReadPassword::Win32 - Asking the user for a password (for Win32)

=head1 SYNOPSIS

  use Term::ReadPassword::Win32;
  while (1) {
    my $password = read_password('password: ');
    redo unless defined $password;
    if ($password eq 'flubber') {
      print "Access granted.\n";
      last;
    } else {
      print "Access denied.\n";
      redo;
    }
  }

=head1 DESCRIPTION

This module lets you ask the user for a password from the keyboard
just as L<Term::ReadPassword|Term::ReadPassword>.

Using L<Term::ReadPassword|Term::ReadPassword> is a good way to make password prompts,
but it doesn't work with ActivePerl under Windows.
So I wrote this module.

You can use this module under Windows or Unix.
If you use this under Windows, Win32::* modules are required.
If you use this under Unix, this acts as a wrapper to L<Term::ReadPassword|Term::ReadPassword>.

The B<Term::ReadPassword::Win32::read_password> function is almost same as
B<Term::ReadPassword::read_password> function.

The first and second parameters are just same.
The first one is a prompt message, and the second one is timeout value.

The third parameter is different from B<Term::ReadPassword::read_password>.

If the third parameter is 0, Ctrl+C will be entered into the input buffer
just as any other character.

If the third parameter is 1, the input operation is terminated
when the user types Ctrl+C or Esc.

If the third parameter is 2, the input operation is terminated
when the user types Esc.
If the user types Ctrl+C, the program may be terminated.

If the user types Ctrl+U, the input buffer will be cleared.

=head1 BUG

Multibyte characters are not treated properly. (When you want to delete
a multibyte character, you must type BackSpace more than once.)

=head1 SEE ALSO

L<Term::ReadPassword>, L<Term::Getch>

=head1 COPYRIGHT

Copyright (C) 2005 Ken Takata <kentkt@anet.ne.jp>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DOWNLOAD

You can download the latest version from http://webs.to/ken/ (Japanese page)

=cut

