#! /usr/bin/env perl
#
use strict;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use autodie;

# install-mib FILE DIR

die "bad number of arguments" unless $#ARGV == 1;

my ($file, $destdir) = @ARGV;

my $mibname;

open(my $fd, '<', $file);
while (<$fd>) {
    s/^\s+//;
    if (/([\S]+)\s+DEFINITIONS\s+::=\s+BEGIN\s*$/) {
	$mibname = $1;
	last;
    }
}
close($fd);

die "no MIB definition in $file" unless defined $mibname;

make_path($destdir) unless -e $destdir;

copy($file, $destdir);

my $index = "$destdir/.index";
my $tmpname = $index . $$;
open(my $ofd, '>', $tmpname);

my $modified;

$file = basename($file);

if (-e $index) {
    open($fd, '+<', $index);
    while (<$fd>) {
	if (defined($mibname) and /^${mibname}\s+/) {
	    chomp;
	    my @a = split /\s+/;
	    unless ($#a == 1 and $a[1] eq $file) {
		print $ofd "$mibname $file\n";
		$modified = 1;
	    }
	    $mibname = undef;
	} else {
	    print $ofd $_;
	}
    }
    close($fd);
}

if (defined($mibname)) {
    print $ofd "$mibname $file\n";
    $modified = 1;
}
close $ofd;

if ($modified) {
    unlink $index if -e $index;
    rename $tmpname, $index;
} else {
    unlink $tmpname;
}
