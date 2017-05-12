# Rcs::Agent
#
# An RCS frobnicator
#
# $Id: Agent.pm,v 1.32 2007/08/20 16:39:56 nick Exp $

package Rcs::Agent;

# Be neutoric about syntax
use strict;

# These packages are part of the base perl system 
use Carp;
use File::Basename;
use File::stat;
use Cwd;

# These packages are from CPAN
use String::ShellQuote;
use File::Temp;

# Data::Dumper is used solely for debugging
# use Data::Dumper;

use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION $AUTOLOAD);

$VERSION = '1.05';

1;


=head1 NAME

Rcs::Agent - an RCS archive manipulation method library

=head1 SYNOPSIS

C<use Rcs::Agent;>

=head1 DESCRIPTION

C<Rcs::Agent> is a perl module for manipulating RCS archives.  It provides
an object-oriented interface to the RCS commands C<rcs(1)>, C<rcsdiff(1)>,
C<ci(1)> and C<co(1)>, in addition to providing easy access to revision
information contained in the RCS archive file.  A description of how RCS
works is beyond the scope of this document, or to put it simply, you need to
learn how to use RCS before using this perl interface to it.

=head1 METHODS

=head2 new

The new() method is the C<Rcs::Agent> constructor, and is used both to 
create new RCS archives files if they do not already exist, or manipulate
existing ones if they already exist in the specified location.

Typically, new() would be called using the following parameters:

    $rcs = new Rcs::Agent (	file => "/data/src/foobar.c");

The C<file> parameter tells the module what the name of the work file is.  This
is the only parameter which is absolutely necessary: if it is not supplied,
then new() will return undef and all subsequent method calls using the C<$rcs>
handle will fail.

The C<workdir> parameter can be used to specify the working directory of
the file, if for some reason the programmer decides not to specify it using
the C<file> parameter.  The example above could easily have been written:

    $rcs = new Rcs::Agent (	file => "foobar.c", 
    				workdir => "/data/src");

The C<rcsdir> parameter specifies the location of the RCS archive.  This is
normally designated as the "RCS/" directory off the working directory, but
there is no reason why C<rcsdir> cannot be placed somewhere else if so 
desired.  If this parameter is not specified, then the module uses some
simplistic heuristics to determine the location of the RCS directory
automatically.  If there is a directory off the working directory called "RCS/"
then the module will use that.  If there is not, then it will use the
working directory.

The C<suffix> parameter specifies the RCS archive file suffix to use.  On a
Unix or a  Unix-lookalike system, this is usually ",v".  There is normally no
need to change this parameter.

The C<tmpdir> parameter specifies the location of a directory which is
writable and which can by used by the L<Rcs::Agent> library to create temporary
files when necessary.  While this defaults to "/tmp", it is strongly suggested
for security reasons that a different, application-specific temporary directory
be used.

=cut

##
## new
##  

sub new {
	my ($type) = shift if @_;
	my $class = ref($type) || $type || "Rcs::Agent";
	my %args = @_;
	my ($tag);
	my @tags = qw (file workdir rcsdir suffix tmpdir);

	my $self = {
		version	=> $VERSION,
		err	=> "",
	};

	foreach $tag (@tags) {
		$self->{$tag} = $args{$tag} if (defined ($args{$tag}));
	}

	# Default suffix is ",v"
	$self->{suffix} = ",v" unless (defined ($self->{suffix}));

	# don't continue unless a filename is supplied
	return undef if (!defined ($self->{file}));

	# filename contains path separators?
	if ($self->{file} =~ /\//) {
		my $dir = dirname($self->{file});
		# if pathname is absolute, then path => workdir, basename => file
		if ($dir =~ /^\//) {
			$self->{workdir} = $dir;
			$self->{file} = basename($self->{file});
		# otherwise append path to workdir, if it already exists.
		} else {
			$self->{workdir} = defined ($self->{workdir}) ? $self->{workdir} : "";
			$self->{workdir} .= "/$dir";
		}
	}

	$self->{workdir} = "." unless (defined ($self->{workdir}));

	# don't continue unless the work directory actually exists
	return undef unless (-d $self->{workdir});

	# trim trailing slashes off end of workdir
	$self->{workdir} =~ s/(\/+)$//g;

	# Figure out correct rcsdir
	#
	# If rcsdir has been supplied, then use that.
	# If rcsdir hasn't been supplied, then check for workdir/RCS/foo,v and workdir/foo,v in order

	unless (defined ($self->{rcsdir})) {
		# if RCS/ directory exists and there's a version file in it, use that.
		if (-d $self->{workdir}."/RCS" && 
				-e $self->{workdir}."/RCS/".$self->{file}.$self->{suffix}) {
			$self->{rcsdir} = $self->{workdir}."/RCS";

		# if the version file is in the workdir, use that...
		} elsif (-e $self->{workdir}."/".$self->{file}.$self->{suffix}) {
			$self->{rcsdir} = $self->{workdir};

		# there's no version file at all => use RCS/ dir if it exists, otherwise workdir
		} else {
			$self->{rcsdir} = (-d $self->{workdir}."/RCS") ?
				$self->{workdir}."/RCS" : $self->{workdir};
		}
	}

	$self->{rcsdir} =~ s/(\/+)$//g;

	$self->{rcsfile} = $self->{rcsdir}."/".$self->{file}.$self->{suffix};

	$self->{hpux} = 1 if $^O eq 'hpux';

	bless $self, $class;

	return $self;
}


