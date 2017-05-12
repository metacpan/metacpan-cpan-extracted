############################################################################
############################################################################
##                                                                        ##
##    Copyright 2004 Stephen Patterson (steve@patter.mine.nu)             ##
##                                                                        ##
##    A cross platform perl printer interface                             ##
##    This code is made available under the perl artistic licence         ##
##                                                                        ##
##    Documentation is at the end (search for __END__) or process with    ##
##    pod2man/pod2text/pod2html                                           ##
##                                                                        ##
##    Debugging and code contributions from:                              ##
##    David W Phillips (ss0300@dfa.state.ny.us)                           ##
##    Graham K Jenkins (Graham.K.Jenkins@team.telstra.com)                ##
##                                                                        ##
############################################################################
############################################################################

# generic routines for Printer

package Printer;
$VERSION = '0.98';

use English;
use strict;
no strict 'refs';
use Carp qw(croak cluck);
use Env qw(PATH);
use vars qw(%Env @ISA);
use DynaLoader;

#############################################################################
sub new {
    # constructor
    my $type = shift;
    my %params = @_;
    my $self = {};

    # frob the system value to use linux routines below for the
    # various unices
    # see perldoc perlport for system names
    if (grep { /^$OSNAME$/  } qw(aix     bsdos  dgux   dynixptx
				 freebsd hpux   irix    rhapsody
				 machten next   openbsd dec_osf
				 svr4    sco_sv unicos  unicosmk
				 solaris sunos  netbsd  linux) ) {
	$self->{system} = 'linux';

	# search PATH for lpr, lpq, lp, lpstat (use first found)
	my %progs;
	my @PathDirs = grep {/^[^\.]/} (split /:/,$PATH);
	foreach my $dir ( @PathDirs ) {
	    foreach my $prg ( qw(lpr lpq lp lpstat) ) {
		next if exists $progs{$prg};
		my $loc = "$dir/$prg";
		-f $loc && -x $loc && ($progs{$prg}=$loc);
		}
	}
	$self->{'program'} = \%progs;

	# load the unix printer module
	require Printer::Unix;
    }


    # load system specific modules for win32
    if ($OSNAME eq "MSWin32") {
	# win32 specific modules
	#bootstrap Printer; # for XS only
	require Win32::Registry;  # to list printers
	require Win32;
	require Win32::API;
	require Win32::Printer;   # load Edgars Binans libs from wasx.net
	require Printer::Win32;
    }

    # for windows, add the windows version.
    # from http://aspn.activestate.com/ASPN/Reference/Products/ActivePerl/lib/Win32.html
    if ($OSNAME eq "MSWin32") {
	$self->{system} = 'MSWin32';
	$self->{winver} = Win32::GetOSName();
    }

    $self->{printer} = \%params;

    # die with an informative message if using an unsupported platform.
    unless ($self->{system} eq 'linux' or $self->{system} eq 'MSWin32') {
	Carp::croak "Platform $OSNAME is not yet supported. Share and enjoy.";
	  return undef;
    }

    # set orientation
    $self->{orientation} = 'portrait';
    if (defined $params{orientation} ) {
        if ($params{orientation} eq 'landscape') {
            $self->{orientation} = 'landscape'
        }
    }

    return bless $self, $type;

}
############################################################################
sub print_command {
    # allow users to specify a print command to use for a system
    my $self = shift();
    my %systems = @_;
    my %final_data;

    foreach my $system (keys %systems) {
	foreach my $opt (keys %{ $systems{$system} }) {
	    my %cmd_data = %{ $systems{$system} };
	    $final_data{$system} = \%cmd_data;
	}
    }

    $self->{print_command} = \%final_data;
}
############################################################################
sub get_unique_spool {
    # Get a filename to use as the
    # spoolfile without overwriting another file
    my ($i, $spoolfile);
    $i = 0;
    my $sys = shift;

    # linux - no TEMP env var
    if ( (! $ENV{TEMP}) && $sys eq 'linux') {
	$ENV{TEMP} = '/tmp';
    }
    # end linux

    while (-e "$ENV{TEMP}/printer-$PID.$i") {
	++$i;
    }
    if ($OSNAME eq 'MSWin32') {
	$spoolfile =  $ENV{TEMP} . '\printer-' . $PID . $i;
    } else {
	$spoolfile = $ENV{TEMP} . '/printer-' . $PID . $i;
    }
    return $spoolfile;
}
############################################################################
__END__

