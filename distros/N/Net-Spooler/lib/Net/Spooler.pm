# -*- perl -*-
#
#   Net::Spooler - A Perl extension for writing spooling daemons
#
#   Copyright (C) 1999		Jochen Wiedmann
#				Am Eisteich 9
#				72555 Metzingen
#				Germany
#
#				E-Mail: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
############################################################################

use strict;

use Net::Daemon ();
use File::Spec ();
use Symbol ();
use Data::Dumper ();
use Fcntl ();
use Safe ();
use Cwd ();

package Net::Spooler;

$Net::Spooler::VERSION = '0.02';
@Net::Spooler::ISA = qw(Net::Daemon);


sub Options ($) {
    my $opts = shift()->SUPER::Options();
    $opts->{'admin'} = { 'template' => 'admin=s',
			 'description' => '--admin=<email>         '
			 . "Admins email address"
		       };
    $opts->{'expiretime'} = { 'template' => 'expiretime=i',
			      'description' => '--expiretime=<secs>     '
			      . "Spool files expire after <secs> seconds"
			    };
    $opts->{'maxsize'} = { 'template' => 'maxsize=s',
			   'description' => '--maxsize=<bytes>       '
			   . "Refuse files larger than <bytes> bytes"
			 };
    $opts->{'processtimeout'} = { 'template' => 'processtimeout=i',
				  'description' => '--processtimeout=<secs> '
				  . "Stop processing files after <secs> seconds"
			 };
    $opts->{'spool-dir'} = { 'template' => 'spool-dir=s',
			     'description' => '--spool-dir=<dir>       '
			     . "Directory for creating spool files"
			   };
    $opts->{'spool-command'} = { 'template' => 'spool-command=s',
				 'description' => '--spool-command=<cmd>   '
				 . "Run <cmd> for processing spool files"
			       };
    $opts;
}


=pod

=head1 NAME

Net::Spooler - A Perl extension for writing spooling daemons


=head1 SYNOPSIS

  # Create a subclass of Net::Spooler
  use Net::Spooler;
  package MySpooler;
  @MySpooler::ISA = qw(Net::Spooler);

  # Inherit everything, except a single method:
  sub ProcessFile {
    my $self = shift; my $file = shift;

    # Try to process the file here
    ...

    # Raise an exception, if something went wrong:
    die "Failed: $!" unless Something();

    # Return to indicate sucess.
  }

  # Create and run the spooler
  package main;
  my $spooler = Net::Spooler->new(
      'spool-dir' => '/var/myspooler'
  );
  $spooler->Bind();


=head1 DESCRIPTION

This package contains a spooling daemon, in other words a process,
that accepts files from an outside source (currently a Unix or
TCP/IP socket), stores them in a spooling directory and processes
them.

The package is implemented as an abstract base class: It is not
usefull in itself, but you can get your spooling daemon easily by
deriving a concrete subclass from C<Net::Spooler>. In the best case
you can inherit everything and overwrite just a single method, the
I<ProcessFile> method, which attempts to process a single file
from the spooling directory.

C<Net::Spooler> is in turn derived from the C<Net::Daemon> package, thus
it borrows class design, in particular methods and attributes, from
C<Net::Daemon>. See L<Net::Daemon> for details on this superclass.

However, there are a few additions to C<Net::Daemon>:


=head2 Attributes

Like in C<Net::Daemon>, attributes can be set via the command line,
in the config file or as constructor arguments (order descending from
most important). And remember, that you can use the C<Net::Daemon>
attributes too! See L<Net::Daemon>.

=over 8

=item I<admin> (B<--admin=E<lt>emailE<gt>)

The administrators email address. From time to time it may happen,
that the admin receives an email in case of problems.

=item I<expiretime> (B<--expiretime=E<lt>timeE<gt>>)

If processing a file fails repeatedly, the file may finally expire.
This means that the file will be removed from the spool directory
and a message is sent to the administrator.

The default value are 432000 seconds (5 days). A value of 0 means
that expiration never happens.

Example: Expire after 3 days.

  --expiretime=259200

=item I<maxsixe> (B<--maxsize=E<lt>maxsizeE<gt>>)