=head2 err

The err() method returns whatever is currently in the error buffer.  Whenever
any method in this library fails for some reason, the method will put a message
into the error buffer and then return undef to the calling function.  This
method is used to access the error message.  It takes no parameters and returns
a scalar text string, which may be zero length if there is no current error.

=cut

##
## err
##

sub err {
	my $self = shift;

	$self->{err};
}


=head2 head

The head() method returns the revision number of the top of the RCS tree.

=cut

##
## head
##

sub head {
	my $self = shift;

	$self->{err} = "";

	$self->parse || return undef;

	return $self->{head};
}


=head2 timestamp

The timestamp() method returns the mtime timestamp of the RCS archive file
in C time format (i.e. seconds since the epoch).  For convenience, this
value can also be accessed by referring to $rcs->{mtime}.

=cut

##
## timestamp
##

sub timestamp {
	my $self = shift;

	$self->{err} = "";

	my $sb = stat($self->{rcsfile});
	unless (defined($sb)) {
		$self->{err} = "couldn't open $self->{rcsfile}: $!";
		return undef;
	}

	$self->{mtime} = $sb->mtime;

	$sb->mtime;
}


=head2 archived

The archived() method indicates whether the file in question is already
in RCS control.  It is a quick and dirty function which simply tests whether
the file has a readable RCS archive file.  It returns 1 or 0, depending on
whether this test is found to be true or not.

=cut

##
## archived
##

sub archived {
	my $self = shift;

	-r $self->{rcsfile} ? 1 : 0;
}


##
## parse
##
## parses the RCS archive file.  This is an internal-only function.  Please ignore it.
##
## returns:     1 if the file already has a readable and parsable RCS archive file
##              undef otherwise, putting flag in error buffer
##

