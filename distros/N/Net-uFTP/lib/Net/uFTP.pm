package Net::uFTP;

use vars qw($VERSION);

$VERSION = 0.161;
#--------------

use warnings;
use strict;
use Carp;
use UNIVERSAL::require;
use base qw(Class::Accessor::Fast::XS);
#----------------------------------------------------------------------
__PACKAGE__->mk_accessors(qw(object host type user password debug port));
#======================================================================
sub new {
	my ($self, $host, %params) = (shift, shift, @_);

	$params{host} = $host;
	$self = bless \%params, $self;
	
	# little standarization :-)	
	$self->type($self->type() or 'Net::uFTP::FTP');
	my $type = $self->type() =~ /^Net::uFTP/o ? $self->type() : 'Net::uFTP::'.$self->type();
	$type =~ s/SCP$/SFTP/;
	
	$type->require or return;
	$self->type($type);

	return $self;
}
#======================================================================
sub get {
    my $self = shift;
    return $self->object()->get(@_);
}
#======================================================================
sub login {
	my ($self, $user, $passwd) = @_;
	
	my $type = $self->type();
	$self->object($type->new($self->host, port => $self->port, user => $user, password => $passwd, debug => $self->debug));
	return 1 if $self->object;
	return;
}
#======================================================================
sub AUTOLOAD {
	our $AUTOLOAD;
	my ($method) = $AUTOLOAD =~ /::([^:]+)$/o;

	return if $method eq 'DESTROY';	

	my $self = shift;
	croak(qq/Unsupported method "$method"/) unless $self->object()->can($method);
	
	return $self->object()->$method(@_);
}
#======================================================================
1;

__END__

=head1 NAME

Net::uFTP - Universal interface for FTP-like modules (FTP, SFTP, SCP), in most cases B<Net::FTP compatible>.

=head1 SYNOPSIS

    use Net::uFTP;

    my $ftp = Net::uFTP->new('some.host.name', type => 'FTP', debug => 1);

    $ftp->login('mylogin','mysecret')
      or die 'Incorrect password or login!';

    $ftp->cwd("/pub")
      or die "Cannot change working directory ", $ftp->message;

    $ftp->get("that.file")
      or die "get failed ", $ftp->message;

    my $recurse = 1;
    $ftp->get("that.dir", "this.path", $recurse)
      or die "get failed ", $ftp->message;

    $ftp->quit;

=head1 DESCRIPTION

This module provides common interface (B<Net::FTP compatible>) to 
popular FTP-like protocols (for now: FTP, SFTP, SCP). Flexibility of 
this module allows to add plugins to support other protocols 
(suggestions and plugins are welcome ;)

Currently C<Net::uFTP> was successfuly tested for compatibility with 
C<Gtk2>, C<Gtk2::GladeXML>, C<Gtk2::GladeXML::OO> and pragma 
C<encoding 'utf-8'>. Other modules (some Pure Perl implementations)
have problems with that. Consider this, when You're planning  to build
Gtk2 / multilingual application.

=head1 ATTENTION