# documentation

=head1 NAME

Printer.pm - a low-level, platform independent printing interface
(curently Linux and MS Win32. other UNIXES should also work.)

This version includes working support for Windows 95 and some changes to
make it work with windows 2000 and XP.

=head1 SYNOPSIS

 use Printer;

 $prn = new Printer('linux' => 'lp',
	 	    'MSWin32' => 'LPT1',
		    $OSNAME => 'Printer');

or for windows network printers
 $prn  = new Printer('MSWin32' => '\\server\printer')

 $prn->print_command('linux' => {'type' => 'pipe',
			        'command' => 'lpr -P lp'},
		    'MSWin32' => {'type' => 'command',
				 'command' => 'gswin32c -sDEVICE=mswinpr2
                                 -dNOPAUSE -dBATCH $spoolfile'}
		    );

 %available_printers = $prn->list_printers;

 $prn->use_default;

 $prn->print($data);

=head2 Special options for print_command under Windows

 $prn->print_command('MSWin32' => {'type' => 'command',
                                  'command' => MS_ie});

Under Windows, the print_command method accepts the options MS_ie, MS_word
and MS_excel to print data using Internet Explorer, Word and Excel.

=head1 DESCRIPTION

A low-level cross-platform interface to system
printers.

This module is intended to allow perl programs to use and query
printers on any computer system capable of running perl. The
intention of this module is for a program to be able to use the
printer without having to know which operating system is being
used.


=head1 PLATFORMS

This code has been tested on Linux, DEC-OSF, Solaris, HP/UX windows 95 and
windows NT4.

UNIX printing works using the Linux routines. This
assumes that your print command is lpr, your queue list command is
lpq and that your printer names can be found by grepping
/etc/printcap. If it's anything different, email me with the value
of C<$OSNAME> or C<$^O> and the corrections.

=head1 USAGE


=head2 Open a printer handle

 $printer = new Printer('osname' => 'printer port');
 $printer = new Printer('MSWin32' => 'LPT1',
                        'Linux' => 'lp');

This method takes a hash to set the printer
name to be used for each operating system that this module is to
be used on (the hash keys are the values of $^O or $OSNAME for
each platform) and returns a printer handle which
is used by the other methods.

If you intend to use the C<use_default()> or C<print_command()> methods,
you don't need to supply any parameters to C<new()>.

B<Printer ports and network printers under windows>

To use a printer which is directly attached to your network, you need to
share that printer from a windows host, otherwise you will just get a file
which contains the print job in the perl script's directory.

This method dies with an error message on unsupported platforms.

=head2 Define a printer command to use

 $prn->print_command('linux' => {'type' => 'pipe',
                     'command' => 'lpr -P lp'},
                     'MSWin32' => {'type' => 'file',
                                  'command' => 'gswin32c -sDEVICE=mswinpr2
                                  -dNOPAUSE -dBATCH $spoolfile'}
                    );

This method allows you to specify your own print command to use. It
takes 2 parameters for each operating system:

B<type>

=over 4

=item * pipe - the specified print command accepts data on a pipe.

=item * file - the specified print command works on a file. The
Printer module replaces $spoolfile with a temporary filename which contains
the data to be printed

=back

B<command>

This specifies the command to be used.

=head2 Select the default printer

 $printer->use_default;

This should not be used in combination with print_command.

B<Linux>

The default printer is read from the environment variables
$PRINTER, $LPDEST, $NPRINTER, $NGPRINTER in that order, or is set to
the value of lpstat -d or is set to
"lp" if it cannot be otherwise determined. You will be warned if
this happens.

B<Win32>

The default printer is read from the registry (trust me, this just-about
works).

=head2 List available printers

 %printers = list_printers().

This returns a hash of arrays listing all available printers.
The hash keys are:

=over 4

=item * %hash{name} - printer names

=item * %hash{port} - printer ports

=back

=head2 Print

 $printer->print($data);

 $printer->print(@pling);

Print a scalar value or an array onto the print server through
a pipe (like Linux)

=head2 List queued jobs

 @jobs = $printer->list_jobs();

This returns an array of hashes where each element in the array
contains a hash containing information on a single print job. The hash
keys are: Rank, Owner, Job, Files, Size.

This code shows how you can access each element of the hash for all of
the print jobs.

=for html <PRE>

 @queue = list_jobs();
 foreach $ref (@queue) {
    foreach $field (qw/Rank Owner Job Files Size/) {
        print $field, " = ", $$ref{$field}, " ";
    }
 print "\n";
 }

=for html </PRE>

B<Windows>

The array returned is empty (for compatibility).

=head1 NOTES ON THE WINDOWS AND LINUX/UNIX PRINT SPOOLERS

(Or why this will work better on Linux/UNIX than windows)

The Linux and UNIX printing systems are based around postscript and
come with a set of ancillary programs to convert anything which should
be printable into postscript. The postscript representation of your
print job is then converted into a set of printing commands which your
printer can recognise.

Windows printing is based on applications wanting to print using windows
API calls (hideous) to create a  GDI file which is then converted
by the print spooler into printer specific commands and sent to the
physical printer.

What this means to a user of the Printer module is that on Linux/UNIX
the data passed to the print method can be anything which should be
printable, i.e. groff/troff, PostScript, plain text, TeX dvi, but on
windows the only data which can be handled by the printing system is
plain text, GDI commands or flies written in your printer's interface
language, though 0.98 adds the ability to print data using Microsoft's
Internet Explorer, Word and Excel via OLE.

=head1 BUGS

=over 4

=item * list_jobs needs writing for win32

=back

=head1 AUTHORS

Stephen Patterson (steve@patter.mine.nu)

David W Phillips (ss0300@dfa.state.ny.us)

=head1 TODO

=over 4

=item * Make list_jobs work on windows.

=item * Port to MacOS. Any volunteers?

=back

=head1 Changelog

=head2 0.98

=over 4

=item * use_default adjusted for Windows XP to pick the first available
printer.

=item * Added windows subroutines for MS IE, Word and Excel.

=item * Basic windows printing (ASCII text) migrated from a collection
of crufty code which was depending on backwards compatibility features
removed in windows 2000/XP to use Edgars Binans Win32::Printer
module. You can call $printer->print_orig() to use the pre 0.98
printing routines should you need to.

=back

=head2 0.97a, 0.97b, 0.97c, 0.97d

=over 4

=item * Sequential fixes to work with 'use strict' and '-w'

=item * list_printers and use_default updated to look at the right parts
of the registry on windows 2000.

=item * Printing an array actually works now.

=back

=head2 0.97

=over 4

=item * Bug which produced: Can't modify constant item in scalar
assignment at line 224 fixed.

=item * Unix and Win32 specific code split from the general routines.

=back

=head2 0.96

=over 4

=item * Some bugs which generated warnings when using -w fixed thanks to a 
patch from David Wheeler

=back

=head2 0.95c

=over 4

=item * Author's email address changed

=back

=head2 0.95b

=over 4

=item * Bug when using print_command with the command option on linux fixed.

=back

=head2 0.95a

=over 4

=item * sundry bug fixes

=back

=head2 0.95

=over 4

=item * added support for user defined print commands.

=back

=head2 0.94c

=over 4

=item * removed unwanted dependency on Win32::AdminMisc

=item * added support of user-defined print command

=back

=head2 0.94b

=over 4

=item * added documentation of the array input capabilities of the print() 
method

=item * windows installation fixed (for a while)

=back

=head2 0.94a

=over 4

=item * glaring typos fixed to pass a syntax check (perl -c)

=back

=head2 0.94

=over 4

=item * uses the first instance of the lp* commands from the user's path

=item * more typos fixed

=item * list_jobs almost entirely rewritten for linux like systems.

=back

=head2 0.93b

=over 4

=item * Checked and modified for dec_osf, solaris and HP/UX thanks to
data from David Phillips.

=item * Several quoting errors fixed.

=back

=head2 0.93a

=over 4

=item * list_jobs returns an array of hashes 

=item * list_printers exported into main namespace so it can be called
without an object handle (which it doesn't need anyway).

=back

=head2 0.93

=over 4

=item * Printing on windows 95 now uses a unique spoolfile which
will not overwrite an existing file.

=item * Documentation spruced up to look like a normal linux manpage.

=back

=head2 0.92

=over 4

=item * Carp based error tracking introduced.

=back

=head2 0.91

=over 4

=item * Use the linux routines for all UNIXES.
    
=back

=head2 0.9
    
Initial release version

=cut