By default the maximum size of a file is restricted to 100000 bytes
and larger files will be rejected. This option is changing the size,
a value of 0 means disabling the limitation.

Example: Disable max size

  --maxsize=0

=item I<processtimeout> (B<--processtimeout=E<lt>timeoutE<gt>>)

If processing a single file may result in an endless loop, or simply
run too long, then you may specify a timeout. The daemon will raise
a signal after the given amount of seconds and stop processing the
file, as if the method C<ProcessFile> raised an exception.

The default value is 0 seconds which means that no timeout is used.

Example: Use a timeout of 30 seconds.

  --processtimeout=30

=item I<loop-timeout> (B<--loop-timeout=E<lt>timeE<gt>>)

If processing a file failed, the spooler will reprocess the file
later by forking a child process after the given amount of
seconds, by default 300 seconds (5 minutes). This child process
will run through all scheduled file

=item I<spool-dir> (B<--spool-dir=E<lt>dirE<gt>>)

If the daemon accepts files, they are stored in the I<spool directory>.
There's no default, you must set this attribute.

Example: Use F</var/myspooler> as a spool directory.

  --spool-dir=/var/myspooler

=item I<tmpfiles>

This attribute is for internal use only. It contains an hash ref, the
keys being temporary file names to be removed later.

=back


=head2 Methods

As already said, the C<Net::Spooler> package inherits from C<Net::Daemon>.
All methods of the superclass are still valid in C<Net::Spooler>, in
particular access control and the like. See L<Net::Daemon> for details.

=over 8

=item Processing a file

  $self->ProcessFile($file)

(Instance method) Called for processing a single file. This is typically
the only method you have to overwrite.

The method raises an exception in case of errors. If an exception is
raised, the scheduler will later retry to process the file until it
expires. See the I<queuetime> and I<expiretime> attributes above.

If processing a file exceeds the I<processtimeout> (see above), then
the scheduler will cancel processing the method and continue as if it
raised an exception. (This timeout can be disabled by setting it to 0,
the default value.)

If the method returns without raising an exception, then the scheduler
assumes that the file was processed successfully and remove it from
the spool directory.

=cut

sub StatusOk {
}
sub StatusError {
}
sub StatusReject {
}

sub CommandFile {
    my($self, $file, $ctrl) = @_;

    my $command = $self->{'spool-command'};
    $command =~ s/\$\@file\$/$file/sg;
    $command =~ s/\$file\$/quotemeta($file)/seg;
    $command =~ s/\$\@control->([\-\w]+)\$/$ctrl>{$1}/seg;
    $command =~ s/\$control->([\-\w]+)\$/quotemeta($ctrl->{$1})/seg;
    $self->Debug("Processing $file: $command");
    my $ph = Symbol::gensym();
    open($ph, "$command 2>>errors.log |")
	or die "Failed to create pipe to command $command: $!";
    my $output;
    my $line;
    while (defined($line = <$ph>)) {
	$output .= $line;
	if ($line =~ /^\s*status\:\s*(.*?)\s*$/i) {
	    my $status = lc $1;
            if ($status eq 'ok') {
	        $self->StatusOk($file, $ctrl);
		return 1;
	    } elsif ($status eq 'error') {
		last;
	    } elsif ($status eq 'reject') {
		$self->StatusReject($file, $ctrl);
		while (defined($line = <$ph>)) {
		    $output .= $line;
		}
		close $ph;
		open($ph, ">>errors.log") and
		    (print $ph "\n" . localtime() . ", Reject while processing $file:\n$output");
		return 0;
	    }
        }
    }

    $self->StatusError($file, $ctrl);
    if (defined $line) {
	while (defined($line = <$ph>)) {
	    $output .= $line;
	}
    }
    close $ph;
    open($ph, ">>errors.log") and
	(print $ph "\n" . localtime() . ", Error while processing $file:\n$output");
    die "Failed to process $file: $output";
}


=pod

=item Choosing file names

  my $sfile = $self->SequenceFile();
  my $seq = $self->Sequence($sfile);
  my $dfile = $self->DataFile($seq);
  my $cfile = $self->ControlFile($seq);