C<Net::uFTP> uses, for speed reason, Net::SSH2, so You have to have 
installed libssh (L<http://www.libssh2.org>). Consider, that 
C<Net::SSH2> module is available on all most popular platforms (Linux,
Windows, Mac, etc.), so You shouldn't have any trouble with this 
dependency.

If You are looking for C<Pure Perl> implementation, take a look at
C<Net::xFTP> (based on Net::SSH::Perl) instead.

=head1 OVERVIEW

Rest of this documentation is based on C<Net::FTP> documentation and 
describes subroutines/methods available in C<Net::uFTP>.

Original version of this document (which describes C<Net::FTP>) is 
avaliable at L<http://cpan.uwinnipeg.ca/htdocs/libnet/Net/FTP.html>.

=head1 CONSTRUCTOR

=over 4

=item new ( HOST, OPTIONS )

This is the constructor for a new Net::FTP object. C<HOST> is the
name of the remote host to which an FTP connection is required.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<Host> - FTP host to connect to. The L</host> method will return the value
which was used to connect to the host.

B<debug> - debug level (see the debug method in L<Net::Cmd>)

B<type> - type of connection. Possible values: FTP, SFTP, SCP. Default 
to FTP.

B<port> - the port number to connect to on the remote machine.

If the constructor fails undef will be returned and an error message will
be in $@

=back

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, failure will be returned as I<undef> or an
empty list.

=over 4

=item login ([LOGIN [,PASSWORD [, ACCOUNT] ] ])

Log into the remote FTP server with the given login information. 

=item ascii

Transfer file in ASCII. CRLF translation will be done if required

=item binary

Transfer file in binary mode. No transformation will be done.

B<Hint>: If both server and client machines use the same line ending for
text files, then it will be faster to transfer all files in binary mode.

=item rename ( OLDNAME, NEWNAME )

Rename a file on the remote FTP server from C<OLDNAME> to C<NEWNAME>. This
is done by sending the RNFR and RNTO commands.

=item delete ( FILENAME )

Send a request to the server to delete C<FILENAME>.

=item cwd ( [ DIR ] )

Attempt to change directory to the directory given in C<$dir>.  If
C<$dir> is C<"..">, the FTP C<CDUP> command is used to attempt to
move up one directory. If no directory is given then an attempt is made
to change the directory to the root directory.

=item cdup ()

Change directory to the parent of the current directory.

=item pwd ()

Returns the full pathname of the current directory.

=item rmdir ( DIR [, RECURSE ])

Remove the directory with the name C<DIR>. If C<RECURSE> is I<true> then
C<rmdir> will attempt to delete everything inside the directory.

=item mkdir ( DIR [, RECURSE ])

Create a new directory with the name C<DIR>. If C<RECURSE> is I<true> then
C<mkdir> will attempt to create all the directories in the given path.

Returns the full pathname to the new directory.

=item ls ( [ DIR ] )

Get a directory listing of C<DIR>, or the current directory.

In an array context, returns a list of lines returned from the server. In
a scalar context, returns a reference to a list.

=item dir ( [ DIR ] )

Get a directory listing of C<DIR>, or the current directory in long format.

In an array context, returns a list of lines returned from the server. In
a scalar context, returns a reference to a list.

=item get ( REMOTE_FILE [, LOCAL_FILE [, RECURSE ] ] )

Get C<REMOTE_FILE> from the server and store locally. If not specified, 
the file will be stored in the current directory with the same leafname 
as the remote file. If C<RECURSE> is I<true> then C<get> will attempt to
get directory recursively. 

Returns C<LOCAL_FILE>, or the generated local file name if C<LOCAL_FILE>
is not given. If an error was encountered undef is returned.

=item put ( LOCAL_FILE [, REMOTE_FILE [, RECURSE ] ] )

Put a file on the remote server. C<LOCAL_FILE> may be a regular file or 
a directory. If C<REMOTE_FILE> is not specified then the file will be 
stored in the current directory with the same leafname as C<LOCAL_FILE>.
If C<RECURSE> is I<true> then C<get> will attempt to put directory 
recursively. 

Returns C<REMOTE_FILE>, or the generated remote filename if C<REMOTE_FILE>
is not given.

B<NOTE>: If for some reason the transfer does not complete and an error is
returned then the contents that had been transfered will not be remove
automatically.

=item mdtm ( FILE )

Returns the I<modification time> of the given file.

=item size ( FILE )

Returns the size in bytes for the given file as stored on the remote server.

B<NOTE>: The size reported is the size of the stored file on the remote server.
If the file is subsequently transfered from the server in ASCII mode
and the remote server and local machine have different ideas about
"End Of Line" then the size of file on the local machine after transfer
may be different.

=back

If for some reason you want to have complete control over the data connection,
then the user can use these methods to do so.

However calling these methods only affects the use of the methods above that
can return a data connection. They have no effect on methods C<get>, C<put>,
C<put_unique> and those that do not require data connections.

=over 4

=item port ( [ PORT ] )

Send a C<PORT> command to the server. If C<PORT> is specified then it is sent
to the server. If not, then a listen socket is created and the correct information
sent to the server.

=item pasv ()

Tell the server to go into passive mode. Returns the text that represents the
port on which the server is listening, this text is in a suitable form to
sent to another ftp server using the C<port> method.

=item quit ()

Send the QUIT command to the remote FTP server and close the socket connection.

=back

C<Net::uFTP> provides also useful, not C<Net::FTP> compatible methods, as 
follow:

=over 4

=item is_dir ( REMOTE )

Returns true if REMOTE is a directory.

=item is_file ( REMOTE )

Returns true if REMOTE is a regular file.

=item change_root ( DIR )

Change root directory of current user. Only available in SFTP environment.

=back

=head1 TODO

Add support for other methods from Net::FTP.

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.
It may be difficult for me to reproduce the problem as almost every setup
is different.

A small script which yields the problem will probably be of help. It would
also be useful if this script was run with the extra options C<debug => 1>
passed to the constructor, and the output sent with the bug report. If you
cannot include a small script then please include a debug trace from a
run of your program which does yield the problem.

=head1 THANKS

Ryan Gorsuch for reaporting a bug as well as supplying relevant patch.

=head1 AUTHOR

Strzelecki £ukasz <lukasz@strzeleccy.eu>

=head1 SEE ALSO

L<Net::xFTP>
L<Net::FTP>
L<Net::SSH2>

=head1 COPYRIGHT

Copyright (c) Strzelecki Łukasz. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
