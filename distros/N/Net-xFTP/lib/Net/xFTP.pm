package Net::xFTP;

require 5.001;

use warnings;

use strict;
use vars qw(@ISA $VERSION %CONSTANTS);
use Carp;
use Cwd 'cwd';
#x use Fcntl ':mode';
#x use File::Copy;

my @supported_mods = (qw(ftp sftp ssh2 local foreign openssh fsp ftpssl));
my %haveit;
my  $haveSFTPConstants = 0;

foreach my $imod (@supported_mods)
{
	$haveit{$imod} = 0;
}
$haveit{'local'} = 1;  #JWT:ADDED 20150123 - WE *ALWAYS* HAVE "local", SINCE NO EXTERNAL MODULE REQUIRED!

my $bummer = ($^O =~ /Win/o) ? 1 : 0;

eval 'use Net::FTP; $haveit{"ftp"} = 1; 1';
eval 'use Net::SFTP; $haveit{"sftp"} = 1; 1';
eval 'use Net::SFTP::Constants qw(SSH2_FXF_WRITE SSH2_FXF_CREAT SSH2_FXF_TRUNC); $haveSFTPConstants = 1; 1';
eval 'use Net::SSH2; use Net::SSH2::SFTP; $haveit{"ssh2"} = 1; 1';
eval 'use Net::SFTP::Foreign; $haveit{"foreign"} = 1; 1';
eval 'use Net::OpenSSH; use IO::Pty; $haveit{"openssh"} = 1; 1';
eval 'use Net::FSP; $haveit{"fsp"} = 1; 1';
eval 'use Net::FTPSSL; $haveit{"ftpssl"} = 1; 1';

our $VERSION = '1.01';