(Instance methods) If the daemon receives a new file, it has to
choose a name for it. These names are constructed as follows:

First of all, a so-called sequence number is generated by calling
the method I<Sequence>. By default these are the numbers 1, 2, 3, ...
in 8 hex digits (00000001, 00000002, 00000003, ...). The last
generated sequence number is always stored in the sequence file
(by default F<$spool-dir/.sequence>, set by calling the I<SequenceFile>
method).

Two files are generated for processing the file: The I<data file>
is the unmodified file, as received by the client. The I<control file>
contains information used internally by C<Net::Spooler>, for example
the time and date of spooling this file. By default the names
F<$spool-dir/$seq.dat> and F<$spool-dir/$seq.ctl> are used, generated
by calling the methods I<DataFile> and I<ControlFile>. Temporary
file names are derived by adding the suffix F<.tmp>.

Typically you rarely need to overwrite these methods.

=back

=cut

sub SequenceFile {
    my $self = shift;
    ".sequence";
}

sub Sequence {
    my $self = shift; my $file = shift;
    my $fh = Symbol::gensym();
    sysopen($fh, $file, Fcntl::O_RDWR()|Fcntl::O_CREAT(), 0644)
	or die "Failed to open sequence file $file for append: $!";
    flock($fh, Fcntl::LOCK_EX())
	or die "Failed to lock sequence file $file: $!";
    my $line = <$fh>;
    my $num = ((defined($line) && $line =~ /(\d+)/) ? $1 : 0) + 1;
    seek($fh, 0, 0)
	or die "Failed to beginning of sequence file $file: $!";
    my $sline = "$num\n";
    (print $fh $sline)
	or die "Failed to write to sequence file $file: $!";
    truncate($fh, length($sline))
	or die "Failed to truncate sequence file $file: $!";
    close($fh); # *No* unlock, this is done automatically as soon as
                # the destructur of $fh is called!
    $num;
}

sub DataFile {
    my $self = shift; my $seq = shift;
    "$seq.dat";
}

sub ControlFile {
    my $self = shift; my $seq = shift;
    "$seq.ctl";
}

sub IsControlFile {
    my $self = shift; my $file = shift;
    return ($file =~ s/\.ctl$/.dat/) ? $file : undef;
}

=pod

=item Accepting a file from the client

  $self->ReadFile($socket, $fh, $file, $control);

(Instance method) This method is actually reading the file $file from
the socket $socket. The file is already opened and the method must use
the file handle $fh for writing into $file. (The file name is passed
for creating error messages only.)

The method may store arbitrary data in the hash ref $control: This
hash ref is stored in the control file later.

The default implementation is accepting a raw file on the socket. You
should overwrite the method, if you are accepting structured data,
for example 4 bytes of file size and then the raw file. However, if
you do overwrite this method, you should consider the I<maxsize>
attribute. (See above.)

A Perl exception is raised in case of problems.

=cut

sub ReadFile {
    my($self, $socket, $fh, $file, $control) = @_;
    my $size = 0;
    my($buf, $len);

    while ($len = read($socket, $buf, 1024)) {
	$size += $len;
	die "Maximum size of $self->{'maxsize'} exceeded."
	    if ($self->{'maxsize'}  and $size > $self->{'maxsize'});
	(print $fh $buf)
	    or die "Failed to write into data file $file: $!";
    }
    die "Error while reading from client: $!" unless defined($len);
}


=pod

=item Creating the control file

  $self->ControlFile($fh, $file, $control);

(Instance method) Creates the control file $file by writing the
hash ref $control into the open file handle $fh. (The file name
$file is passed for use in error messages only.)

The default implementation is using the C<Data::Dumper> module for
serialization of $control and then writing the dumped hash ref
into $fh.

A Perl exception is raised in case of problems; nothing is returned
otherwise.

=cut

sub WriteControlFile {
    my($self, $fh, $file, $control) = @_;
    my $d = Data::Dumper->new([$control], ['control']);
    $d->Indent(1);
    (print $fh $d->Dump())
	or die "Failed to create control file $file: $!";
}


=pod

=item Reading the control file

  my $ctrl = $self->ReadControlFile($file);

