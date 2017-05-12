# Implementation of the file protocol for LWP::Parallel, based on 
# LWP::Protocol::file and LWP::Parallel::Protocol::ftp pattern.
# contributed by Jeff Behr, October 2001
# $Id: file.pm,v 1.2 2003/05/26 08:03:34 langhein Exp $

package LWP::Parallel::Protocol::file;

use HTTP::Status ();
use HTTP::Response ();
use LWP::MediaTypes ();
use IO::File();
use IO::Dir();

use vars qw(@ISA);

require LWP::Parallel::Protocol;
require LWP::Protocol::file;
@ISA = qw(LWP::Parallel::Protocol LWP::Protocol::file);

use strict;

# this method just sees that the file or directory exists and can
# be read by the user, etc., and then creates a handle for it from
# IO::File or IO::Dir
sub handle_connect {
    my ($self, $request, $proxy, $timeout, $nonblock) = @_;

    LWP::Debug::trace('(Entered Parallel::Protocol::file::handle_connect)');

    # check proxy
    if (defined $proxy) {
	my $res = HTTP::Response->new(&HTTP::Status::RC_BAD_REQUEST, 
		'You cannot proxy through the filesystem');
	return(undef, $res);
    }

    #check method
    my $method = $request->method;
    unless ($method eq 'GET' || $method eq 'HEAD' || $method eq 'DELETE') {
	my $res = HTTP::Response->new(&HTTP::Status::RC_METHOD_NOT_ALLOWED, 
		"Method $method not allowed for 'file:' URLs");
	return(undef, $res);
    }

    # check url
    my $url = $request->url;
    my $scheme = $url->scheme;
    if ($scheme ne 'file') {
	my $res = HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR, 
		"LWP::file::handle_connect called for '$scheme'");
	return(undef, $res);
    }

    ########
    # URL OK
    ########
    # If we get here, URL is OK
    my $path = $url->file;
    
    # test file exists and is readable
    unless (-e $path) {
	my $res = HTTP::Response->new(&HTTP::Status::RC_NOT_FOUND, 
				"File '$path' does not exist.");
	return(undef, $res);
    }

    unless (-r _) {
	my $res = HTTP::Response->new(&HTTP::Status::RC_FORBIDDEN, 
			"User does not have read permission");
	return(undef, $res);
    }
  
    if ($method eq 'DELETE' && !(-w _)) {
	my $res = HTTP::Response->new(&HTTP::Status::RC_FORBIDDEN,
		"User does not have permission to delete $path");
        return(undef, $res);
    }

    # file exists and is readable/writable ...
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$filesize,
       $atime,$mtime,$ctime,$blksize,$blocks) = stat(_);

    # check if-modified-since
    my $ims = $request->header('If-Modified-Since');
    if (defined $ims) {
	my $time = HTTP::Date::str2time($ims);
	if (defined $time and $time >= $mtime) {
	    my $res = HTTP::Response->new(&HTTP::Status::RC_NOT_MODIFIED,
						"$method $path");
	    return(undef, $res);
	}
    }

    # the return value is an object of IO::Handle, either 
    # IO::File or IO::Dir.  
    # Ooops.  Turns out IO::Dir is not derived from IO::Handle and 
    # IO::Select calls in UserAgent->wait calls don't see a handle.
    # for objects of IO::Dir even though they can be "connections".
    # Return (undef, response) for directory calls, for now.  Prob-
    # ably have to one-time directory lists in the future, or skip
    # doing dirs here in favor of list_urls in FileCopy.pm.
    my $fh;
    if (-d _) {
	return (undef,
            HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR,
            "Skipping directory handle for '$path'."));
	
	#$fh = IO::Dir->new($path) or return (undef,
        #    HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR,
        #    "Unable to create directory handle for '$path': $!"));
    }
    elsif (-f _) {
        $fh = IO::File->new($path) or return (undef, 
	    HTTP::Response->new(&HTTP::Status::RC_INTERNAL_SERVER_ERROR, 
	    "Unable to create file handle for '$path': $!"));
    } 
    else {
	return (undef,
            HTTP::Response->new(&HTTP::Status::RC_UNSUPPORTED_MEDIA_TYPE,
            "'$path' is not a directory or file listing."));
    }

    # Response looks to be OK
    my $response = HTTP::Response->new(&HTTP::Status::RC_OK, "OK");
    $response->request($request);

    # Add header(s)
    $response->header('Last-Modified', HTTP::Date::time2str($mtime));	

    return ($fh, $response);
}


