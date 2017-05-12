package Net::FTP::Versioning;
use strict;
require 5.001;
use Net::FTP;
use vars qw(@ISA $VERSION);
use Carp;
@ISA = ("Net::FTP");
$VERSION = "0.01";

sub new {
    my $classname  = shift;
    my $self       = $classname->SUPER::new(@_);
    $self->_init(@_);
    return $self;
}
sub _init {
    my $self = shift;
    ${*$self}->{net_ftp_versioning_transfertime} = undef;
}
sub _setTransferTime { # returns: nothing
	my $self = shift;
	${*$self}->{net_ftp_versioning_transfertime} = shift;
}
sub transferTime { # returns: Integer: the transfer time in seconds
	my $self = shift;
	my $seconds = ${*$self}->{net_ftp_versioning_transfertime};
	return ($seconds);
}
# put ( LOCAL_FILE [, REMOTE_FILE][, versions => N ] )
sub put {  # returns: what Net::FTP->put() returns
	my $self = shift;
	# checking if versionning is enabled
	my $versions = 0;
	my $end = $#_;	# last element's index of @_
	if (@_ >= 3 && $_[$end - 1] eq 'versions' ) { # versionning is enabled
		$versions = pop (@_);
		pop (@_); # to remove the "versions" element
		# defining the remote filename. the piece of code bellow
		# was cut-and-pasted from Net::FTP module.
		my($local,$remote) = @_;
		my $localfd = ref($local) || ref(\$local) eq "GLOB";
		unless(defined $remote){
	 		croak 'Must specify remote filename with stream input'
	        	if $localfd;
			require File::Basename;
	  		$remote = File::Basename::basename($local);
	 	}
	 	croak("Bad remote filename '$remote'\n")
        	if $remote =~ /[\r\n]/s;
        # end of cut-and-pasting
        
	 	# If $versions != 0, we set $remote to rotation in the remote
	 	# server. It only will be rotated if already exists a file with 
	 	# the same name as $remote.
	 	if ( $versions != 0 ) {
			$self->_rotate_file("remote", $remote, $versions);
		}
	}
    # Let's make the file transfer gathering the transfer time
    my ($t0,	# time before the transfer
		$t1		# time after the transfer
    );
    my $result = undef; # will store what Net::FTP->put() returns
    $t0 = time;
	$result = $self->SUPER::put(@_);
	$t1 = time;
	$self->_setTransferTime($t1 - $t0);
	return $result;
}
# get ( REMOTE_FILE [, LOCAL_FILE [, WHERE]][, versions => N])
sub get { # returns: what Net::FTP->get() returns
	my $self = shift;
	# checking if versionning is enabled
	my $versions = 0;
	my $end = $#_;	# last element's index of @_
	if (@_ >= 3 && $_[$end - 1] eq 'versions' ) { # versionning is enabled
		$versions = pop (@_);
		pop (@_); # to remove the "versions" element
		# defining the local filename as is done in Net::FTP module.
		my($remote, $local) = @_;
		my $localfd = ref($local) || ref(\$local) eq "GLOB";
		croak "Can't enable versioning if the local_file is a filehandle\n."
			if $localfd;
		($local = $remote) =~ s#^.*/## unless(defined $local);
 		croak("Bad remote filename '$remote'\n")
			if $remote =~ /[\r\n]/s;
		
	 	# If $versions != 0, we set $local to rotation in the localhost.
	 	# It only will be rotated if already exists a file with 
	 	# the same name as $remote.
	 	if ( $versions != 0 ) {
			$self->_rotate_file("local", $local, $versions);
		}
	}
    # Let's make the file transfer gathering the transfer time
    my ($t0,	# time before the transfer
		$t1		# time after the transfer
    );
    my $result = undef; # will store what Net::FTP->put() returns
    $t0 = time;
	$result = $self->SUPER::get(@_);
	$t1 = time;
	$self->_setTransferTime($t1 - $t0);
	return $result;
}