(Instance method) This method reads a control file, as created by the
I<ControlFile> method and creates an instance of I<Net::Spooler::Control>.

The default implementation does a simple B<require> (in a Safe compartment
for security reasons, see the L<Safe> package for details) for loading the
hash ref from the file. The hash ref is then blessed into the package
corresponding to $self: The package name of $self is taken by appending
the string B<::Control>.

The method returns nothing, a Perl exception is thrown in case of
trouble.

=cut

sub ReadControlFile {
    my $self = shift;  my $file = shift;  my $fh = shift;
    my $ctrl;
    if (ref($file) eq 'HASH') {
	$ctrl = $file;
    } else {
	unless ($fh) {
	    $fh = Symbol::gensym();
	    open($fh, "<$file") or die "Failed to open control file $file: $!";
	}
	local $/ = undef;
	my $contents = <$fh>;
	die "Failed to read control file $file: $!" unless defined($contents);
	my $cpt = Safe->new();
	$ctrl = $cpt->reval($contents);
	die $@ if $@;
	die "Expected hash ref being read from $file"
	    unless defined($ctrl) and ref($ctrl) eq 'HASH';
    }
    my $class = ref($self) . "::Control";
    my $clisa = $class . "::ISA";

    no strict 'refs';
    @$clisa = qw(Net::Spooler::Control) unless @$clisa;
    $class->new($ctrl);
}


############################################################################
#
#   Name:    new
#
#   Purpose: Constructor of the Net::Spooler class; overwrites
#	     Net::Daemon::new
#
#   Inputs:  $proto - Class name
#            $attr - Attributes hash ref
#            $options - Options array ref
#
#   Returns: New object, dies in case of trouble
#
############################################################################

sub new {
    my($proto, $attr, $options) = @_;
    $attr->{'loop-timeout'} = 300    unless exists $attr->{'loop-timeout'};
    $attr->{'loop-child'} = 1        unless exists $attr->{'loop-child'};
    my $self = $proto->SUPER::new($attr, $options);

    my $sdir = $self->{'spool-dir'}
        or die "Missing spool-dir attribute, use --spool-dir=<dir>";
    $sdir = $self->{'spool-dir'} = Cwd::abs_path($sdir);
    my $admin = $self->{'admin'}
        or die "Missing admin email address, use --admin=<admin>";

    # Test whether we have write permissions in the spool directory
    my $fh = Symbol::gensym();
    my $file = File::Spec->catfile($sdir, "WRITETEST");
    (open($fh, ">$file")  and  close($fh)  and  unlink $file)
	or die "Write test in $sdir failed, check --spool-dir and permissions";

    $self->{'expiretime'} = 432000 unless exists($self->{'expiretime'});
    $self->{'processtimeout'} = 0  unless exists($self->{'processtimeout'});
    $self->{'queuetime'} = 300     unless exists($self->{'queuetime'});
    $self->{'maxsize'} = 100000    unless exists($self->{'maxsize'});

    $self;
}


############################################################################
#
#   Name:    Loop
#
#   Purpose: In a loop, build the list of currently queued files and
#	     process them.
#
#   Inputs:  $self - Instance
#
#   Returns: Nothing; throws a Perl exception in case of errors.
#
############################################################################

sub Loop {
    my $self = shift;
    my $dh = Symbol::gensym();
    $self->Fatal("Failed to open directory $self->{'spool-dir'}: $!")
	unless opendir($dh, File::Spec->curdir());
    while (my $cfile = readdir($dh)) {
	my $dfile = $self->IsControlFile($cfile);
	next unless defined $dfile;
	my $ctrl = $self->ReadControlFile($cfile);
	$ctrl->Process($self);
    }
}

############################################################################
#
#   Name:    Run
#
#   Purpose: Accepts a single file from a client and stores it in the
#	     spool directory
#
#   Inputs:  $self - Instance
#
#   Returns: Nothing, dies in case of problems.
#
############################################################################

