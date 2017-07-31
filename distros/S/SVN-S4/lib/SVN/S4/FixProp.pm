# See copyright, etc in below POD section.
######################################################################

package SVN::S4::FixProp;
require 5.006_001;

use SVN::S4;
use SVN::S4::Debug qw (DEBUG is_debug);
use strict;
use Carp;
use IO::Dir;
use IO::File;
use Cwd;
use vars qw($AUTOLOAD);

use SVN::S4::Path;

our $VERSION = '1.066';

# Basenames we should ignore, because they contain large files of no relevance
our %_SkipBasenames = (
		      CVS => 1,
		      '.git' => 1,
		      '.svn' => 1,
		      blib => 1,
		      );

#######################################################################
# Methods

sub skip_filename {
    my $filename = shift;
    (my $basename = $filename) =~ s!.*/!!;
    return $_SkipBasenames{$basename}
}

sub file_has_keywords {
    my $filename = shift;
    # Return true if there's a svn metacomment in $filename

    return undef if readlink $filename;
    my $fh = IO::File->new("<$filename") or return undef;
    my $lineno = 0;
    while (defined(my $line = $fh->getline)) {
	$lineno++; last if $lineno>1000;
	if ($line =~ /[\001\002\003\004\005\006]/) {
	    # Binary file.
	    $fh->close;
	    return 0;
	}
	if ($line =~ /\$(LastChangedDate|Date|LastChangedRevision|Revision|Rev|LastChangedBy|Author|HeadURL|URL|Id)[: \$]/) {
	    $fh->close;
	    return 1;
	}
	if ($lineno==1 && $line =~ /^SVN-fs-dump-format/) {
	    return 0;
	}
    }
    $fh->close;
    return 0;
}

#######################################################################
#######################################################################
#######################################################################
#######################################################################
# OVERLOADS of S4 object
package SVN::S4;
use Cwd qw(getcwd);
use SVN::S4::Debug qw (DEBUG is_debug);

sub fixprops {
    my $self = shift;
    my %params = (#filename=>,
		  keyword_propval => 'author date id revision',
		  personal => undef,
		  autoprops => 1,
		  ignores => 1,
		  keywords => 1,
		  recurse => 1,
		  @_);

    DEBUG "fixprops (filename=>$params{filename})\n" if $self->debug;
    my $filename = $params{filename};
    $filename = getcwd()."/".$filename if $filename !~ m%^/%;
    $filename = $self->abs_filename($filename);
    _fixprops_recurse($self,\%params,$filename);
}

sub _fixprops_recurse {
    my $self = shift;
    my $param = shift;
    my $filename = shift;

    if (-d $filename) {
	my $dir = $filename;
	DEBUG "In $dir\n" if $self->debug;
	if (!$self->dir_uses_svn($dir)) {
	    # silently ignore a non a subversion directory
	} else {
	    if ($param->{ignores}) {
		$self->_fixprops_add_ignore($dir);
	    }
	    my $dh = new IO::Dir $dir or die "s4: %Error: Could not directory $dir.\n";
	    while (defined (my $basefile = $dh->read)) {
		next if $basefile eq '.' || $basefile eq '..';
		my $file = $dir."/".$basefile;
		next if SVN::S4::FixProp::skip_filename($file);
		if (-d $file) {
		    if ($param->{recurse} && !readlink $file) {
			_fixprops_recurse($self,$param,$file);
		    }
		} else {
		    if ($param->{recurse} || $file =~ m!/(\.cvsignore|\.gitignore)$!) {
			# If not recursing, we did a dir with -N; process the dir's ignore
			_fixprops_recurse($self,$param,$file);
		    }
		}
	    }
	    $dh->close();
	}
    }
    else {
	# File
	if ($param->{keywords}
	    && SVN::S4::FixProp::file_has_keywords($filename)) {
	    if ($self->file_url(filename=>$filename)
		&& !defined ($self->propget_string(filename=>$filename,
						   propname=>"svn:keywords"))
		&& (!$param->{personal}
		    || $self->is_file_personal(filename=>$filename))) {
		$self->propset_string(filename=>$filename, propname=>"svn:keywords",
				      propval=>$param->{keyword_propval});
	    }
	}
	if ($param->{autoprops}
	    && $self->file_url(filename=>$filename, assert_exists=>0)) {
	    $self->_fixprops_autoprops($filename);
	}
    }
}