sub write_request {
    my ($self, $req, $fh, $response, $arg, $timeout) = @_;

    LWP::Debug::trace('(Entered Parallel::Protocol::file::write_request)');

    # $fh should be an IO::File or IO::Dir
    unless (ref($fh) eq 'IO::File' or ref($fh) eq 'IO::Dir') { 
	my $res = HTTP::Response->new(&HTTP::Status::RC_UNSUPPORTED_MEDIA_TYPE,
	    "Socket is not IO::File or IO::Dir");
    	return(undef, $res);
    }
    
    # Delete the file, return the response.  
    if ($req->method eq 'DELETE') {
	my $cnt = unlink $req->uri->file;
	my $res;
	if ($cnt) {
	    $res = HTTP::Response->new(&HTTP::Status::RC_OK,
	    	"Deleted $req->uri->file");
	}
	else {
	    $res = HTTP::Response->new(&HTTP::Status::RC_METHOD_NOT_ALLOWED,
		"Deletion failed on $req->uri->file");
	}
	return(undef, $res);
    }

    # return input $fh/$socket, response
    return($fh, $response);
}

 
sub read_chunk {
    my ($self, $response, $fh, $request, $arg, $size, $timeout, $entry) = @_;

    LWP::Debug::trace('(Entered Parallel::Protocol::file::read_chunk)');

    $size = 32768 unless defined $size and $size > 0;

    my $path = $request->uri->path;
    my $method = $request->method;
    #print "Performing $method on $path\n";

    # this is redundant from &handle_connect - see if it can be streamlined
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$filesize,
       $atime,$mtime,$ctime,$blksize,$blocks) = stat($path);

    # Collect the data from the dir or file.  If it's a dir, we get it in
    # one shot and send it back to collect_once.  Otherwise, we try to stay
    # with the Parallel fashion and do things through wait().  Doing it this
    # way will, I think, minimize the amount of memory that gets sucked up.
    my $buf = "";
    if (ref($fh) eq 'IO::File') {
	# LWP::Proto::file does nothing with files under HEAD - 
	# sets header(s) from the values returned by stat, etc.
	$response->header('Content-Length', $filesize);
	my $type = LWP::MediaTypes::guess_media_type($path, $response);

 	my $bytes;
	($buf, $bytes) = $self->_read_file($fh, $response, $size);

        # receive() method bases its action on the $arg value
        my $retval = $self->receive($arg, $response, \$buf, $entry);
    
        # $retval from Parallel::Proto->receive()
        # this should be bytes read or a constant error value
	# Could do more with the return value here
        return (defined $retval ? $retval : $bytes);
    }
    elsif (ref($fh) eq 'IO::Dir') {
	$buf = $self->_read_dir($fh, $response);
	if ($ENV{DIR_AS_HTML}) {
	    ($buf, $response) = $self->_write_as_html($buf, $response);
    	    $response->header('Content-Type',  'text/html');
	} else {
    	    $response->header('Content-Type',  'text/plain');
	}
    	$response->header('Content-Length', length $buf);
    	$buf = "" if $method eq "HEAD";
        $self->collect_once($arg, $response, $buf);
	return 0;
    }
    else {
	my $res = HTTP::Response->new(&HTTP::Status::RC_UNSUPPORTED_MEDIA_TYPE,
	    "Socket is not IO::File or IO::Dir");
	# Not too sure about this return value
    	return 0;
    }
}

sub close_connection {
   my ($self, $response, $fh, $request, $socket) = @_;

   LWP::Debug::trace('(Entered Parallel::Protocol::file::close_connect)');

   $fh->close;	# Dir or File
   return;
}

sub _read_file {
    my ($self, $fh, $response, $size) = @_;
    
    my $content;
    #$fh->binmode;
    my $bytes_read = $fh->sysread($content, $size);

    $content, $bytes_read;
}
    

# when reading directories, just get it all in one shot
sub _read_dir {
    my $self = shift;
    my $fh = shift;
    my $res = shift;

    my @files = sort $fh->read;

    # Make full directory listing
    my $path = $res->request->uri->path;
    for (@files) {
        if($^O eq "MacOS") {
            $_ .= "/" if -d "$path:$_";
        } else {
            $_ .= "/" if -d "$path/$_";
        }
    }
    my $files = join "", @files;

    return $files;
}


sub _write_as_html {
    my ($self, $filelist, $response) = @_;

    my $path = $response->request->uri->path;

    # Re-Make directory listing
    my @files = split '\n', $filelist;
    for (@files) {
        my $furl = URI::Escape::uri_escape($_);	# file's url
        my $desc = HTML::Entities::encode($_);	# file's link
        $_ = qq{<LI><A HREF="$furl">$desc</A>};
    }

    my $url = $response->request->uri;
    # Ensure that the base URL is "/" terminated
    my $base = $url->clone;
    unless ($base->epath =~ m|/$|) {
        $base->epath($base->epath . "/");
    }
    my $files = join("\n",
                    "<HTML>\n<HEAD>",
                    "<TITLE>Directory $path</TITLE>",
                    "<BASE HREF=\"$base\">",
                    "</HEAD>\n<BODY>",
                    "<H1>Directory listing of $path</H1>",
                    "<UL>", @files, "</UL>",
                    "</BODY>\n</HTML>\n");
    
    return ($files, $response);
}

1;
