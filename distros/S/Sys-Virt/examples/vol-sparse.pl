#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;
use Fcntl;

my $FILE;

sub download_handler {
	my $st = shift;
	my $data = shift;
	my $nbytes = shift;
	return syswrite FILE, $data, $nbytes;
}

sub download_hole_handler {
    my $st = shift;
    my $offset = shift;
    my $pos = sysseek FILE, $offset, Fcntl::SEEK_CUR or die "Unable to seek in $FILE: $!";
    truncate FILE, $pos;
}


sub download {
    my $vol = shift;
    my $st = shift;
    my $filename = shift;
    my $offset = 0;
    my $length = 0;

    open FILE, ">$filename" or die "unable to create $filename: $!";
    eval {
        $vol->download($st, $offset, $length, Sys::Virt::StorageVol::VOL_DOWNLOAD_SPARSE_STREAM);
        $st->sparse_recv_all(\&download_handler, \&download_hole_handler);
        $st->finish();
    };
    if ($@) {
        unlink $filename if $@;
        close FILE;
        die $@;
    }

    close FILE or die "cannot save $filename: $!"
}

sub upload_handler {
    my $st = $_[0];
    my $nbytes = $_[2];
    return sysread FILE, $_[1], $nbytes;
}

sub upload_hole_handler {
    my $st = shift;
    my $in_data;
    my $section_len;

    # HACK, Perl lacks SEEK_DATA and SEEK_HOLE.
    my $SEEK_DATA = 3;
    my $SEEK_HOLE = 4;

    my $cur = sysseek FILE, 0, Fcntl::SEEK_CUR;
    eval {
        my $data = sysseek FILE, $cur, $SEEK_DATA;
        # There are three options:
        # 1) $data == $cur;  $cur is in data
        # 2) $data > $cur; $cur is in a hole, next data at $data
        # 3) $data < 0; either $cur is in trailing hole, or $cur is beyond EOF.

        if (!defined($data)) {
            # case 3
            $in_data = 0;
            my $end = sysseek FILE, 0, Fcntl::SEEK_END or die "Unable to get EOF position: $!";
            $section_len = $end - $cur;
        } elsif ($data > $cur) {
            #case 2
            $in_data = 0;
            $section_len = $data - $cur;
        } else {
            #case 1
            my $hole = sysseek FILE, $data, $SEEK_HOLE;
            if (!defined($hole) or $hole eq $data) {
                die "Blah";
            }
            $in_data = 1;
            $section_len = $hole - $data;
        }
    };

    die "Blah" if ($@);

    # reposition file back
    sysseek FILE, $cur, Fcntl::SEEK_SET;

    return ($in_data, $section_len);
}

sub upload_skip_handler {
    my $st = shift;
    my $offset = shift;
    sysseek FILE, $offset, Fcntl::SEEK_CUR or die "Unable to seek in $FILE";
    return 0;
}

sub upload {
    my $vol = shift;
    my $st = shift;
    my $filename = shift;
    my $offset = 0;
    my $length = 0;

    open FILE, "<$filename" or die "unable to open $filename: $!";
    eval {
        $vol->upload($st, $offset, $length, Sys::Virt::StorageVol::VOL_UPLOAD_SPARSE_STREAM);
        $st->sparse_send_all(\&upload_handler, \&upload_hole_handler, \&upload_skip_handler);
        $st->finish();
    };
    if ($@) {
        close FILE;
        die $@;
    }

    close FILE or die "cannot close $filename: $!"
}

die "syntax: $0 URI --download/--upload VOLUME FILE" unless int(@ARGV) == 4;

my $uri = shift @ARGV;
my $action = shift @ARGV;
my $volpath = shift @ARGV;
my $filename = shift @ARGV;

my $c = Sys::Virt->new(uri => $uri) or die "Unable to connect to $uri";
my $vol = $c->get_storage_volume_by_key($volpath) or die "No such volume";
my $st = $c->new_stream();

if ($action eq "--download") {
    download($vol, $st, $filename);
} elsif ($action eq "--upload") {
    upload($vol, $st, $filename);
} else {
    die "unknown action $action";
}