sub _fixprops_add_ignore {
    my $self = shift;
    my $dir = shift;

    $dir =~ s!/\.$!!;
    my $ignores = "";
    my $went_up;
    for (my $updir = $dir; 1;) {
	$ignores .= $self->_fixprops_read_ignore($updir, $went_up++);
	$updir =~ m!(.*)/([^/]+)$! or last;
	$updir = $1;
	$self->dir_uses_svn($updir) or last;
    }
    if ($ignores && $ignores !~ /^\s*$/) { # else not found
	$ignores .= "\n";
	$ignores =~ s/[ \t\n\r\f]+/\n/g;
	$ignores =~ s/^\n+//g;
	$ignores =~ s/\n\n+/\n/g;
	$ignores =~ s!^/!!g; $ignores =~ s!\n/!\n!g;  # gitignore prepends / to mean current dir
	$self->propset_string(filename=>$dir, propname=>"svn:ignore", propval=>$ignores);
    }
}

sub _fixprops_read_ignore {
    my $self = shift;
    my $dir = shift;
    my $recursive_only = shift;
    my $val = $self->{_fixprops_read_ignore_cache}{$dir};
    if (!defined $val) {
	$val = (SVN::S4::Path::wholefile("$dir/.cvsignore")
		       || SVN::S4::Path::wholefile("$dir/.gitignore"));
	$val = "" if !defined $val;
	$self->{_fixprops_read_ignore_cache}{$dir} = $val;
    }
    if ($recursive_only) {
	if ($val =~ /\[recursive\]/) {
	    $val =~ s/.*\[recursive\]//g;
	} else {
	    $val = "";
	}
    } else {
	$val =~ s/\[recursive\]//g;
    }
    return $val;
}

sub _fixprops_autoprops {
    my $self = shift;
    my $filename = shift;
    my $val;
    for (my $updir = $filename; 1;) {
	$updir =~ m!(.*)/([^/]+)$! or last; $updir=$1;
	$self->dir_uses_svn($updir) or last;
	$val = $self->_fixprops_read_autoprops($updir);
	last if $val ne "";
    }
    return if !$val || $val eq '';
    foreach my $line (split /\n/, $val) {
	next if $line =~ /^\s*$/;
	if ($line =~ /^\s*([^= \t]*)\s*=\s*(.*)/) {
	    my $re = quotemeta($1);  my $props = $2;
	    $re =~ s/\\\*/.*/g; # Convert glob regexp to perl regexp
	    $re =~ s/\\\?/?/g;
	    if ($filename =~ /$re/) {
		while ($props =~ /([^;=]*)=([^;=]*)/g) {
		    my $prop=$1; my $val=$2;
		    DEBUG "autoprop: '$re' : '$prop'='$val'\n" if $self->debug;
		    if (!$self->propget_string(filename=>$filename, propname=>$prop)) {
			$self->propset_string(filename=>$filename, propname=>$prop, propval=>$val);
		    }
		}
	    }
	}
    }
}

sub _fixprops_read_autoprops {
    my $self = shift;
    my $dir = shift;
    my $val = $self->{_fixprops_read_autoprops_cache}{$dir};
    if (!defined $val) {
	$val = $self->propget_string(filename=>$dir, propname=>"tsvn:autoprops");
	$val = "" if !defined $val;
	$self->{_fixprops_read_autoprops_cache}{$dir} = $val;
	DEBUG "_fixprops_autoprops($dir) => $val\n" if $self->debug;
    }
    return $val;
}

######################################################################
### Package return
package SVN::S4::FixProp;
1;
__END__

=pod

=head1 NAME

SVN::S4::FixProp - Fix svn:ignore and svn:keywords properties

=head1 SYNOPSIS

Shell:
  s4 fixprop {files_or_directories}

Scripts:
  use SVN::S4::FixProp;
  $svns4_object->fixprop(filename=>I<filename>);

=head1 DESCRIPTION

SVN::S4::FixProp provides utilities for changing properties on a file-by-file basis.

=head1 METHODS

=over 4

=item file_has_keywords(I<filename>)

Return true if the filename contains a SVN metacomment.

=item skip_filename(I<filename>)

Return true if the filename has a name which shouldn't be recursed on.

=back

=head1 METHODS ADDED TO SVN::S4

The following methods extend to the global SVN::S4 class.

=over 4

=item $s4->fixprops

Recurse the specified files, searching for .cvsignore, .gitignore or
keywords that need repair.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2005-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SVN::S4>

=cut
