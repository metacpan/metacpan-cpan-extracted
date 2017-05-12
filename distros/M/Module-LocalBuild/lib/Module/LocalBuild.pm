# See copyright, etc in below POD section.
######################################################################

package Module::LocalBuild;
# This package is used by a LOT of other packages.  Keep it small.
use Carp;
use IO::Dir;

use strict;
use vars qw ($VERSION @Ignore_Files_Regexps);

$VERSION = '1.013';

@Ignore_Files_Regexps = (qr!/CVS$!,
			 qr!.git$!,
			 qr!.svn$!,
			 qr!/here_perl$!,
			 qr!/blib$!,
			 qr!\.old$!,
			 qr!\.t$!,	# Ignore all tests
			 qr!Makefile$!,
			 qr!Changes$!,
			 qr!pm_to_blib$!,
			 qr!/README$!,
			 );

#######################################################################
# User interface

sub need {
    my $self = {dest_dir => undef,
		locker_module => undef,
		libs => [],
		packages => [],
		ignore_files => [@Ignore_Files_Regexps],
		debug => $::Debug,
		mlbuilder => "$^X mlbuilder",
		deps => [],
		@_};
    $self->{dest_dir} or $#{$self->{packages}<0}
    or croak "%Error: Module::LocalBuild::build called without dest_dir argument, stopped";

    # Make sure the dest area is included in lookups
    if ($self->{dest_dir}) {
	push @{$self->{libs}}, ("$self->{dest_dir}/blib/lib",
				"$self->{dest_dir}/blib/arch");
    }

    # Use libraries
    foreach (@{$self->{libs}}) { _use_lib($_); }

    # Is the dest dir up to date?
    if ($self->{dest_dir}) {
	my $built_file = $self->{dest_dir}."/.built";

	my $rebuild = 0;
	if ($::Perl_Path_Build_Skip) {   # Historical avoidance of building
	}
	elsif (defined $ENV{MODULELOCALBUILD_CHECKED}) {  # We've done it recently
	}
	elsif (-r $self->{dest_dir}."/.builtforce") {  # User forced it, for example if a published area
	}
	elsif (! -r $built_file) {  # Haven't built
	    $rebuild = 1;
	} else {
	    # Have any files changed?
	    my $build_mtime = (stat($built_file))[9] || 0;
	    # Get true if any files newer than specified time
	    foreach my $dir (@{$self->{packages}}) {
		my $action = 'build';
		$rebuild=1 if _date_check_recurse($self, $dir, $build_mtime);
	    }
	    foreach my $dir (@{$self->{deps}}) {
		$rebuild=1 if _date_check_recurse($self, $dir, $build_mtime);
	    }
	}

	# Build the objects
	if ($rebuild) {
	    _request_build($self);
	    if (! -r $built_file) {
		die "%Error: Perl LocalBuild failed\n";
	    }
	}

	$ENV{MODULELOCALBUILD_CHECKED} = (scalar(localtime));
    }
}

sub _request_build {
    my $self = shift;
    print STDERR "Building Perl Libraries...\n";
    my @args;
    foreach my $dir (@{$self->{packages}}) {
	my $action = 'build';  # Later, check if $dir is a hash and check action
	if ($action eq 'build') {
	    push @args, "--".$action, $dir;
	} else {
	    croak "%Error: Invalid action $action for $dir, stopped";
	}
    }
    my $cmd = ($self->{mlbuilder}
	       .($self->{debug}?" --debug":"")
	       ." --destdir ".$self->{dest_dir}
	       .(defined $self->{locker_module}
		 ? " --locker ".$self->{locker_module} : "")
	       .' '.join(' ',@args));
    print "\t$cmd\n" if $self->{debug};
    system $cmd;  # No error checking, .built will do it for us
}

#######################################################################
# Internals

sub _use_lib {
    my $lib = shift;
    # Do a 'use lib' and also add to PERL5LIB
    #print "_use_lib $lib\n";
    my %p5lib_now = map {$_,$_} split (/:/, ($ENV{PERL5LIB}||""));
    if (!$p5lib_now{$lib}) {
	# Add to current lib list
	import lib $lib;  # Hack because don't want BEGIN block; in scripts 'use lib "..."' instead
	# Add to PERL5LIB also.  This enables scripts to call secondary
	# scripts and still find our perltools, without requiring the
	# secondary (and probably public) scripts to be changed
	if ($ENV{PERL5LIB}) {
	    $ENV{PERL5LIB}=$lib.":".$ENV{PERL5LIB};
	} else {
	    $ENV{PERL5LIB}=$lib;
	}
    }
}