sub new
{
	my $class = shift;
	$@ = '';
	my $pkg  = shift || 0;
	$pkg =~ s/\s+//go;
	$pkg = 'Net::' . $pkg  unless (!$pkg || $pkg =~ /^Net/o);
	$pkg = 'Net::SFTP::Foreign'  if ($pkg eq 'Net::Foreign');   #FIXUP.
	my $host = shift;
	my %args = @_;
	my $xftp;
	my %xftp_args;
	my ($i, $j, $t);

	foreach $i (keys %args)
	{
		if ($i =~ s/^xftp_//o)   #EXTRACT OUT OUR SPECIAL ARGS ("xftp_*")
		{
			$xftp_args{$i} = $args{"xftp_$i"};

			delete $args{"xftp_$i"};
		}
	}
	if ($pkg =~ /Net::FTPSSL/)
	{
		eval { require "Net/xFTP_FTPSSL.pm" };
		if ($@ || !$haveit{'ftpssl'})
		{
			warn "xFTP:Could not require Net::xFTP_FTPSSL.pm module($@)!";
			return undef;
		}
		foreach $i (keys %args)
		{
			foreach $j (@supported_mods)
			{
				if ($i =~ /^${j}\_/)
				{
					if ($j eq 'ftpssl')
					{
						($t = $i) =~ s/^${j}_//;
						$args{$t} = $args{$i};
					}
					delete $args{$i};
				}
			}
		}
		$xftp = Net::xFTP::FTPSSL::new_ftpssl("${class}::FTPSSL", $pkg, $host, %args);
	}
	elsif ($pkg =~ /Net::FTP/)
	{
		eval { require "Net/xFTP_FTP.pm" };
		if ($@ || !$haveit{'ftp'})
		{
			warn "xFTP:Could not require Net::xFTP_FTP.pm module($@)!";
			return undef;
		}
		foreach $i (keys %args)
		{
			foreach $j (@supported_mods)
			{
				if ($i =~ /^${j}\_/)
				{
					if ($j eq 'ftp')
					{
						($t = $i) =~ s/^${j}_//;
						$args{$t} = $args{$i};
					}
					delete $args{$i};
				}
			}
		}
		$xftp = Net::xFTP::FTP::new_ftp("${class}::FTP", $pkg, $host, %args);
	}
	elsif ($pkg =~ /Net::SFTP::Foreign/)
	{
		eval { require "Net/xFTP_Foreign.pm" };
		if ($@ || !$haveit{'foreign'})
		{
			warn "xFTP:Could not require Net::xFTP_Foreign.pm module($@)!";
			return undef;
		}
		foreach $i (keys %args)
		{
			foreach $j (@supported_mods)
			{
				if ($i =~ /^${j}\_/)
				{
					if ($j eq 'foreign')
					{
						($t = $i) =~ s/^${j}_//;
						$args{$t} = $args{$i};
					}
					delete $args{$i};
				}
			}
		}
		$xftp = Net::xFTP::Foreign::new_foreign("${class}::Foreign", $pkg, $host, %args);
	}
	elsif ($pkg =~ /Net::SSH2/)
	{	
		eval { require "Net/xFTP_SSH2.pm" };
		if ($@ || !$haveit{'ssh2'})
		{
			warn "xFTP:Could not require Net::xFTP_SSH2.pm module($@)!";
			return undef;
		}
		foreach $i (keys %args)
		{
			foreach $j (@supported_mods)
			{
				if ($i =~ /^${j}\_/)
				{
					if ($j eq 'ssh2')
					{
						($t = $i) =~ s/^${j}_//;
						$args{$t} = $args{$i};
					}
					delete $args{$i};
				}
			}
		}
		$xftp = Net::xFTP::SSH2::new_ssh2("${class}::SSH2", $pkg, $host, %args);
	}
	elsif ($pkg =~ /Net::SFTP/)
	{
		eval { require "Net/xFTP_SFTP.pm" };
		if ($@ || !$haveit{'sftp'})
		{
			warn "xFTP:Could not require Net::xFTP_SFTP.pm module($@)!";
			return undef;
		}
		foreach $i (keys %args)
		{
			foreach $j (@supported_mods)
			{
				if ($i =~ /^${j}\_/)
				{
					if ($j eq 'sftp')
					{
						($t = $i) =~ s/^${j}_//;
						$args{$t} = $args{$i};
					}
					delete $args{$i};
				}
			}
		}
		$xftp = Net::xFTP::SFTP::new_sftp("${class}::SFTP", $pkg, $host, %args);
		$xftp->{haveSFTPConstants} = $haveSFTPConstants  if ($xftp);
	}
	elsif ($pkg =~ /Net::FSP/)
	{	
		eval { require "Net/xFTP_FSP.pm" };
		if ($@ || !$haveit{'fsp'})
		{
			warn "xFTP:Could not require Net::xFTP_FSP.pm module($@)!";
			return undef;
		}
		foreach $i (keys %args)
		{
			foreach $j (@supported_mods)
			{
				if ($i =~ /^${j}\_/)
				{
					if ($j eq 'fsp')
					{
						($t = $i) =~ s/^${j}_//;
						$args{$t} = $args{$i};
					}
					delete $args{$i};
				}
			}
		}
		$xftp = Net::xFTP::FSP::new_fsp("${class}::FSP", $pkg, $host, %args);
	}
	elsif ($pkg =~ /Net::OpenSSH/)
	{
		eval { require "Net/xFTP_OpenSSH.pm" };
		if ($@ || !$haveit{'openssh'})
		{
			warn "xFTP:Could not require Net::xFTP_OpenSSH.pm module($@)!";
			return undef;
		}
		foreach $i (keys %args)
		{
			foreach $j (@supported_mods)
			{
				if ($i =~ /^${j}\_/)
				{
					if ($j eq 'openssh')
					{
						($t = $i) =~ s/^${j}_//;
						$args{$t} = $args{$i};
					}
					delete $args{$i};
				}
			}
		}
		$xftp = Net::xFTP::OpenSSH::new_openssh("${class}::OpenSSH", $pkg, $host, %args);
	}
	elsif (!$pkg || $pkg =~ /local/i)
	{
		eval { require "Net/xFTP_LOCAL.pm" };
		if ($@)
		{
			warn "xFTP:Could not require Net::xFTP_LOCAL.pm module($@)!";
			return undef;
		}
		foreach $i (keys %args)
		{
			foreach $j (@supported_mods)
			{
				if ($i =~ /^${j}\_/)
				{
					if ($j eq 'local')
					{
						($t = $i) =~ s/^${j}_//;
						$args{$t} = $args{$i};
					}
					delete $args{$i};
				}
			}
		}
		$xftp = Net::xFTP::LOCAL::new_local("${class}::LOCAL", $pkg, $host, %args);
	}
	else
	{
	$@ = "No such package \"$pkg\"!";
		warn "xFTP:$@!";
		return undef;
	}

	if ($xftp)
	{
		$xftp->{pkg} = ($pkg =~ /local/io) ? $pkg : '';
		$xftp->{bummer} = ($^O =~ /Win/o) ? 1 : 0;
		return $xftp;
	}
	else
	{
		@_ = @_ . " Could not get new $pkg object (undef)!";
	}
	return undef;
}

sub haveFTP        #DEPRECIATED, USE haveModule($module) INSTEAD!
{
	return $haveit{'ftp'};
}

sub haveSFTP
{
	return $haveit{'sftp'};
}

sub haveModule
{
	my $self = shift;
	my $modul = shift;

	my $modHash = &haveModules();
	if ($modul =~ /^Net\:\:/) {
		return (defined $modHash->{$modul}) ? $modHash->{$modul} : 0;
	}
	$modul =~ tr/A-Z/a-z/;
	return (defined $haveit{$modul}) ? $haveit{$modul} : 0;
}

sub haveModules
{
	return { 'Net::FTP' => $haveit{'ftp'}, 'Net::SFTP' => $haveit{'sftp'},
			'Net::SSH2' => $haveit{'ssh2'}, 'Net::SFTP::Foreign' => $haveit{'foreign'},
			'Net::OpenSSH' => $haveit{'openssh'}, 'Net::FSP' => $haveit{'fsp'}, 
			'Net::FTPSSL' => $haveit{'ftpssl'}};
}

sub protocol
{
	my $self = shift;

	return $self->{pkg};
}

1

__END__

=head1 NAME

Net::xFTP - Common wrapper functions for use with either Net::FTP, Net::SFTP, 
Net::FSP, Net::FTPSSL, Net::OpenSSH, Net:SSH2, and Net::SFTP::Foreign.

=head1 AUTHOR

Jim Turner, C<< <mailto:turnerjw784@yahoo.com> >>

=head1 COPYRIGHT

Copyright (c) 2005-2015 Jim Turner <mailto:turnerjw784@yahoo.com>.  
All rights reserved.  

This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

This is a derived work from Net::FTP and Net::SFTP.  Net::FTP is 
copyrighted by Graham Barr and Net::SFTP is copyrighted by Benjamin Trott 
and maintained by Dave Rolsky.  Both are copyrighted under the same terms 
as this module.  

Many thanks go to these gentlemen whose work made this module possible.

=head1 SYNOPSIS

	use Net::xFTP;

	#Test for needed protocol module.
	die "..This server connection needs Net::SFTP!" 
		unless (Net::xFTP->haveModule('Net::SFTP'));

	#Example 1:  Establish a new SFTP connection to a remote host.
	$ftp = Net::xFTP->new('SFTP', "some.host.name", Debug => 0,
			user => 'userid', password => 'opensesme')
		or die "Cannot connect to some.host.name: $@";

	#Example 2:  Establish a "local" (simulated connection) to self.
	$ftp = Net::xFTP->new();  # -OR-
	$ftp = Net::xFTP->new('Local');

	#Change the current working directory on the remote host.
	$ftp->cwd('/pub')  or die 
		"Cannot change working directory ", $ftp->message();

	#Get the current working directory on the remote host.
	my $current_remote_path = $ftp->pwd();

	#Get a list of files and subdirectories in "/pub".
	my @filesAndSubfolders = $ftp->ls('/pub');

	#Get a detailed (ls -l) list of files and subdirectories.
	my @ls_l_details = $ftp->dir('/pub');

	#Create a new subdirectory.
	$ftp->mkdir('myownfolder')
		or die "Cannot make subdirectory ", $ftp->message();

	#Remove an empty subdirectory.
	$ftp->rmdir('myownfolder')
		or die "Cannot remove subdirectory ", $ftp->message();

	#Get the contents of a file on the remote server.
	$ftp->get('remote.file', 'local.file')
		or die "get failed ", $ftp->message();

	#Get the contents of a remote file and write to an open filehandle.
	open FHANDLE, ">local.file" or die "Could not open local file ($!)";
	print FHANDLE "A Header Line!\n";
	flush FHANDLE;
	$ftp->get('remote.file', *FHANDLE)
		or die "get failed ", $ftp->message();
	print FHANDLE "A Footer Line!\n";
	close FHANDLE;

	#Put a local file onto the remote server.
	$ftp->put('local.file', 'remote.file')
		or die "put failed ", $ftp->message();

	#Read from a file handle putting the content in a remote file.
	open FHANDLE "<local.file" or die "Could not open local file ($!)";
	$ftp->put(*FHANDLE, 'remote.file')
		or die "put failed ", $ftp->message();
	close FHANDLE;

	#Delete a remote file.
	$ftp->delete('some.file')
		or die "Cannot delete file ", $ftp->message();

	#Rename a remote file.
	$ftp->rename('oldfilename', 'newfilename')
		or die "Cannot delete file ", $ftp->message();

	#Change permissions of a remote file.
	$ftp->chmod(755, 'some.file.or.dir')
		or die "Cannot change permissions ", $ftp->message();

	#Fetch the size of a remote file.
	print "remote.file has ".$ftp->size('remote.file')." bytes.\n";

	#Fetch the modification time of a remote file.
	print "remote.file has ".$ftp->mdtm('remote.file')." bytes.\n";

	#Copy a remote file to a new remote location.
	$ftp->copy('remote.fileA','remote.fileB')
		or die "Cannot copy the file ", $ftp->message();

	#Move a remote file to a new remote location.
	$ftp->move('old/path/old.filename', 'new/path/new.filename')
		or die "Cannot move the file ", $ftp->message();

	#Call a protocol-specific method.
	$result = $ftp->method('timeout',100)

	#Disconnect an existing connection.
	$ftp->quit();

=head1 PREREQUISITES

Even though Net::xFTP will work in a connection-simulating "I<local>" mode, 
to be truly useful, one needs either C<Net::FTP>, C<Net::SFTP>, or 
one or more of the other supported Net::* protocol modules.

C<Net::SFTP::Attributes> is also needed, if using Net::SFTP.

C<Net::SFTP::Constants> is also needed for using the I<copy>, 
I<move> functions, or using the I<put> function with a filehandle.

=head1 DESCRIPTION

C<Net::xFTP> is a wrapper class to combine common functions of (currently) 
Net::FTP, Net::SFTP, Net::FSP, Net::FTPSSL, Net::OpenSSH, Net:SSH2, and 
Net::SFTP::Foreign into a single set of functions allowing one to switch 
seemlessly between the two without having to make non-trivial code changes.  
Only functionality common to all protocols has been implemented here with 
the intent and invitation to add more functions and features and other 
*FTP-ish modules in the future, as discovered or requested.

=head1 PURPOSE

I created this module when I had developed several web application 
programs which FTP'd data to and from a central server via Net::FTP.  
The client changed to a new remote server that required Net::SFTP.  Faced 
with rewriting these programs without changing functionality (since for 
some reason Net::FTP and Net::SFTP use slightly different methods and 
conventions).  I decided instead to simply create a common module that 
would use the same method calls to do the same things and allow me to 
specify the protocol in a single place.  I also am the author of I<ptkftp>, 
a Perl/Tk graphical user-interface to Net::FTP and Net::SFTP.  I now 
intend to rewrite it to use Net::xFTP and greatly reduce and simplify 
the code for that application.

Hopelfully others will find this module useful.  Patches adding needed 
functionality are welcome.  

=head1 CONSTRUCTOR

=over 4

=item new ( PROTOCOL, HOST [, OPTIONS ])

This is the constructor for a new Net::FTP object.  The first two 
arguments are required and are positional.  Sebsequent arguments (OPTIONS) 
are in the form "name => value".  It returns a Net::xFTP handle object, 
or I<undef> on failure.  If it fails, the reason will be in $@.

C<PROTOCOL> is the underling module or protocol name.  Currently valid 
values are:  C<FTP>, C<SFTP>, C<Net::FTP>, and C<Net::SFTP>.  There are only
two real options - one may either include or omit the "Net::" part.  A third 
option is to pass I<"local">, zero, an empty string, or I<undef> in which 
case the functions are mapped over the local machine, accessable as if 
connected via ftp!  For example, the I<get> and I<put> methods simply copy 
files from one directory to another on the user's local machine.  
If C<PROTOCOL> is local, then the other options, ie. C<HOST> are optional.
Default is I<local> (no remote connection).

C<HOST> is the name of the remote host to which an FTP connection is 
required (except with the I<local> protocol.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<user> is the user-name or login-id to log in with.  For FTP, if not 
specified, then 'anonymous' is used.

B<password> is the password, if required, for connecting.  For FTP, if 
not specified, then 'anonymous@' is used.

B<BlockSize> specifies the buffer size to use for buffered data transfers.  
Default is 10240.  

B<Debug> specifies the debug level for FTP and toggles it for SFTP.  
Default is zero (I<false>), which turns debug off for both.  Set the 
numeric level (non-zero) for FTP, and SFTP will accept it as I<true> and 
turn on debugging.

B<xftp_home> specifies an alternate directory for SFTP to create the ".ssh" 
subdirectory for keeping track of "known hosts".  The default is 
$ENV{HOME}.  This option is useful for web CGI scripts which run often 
under a user with no "home" directory.  The format is: 
"/some/path/that/the/user/can/write/to".

To specify protocol-specific args Not to be passed if the other protocol 
is used, append "protocol_" to the option, ie. "sftp_ssh_args" to specify 
the SFTP option "ssh_args".  

=back

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, failure will be returned as I<undef> or an
empty list.

=over 4

=item ascii

Transfer file in ASCII, if using FTP. CRLF translation will be done if 
required.  This is a do-nothing method for SFTP and I<local>.

Always returns I<undef>.

=item binary

Transfer file in binary mode. No transformation will be done if using 
FTP.  This is a do-nothing method for SFTP and I<local>.

Always returns I<undef>.

=item chmod ( PERMISSIONS, PATH )

Sets the permissions on C<PATH>, which can be either a file or subdirectory.  
C<PERMISSIONS> is an octal number expressed as a decimal.  Common values are 
777 (full access), 755 (rwxr-xr-x) and 644 (rw-r--r--).

Returns 1 if successful, I<undef> if fails.

=item copy ( OLDFILE, NEWFILE )

Copies the file C<OLDFILE> to C<NEWFILE>, creating or overwriting it if 
necessary.  C<OLDFILE> and C<NEWFILE> may be in different directories.

Returns 1 if successful, I<undef> if fails.

=item cwd ( [ DIR ] )

Attempt to change directory to the directory given in C<$dir>.  If
C<$dir> is C<"..">, the FTP C<CDUP> command is used to attempt to
move up one directory.  If no directory is given then an attempt is made
to change the directory to the root directory.  For SFTP, the new directory 
is saved and subsequent relative paths have this value appended to them.

Returns 1 if successful, I<undef> if fails.

=item delete ( FILENAME )

Send a request to the server to delete C<FILENAME>.  Calls either the 
FTP->delete method or SFTP->do_remove method.  For local, calls Perl's 
I<unlink> function.

Returns 1 if successful, I<undef> if fails.

=item dir ( [ DIR [, SHOWALL ]] )

Get a directory listing of C<DIR>, or the current directory in long (ls -l) 
format.  See also the C<ls> method.

C<DIR> specifies the absolute or relative path.  Default is "." (Current 
working directory).  ".." is also valid.

C<SHOWALL> - if I<true>, all files and subdirectory names will be listed.
If I<false>, "hidden" files and subdirectories (those whose names begin 
with a ".") will be omitted.  Default is I<false>.

In an array context, returns a sorted list of lines returned from the 
server. In a scalar context, returns a reference to the list.  Each line 
consists of either a file or subdirectory name or "." or "..".  ".." 
is omitted if C<DIR> is "/".  

Returns I<undef> on failure.

=item get ( REMOTE_FILE [, LOCAL_FILE ] )

Get C<REMOTE_FILE> from the server and store locally.  If C<LOCAL_FILE>
is not specified, then a file with the same name as C<REMOTE_FILE> sans 
the path information will be created on the current working directory of 
the machine the program is running on.  C<LOCAL_FILE> can also be an open 
file-handle (see example in the C<SYNOPSIS> section).  If so, it must be 
passed as a typeglob.  For I<local> protocol, simply copys C<REMOTE_FILE> 
to C<LOCAL_FILE>.

Returns 1 if successful, I<undef> if fails.

=item isadir ( DIR )

Returns 1 (I<true>) if C<DIR> is a subdirectory, 0 (I<false>) otherwise.

=item ls ( [ DIR [, SHOWALL ]] )

Get a directory listing of C<DIR>, or the current directory.  Just the file 
and or subfolder names are returned.  For a full listing (like C<ls -l>), 
see the C<dir> method.

C<DIR> specifies the absolute or relative path.  Default is "." (Current 
working directory).  ".." is also valid.

C<SHOWALL> - if I<true>, all files and subdirectory names will be listed.
If I<false>, "hidden" files and subdirectories (those whose names begin 
with a ".") will be omitted.  Default is I<false>.

In an array context, returns a sorted list of lines returned from the 
server. In a scalar context, returns a reference to the list.  Each line 
consists of either a file or subdirectory name or "." or "..".  ".." 
is omitted if C<DIR> is "/".  

Returns I<undef> on failure.

=item message ()

Returns the last error message from the most recent method call.  For FTP, 
simply calles I<$FTP->message()>.  For SFTP, we must eval / trap the error 
from @_ and or use some method's call-back function option.

=item mkdir ( DIR [, RECURSE ])

Create a new directory with the name C<DIR>. If C<RECURSE> is I<true> then
C<mkdir> will attempt to create all the directories in the given path.

Calls the C<mkdir> method in FTP or C<do_mkdir> method in SFTP.

Returns 1 if successful, I<undef> if fails.

=item move ( OLDFILE, NEWFILE )

Moves the file C<OLDFILE> to C<NEWFILE>, creating or overwriting it if 
necessary.  C<OLDFILE> and C<NEWFILE> may be in different directories, 
unlike I<rename>, which can only change the name (in the same path).  
Essentially does a I<copy>, followed by a I<delete>, if successfully 
copied.

Returns 1 if successful, I<undef> if fails.

=item Net::xFTP->haveFTP ()

Returns 1 if Net::FTP is installed, 0 otherwise.

=item Net::xFTP->haveSFTP ()

Returns 1 if Net::SFTP is installed, 0 otherwise.

=item Net::xFTP->haveModules ()

Returns a reference to a hash in the form: 
{ 'Net::FTP' => 1|0, 'Net::SFTP' => 1|0 }

=item Net::xFTP->haveModule ( MODULE_NAME )

Expects the name of one of the supported FTP modules (currently:  'Net::FTP', 'Net::SFTP', 'Net::SSH2',
'Net::SFTP::Foreign', 'Net::OpenSSH', 'Net::FSP', or 'Net::FTPSSL'.

Returns either 1, if the module is installed or 0 if not.

=item new ( PROTOCOL, HOST [, OPTIONS ])

This is the constructor.  It returns either a Net::xFTP object or I<undef> 
on failure.  For details, see the "CONSTRUCTOR" section above.  For FTP, 
this method also calls the "login" method to connect.

Returns a Net::xFTP handle object, or I<undef> on failure.  If it fails, 
the reason will be in $@.

=item protocol ()

Returns either C<Net::FTP> or C<Net::SFTP>, depending on which underlying 
module is being used.  Returns an empty string is C<local> is used.

=item put ( LOCAL_FILE [, REMOTE_FILE ] )

Put a file on the remote server. C<LOCAL_FILE> and C<REMOTE_FILE> are 
specified as strings representing the absolute or relative path and file 
name.  If C<REMOTE_FILE> is not specified then the file will be stored in 
the current working directory on the remote machine with the same fname 
(sans directory information) as C<LOCAL_FILE>.  C<LOCAL_FILE> can also be 
an open file-handle (see example in the C<SYNOPSIS> section).  If so, it 
must be passed as a typeglob and C<REMOTE_FILE> must be specified.  For 
I<local> protocol, simply copies C<LOCAL_FILE> to C<REMOTE_FILE>.

Returns 1 if successful, I<undef> if fails.

B<NOTE>: If for some reason the transfer does not complete and an error is
returned then the contents that had been transfered will not be remove
automatically.

=item pwd ()

Returns the full pathname of the current working directory.

=item quit ()

Calls FTP->quit() for FTP, For SFTP, which does not have a terminating 
method, simply deletes the SFTP object.

=item rename ( OLDNAME, NEWNAME )

Rename a file on the remote FTP server from "OLDNAME" to "NEWNAME".  
Calls the I<rename> method for FTP and I<do_rename> for SFTP.  For 
I<local> protocol, simply renames the file.

Returns 1 if successful, I<undef> if fails.

=item rmdir ( DIR )

Remove the directory with the name C<DIR>.  The directory must first be 
empty to remove.  Calls the I<rmdir> method for FTP and I<do_rmdir> for 
SFTP.  For I<local> protocol, simiply removes the directory.

Returns 1 if successful, I<undef> if fails.

=item size ( FILE )

Returns the size in bytes of C<FILE>, or I<undef> on failure.  For FTP, 
the I<size> method is called, for SFTP:  I<do_stat>.  For <local>, perl's 
I<stat> function.

=item mdtm ( FILE )

Returns the modification time in Perl "time" format of C<FILE>, or I<undef> 
on failure.  For FTP, the I<size> method is called, for SFTP:  I<do_stat>.  
For <local>, perl's I<stat> function.

=item method ( args )

Even though C<Net::xFTP> is designed for commonality, it may occassionally 
be necessary to call a method specific to a given protocol.  To do this,
simply invoke the method as follows:

$ftp->{xftp}->method ( args )    #DEPRECIATED with v1.00, use:
$ftp->method ( args )

Example:

 print "-FTP size of file = ".$ftp->method('size', '/pub/myfile').".\n"
		if ($ftp->protocol() eq 'Net::FTP');

=item sftpWarnings

Internal module used to capture non-fatal warning messages from Net::SFTP 
methods.

=back

=head1 TODO

Add a C<stat> method when this is supported in Net::FTP.
Add any additional Net::*FTP-ish protocols as discovered or requested.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-xftp@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-xFTP>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

This is a derived work from Net::FTP and Net::SFTP.  Net::FTP is 
copyrighted by Graham Barr and Net::SFTP is copyrighted by Benjamin Trott 
and maintained by Dave Rolsky.  Both are copyrighted under the same terms 
as this module.  

Many thanks go to these gentlemen whose work made this module possible.

=head1 SEE ALSO

L<Net::FTP|Net::FTP>

L<Net::SFTP|Net::SFTP>

L<Net::SFTP::Foreign|Net::SFTP::Foreign>

L<Net::FSP|Net::FSP>

L<Net::FTPSSL|Net::FTPSSL>

L<Net::OpenSSH|Net::OpenSSH>

L<Net::SSH2|Net::SSH2>

L<Net::SFTP::Constants|Net::SFTP::Constants>

L<Net::SFTP::Attributes|Net::SFTP::Attributes>

=head1 KEYWORDS

ftp, sftp, xftp, Net::FTP, Net::SFTP

=cut