sub Run {
    my $self = shift;
    chdir $self->{'spool-dir'}
	or die "Failed to change directory to $self->{'spool-dir'}: $!";

    # Create a sequence number. This must not fail, because it may
    # impact the complete system. That's why we treat it special here.
    my($sfile, $seq);
    eval {
	$sfile = $self->SequenceFile();
	$seq = $self->Sequence($sfile);
    };
    if (!$seq) {
	$sfile ||= "the sequence file";
	my $msg = "Creating a sequence number from $sfile failed: $@";
	$self->Mail($msg
		    . "\n\nThis may prevent the system to work."
		    . "\nPlease take immediate action and restore the"
		    . "\nsequence file.");
	$self->Fatal($msg);
    }

    my $control = {};
    my $cfile = $self->ControlFile($seq);
    my $dfile = $self->DataFile($seq);
    my $time = time;
    $control->{'created'} = "$time (" . localtime($time) . ")";
    $control->{'control'} = $cfile;
    $control->{'data'} = $dfile;

    # Read the data file from the client
    my $dtfile = "$dfile.tmp";
    my $dtfh = Symbol::gensym();
    my $tmpfiles = $self->{'tmpfiles'} = { $dtfile => 1 };
    open($dtfh, ">$dtfile")
	or die "Failed to open data file $dtfile: $dtfh";
    $self->ReadFile($self->{'socket'}, $dtfh, $dtfile, $control);

    my $ctfile = "$cfile.tmp";
    my $ctfh = Symbol::gensym();
    $tmpfiles->{$ctfile} = 1;
    open($ctfh, ">$ctfile")
	or die "Failed to create temporary file $ctfile: $!";
    $self->WriteControlFile($ctfh, $ctfile, $control);

    rename $dtfile, $dfile
	or die "Failed to rename $dtfile to $dfile: $!";
    rename $ctfile, $cfile
	or die "Failed to rename $ctfile to $cfile: $!";
    my $ctrl = $self->ReadControlFile($control);
    undef $dtfh;
    undef $ctfh;
    delete $self->{'tmpfiles'};

    $ctrl->Process($self);
}


############################################################################
#
#   Name:    DESTROY
#
#   Purpose: Destructor of the Net::Spooler class; removes temporary files.
#
#   Inputs:  $self - Instance
#
#   Returns: Nothing
#
############################################################################

sub DESTROY {
    if (my $tf = delete shift()->{'tmpfiles'}) {
	unlink keys %$tf;
    }
}

sub Bind {
    my $self = shift;
    chdir $self->{'spool-dir'}
	or die "Failed to change directory to $self->{'spool-dir'}: $!";
    $self->SUPER::Bind(@_);
}

package Net::Spooler::Control;

sub new {
    my $proto = shift; my $hash = shift;
    my $self = $hash ? { %$hash } : {};
    bless($self, (ref($proto) || $proto));
}

sub Process {
    my $self = shift;  my $spooler = shift;

    # Lock the control file
    my $cfh = Symbol::gensym();
    my $cfile = $self->{'control'};
    my $dfile = $self->{'data'};
    $spooler->Debug("Processing file: data=$dfile, control=$cfile");
    open($cfh, "<$cfile") or die "Failed to open $cfile for input: $!";
    flock($cfh, Fcntl::LOCK_EX()) or die "Failed to lock $cfile: $!";

    # Set a timeout, if required
    my $result;
    eval {
	my $timeout = $spooler->{'processtimeout'};
	local $SIG{'ALRM'} = sub { die "Timeout" } if $timeout;
	alarm $timeout if $timeout;
	if ($spooler->{'spool-command'}) {
	    $result = $spooler->CommandFile($dfile, $self);
	} else {
	    $result = $spooler->ProcessFile($dfile);
	}
	alarm 0 if $timeout;
    };
    if ($@) {
	$spooler->Error("Failed to process $dfile: $@");
    } else {
	$spooler->Log('info', "Processed $dfile, result = %s\n",
			defined $result ? $result : "undef");
	unlink $cfile, $dfile;
    }
}

1;


__END__

=pod

=head1 AUTHOR AND COPYRIGHT

This package is

  Copyright (C) 1999		Jochen Wiedmann
                                Am Eisteich 9
			        72555 Metzingen
				Germany

                                E-Mail: joe@ispsoft.de

  All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

  L<Net::Daemon(3)>

=cut
