# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/Utils.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 3814 $ $DateTime: 2003/01/25 00:45:49 $

package OurNet::BBS::Utils;

use strict;
no warnings 'deprecated';
use Date::Parse;
use Date::Format;
use Sys::Hostname;
use Digest::MD5 'md5_base64';

our $hostname = &Sys::Hostname::hostname();

sub deltree {
    require File::Find;

    my $dir = shift or return;

    File::Find::finddepth(sub {
	if (-d $File::Find::name) {
	    rmdir $File::Find::name;
	}
	else {
	    unlink $File::Find::name;
	}
    }, $dir) if -d $dir;

    rmdir $dir;
}

sub locate {
    my ($file, $path) = @_;

    unless ($path) {
	$path = (caller)[0];
	$path =~ s|::\w+$||;
    }

    $path =~ s|::|/|g;

    unless (-e $file) {
	foreach my $inc (@INC) {
	    last if -e ($file = join('/', $inc, $_[0]));
	    last if -e ($file = join('/', $inc, $path, $_[0]));
	}
    }

    return -e $file ? $file : undef;
}

# hash message id from Date, From, Board and Subject
sub set_msgid {
    my ($header, $host) = @_;
    my $timestamp = $header->{Date};

#   $host ||= $hostname ||= 'localhost';

    if (($timestamp ||= '') =~ /\D/) {
	# conversion from ctime format
	$timestamp = str2time($timestamp);
    }

    $timestamp = time2str('%Y%m%d%H%M%S', $timestamp)
	unless length($timestamp ||= ('0' x 14)) == 14;

    use bytes;
    no warnings 'uninitialized';
    my $hash = md5_base64("@{$header}{qw/From Subject Board/}");

    # shouldn't be elixus.org
    $_[0]->{'Message-ID'} = "<$timestamp.$hash\@bbs.elixus.org>";
}

# arg: timestamp author board title host
sub get_msgid {
    my ($timestamp, $author, $board, $title, $host) = @_;

    $host ||= $hostname;

    if (($timestamp ||= '') !~ /^\d+$/) {
        # conversion from ctime format
        $timestamp = str2time($timestamp);
    }

    $timestamp = time2str('%Y%m%d%H%M%S', $timestamp)
        unless length($timestamp ||= ('0' x 14)) == 14;

    no warnings 'uninitialized';
    return "<$timestamp.".md5_base64("$author $title $board")."\@$host>";
}

1;
