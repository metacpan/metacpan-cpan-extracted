# build_common.pl -- Build file common info
# RCS Info        : $Id: build_common.pl,v 1.5 2005/02/27 15:34:33 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Jan  5 16:44:56 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sun Feb 27 16:34:30 2005
# Update Count    : 8
# Status          : Unknown, Use with caution!

use strict;
use Config;
use File::Spec;

our $data;

$data->{version} = "0.95";

$data->{author} = 'Johan Vromans (jvromans@squirrel.nl)';
$data->{abstract} = 'Build standard web sites using the Template Toolkit';
$data->{pl_files} = {};
$data->{installtype} = 'site';
$data->{distname} = 'Template-TT2Site';
$data->{name} = "tt2site";
$data->{scripts} = [ map { File::Spec->catfile("scripts", $_) }
		     $data->{name} ];
$data->{prereq_pm} = {
		'Getopt::Long' => '2.1',
		'AppConfig' => '1.56',
		'Template' => '2.13'
	       };
$data->{recomm_pm} = {
		'Getopt::Long' => '2.32',
		'Template' => '2.14'
	       };
$data->{usrbin} = "/usr/bin";

sub checkbin {
    my ($msg) = @_;
    my $installscript = $Config{installscript};

    return if $installscript eq $data->{usrbin};
    print STDERR <<EOD;

WARNING: This build process will install a user accessible script.
The default location for user accessible scripts is
$installscript.
EOD
    print STDERR ($msg);
}

sub checkexec {
    my ($exec) = @_;
    my $path = findbin($exec);
    if ( $path ) {
	open (my $f, "<$path") or die("Cannot open $path: $!\n");
	my $line = <$f>;
	close($f);
	if ( $line =~ m;^#!.*\bperl\b; ) {
	    print STDERR ("Good, found ttree [Perl program] in $path\n");
	}
	else {
	    print STDERR ("Found ttree in $path, but it doesn't seem".
			  " to be a Perl program.\n",
			  "$data->{distname} needs the Perl program to execute.\n",
			  "Please make it available.\n");
	}
    }
    else {
	print STDERR ("Hmm. Couldn't find $exec in PATH\n");
    }
}

sub findbin {
    my ($bin) = @_;
    foreach ( File::Spec->path ) {
	return "$_/$bin" if -x "$_/$bin";
    }
    undef;
}

sub filelist {
    my ($dir, $pfx) = @_;
    $pfx ||= "";
    my $dirl = length($dir);
    my $pm;
    find(sub {
	     if ( $_ eq "CVS" ) {
		 $File::Find::prune = 1;
		 return;
	     }
	     return if /^#.*#/;
	     return if /~$/;
	     return unless -f $_;
	     if ( $pfx ) {
		 $pm->{$File::Find::name} = $pfx .
		   substr($File::Find::name, $dirl);
	     }
	     else {
		 $pm->{$File::Find::name} = $pfx . $File::Find::name;
	     }
	 }, $dir);
    $pm;
}

1;