########################################################################

our $_Date_Check_Recurse_Newer;

sub _date_check_recurse {
    my $self = shift;
    my $filename = shift;
    my $build_mtime = shift;
    # Return true if any file is newer than specified date
    #print "_date_check_recurse $filename\n" if $self->{debug};

    # Exceptions
    foreach my $re (@{$self->{ignore_files}}) {
	return 0 if $filename =~ /$re/;
    }

    if (-d $filename) {
	my $rebuild;
	my $dh = new IO::Dir($filename) or return 0;
	while (defined (my $basefile = $dh->read)) {
	    next if (($basefile eq ".") || ($basefile eq ".."));
	    my $file = "$filename/$basefile";
	    $rebuild = 1 if _date_check_recurse($self, $file, $build_mtime);
	}
	$dh->close();
	return $rebuild;
    } else {
	my $file_mtime = (stat($filename))[9] || 0;
	if (($file_mtime > $build_mtime) && -f $filename) {
	    if (1 || $self->{debug}) {  # So much will be printed out, we might as well.
		if (!$_Date_Check_Recurse_Newer) {
		    print "Some Perl files have changed:\n";
		}
		$_Date_Check_Recurse_Newer++;
		print "\t$filename is newer\n";
	    }
	    return 1;
	}
	return undef;
    }
}

#######################################################################
1;
__END__

=pod

=head1 NAME

Module::LocalBuild - Support routines for setting up perltools area

=head1 SYNOPSIS

    Module::LocalBuild::need
	( dest_dir => "obj_foobar",
	  # Areas we don't need to build, but need to add libraries for
	  libs => ["some_path/ModuleFoo/lib",
		   "some_path/ModuleBar/lib",
		   ],
          # Packages we need to build
	  # It is important to include Module-LocalBuild in its own list
	  # otherwise changes in the build process won't be detected as changes!
	  packages => ['some_path/Module-LocalBuild',
		       'some_path/ModuleBaz',
		       ],
	  # Additional build dependencies
	  deps => [],
	  );

=head1 DESCRIPTION

Module::LocalBuild is used to call 'perl Makefile.PL' and friends on
packages in a local working copy of a source code repository.  This allows
people to have local copies of Perl modules, and edit them at will without
having to worry about when to compile them.

It also allows the same sources to be simultaneously built and maintained
under different operating systems.

=head1 METHODS

=over 4

=item need

Specify needed submodules.  Checks the specified modules's date stamps, and
if needed run make on them, and install them into a local directory.

Setup the 'use lib' and PERL5LIB path appropriately to find the modules,
and so any programs called under a new shell (with the same environment)
will also find them.

Requires named parameters as specified below.

=over 4

=item dest_dir => I<directory>

Directory name to write the blib library tree under.  This directory should
be absolute, and should include the Perl version number; otherwise builds
on different OSes may collide.

=item deps => [ I<directories>... ]

Additional directory names which if change will request a rebuild.  This
is useful for local files, such as scripts which wrap mlbuilder.

=item libs => [ I<directories>... ]

Add the specified perl library directories, as if using 'use lib'.
However, in addition to doing a 'use lib' they will be added to PERL5LIB
such that subprocesses may see the libraries specified.

=item locker_module => I<package_name>

If specified, when a rebuild is required this package will be used for lock
services.  This prevent multiple processes from building at once, even when
run under NFS on different machines.  IPC::Locker is compatible with the
API required.

=item packages => [ I<packages>... ]

List of packages.  Future versions will support an array of hash
references, where each hash may specify an action associated with the
package.

=back

=back

=head1 ENVIRONMENT

=over 4

=item MODULELOCALBUILD

This environment variable is set automatically when the packages are built.
When set calling Module::LocalBuild will skip the build process.  This
accelerates subprocesses, as only the parent process needs to complete the
up-to-date check.

=item PERL5LIB

The requested libraries are appended to the standard Perl PERL5LIB
variable.

=back

=head1 DISTRIBUTION

Copyright 2000-2010 by Wilson Snyder.  This program is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License
Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<mlbuilder>, L<IPC::Locker>

=cut

######################################################################
