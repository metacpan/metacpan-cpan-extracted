
=head1 NAME

Net::Printer - Perl extension for direct-to-lpd printing.

=head1 SYNOPSIS

  use Net::Printer;

  # Create new Printer Object
  $lineprinter = new Net::Printer(
                                  filename    => "/home/jdoe/myfile.txt",
                                  printer     => "lp",
                                  server      => "printserver",
                                  port        => 515,
                                  lineconvert => "YES"
                                  );

  # Print the file
  $result = $lineprinter->printfile();

  # Optionally print a file
  $result = $lineprinter->printfile("/home/jdoe/myfile.txt");

  # Print a string
  $result =
    $lineprinter->printstring("Smoke me a kipper, I'll be back for breakfast.");

  # Did I get an error?
  $errstr = $lineprinter->printerror();

  # Get Queue Status
  @result = $lineprinter->queuestatus();

=head1 DESCRIPTION

Perl module for directly printing to a print server/printer without
having to create a pipe to either lpr or lp.  This essentially mimics
what the BSD LPR program does by connecting directly to the line
printer printer port (almost always 515), and transmitting the data
and control information to the print server.

Please note that this module only talks to print servers that speak
BSD.  It will not talk to printers using SMB, SysV, or IPP unless they
are set up as BSD printers.  CUPS users will need to set up
B<cups-lpd> to provide legacy access. ( See L</"Using Net::Printer
with CUPS"> )

=cut

use strict;
use warnings;

package Net::Printer;

our @ISA = qw( Exporter );

use 5.006;

use Carp;
use File::Temp;
use FileHandle;
use IO::Socket;
use Sys::Hostname;

our $VERSION = '1.12';

# Exported functions
our @EXPORT = qw( printerror printfile printstring queuestatus );

# ----------------------------------------------------------------------

=head1 METHODS

=head2 new

Constructor returning Net::Printer object

=head3 Parameters

A hash with the following keys:

=over

=item  * filename

[optional] absolute path to the file you wish to print.

=item  * printer

[default: "lp"] Name of the printer you wish to print to.

=item  * server

[default: "localhost"] Name of the printer server

=item  * port

[default: 515] The port you wish to connect to

=item  * lineconvert

[default: "NO"] Perform LF -> LF/CR translation

=item  * rfc1179

[default: "NO"] Use RFC 1179 compliant source address.  Default
"NO". see L<"RFC-1179 Compliance Mode and Security Implications">.

=back

=head3 Returns

The blessed object

=cut

sub new
{

        my (%vars) = ("filename"    => "",
                      "lineconvert" => "No",
                      "printer"     => "lp",
                      "server"      => "localhost",
                      "port"        => 515,
                      "rfc1179"     => "No",
                      "debug"       => "No",
                      "timeout"     => 15,
        );

        # Parameter(s);
        my $type   = shift;
        my %params = @_;
        my $self   = {};

        # iterate through each variable
        foreach my $var (keys %vars) {
                if   (exists $params{$var}) { $self->{$var} = $params{$var}; }
                else                        { $self->{$var} = $vars{$var}; }
        }

        $self->{errstr} = undef;

        return bless $self, $type;

}          # new

=head2 printerror

Getter for error string, if any.

=head3 Returns

String containing error text, if any.  Undef otherwise.

=cut

sub printerror
{

        # Parameter(s)
        my $self = shift;
        return $self->{errstr};

}          # printerror()

=head2 printfile

Transmits the contents of the specified file to the print server

=head3 Parameters

=over

=item  * file

Path to file to print

=back

=head3 Returns

1 on success, undef on fail

=cut

sub printfile
{
        my $dfile;

        my $self  = shift;
        my $pfile = shift;

        $self->_logDebug("invoked ... ");

        # Are we being called with a file?
        $self->{filename} = $pfile if ($pfile);
        $self->_logDebug(sprintf("Filename is %s", $self->{filename}));

        # File valid?
        if (!($self->{filename}) || (!-e $self->{filename})) {

                # Bad file name
                $self->_lpdFatal(
                                 sprintf("Given filename (%s) not valid",
                                         $self->{filename}));
                return undef;

        } elsif (uc($self->{lineconvert}) eq "YES") {

                # do newline coversion
                $dfile = $self->_nlConvert();

        } else {

                # just set $dfile to the filename
                $dfile = $self->{filename};
        }

        $self->_logDebug(sprintf("Real Data File    %s", $dfile));

        # Create Control File
        my @files = $self->_fileCreate();

        $self->_logDebug(sprintf("Real Control File %s", $files[0]));
        $self->_logDebug(sprintf("Fake Data    File %s", $files[1]));
        $self->_logDebug(sprintf("Fake Control File %s", $files[2]));

        # were we able to create control file?
        unless (-e $files[0]) {
                $self->_lpdFatal("Could not create control file\n");
                return undef;
        }

        # Open Connection to remote printer
        my $sock = $self->_socketOpen();

        # did we connect?
        if ($sock) { $self->{socket} = $sock; }
        else {
                $self->_lpdFatal("Could not connect to printer: $!\n");
                return undef;
        }

        # initialize LPD connection
        my $resp = $self->_lpdInit();

        # did we get a response?
        unless ($resp) {
                $self->_lpdFatal(
                                 sprintf("Printer %s on %s not ready!\n",
                                         $self->{printer}, $self->{server}));
                return undef;
        }

        $resp = $self->_lpdSend($files[0], $dfile, $files[2], $files[1]);

        unless ($resp) {
                $self->_lpdFatal("Error Occured sending data to printer\n");
                return undef;
        }

        # Clean up
        $self->{socket}->shutdown(2);

        unlink $files[0];
        unlink $dfile if (uc($self->{lineconvert}) eq "YES");

        return 1;

}          # printfile()

=head2 printstring

Prints the given string to the printer.  Note that each string given
to this method will be treated as a separate print job.

=head3 Parameters

=over

=item  * string

String to send to print queue

=back

=head3 Returns

1 on succes, undef on fail

=cut

sub printstring
{

        my $self = shift;
        my $str  = shift;

        # Create temporary file
        my $tmpfile = $self->_tmpfile();
        my $fh      = FileHandle->new("> $tmpfile");

        # did we connect?
        unless ($fh) {
                $self->_lpdFatal("Could not open $tmpfile: $!\n");
                return undef;
        }

        # ... and print it out to our file handle
        print $fh $str;
        $fh->close();
        return undef unless $self->printfile($tmpfile);

        # otherwise return
        unlink $tmpfile;

        return 1;

}          # printstring()

=head2 queuestatus

Retrives status information from print server

=head3 Returns

Array containing queue status

=cut

sub queuestatus
{

        my @qstatus;
        my $self = shift;

        # Open Connection to remote printer
        my $sock = $self->_socketOpen();

        # did we connect?
        unless ($sock) {
                push( @qstatus,
                      sprintf("%s\@%s: Could not connect to printer: $!\n",
                              $self->{printer}, $self->{server},
                      ));
                return @qstatus;
        }

        # store the socket
        $self->{socket} = $sock;

        # Note that we want to handle remote lpd response ourselves
        $self->_lpdCommand(sprintf("%c%s\n", 4, $self->{printer}), 0);

        # Read response from server and format
        eval {
                local $SIG{ALRM} = sub { die "timeout\n" };
                alarm 15;
                $sock = $self->{socket};
                while (<$sock>) {
                        s/($_)/$self->{printer}\@$self->{server}: $1/;
                        push(@qstatus, $_);
                }
                alarm 0;
                1;
        };

        # did we get an error retrieving status?
        if ($@) {
                push( @qstatus,
                      sprintf(
"%s\@%s: Timed out getting status from remote printer\n",
                              $self->{printer}, $self->{server})
                ) if ($@ =~ /timeout/);
        }

        # Clean up
        $self->{socket}->shutdown(2);
        return @qstatus;
}          # queuestatus()

# Private Methods
# ----------------------------------------------------------------------

# Method: _logDebug
#
# Displays informative messages ... meant for debugging.
#
# Parameters:
#
#   msg    - message to display
#
# Returns:
#
#   none
sub _logDebug
{

        # Parameter(s)
        my $self = shift;
        my $msg  = shift;

        # strip newlines
        $msg =~ s/\n//;

        # get caller information
        my @a = caller(1);

        printf("DEBUG-> %-32s: %s\n", $a[3], $msg)
            if (uc($self->{debug}) eq "YES");

}          # _logDebug()

# Method: _lpdFatal
#
# Gets called when there is an unrecoverable error.  Sets error
# object for debugging purposes.
#
# Parameters:
#
#   msg - Error message to log
#
# Returns:
#
#   1
sub _lpdFatal
{

        my $self = shift;
        my $msg  = shift;

        # strip newlines
        $msg =~ s/\n//;

        # get caller information and b uild error string
        my @a = caller();
        my $errstr = sprintf("ERROR:%s[%d]: %s", $a[0], $a[2], $msg,);
        $self->{errstr} = $errstr;

        # carp it
        carp "$errstr\n";

        return 1;

}          # _lpdFatal()

# Method: _tmpfile
#
# Creates temporary file returning its name.
#
# Parameters:
#
#   none
#
# Returns:
#
#   name of temporary file
sub _tmpfile
{

        my $self = shift;

        my $fh    = File::Temp->new();
        my $fname = $fh->filename;

        # Clean up
        $fh->close();

        return $fname

}          # _tmpfile()

# Method: _nlConvert
#
# Given a filename, will convert newline's (\n) to
# newline-carriage-return (\n\r), output to new file, returning name
# of file.
#
# Parameters:
#
#   none
#
# Returns:
#
#   name of file containing strip'd text, undef on fail
sub _nlConvert
{
        my $self = shift;

        $self->_logDebug("invoked ... ");

        # Open files
        my $ofile = $self->{filename};
        my $nfile = $self->_tmpfile();
        my $ofh   = FileHandle->new("$ofile");
        my $nfh   = FileHandle->new("> $nfile");

        # Make sure each file opened okay
        unless ($ofh) {
                $self->_logDebug("Cannot open $ofile: $!\n");
                return undef;
        }
        unless ($nfh) {
                $self->_logDebug("Cannot open $nfile: $!\n");
                return undef;
        }
        while (<$ofh>) {
                s/\n/\n\r/;
                print $nfh $_;
        }          # while ($ofh)

        # Clean up
        $ofh->close();
        $nfh->close();

        return $nfile;

}          # _nlConvert()

# Method: _socketOpen
#
# Opens a socket returning it
#
# Parameters:
#
#   none
#
# Returns:
#
#   socket
sub _socketOpen
{

        my $sock;
        my $self = shift;

        # See if user wants rfc1179 compliance
        if (uc($self->{rfc1179}) eq "NO") {
                $sock =
                    IO::Socket::INET->new(Proto    => 'tcp',
                                          PeerAddr => $self->{server},
                                          PeerPort => $self->{port},
                    );
        } else {

                # RFC 1179 says "source port be in the range 721-731"
                # so iterate through each port until we can open
                # one.  Note this requires superuser privileges
                foreach my $p (721 .. 731) {
                        $sock =
                            IO::Socket::INET->new(PeerAddr  => $self->{server},
                                                  PeerPort  => $self->{port},
                                                  Proto     => 'tcp',
                                                  LocalPort => $p
                            ) and last;
                }
        }

        # return the socket
        return $sock;

}          # _socketOpen()

# Method: _fileCreate
#
# Purpose:
#
#   Creates control file
#
# Parameters:
#
#   none
#
# Returns:
#
#   *Array containing following elements:*
#
#    - control file
#    - name of data file
#    - name of control file
sub _fileCreate
{
        my %chash;
        my $self   = shift;
        my $myname = hostname();
        my $snum   = int(rand 1000);

        # Fill up hash
        $chash{'1H'} = $myname;
        $chash{'2P'} = getlogin || getpwuid($<) || "nobody";
        $chash{'3J'} = $self->{filename};
        $chash{'4C'} = $myname;
        $chash{'5f'} = sprintf("dfA%03d%s", $snum, $myname);
        $chash{'6U'} = sprintf("cfA%03d%s", $snum, $myname,);
        $chash{'7N'} = $self->{filename};

        my $cfile = $self->_tmpfile();
        my $cfh   = new FileHandle "> $cfile";

        # validation
        unless ($cfh) {
                $self->_logDebug(
                                "_fileCreate:Could not create file $cfile: $!");
                return undef;
        }          # if we didn't get a proper filehandle

        # iterate through each key cleaning things up
        foreach my $key (sort keys %chash) {
                $_ = $key;
                s/(.)(.)/$2/g;
                my $ccode = $_;
                printf $cfh ("%s%s\n", $ccode, $chash{$key});

        }

        # Return what we need to
        return ($cfile, $chash{'5f'}, $chash{'6U'});

}          # _fileCreate()

# Method: _lpdCommand
#
# Sends command to remote lpd process, returning response if
# asked.
#
# Parameters:
#
#   self - self
#
#   cmd  - command to send (should be pre-packed)
#
#   gans - do we get an answer?  (0 - no, 1 - yes)
#
# Returns:
#
#   response of lpd command

sub _lpdCommand
{

        my $response;

        my $self = shift;
        my $cmd  = shift;
        my $gans = shift;

        $self->_logDebug(sprintf("Sending %s", $cmd));

        # Send info
        $self->{socket}->send($cmd);

        if ($gans) {

                # We wait for a response
                eval {
                        local $SIG{ALRM} = sub { die "timeout\n" };
                        alarm 5;
                        $self->{socket}->recv($response, 1024)
                            or die "recv: $!\n";
                        1;
                };

                alarm 0;

                # did we get an error?
                if ($@) {
                        if ($@ =~ /timeout/) {
                                $self->_logDebug("Timed out sending command");
                                return undef;
                        }
                }

                $self->_logDebug(sprintf("Got back :%s:", $response));

                return $response;

        }

}          # _lpdCommand()

# Method: _lpdInit
#
# Notify remote lpd server that we're going to print returning 1 on
# okay, undef on fail.
#
# Parameters:
#
#   none
#
# Returns:
#
#   1 on success, undef on fail
sub _lpdInit
{
        my $self = shift;

        my $buf     = "";
        my $retcode = 1;

        $self->_logDebug("invoked ... ");

        # Create and send ready
        $buf = sprintf("%c%s\n", 2, $self->{printer}) || "";
        $buf = $self->_lpdCommand($buf, 1);
        $retcode = unpack("c", $buf || 1);

        $self->_logDebug("Return code is $retcode");

        # check return code
        if (($retcode =~ /\d/) && ($retcode == 0)) {
                $self->_logDebug(
                                 sprintf("Printer %s on Server %s is okay",
                                         $self->{printer}, $self->{server}));
                return 1;
        } else {
                $self->_lpdFatal(
                                 sprintf("Printer %s on Server %s not okay",
                                         $self->{printer}, $self->{server}));
                $self->_logDebug(sprintf("Printer said %s", $buf || "nothing"));

                return undef;
        }
}          # _lpdInit()

# Method: _lpdSend
#
# Sends the control file and data file
#
# Parameter(s):
#
#   cfile   - Real Control File
#   dfile   - Real Data File
#   p_cfile - Fake Control File
#   p_dfile - Fake Data File
#
# Returns:
#
#   1 on success, undef on fail
sub _lpdSend
{
        my $self    = shift;
        my $cfile   = shift;
        my $dfile   = shift;
        my $p_cfile = shift;
        my $p_dfile = shift;

        $self->_logDebug("invoked ... ");

        # build hash
        my $lpdhash = {
                        "3" => {
                                 "name" => $p_dfile,
                                 "real" => $dfile
                        },
                        "2" => {
                                 "name" => $p_cfile,
                                 "real" => $cfile
                        },
        };

        # iterate through each keytype and process
        foreach my $type (keys %{$lpdhash}) {

                $self->_logDebug(
                                 sprintf("TYPE:%d:FILE:%s:",
                                         $type, $lpdhash->{$type}->{"name"},
                                 ));

                # Send msg to lpd
                my $size = (stat $lpdhash->{$type}->{"real"})[7];
                my $buf = sprintf(
                        "%c%ld %s\n", $type,          # Xmit type
                        $size,                        # size
                        $lpdhash->{$type}->{"name"},  # name
                );

                $buf = $self->_lpdCommand($buf, 1);

                # check bugger
                unless ($buf) {
                        carp "Couldn't send data: $!\n";
                        return undef;
                }

                $self->_logDebug(
                                 sprintf("FILE:%s:RESULT:%s",
                                         $lpdhash->{$type}->{"name"}, $buf
                                 ));

                # open new file handle
                my $fh = FileHandle->new($lpdhash->{$type}->{"real"});

                unless ($fh) {
                        $self->_lpdFatal(
                                        sprintf("Could not open %s: %s\n",
                                                $lpdhash->{$type}->{"real"}, $!,
                                        ));
                        return undef;
                }

                # set blocksize
                my $blksize = (stat $fh)[11] || 16384;

                # read from socket
                while (my $len = sysread $fh, $buf, $blksize) {

                        # did we get anything back?
                        unless ($len) {
                                next if ($! =~ /^Interrupted/);
                                carp "Error while reading\n";
                                return undef;
                        }

                        my $offset = 0;

                        # write out buffer
                        while ($len) {
                                my $resp = syswrite($self->{socket},
                                                    $buf, $len, $offset);
                                next unless $resp;
                                $len -= $resp;
                                $offset += $resp;

                        }
                }

                # Clean up
                $fh->close();

                # Confirm server response
                $buf = $self->_lpdCommand(sprintf("%c", 0), 1);
                $self->_logDebug(sprintf("Confirmation status: %s", $buf));
        }

        return 1;

}          # _lpdSend()

# ----------------------------------------------------------------------
# Standard publically accessible method
# ----------------------------------------------------------------------

# Method: DESTROY
#
# called when module destroyed
#
sub DESTROY
{

        # Parameter(s)
        my $self = shift;

        # Just in case :)
        $self->{socket}->shutdown(2) if ($self->{socket});

}          # DESTROY

1;

=head1 TROUBLESHOOTING

=head2 Stair Stepping Problem

When printing text, if you have the infamous "stair-stepping" problem,
try setting lineconvert to "YES".  This should, in most cases, rectify
the problem.

=head2 RFC-1179 Compliance Mode and Security Implications

RFC 1179 specifies that any program connecting to a print service must
use a source port between 721 and 731, which are I<reserved ports>,
meaning you must have root (administrative) privileges to use them.
I<This is a security risk which should be avoided if at all
possible!>

=head2 Using Net::Printer with CUPS

Net::Printer does not natively speak to printers running CUPS (which
uses the IPP protocol).  In order to provide support for legacy
clients, CUPS provides the B<cups-lpd> mini-server which can be set up
to run out of either B<inetd> or B<xinetd> depending on preference.
You will need to set up this functionality in order to use
Net::Printer with CUPS server.  Consult your system documentation as
to how to do this.

=head1 SEE ALSO

L<cups-lpd|cups-lpd/8>, L<lp|lp/1>, L<lpr|lpr/1>, L<perl|perl/1>

RFC 1179 L<http://www.ietf.org/rfc/rfc1179.txt?number=1179>

=head1 AUTHOR

Christopher M. Fuhrman C<< <cfuhrman at panix.com> >>

=head1 REVISION INFORMATION

  $Id: 9044ee617cffd95213cff21af410d8ea1dc3f1fd $

=head1 COPYRIGHT & LICENSE

Copyright (c) 2000-2005,2008,2011,2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

__END__