sub parse {
	my $self = shift;
	my %args = @_;
	my %branches;

	$self->{err} = "";

	# only parse file if not parsed previously and rcs file has not been modified
	if ($self->{parsed}) {
		my $mtime = $self->{mtime};
		return 1 if ($mtime == $self->timestamp);
	}

	if (!$self->archived) {
		$self->{err} = "RCS archive file not found";
		return undef;
	} 

	# This is to prevent recursion
	if (defined ($self->{parsing})) {
		return 1;
	}
	$self->{parsing} = 1;

	# First, we need to delete a whole bunch of stuff if it's already
	# defined from previous parsing attempts.
	foreach my $tag (qw (access revisions head symbols strict)) {
		delete $self->{$tag} if defined ($self->{$tag});
	}

	unless (open (INPUT, $self->{rcsfile})) {
		$self->{err} = "couldn't open $self->{rcsfile}: $!";
		return undef;
	}

	# The preamble contains information about the archive.  We slurp it in as a single
	# paragraph

	my $oldseparator = $/;
	$/ = "";

	my $data = <INPUT>;
	$data =~ s/[\n\r\s]+/ /g;
	my @tokens = split (/\s*;\s*/, $data);

	$self->{strict} = 0;

	# For the moment, we only parse head, locks, symbols and strict.
	foreach my $token (@tokens) {
		if ($token =~ /^access/) {
			my @access = split (/ /, $token); shift @access;
                        $self->{access} = \@access if @access;
			next;
		}

		if ($token =~ /^head\s+([\d\.]+)/) {
			$self->{head} = $1;
			next;
		}

		if ($token =~ /^strict/) {
			$self->{strict} = 1;
			next;
		}

		if ($token =~ /^symbols/) {
			my @symtokens = split (/ /, $token); shift @symtokens;
			foreach my $tag (@symtokens) {
				next unless ($tag =~ /(.*):(.*)/);
				$self->{symbols}->{$1} = $2;
			}
			next;
		}

		if ($token =~ /^locks/) {
			my @symtokens = split (/ /, $token); shift @symtokens;
			foreach my $tag (@symtokens) {
				next unless ($tag =~ /(.*):(.*)/);
				$self->{revisions}->{$2}->{locker} = $1;
			}
			next;
		}
	}

	# deal with the individual revision entry
	while ($data = <INPUT>) {
		my ($nextrev);
		$data =~ s/[\n\r\s]+/ /g;
		next unless ($data =~ /([\d\.]+)\s+(.*)/);
		my $revision = $1; $data = $2;

		delete $branches{$revision} if ($branches{$revision});

		@tokens = split (/\s*;\s*/, $data);

		foreach my $token (@tokens) {
			if ($token =~ /^next\s+([\d\.]+)/) {
				my ($up, $down) = qw (parent child);
				$nextrev = $1;

				# set up doubly linked list so that each revision knows what's next
				# to it.  For some reason which I don't see, the direction of the
				# next revisions in the head line is in the opposite direction to
				# revisions in the branches.  If you don't understand what I mean
				# here, take a look at the direction of the arrows in the ascii art
				# in the man page for rcsfile(5).  This means that we have to
				# invert child and parent in this context.

				if ($revision =~ /^\d+\.\d+$/) {		# i.e. head branch
					($up, $down) = qw (child parent);	# i.e. arseways
				}

				$self->{revisions}->{$revision}->{$down} = $nextrev;
				$self->{revisions}->{$nextrev}->{$up} = $revision;

				# we need a place to put in initial revision numbers. This is as
				# good as any
				$self->{revisions}->{$revision}->{linesadded} = 0;
				$self->{revisions}->{$revision}->{linesdeleted} = 0;
				next;
			}

			if ($token =~ /^author\s+(\S+)/) {
				$self->{revisions}->{$revision}->{author} = $1;
				next;
			}

			if ($token =~ /^state\s+(\S+)/) {
				$self->{revisions}->{$revision}->{state} = $1;
				next;
			}

			if ($token =~ /^date\s+(\S+)/) {
				$self->{revisions}->{$revision}->{date} = $1;
				next;
			}

			if ($token =~ /^branches/) {
				my @symtokens = split (/ /, $token); shift @symtokens;
				next unless ($#symtokens >= 0);
				push (@{$self->{revisions}->{$revision}->{branches}}, @symtokens);
				foreach my $symtoken (@symtokens) {
					$self->{revisions}->{$symtoken}->{parent} = $revision;
					$branches{$symtoken} = 1;
				}

				next;
			}
		}

		last unless ($nextrev || scalar(%branches));
	}

	# Now we need to go back to line-by-line processing mode
	$/ = $oldseparator;

	my $intext = 0;

	# pull out the archive description
	while (chomp($data = <INPUT>)) {

		if (!$intext && $data =~ /^desc/) {
			$intext = 1;
			next;
		}

		# first line of data text
		if ($intext == 1 && $data =~ /^\@/) {
			$data =~ s/^\@//;
			$intext++;
		}
			
		# end of text input is marked by @ at EOL
		if ($intext && $data =~ /[^\@]*\@$/) {
			$data =~ s/\@$//;	# remove trailing 
			push @{$self->{desc}}, $data if ($data);
			$intext = 0;
			last;
		}

		push @{$self->{desc}}, $data if ($intext);
	}

	my $texttype = ""; my $revision = "";
	my $donelog = 0; my $donetext = 0;

	# finally we reach the revision info
	while ($data = <INPUT>) {
		my $added = 0;
		my $deleted = 0;

		chomp ($data);

		next if (!$revision && $data =~ /^\s*$/);

		$revision = $data;

		$data = <INPUT>;
		if ($data =~ /^log/) {
			chomp ($data = <INPUT>);
			$data =~ s/^\@//;
			push @{$self->{revisions}->{$revision}->{log}}, log_unquote($data) if ($data =~ /./);
			while (chomp($data = <INPUT>)) {
				if ($data =~ /(|[^\@])\@$/) {
					$data =~ s/\@$//;
					push @{$self->{revisions}->{$revision}->{log}}, log_unquote($data) if ($data);
					last;
				}
				push @{$self->{revisions}->{$revision}->{log}}, log_unquote($data);
			}
		}

		$data = <INPUT>;
		if ($data =~ /^text/) {
			$data = <INPUT>;
			$data =~ s/^\@//;

			TEXT: while ($data) {
				chomp($data);

				if ($data =~ /(|[^\@])\@$/) {
					$data =~ s/\@$//;
					last TEXT;
				}

				if ($revision eq $self->{head}) {
					$data = <INPUT>;
					next TEXT;
				} elsif ($data =~ /^d\d+\s+(\d+)$/) {
					$deleted += $1;
				} elsif ($data =~ /^a\d+\s+(\d+)$/) {
					my $localadd = $1;
					$added += $localadd;
					for (my $i = 0; $i <$localadd; $i++) {
						$data = <INPUT>;
						redo TEXT if ($data =~ /(|[^\@])\@$/); # urk, spaghetti
					}
				}
				$data = <INPUT>;
			};

			if ($revision eq $self->{head}) {
				$revision = "";
				next;
			}

			# Due to the way that branches are managed, the head branch always lists
			# diffs relative to the child revision, while sub-branches always list them
			# relative to the current revision.  See the explanation above for more
			# details

			my ($diffrecip);

			if ($revision =~ /^\d+\.\d+$/) {
				$diffrecip = $self->child(revision => $revision);
				$self->{revisions}->{$diffrecip}->{linesadded} = $deleted;
				$self->{revisions}->{$diffrecip}->{linesdeleted} = $added;
			} else {
				$diffrecip = $revision;
				$self->{revisions}->{$diffrecip}->{linesadded} = $added;
				$self->{revisions}->{$diffrecip}->{linesdeleted} = $deleted;
			}

			$revision = "";
		}
	}

	close (INPUT);

	delete ($self->{parsing});
	$self->timestamp;
	$self->{parsed} = 1;

	1;
}


=head2 diff

The diff() method returns a list of differences between one version of the 
RCS archive and another.  If neither the C<revision1> nor C<revision2> 
parameters are passed to this method, then it will return the list of diffs 
between the current working file and the head version.  If C<revision1> alone
is specified, then it will return a list of diffs between the current working
file and the specified version, and if both parameters are supplied, then it 
will provide a list of diffs between the version specified in C<revision1>
and C<revision2>.  The method will return undef if either of the revisions
specified don't exist.

It is also possible to specify the revisions using symbolic names or tags
instead of version numbers.

The format of the diff output can be controlled using the C<format> parameter.
If this is set to C<context>, then it will produce context diffs; if it is set
to C<unified>, then unified diffs will be returned if the system's version of
diff(1) supports unified diffs.  If the format is not specified, or if it is
set to C<old>, then diff() will return a list of diffs in classic format.

=cut

##
## diff
##

sub diff {
	my $self = shift;
	my %args = @_;
	my ($exitcode, $stdout, $stderr);

	$self->{err} = "";

	$self->parse || return undef;

	my $cmdargs = "";

	my %outputformat = (
		"context" => "-c",
		"unified" => "-u",
		"old" => "",
	);

	unless (defined $args{format}) {
		$args{format} = "old";
	}

	my $validformats = join('|', keys %outputformat);
	if ($args{format} =~ /^($validformats)$/i) {
		$cmdargs = $outputformat{lc($1)};
	} else {
		$cmdargs = $outputformat{"old"};
	}

	foreach my $rev ($args{revision1}, $args{revision2}) {
		next unless (defined ($rev));
		# We can either have a revision or a tag here
		unless (defined ($self->{revisions}->{$rev}) || 
			defined ($self->{symbols}->{$rev})) {
			$self->{err} = "invalid revision number / tag supplied";
			return undef;
		}

		$cmdargs .= " -r".shell_quote("$rev");
	}

	my $q = $self->{hpux} ? '' : '-q';
	my $command = "rcsdiff $q $cmdargs ".shell_quote($self->{rcsfile});

	($exitcode, $stdout, $stderr) = $self->pipestderrout(command => $command, dir => $self->{workdir});

	if ($exitcode > 1) {
		$self->{err} = join("\n", @{$stderr})."\n";
		return undef;
	}

	return $stdout;
}


=head2 checkin

The checkin() method allows the programmer to check a version of the file into
the RCS archive.  By default, the revision will be inserted at the head of the
revision tree, unless the revision is specified using the C<revision> parameter.

A comment can be added to the revision's log using the I<log> parameter.  If
no comment or a blank comment is specified, then the revision is logged with the 
text "*** empty log message ***", as happens when using the RCS C<ci> program.

The revision may be tagged with a symbolic name using the I<tag> parameter.
If the I<force> parameter is set to "yes" then the symbolic name will override
any previous assignment of the symbolic name.

If the programmer wishes to check the version out after check-in, then the 
C<checkout> parameter should be set to "yes".  This is useful if the programmer
wishes to keep a working copy of the file outside the archive.  If checkout is
disabled, then the working copy of the file is deleted on check-in, which may
not suit all purposes.  By default, this option is turned on.

In addition, the programmer may wish to check out and lock the revision
immediately  after checkin.  This can be accomplished setting the C<lock>
parameter to "yes".

These last two options correspond to the I<-u> and I<-l> options in C<ci>
respectively.

The checkin() method will return the numeric value 1 on success and undef on
failure.  As with all of these methods, in the event of the method returning
undef, a failure message will be logged into the error buffer.

=cut

##
## checkin
##

sub checkin {
	my $self = shift;
	my %args = @_;
	my $cmdargs = "";
	my ($exitcode, $stdout, $stderr);

	$self->{err} = "";

	$args{log} = "*** empty log message ***" unless (defined ($args{log}) && $args{log} =~ /\S/);

	$cmdargs .= "-m".shell_quote($args{log});

	# Added 'tag' argument to checkin so we can tag the revision checked in
	if ( defined $args{tag} ) {
		$cmdargs .= ( defined($args{force}) and istrue($args{force}) ) ? " -N" : " -n";
		$cmdargs .= shell_quote($args{tag});
	}

	my $lock = defined ($args{lock}) ? istrue ($args{lock}) : 0;
	my $checkout = (defined ($args{checkout}) || $lock) ? istrue ($args{checkout}) : 1;

	if ($lock) {
		$cmdargs .= " -l";
	} elsif ($checkout) {
		$cmdargs .= " -u";
	}

	if (defined ($args{revision})) {
		unless ($args{revision} =~ /^\d[\d\.]*\d$/) {
			$self->{err} = "incorrect revision format";
			return undef;
		}
		if (defined ($self->{revisions}->{$args{revision}})) {
			$self->{err} = "specified revision already exists";
			return undef;
		}
		$cmdargs .= " -r".shell_quote($args{revision});
	}

	my $command = "ci $cmdargs ".shell_quote($self->{rcsfile});

	($exitcode, $stdout, $stderr) = $self->pipestderrout(command => $command, dir => $self->{workdir});

	if ($exitcode > 0) {
		$self->{err} = join("\n", @{$stderr})."\n";
		return undef;
	}

	return 1;
}


=head2 checkout

The checkout() method allows the programmer to check a version of the file
out of the RCS archive.  By default, if no revision is specified using the
C<revision> parameter, then the head revision will be checked out. It is 
possible to specify the revisions using symbolic names or tags instead of
version numbers when checking out revisions.

The programmer may put a lock on the revision being checked out by setting
the C<lock> parameter to be "yes".

If there is a version of the archive already locked, or if the working file
is writable, the check-out procedure will normally fail.  This behaviour is
to prevent the programmer from accidentally over-writing the work of another
user who may also be editing a revision of the file.  Checkouts can be forced
by setting the C<force> parameter to be "yes";  this option should not be
used unless the operator is certain that no damage will be done.

The checkout() method will return the numeric value 1 on success and undef on
failure.

=cut

##
## checkout
##

sub checkout {
	my $self = shift;
	my %args = @_;
	my $cmdargs = "";
	my ($exitcode, $stdout, $stderr);

	$self->{err} = "";

	$self->parse || return undef;

	$cmdargs .= " -l" if (defined ($args{lock}) && istrue ($args{lock}));

	# HP-UX co does not have -f option, so just delete the file
	if ( $self->{hpux} ) {
		if (defined($args{force}) and istrue($args{force})) {
			unlink "$self->{workdir}/$self->{file}";
		}
	} else {
		$cmdargs .= " -f" if (defined ($args{force}) && istrue ($args{force}));
	}

	if (defined ($args{revision})) {
		$self->rexists (revision => $args{revision}) || return undef;
		$cmdargs .= " -r".shell_quote($args{revision});
	}

	my $command = "co $cmdargs ".shell_quote($self->{rcsfile});

	($exitcode, $stdout, $stderr) = $self->pipestderrout(command => $command, dir => $self->{workdir});

	if ($exitcode > 0) {
		$self->{err} = join("\n", @{$stderr})."\n";
		return undef;
	}

	return 1;
}


=head2 lock

The lock() method permits the operator to lock a specific revision in the 
RCS archive without actually checking it out.  By default, if no revision
is specified using the C<revision> parameter, then the head revisision will
be locked. It is possible to specify the revisions using symbolic names or
tags instead of version numbers when checking out revisions.

If the specified revision in the archive is already locked, then this method
will fail.

The checkout() method will return the numeric value 1 on success and undef on
failure.

=cut

##
## lock
##
## Locks the specified revision in the archive 
##
## parameters:
##	[revision]	the revision number to lock
##	[lock]		1 => lock, 0 => unlock [default: lock]
##

sub lock {
	my $self = shift;
	my %args = @_;
	
	my $cmdargs = "";
	my ($exitcode, $stdout, $stderr, $lockcmd);

	$self->{err} = "";

	$self->parse || return undef;

	if (defined ($args{lock})) {
		$lockcmd = istrue ($args{lock}) ? "l" : "u";
	} else {
		$lockcmd = "l";
	}

	$cmdargs .= " -$lockcmd";
	
	if (defined ($args{revision})) {
		$self->rexists (revision => $args{revision}) || return undef;
		$cmdargs .= shell_quote($args{revision});
	}

	my $command = "rcs $cmdargs ".shell_quote($self->{rcsfile});

	($exitcode, $stdout, $stderr) = $self->pipestderrout(command => $command, dir => $self->{workdir});

	if ($exitcode > 0) {
		$self->{err} = join("\n", @{$stderr})."\n";
		return undef;
	}

	return 1;
}


=head2 unlock

The unlock() method performs the exact opposite as the lock() method: it
unlocks the specified revision in the archive.

If the specified revision in the archive is already unlocked, then this method
will fail.

The unlock() method will return the numeric value 1 on success and undef on
failure.

=cut

##
## unlock
##

sub unlock {
	my $self = shift;

	$self->lock (lock => 0, @_);
}


=head2 initialize

The initialize() method is used to create and initialize an RCS archive for
the working file if none existed previously.

The archive description can be specified using the "description" parameter.

If RCS version 5.7 or higher is installed on the system, the archive can be
initialized to be binary safe by setting the "binary" parameter.  Note that
rcsmerge may not work properly on archives with binary data, and also that
if there is a string in the binary file which matches an RCS keyword (i.e.
\$Id\$, \$Log\$, etc), RCS may attempt to replace it with the its
corresponding expanded value on checkout which may corrupt your binary file. 
See L<co> for more details both of these issues.

The initialize() method returns the numeric value 1 on success and undef on
failure.

=cut

##
## initialize
##

sub initialize {
	my $self = shift;
	my %args = @_;

	my $cmdargs = "";
	my ($exitcode, $stdout, $stderr, $lockcmd);

	if ($self->archived) {
		$self->{err} = "RCS archive already exists";
		return undef;
	}

	$args{description} = "" unless (defined ($args{description}) && $args{description} =~ /\S/);

	$cmdargs .= " -kb" if ($args{binary});
	$cmdargs .= " -t-".shell_quote($args{description}) if ($args{description});

	my $command = "rcs -i $cmdargs ".shell_quote($self->{rcsfile});

	($exitcode, $stdout, $stderr) = $self->pipestderrout(command => $command, dir => $self->{workdir});

	if ($exitcode > 0) {
		$self->{err} = join("\n", @{$stderr})."\n";
		return undef;
	}

	return $self->parse;
}


=head2 rexists

The rexists() method checks to make sure that the revision specified in the
parameter list actually exists in the RCS archive.  If this is the case,
then the revision number will be returned.  If it does not exist, or some
other error is detected, then undef is returned, and an error is left in the
error buffer.

=cut

##
## rexists
##

sub rexists {
	my $self = shift;
	my %args = @_;
	my $revision;

	$self->{err} = "";

	$self->parse || return undef;

	unless (defined ($args{revision})) {
		$self->{err} = "revision parameter not defined";
		return undef;
	}

	$revision = $self->symbol_lookup(symbol => $args{revision});

	unless (defined($self->{revisions})) {
		$self->{err} = "revision tree does not exist - RCS archive not yet set up";
		return undef;
	}

	if (defined ($self->{revisions}->{$revision})){
		return $revision;
	}

	$self->{err} = "revision not found in RCS archive";
	return undef;
}

=head2 parent

The parent() method returns the previous revision relative to the revision
specified in the parameter list, or undef if it does not exist:

In the following example, $parent might be assigned the value '1.1'.

    my $parent = $rcs->parent (revision => '1.2');

When dealing with branches, the real parent branch is returned, and not the
virtual branch fork revision.  So, for example, the following code sets the
value of $parent to be '1.5' rather than '1.5.3':

    my $parent = $rcs->parent (revision => '1.5.3.1');

If the I<revision> parameter is omitted, the revision defaults to the head
revision.

=cut

##
## parent
##

sub parent {
	my $self = shift;
	my %args = @_;

	$self->{err} = "";

	$self->parse || return undef;

	my $revision = defined ($args{revision}) ? $self->symbol_lookup(symbol => $args{revision}) : $self->{head};

	$self->rexists (revision => $revision) || return undef;

	return $self->{revisions}->{$revision}->{parent};
}


=head2 child

Similar to parent(), child() returns the next revision relative to the
revision specified in the parameter list, or undef if it does not exist.

=cut

##
## child
##

sub child {
	my $self = shift;
	my %args = @_;

	$self->{err} = "";

	$self->parse || return undef;

	my $revision = defined ($args{revision}) ? $self->symbol_lookup(symbol => $args{revision}) : $self->{head};

	$self->rexists (revision => $revision) || return undef;

	return $self->{revisions}->{$revision}->{child};
}


=head2 revisions

The revisions() method returns a reference to an array containing the names
of all of the revisions listed in the RCS archive.

=cut

##
## revisions
##

sub revisions {
	my $self = shift;
	my %args = @_;

	# FIXME: we need to do something about branches here

	$self->{err} = "";

	$self->parse || return undef;

	my @array = keys (%{$self->{revisions}});

	\@array;
}


=head2 symbols

The symbols() method returns a reference to an array containing the names
of all of the symbolic names listed in the RCS archive.

=cut

##
## symbols
##

sub symbols {
	my $self = shift;
	my %args = @_;

	$self->{err} = "";

	$self->parse || return undef;

	my @array = keys (%{$self->{symbols}});

	\@array;
}

=head2 access

The access() method returns a reference to an array containing the names
of all of the logins who have access to lock the RCS file, or undef
if it is an empty list.

=cut

##
## access
##

# Added access method to return access list of rcs file
sub access {
	my $self = shift;
	my %args = @_;

	$self->{err} = "";

	$self->parse || return undef;

	return unless exists $self->{access};

	my @array = @{$self->{access}} or return;

	\@array;
}

=head2 description

description() is used to read or write the archive description.  This is the
text which is logged in the RCS archive using the "-t-" parameter.  If the
"description" parameter is set in the argument list, then the description in
the archive file is set to the value specified.

    my $description = $rcs->description ();

In this code, the $description variable will be set to the archive's
description field, if it exists.

    $rcs->description (description => 'Main source file');

In this code snippet, the RCS archive description is set to be be the value
"Main source file".

=cut

##
## description
##

sub description {
	my $self = shift;
	my %args = @_;

	$self->{err} = "";

	$self->parse || return undef;

	if ($args{description}) {
		my ($exitcode, $stdout, $stderr);
		my $cmdargs .= " -t-".shell_quote($args{description});
		my $command = "rcs -q $cmdargs ".shell_quote($self->{rcsfile});
		
		($exitcode, $stdout, $stderr) = $self->pipestderrout(command => $command, dir => $self->{workdir});
		
		if ($exitcode > 1) {
			$self->{err} = join("\n", @{$stderr})."\n";
			return undef;
		}
		$self->{desc} = $args{description};
	}

	return $self->{desc};
}

=head2 locked, locker, state, author, date, log

These methods return the RCS archive data specified by the method name.  If
the "revision" parameter is given, then the method will return data relevant
to the specified revision.  Otherwise, the method will return data relevant
to the head revision.  All of the methods except for "log" return a scalar
value.  "log" returns a reference to an array of scalars, each of which
corresponds to a line of the log message for the specified revision.

The locked() method is the same as locker(), and is included to allow more
readable code such as

    if ($rcs->locked(revision => "1.3")) {
        <code if version is locked>
    } else {
        <code if version is unlocked>
    }

As another example, the following line of code will return the author of
revision 1.2 of the current RCS object:

    my $author = $rcs->author(revision => "1.3");

If the data for the specified revision does not exist, then the method will
return undef.

=cut

##
## AUTOLOAD
##

sub AUTOLOAD {
	my $self = shift;
	my ($method) = $AUTOLOAD;
	my %args = @_;
	my $revision;

	$method =~ s/^.*:://;

	($method =~ /^(access|locked|locker|state|author|date|log)$/) ||
		confess ("Can't locate object method \"$method\"");

	$method = "locker" if ($method eq "locked");

	$self->{err} = "";

	$self->parse || return undef;

	$revision = defined ($args{revision}) ? $self->symbol_lookup(symbol => $args{revision}) : $self->{head};

	$self->rexists (revision => $revision) || return undef;

	if (defined ($self->{revisions}->{$revision}->{$method})) {
		return $self->{revisions}->{$revision}->{$method};
	}

	return undef;
}

##
## DESTROY
##
## Some methods explicitly call DESTROY().  We need something to return
## success.
##

sub DESTROY {
	return;
}


##
## pipestderrout
##
## executes a command, trapping the output from both STDERR and STDOUT. This sort of thing is a 
## real pain in the ass in perl, and the simplest (but not the most efficient) way to do it is
## to simply use shell redirects to files and then slurp up the contents of these files.  The best 
## way to do it is probably to use IPC::Run which is unfortunately a pretty heavyweight package.
##
## this command should not be called from any user programs.  The API may change at any stage
## without warning.  Use at your own risk.  May bite if not handled carefully.
##
## returns:	an array containing the exit code and references to stdout and stderr respectively
##		undef if no command is issued, or if the temporary directory is unwritable,
##		putting flag in error buffer.
##

sub pipestderrout {
	my $self = shift;
	my %args = @_;
	my ($exitcode, $stdout, $stderr, $cwd);

	unless (defined ($args{command})) {
		$self->{err} = "must supply \"command\" argument";
		return undef;
	}

	my $tmpdir = defined ($self->{tmpdir}) ? $self->{tmpdir} : "/tmp";
	unless (-d $tmpdir && -r$tmpdir) {
		$self->{err} = "cannot write to tmpdir: \"$tmpdir\"";
		return undef;
	}

	my $tmpstdout = File::Temp::mktemp("$tmpdir/tempXXXXXX");
	my $tmpstderr = File::Temp::mktemp("$tmpdir/tempXXXXXX");

	if (defined ($args{dir})) {
		$cwd = cwd();
		# $cwd is tainted.  we need to untaint
		$cwd =~ m|^([/\w\-\._]+)$|;
		$cwd = $1;
		unless (chdir ($args{dir})) {
			$self->{err} = "cannot change to working directory";
			return undef;
		}
	}

	my $retval = system ("$args{command} < /dev/null 1> $tmpstdout 2> $tmpstderr");

	if (defined ($cwd)) {
		chdir ($cwd);
	}

	$exitcode = $retval >> 8;
	
	my @buf1 = ();
	open (INPUT, $tmpstdout);
	while (<INPUT>) {
		chomp;
		push @buf1, $_;
	}
	close (INPUT);
	unlink ($tmpstdout);
	$stdout = \@buf1;	

	my @buf2 = ();
	open (INPUT, $tmpstderr);
	while (<INPUT>) {
		chomp;
		push @buf2, $_;
	}
	close (INPUT);
	unlink ($tmpstderr);
	$stderr = \@buf2;

	return ($exitcode, $stdout, $stderr);
}


##
## symbol_lookup
##
## Looks up the parameter "symbol" in the RCS symbols table, and if found,
## returns the revision version of the symbol.  Otherwise, returns the
## original version of the "symbol" parameter.
##
## This function allow you do do things like:
##
## $args{revision} = $self->symbol_lookup(symbol => $args{revision});
##
## which allows the programmer to use rcs symbols everywhere instead of
## version numbers.
##

sub symbol_lookup {
        my $self = shift;
	my %args = @_;

	if (defined ($self->{symbols}->{$args{symbol}})) {
		return $self->{symbols}->{$args{symbol}};
	}

	return $args{symbol};
}


##
## log_unquote
##
## Converts from internal RCS quoted-log format to normal format
##

sub log_unquote {
	my $arg = shift;
	
	$arg =~ s/\@\@/\@/g;

	$arg;
}


##
## log_quote
##
## Converts from normal text format to internal RCS quoted-log format.
##

sub log_quote {
	my $arg = shift;
	
	$arg =~ s/\@/\@\@/g;

	$arg;
}


##
## true
##
## evaluates to one or zero, depending on the argument supplied 
##

sub istrue {
	my $arg = shift;
	
	if ($arg =~ /^(y|ye|yes|t|tr|tru|true|1)/i) {
		return 1;
	}
	
	return 0;
}

##
## usinghpux
##
## Setting this invokes some hackery elsewhere
## to get around crippled behaviour on HP's version of rcs
##

sub usinghpux {
  my $self = shift;
  $self->{hpux} = shift;
}



=head1 BUGS

=over 4

=item o

unfortunately, it was all but impossible to call this module RCS::Agent,
which is probably the more natural name.  The reason for this is left as an
exercise for the reader.

=item o

the code hasn't been tested on non-unix operating systems like the
Windows family, MacOS, VMS and so forth.  It will almost certainly not work
on them.

=item o

"Merge is Hard!".  Rcs::Agent does not support merging branches because this
is something which often requires manual intervention.  On the grounds that
providing broken functionality along these lines would just encourage a bad
habit, it's been left out completely.  There are no plans to change this
policy - at least not until the code develops self awareness.

=item o

L<Rcs::Agent> does not yet grok CVS's magic branch tags.

=item o

revisions() and symbols() both contain references to branch revisions.
This needs to be changed.

Please mail rcs-agent-lib@netability.ie if you find any more bugs.  Patches
should be sent in unified diff format (i.e. I<diff -u>), or context diff
format (I<diff -c>) if your version of diff doesn't support unified diffs.

=head1 WARRANTY AND LIABILITY

THIS SOFTWARE IS PROVIDED BY NETWORK ABILITY LIMITED ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL NETWORK ABILITY LIMITED OR ANY CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=head1 COPYRIGHT

Copyright (C) 2001 - 2007 Network Ability Ltd.  All rights reserved.  This
software may be redistributed under the terms of the license included in
this software distribution.  Please see the file "LICENSE" for further
details.

=cut

=head1 SEE ALSO

L<perl(1)>, L<rcsintro(1)>, L<rcsfile(5)>, L<rcs(1)>, L<rcsdiff(1)>, L<ci(1)>,
L<co(1)>, L<rlog(1)>.

=cut