# rotates a filename. the file can be 'local' or 'remote'.
# _rotate_file (
#	'local' | 'remote', $filename,
#	$number_of_versions [, $counter]
# )
sub _rotate_file { # returns: nothing
	my $i;		# counter. on the first run it must be = 0
	$i = ( @_ == 5 ? pop (@_) : 0 );
	my ($self, $where, $file, $nversions) = @_;
	# Anonymous Subroutines ########################
	# All the anonymous subroutines bellow are available only inside 
	# _rotate_file() and they relly on $where and $self
	# variables set inside _rotate_file()
	my $exist = sub { # tells if the file exists
		my $file = shift;
		if ($where eq 'local') {
			return ( -f $file );
		} else { # remote file
			return $self->size($file);
		}
	};
	my $del = sub { # removes the file
		my $file = shift;
		if ($where eq 'local') {
			unlink ($file);
		} else { # remote file
			$self->delete($file);
		}
	};
	my $move = sub { # rename the file
		my ($oldName, $newName) = @_;
		if ($where eq 'local') {
			rename ($oldName, $newName);
		} else {
			$self->rename($oldName, $newName);
		}
	};
	# Here goes the rotation code    
	my ($oldName, $newName);
	if ( $i == 0 && &$exist($file) ) {
		$oldName = $file;
	} elsif ( &$exist("$file.$i") ) {
		$oldName = "$file.$i";
	}
	if ($oldName) {
		$newName = "$file." . ++$i;
		$self->_rotate_file($where, $file, $nversions, $i) unless ($i == $nversions);
		&$del($newName) if &$exist ($newName);
		&$move($oldName, $newName);
	}
}
sub DESTROY {
    my $self = shift;
    $self->close();
} 
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::FTP::Versioning - Extends Net::FTP get() and put() methods to add versioning support to them

=head1 SYNOPSIS

	use Net::FTP::Versioning;
  
	# Start your ftp connection as you do when using Net::FTP.
	$ftp = Net::FTP::Versioning->new("some.host.name", Debug => 0)
		or die "Cannot connect to some.host.name: $@";
	$ftp->login("anonymous",'-anonymous@')
		or die "Cannot login ", $ftp->message;
	$ftp->cwd("/pub")
		or die "Cannot change working directory ", $ftp->message;

	# Now, get the remote file but activate versioning support
	# so your local file (if it exists) will be rotated until
	# $NROTATIONS instead of being silently overwritten
	$NROTATIONS = 2;
	$ftp->get("that.file", versions => $NROTATIONS)
		or die "get failed ", $ftp->message;
	
	# Also, print the transfer time in seconds
	print "File transfered in: ", $ftp->transferTime(), "seconds.\n";
	  
	$ftp->quit;

=head1 ABSTRACT

C<Net::FTP::Versioning> inherits all methods from C<Net::FTP> and 
can be used in substitution of it. Extends the C<get()> and C<put()>
methods to add versioning support to them. 
A new C<transferTime()> method was added to report the file transfer
time in seconds.

=head1 DESCRIPTION

Net::FTP::Versioning extends Net::FTP->get() and Net::FTP->put() to add
versioning support to these methods.

Versioning support means that, when you are getting a remote file, 
if exists a local file with the same name of the file you're going
to download, the local file can be rotated instead of just being
overwriten. The same thing occurs if you are uploading a file with
put() and in the remote ftp server already exists a
file with the name you are uploading - the remote file can be rotated too.

The rotation procedure simply renames the existing file with a ".1",
".2", ".3" ... ".N" suffix, until the number of versions you wish to use.

Depending on the file sizes and the number of rotations you're using, the
rotation process could take significant time. This would give the fake idea 
that the file transfer time took longer than it really took. Remember that
with versioning enabled, the extended get() and put() methods will rotate
the existing files before making the file transfer. 

For this reason, I added a transferTime() method that returns the actual 
file transfer time, recorded after the versioning code already finished.
You can, of course, use transferTime() even if you're not enabling versioning.

=head1 CONSTRUCTOR

=over 4

=item new ([ HOST ] [, OPTIONS ]) 

Just like Net::FTP->new(). Refer to its documentation.

=back

=head1 METHODS

=over 4

=item get ( REMOTE_FILE [, LOCAL_FILE [, WHERE]][, versions => N])

Works like** C<< Net::FTP->get() >> does but accepts an extra optional
option, 'versions', that can be used to enable versioning support;

** if you enable versioning, unlike C<< Net::FTP->get() >>, this method 
will not accept a filehandle as the C<LOCAL_FILE>, since it could not
know the name of the local file to be rotated. It croaks an error
message in this case.

=item put ( LOCAL_FILE [, REMOTE_FILE][, versions => N ] )

Works just like C<< Net::FTP->put() >> does but accepts an extra optional
option, 'versions', that can be used to enable versioning support;

=item transferTime()

Returns an integer standing for the time in seconds taken by
the last file transfer accomplished by C<get()> or C<put()> methods.

=item ALL OTHER Net::FTP METHODS

All other Net::FTP methods are inherited and perfectly usable. Refer to 
Net::FTP documentation to know about them.

=back

=head1 INTERNALS

I didn't touch the networking code of C<get()> and C<put()> methods of
C<Net::FTP>. I just added the versioning code. The file transfers 
are performed by using the original C<get()> and C<put()> methods from
C<Net::FTP>, by calling them with C<< $self->SUPER::get(@_) >> and 
C<< $self->SUPER::put(@_) >>.

=head1 SEE ALSO

L<Net::FTP>

=head1 AUTHOR

Bruno Negrao.
Contact info: see in L<http://www.qmailwiki.org/User:Bnegrao>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Bruno Negrao

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
