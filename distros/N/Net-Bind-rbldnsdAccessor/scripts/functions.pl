#!/usr/bin/perl
#
# functions.pl	version 1.00
#
# functions useful in the build process
#
use strict;
#use diagnostics;

# recursive copy, copy the directory for rbldnsd source without the "trash"
#
sub copy_r {
  my($dst,$src) = @_;
  $dst .= '/' unless $dst =~ m|/$|;
  die "file '$dst' found where directory expected\n"
	if -e $dst && ! -d $dst;
  unless (-e $dst) {
    mkdir $dst,0755;
  }
  $src .= '/' unless $src =~ m|/$|;
  my $buf;
  local(*IN,*OUT);
  opendir(IN,$src) or die "could not open directory '$src' for read\n";
  my @file = grep(	$_ ne '.' &&
			$_ ne '..' &&
			$_ ne 'Makefile' &&
			$_ !~ /^config\./ &&
			$_ !~ /o$/ &&
			$_ !~ /gz$/,
		readdir(IN));
  closedir IN;
  foreach(@file) {
    my $in = $src . $_;
    my $out = $dst . $_;
    if (-d $in) {	# if this is a directory
      copy_r($out,$in);
      next;
    }
    next unless -r $in;
    open(IN,$in) or die "could not open file '$in' for read\n";
    open(OUT,'>'. $out) or die "could not open file '$out' for write\n";
    my $bytes;
    while ($bytes = sysread(IN,$buf,4096)) {
      syswrite(OUT,$buf,$bytes) or die "failed to write '$bytes' bytes to '$out'\n";
    }
    close IN;
    close OUT;
  }
}

#
# find the path to an executable
#
sub findpath {
  my $file = shift;
  if ( -x "/bin/$file" ) {
    return "/bin/$file";
  }
  elsif ( -x "/usr/sbin/$file" ) {
    return "/usr/sbin/$file";
  }
  elsif ( -x "/sbin/$file" ) {
    return "/sbin/$file";
  }
  elsif ( -x "/usr/bin/$file" ) {
    return "/usr/bin/$file";
  }
  return '';
}

#
# remove directory and all contents
#
sub rm_dircon {
  my $dir = shift;
  $dir .= '/' unless $dir =~ m|/$|;
  return unless -e $dir && -d $dir;
  local *X;
  opendir(X,$dir) or do {print "could not open '$dir' for read\n"; exit;};
  my @file = grep($_ ne '.' && $_ ne '..',readdir(X));
  closedir X;
  foreach (@file) {
    my $file = $dir . $_;
    if (-d $file) {
      rm_dircon($file);		# recurse if directory
    }
    unlink $file;
  }
}

1;
