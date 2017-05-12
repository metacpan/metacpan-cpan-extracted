# PANT - Perl version of the ANT/NANT building tools.
# Actually not much like them as it doesnt mess with XML currently.
# strike that - it now writes XML, but in an HTML kinda way, well XHTML actually.
package PANT;

use 5.008;
use strict;
use warnings;
use Carp;
use Cwd;
use File::Copy;
use File::Copy::Recursive;
use File::Compare ();
use File::Basename;
use File::Spec::Functions qw(:ALL);
use File::Find;
use File::Path;
use Getopt::Long;
use XML::Writer;
use IO::File;
use Exporter;
use Digest;
use Config;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PANT ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	Phase Task NewerThan Command CopyFile CopyFiles DateStamp FileCompare
	CopyTree BuildSolution
        MoveFile MoveFiles MakeTree RmTree Cvs Svn FindPatternInFile
	UpdateFileVersion StartPant EndPant CallPant RunTests Zip) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT =  ( @{ $EXPORT_TAGS{'all'} } );


our $VERSION = '0.17';

my $dryrun = 0;
my ($logvolume, $logdirectory, $logfilename, $logstem, $logsuffix);
my $logcount= 1;
my $writer;

my $this_perl = $^X; 
if ($^O ne 'VMS') {
    $this_perl .= $Config{_exe}
    unless $this_perl =~ m/$Config{_exe}$/i;
}

=head1 NAME

PANT - Perl extension for ANT/NANT like build environments

=head1 SYNOPSIS

  perl buildall.pl -output buildlog

  use PANT;
  StartPant();
  Phase(1, "Update");
  Task(Command("cvs update"), "Fetch the latest code");
  Phase(2, "Build");
  Task(UpdateFileVersion("h/version.h",
	 qr/(#define\s*VERSION\s+)(\d+)/=>q{"$1" . ($2+1)},
	 "Version file updated");
  Task(Command("make all"), "Built distribution");
  Phase(3, "Deploy");
  Task(Command("make distribution"), "Distribution built");
  if (NewerThan(sources=>["myexe"], targets=>["/usr/bin/myexe"])) {
     CopyFiles("myexe", "/usr/bin");
  }
  EndPant();

=head1 ABSTRACT

  This is a module to help construct automated build environments.
  The inspiration came from the ANT/NANT build environments which use
  XML to describe a make like syntax of dependencies. For various
  reasons none of these were suitable for my purposes, and I suspect
  that eventually you will end up writing something pretty similar to
  perl in XML to cater for all the things you want to do.  Also a
  module named PANT was just too good a name to miss!

  This module draws on some of the ideas in ANT/NANT, and also in the
  Test::Mode module for ways to do things.  This module is therefore a
  collection of tools to help automate processes, and provide a build
  log of what happened, so remote builds can be observed.

  The basic philosophy is that you can probably use make or visual studio
  or similar to do the heavy building. There is no real need to replicate 
  that. However stuff like checking out of CVS/SVN repositories, updating
  version numbers, checking it back in, running test harnesses, and similar
  are things that make is not good at. 

  XML is not a programming language, but you can describe a lot of
  what you want using it, which is what ANT/NANT basically do. However
  there is always something you want to do, which can't be described
  in the current description language. In these cases you can call out
  to an external routine to do things.

  However it seems much easier to provide a number of useful
  subroutines in a scripting language, which help you build
  things. Then if you need to do something slightly of piste, you have
  all the power right there.

  The other thing I want to know about is "did it work" and if it
  didn't, what went wrong? To this end plenty of logging is required so
  the build can be tracked. As the build is probably going to be remote,
  HTML seems the obvious choice to report in, so you can just look at it
  from a web server.

=head1 DESCRIPTION

This module provides various useful functions to help in the automated
build of a project and to produce a build log. It is still in
development, and may well change shape in the light of experience.

=head1 EXPORTS

=head2 StartPant([title],[style=>stuff])

This call should be the first call into the module. It does some
intialisation, and parses command line arguments in @ARGV. It takes
the following arguments.

=over 4

=item String

The first argument is a string, and is used as the title of the web page if present.
If not present it will be called "Build Log".

=item style=>stuff

This argument if present signals some style data to include. This will
be included in a E<lt>styleE<gt> tag. This allows you to apply different styles to
the generated page.

=item stylelink=>href

This argument if present directs the inclusion of a style sheet external link.

=back


Supported command line options are 

=over 4

=item -output file

Write the output to the given file.

=item -dryrun

Simulate a run without actually doing anything.

=back

=cut 

sub StartPant {
    my $title = shift || "Build log";
    my(%extra) = @_;
    my $logname = "";
    GetOptions("output=s"=>\$logname,
    		n=>\$dryrun,
    		dryrun=>\$dryrun);
    my $fh;
    if ($logname) {
	$fh = new IO::File "$logname", "w" or die "Can't open file $logname: $!";

    }
    else {
	$logname = "buildlog.html";
	open $fh,  ">&STDOUT" or die "Can't duplicate stdout: $!";
    }
    if (file_name_is_absolute($logname)) {
	($logvolume,$logdirectory,$logfilename) = splitpath( $logname );
    }
    else {
	($logvolume,$logdirectory,$logfilename) = splitpath(catfile(getcwd, $logname));
    }
    $logstem = $logfilename;
    $logstem =~ s/(\.[^.]+)$//;
    $logsuffix = $1;
    $writer = XML::Writer->new(NEWLINES=>1, OUTPUT=>$fh);
    $writer->xmlDecl();
    $writer->doctype('html', "-//W3C//DTD XHTML 1.0 Transitional//EN", "http://www.w3.org/TR/xhtml1/DTD/transitional.dtd");
    $writer->startTag('html', xmlns=>"http://www/w3/org/TR/xhtml1");
    $writer->startTag('head');
    $writer->dataElement('title', $title);
    if ($extra{stylelink}) {
      $writer->emptyTag('link', href=>$extra{stylelink}, type=>"text/css");
    }
    if ($extra{style}) {
      $writer->dataElement('style', $extra{style}, type=>"text/css");
    }
    $writer->endTag('head');
    $writer->startTag('body');
}

=head2 EndPant()

This function finishes up the run, and should be the last call into
the module. It completes the build log in a tidy way.

=cut 

sub EndPant {
    $writer->endTag('ul') if $writer->in_element('ul');
    $writer->endTag('body');
    $writer->endTag('html');
    $writer->end();
    undef $writer; # close files and flush
}


=head2 CallPant(name, options)

This function allows you to call a subsidiary pant build. The build
will be run and waited for. A reference in the current log will be
made to the new log. It is assumed that the subsidiary build is also
using PANT as it passes some command line arguments to sort out the
logging.

Options include

=over 4

=item directory=>place

Change to the given directory to run the subsidiary build. The log
path should be modified so it fits.

=item logname=>name

Name the log file that it will write to this. If this is not given, a
name will be made up for you.

=back

=cut

# call a subsidiary build
sub CallPant {
    my $build = shift;
    my (%args) = @_;
    $writer->startTag('li');
    
    $writer->characters("Calling subsidiary build $build.");
    my $dir = exists $args{directory} ? $args{directory} : ".";
    my $logthisname =  $args{logname} || "$logstem-$logcount$logsuffix";
    $logthisname .= $logsuffix if ($logthisname !~ /\.[^.]+/);
    my $logfile = catpath($logvolume, $logdirectory, $logthisname);
    my $relfile = abs2rel($logfile, $dir);
    my $rv = Command("$this_perl $build -output $relfile", 
		     log=>$logfile, @_);
    $logcount ++;
    $writer->endTag('li');   
    return $rv;
}

=head2 Phase([list])

This function is purely for help in dividing up the build log. It
inserts a heading into the log allowing you to divide the build up
into a variety of parts. You might have a pre-build cvs checkput
phase, a build phase, and followed up by a test and deployment phase.

The list is used as the contents of the header, and the first element
of the list is used as an HTML anchor in case you want to refer to it.

=cut

# a phase marker, for dividing up output a bit
sub Phase {
    $writer->endTag('ul') if $writer->in_element('ul');
    $writer->startTag('a', name=>$_[0]);
    $writer->startTag('h1');
    $writer->characters("@_");
    $writer->endTag('h1');
    $writer->endTag('a');
    $writer->startTag('ul');
}

=head2 DateStamp 

This function returns a datestamp in a common format. Its is intended
for use in logging output, and also in CVS/SVN type retrievals.

=cut

## cvs like date/time
sub DateStamp {
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $year += 1900;
    $mon++;
    
    return "$year-$mon-$mday $hour:$min:$sec";
}


=head2 NewerThan(sources=>[qw(f1 f2*.txt)], targets=>[build], ...)

This function provides a make like dependency checker.
It has the following arguments,

=over 4

=item sources

A list of wildcard (glob'able) files that are the source.

=item treesources

A list of wildcard directories that are descended for source files. 
Currently all files in the tree are considered possibilities.

=item targets

A list of wildcard (glob'able) files that are the target

=back

The function will return true if any of the sources are
newer than the oldest of the targets. 

=cut

# compares sources and targets
# Pick oldest of the targets
# newest of the sources.
sub NewerThan {
    my (%args) = @_;
    $writer->startTag('ul') if ! $writer->in_element('ul');
    $writer->startTag('li');
    my $srcs = "";
    $srcs .= " the files @{ $args{sources} }" if exists $args{sources};
    $srcs .= " the directories @{ $args{treesources} }" if exists $args{treesources};
    $writer->characters("Are any of $srcs newer than @{ $args{targets} }?  ");
    my $newestt = time;
    my $tfile = "none";
    foreach my $glob (@{ $args{targets} }) {
	foreach my $sfile (glob $glob) {

	    my $t = (stat($sfile))[9];
	    if ($t) {
		$newestt = $t if ($t < $newestt);
		$tfile = $sfile;
	    }
	    else {
		$writer->dataElement('li', "Warning: $sfile doesn't exist\n");
		$newestt = 0;
	    }
    	}
    }
    my $newests = 1;
    my $srcfile = "none";
    if ($newestt > 0) {
	GLOB: foreach my $glob (@{ $args{sources} }) {
	    foreach my $sfile (glob $glob) {
		my $t = (stat($sfile))[9];
		if ($t) {
		    if ($t > $newests) {
			$srcfile = $sfile;
			$newests = $t  
		    }
		    last GLOB if ($newests > $newestt);
		}
		else {
		    carp "$sfile doesn't exist\n";
		    Abort("$sfile doesn't exist\n") if ($args{dieonerror});
		    $newests = 0;
		}
	    }
	}
	my $wanted = sub { 
	    my $t = (stat($_))[9]; 
	    if ($t > $newestt) {
		$srcfile = $_;
		$newests = $t;
	    }
	};
	foreach my $glob (@{ $args{treesources} }) {
	    foreach my $sfile (glob $glob) {
		find($wanted, $sfile);
		#print "Check tree $sfile\n";
	    }
	}
    }
    my $rval = $newests > $newestt;
    $writer->characters($rval ? "Yes" : "No");
    $writer->endTag('li');
#    print "Source $srcfile ", scalar(localtime($newests)), " Dest $tfile ", scalar(localtime($newestt)), " $rval\n";
    return $rval;
}

=head2 Task(result, message)

This command evaluates the first argument to see if it is true, and
prints the second argument into the log. If the first argument is
false, the build will abort.

=cut

# checks a task succeeded
sub Task {
    my $test = shift;
    $writer->dataElement('li', "@_\n");
    Abort("FAILED: ", @_) if ! $test;
    return 1;
}

=head2 Abort(list)

This function aborts the build and is called internally when thigns go
wrong.

=cut

# give up and go home
sub Abort {
    $writer->dataElement('span', Carp::longmess("@_"), 
			 style=>"color:red;font-weight:bold");
    EndPant();
    confess @_;
}
=head2 Command(cmd, options)

This function runs the given external command, capturing the output
for the log, and evaluating the return code to see if it worked.

=over 4

Currently there is only one option 

=item directory=>"somewhere"

This will cause the command to run in the given directory, rather than
being where you happen to be currently.

=back

=cut

# run a command, in a directory maybe
sub Command {
    my $cmd = shift;
    my (%args) = @_;
    my $cdir = ".";
    if ($args{directory}) {
	$cdir = getcwd;
	chdir($args{directory}) || Abort("Can't change to directory $args{directory}");
	
    }
    $writer->startTag('li');
    $writer->characters("Run $cmd\n");
    my $output;
    my $retval;
    if ($dryrun) {
	$output = "Output of the command $cmd would be here";
	$retval = 1;
    }
    else {
        $writer->startTag('pre');
	$cmd .= " 2>&1"; # collect stderr too
	if (open(PIPE, "$cmd |")) {
	    while(my $line = <PIPE>) {
		$writer->characters($line);
	    }
	    close(PIPE);
	    $retval = $? == 0;
	}
	else {
	    $retval = 0;
	}
        $writer->endTag('pre');
    }
    $writer->characters("$cmd failed: $!") if ($retval == 0);
    if ($args{log}) {
	my($v,$d, $f) = splitpath($args{log});
	my $fulllog = rel2abs($args{log});
	my $destlog = catpath($logvolume, $logdirectory, $f);
	CopyFile($args{log},   $destlog) if($fulllog ne $destlog);
	my $reldir = abs2rel($args{log}, catpath($logvolume, $logdirectory, ''));

	$writer->dataElement('a', "Log file", href=>$f);
    }
    $writer->endTag('li');
    do { chdir($cdir) || Abort("Can't change back to $cdir: $!"); } if ($args{directory});
    return $retval;
}
=head2 CopyFiles(source, destdir)

This function copies all the files that match the source glob pattern
to the given directory. The names will remain the same.

=cut

# copy over several files into a new directory
sub CopyFiles {
    my ($src, $dest) = @_;
    Abort("$dest is not a directory") if (!$dryrun && ! -d $dest);
    foreach my $sfile (glob $src) {
	my $bname = basename($sfile);
	return 0 if CopyFile($sfile, "$dest/$bname") == 0;
    }
    return 1;
    
}

=head2 CopyTree(source, dest)

This function copies an entire tree hierarchy from the source to the 
destination. It makes use of File::Copy::Recursive routines to do this.

=cut

# copy over several files into a new directory
sub CopyTree {
    my ($src, $dest) = @_;
    $writer->dataElement('li', "Copy $src tree to $dest\n");
    if (!$dryrun) {
	my($nfdirs,$ndirs,$depth) = File::Copy::Recursive::rcopy($src, $dest);
	$writer->dataElement('li', 
			     "Copied $nfdirs files and directories, $ndirs directories to a depth of $depth");
	
	return $nfdirs;
    }
    return 1;
}

=head2 CopyFile(source, dest)

This function copies an individual file from the source to the
destination. It allows for renaming.

=cut

# copy a file and possibly rename.
sub CopyFile {
    my ($src, $dest) = @_;
    $writer->dataElement('li', "Copy $src to $dest\n");
    return 1 if ($dryrun);
    if( copy($src, $dest) == 0) {
	$writer->dataElement('li', "Copy failed: $!\n");
	return 0;
    }
    return 1;
}


=head2 MoveFiles(source, destdir)

This function moves all the files that match the source glob pattern
to the given directory. The names will remain the same.

=cut

# move over several files into a new directory
sub MoveFiles {
    my ($src, $dest) = @_;
    Abort("$dest is not a directory") if (!$dryrun && ! -d $dest);
    foreach my $sfile (glob $src) {
	my $bname = basename($sfile);
	return 0 if MoveFile($sfile, "$dest/$bname") == 0;
    }
    return 1;
    
}

=head2 MoveFile(source, dest)

This function moves an individual file from the source to the
destination. It allows for renaming.

=cut

# copy a file and possibly rename.
sub MoveFile {
    my ($src, $dest) = @_;
    $writer->dataElement('li', "Move $src to $dest\n");
    return 1 if ($dryrun);
    if( move($src, $dest) == 0) {
	$writer->dataElement('li', "Move failed: $!\n");
	return 0;
    }
    return 1;
}
=head2 UpdateFileVersion(file, patterns)

This functions name will probably change. It allows for updating files
contents based on the given set of patterns. Some care is needed to
get the patterns and the replacements correct. The replacement text is
subject to double evaluation.

=cut

sub UpdateFileVersion {
    my ($file, %patterns) = @_;
    $writer->startTag('ul') if ! $writer->in_element('ul');
    $writer->startTag('li');
    $writer->characters("Update file $file\n");
    $writer->startTag('ul');
    open(FILE, $file) || do { $writer->characters("Can't open file $file: $!"); return 0; };
    open(FILEOUT, ">$file.$$") || do {  $writer->characters("Can't open file $file.$$: $!"); return 0; };
    while (my $line = <FILE>) {
	while( my($k, $v) = each %patterns) {
	    if ($line =~ s/$k/$v/ee) {
		my $vv;
		eval "\$vv = $v";
		$writer->dataElement("li","Changed line '$line' '$1' '$2' '$v' $vv\n");
	    }
    	}
	print FILEOUT $line;
    }
    close(FILE);
    close(FILEOUT);
    $writer->endTag('ul');
    $writer->endTag('li');
    return 1 if ($dryrun);
    return rename("$file.$$", $file);
}


=head2 AddOutput(list)

This allows additional commentary to be added to the output stream.

=cut 

sub AddOutput {
    $writer->characters("@_");
}

=head2 AddElement(list)

This allows additional constructs to be added to the output, such a
href references and so on. It is passed onto XML::Writer::dataElement
directly and takes the same syntax.

=cut

sub AddElement {
    $writer->dataElement(@_);
}


=head2 RunTests(args)

Run the list of perl style test files, and capture the result in the
output of the log. The The arguments allow you to specify the tests to
run, see PANT::Test for details.

=cut

sub RunTests {
    require PANT::Test;
    my $test = new PANT::Test($writer, dryrun=>$dryrun);
    return $test->RunTests(@_);
}

=head2 Zip(file)

This function returns a PANT::Zip object to help construct the given zip file.
See PANT::Zip for more details.

=cut

sub Zip {
    require PANT::Zip;
    return new PANT::Zip($writer, @_, dryrun=>$dryrun);
}

=head2 Cvs()

This function returns a PANT::Cvs object to help with running Cvs commands.
See PANT::Cvs for more details.

=cut

sub Cvs {
    require PANT::Cvs;
    return new PANT::Cvs($writer, @_, dryrun=>$dryrun);
}

=head2 Svn()

This function returns a PANT::Svn object to help with running Svn commands.
See PANT::Svn for more details.

=cut

sub Svn {
    require PANT::Svn;
    return new PANT::Svn($writer, @_, dryrun=>$dryrun);
}


=head2 FileCompare(F1, F2)

This function compares two files using the File::Compare routines to
see if their contents are identical.

=cut

sub FileCompare {
    my($f1, $f2) = @_;
    return File::Compare::compare($f1, $f2) == 0;
}

=head2 MakeTree(dir)

Create a given directory, and all required intermediate paths.

=cut

sub MakeTree {
    my $dir = shift;
    $writer->dataElement('li', "Create directory tree $dir\n");
    return 1 if ($dryrun);
    eval { mkpath($dir) };
    if ($@) {
	$writer->dataElement('li', "Couldn't create directory $dir: $@");
	return 0;
    }
    return -d $dir;
}

=head2 RmTree(dir)

This function removes the entire tree starting at the given directory.
Obviously be careful!

=cut

sub RmTree {
    my $dir = shift;
    $writer->dataElement('li', "Remove tree $dir\n");
    return 1 if ($dryrun);
    rmtree($dir);
    return ! -d $dir;
}


=head2 BuildSolution(project, args...)

This function attempts to build a visual studio style project.
The first argument is the base name of the project, which will be used to
derive the F<.SLN> and other files.
It has the following parameters, 

=over 4

=item solution=>name

The name of the solution file. This can be used to insert a .vcproj file
to have a similar effect.

=item project=>name

The given project in the solution you wish to build.

=item buildtype=>type

What sort of build you want to do. These are the support targets from
visual studio, such as /build (default), /rebuild, /clean, /deploy etc.

=item log=>file

Where to output the log. The default is the base name with .log appended.

=item target=>Release

The target build environment, usually Debug or Release.

=item devenv=>devenv

The name of the devenv binary - which might be a full pathname.

=back

=cut

sub BuildSolution {
    my($sln, %args) = @_;
    my $slnfile = $args{solution} || "$sln.sln";
    my $project = $args{project} || $sln;
    my $buildtype = $args{buildtype} || "/build";
    my $log = $args{log} || "$sln.log";
    my $buildtarget = $args{target} || "Release";
    my $devenv = $args{devenv} || "devenv";

    my $cmd = qq{$devenv $slnfile $buildtype "$buildtarget" /project $project /out $log};
    return Command($cmd, log=>$log);

}

=head2 FindPatternInFile(file, pattern)

This function searches the given file line by line, until it finds the
pattern given, and returns the string matching the first bracketed
expression int the regexp. This can be used to 
find things like file versions.

=over 4

my $ver = FindPatternInFile("thing.rc", qr/^\s*FILEVERSION\s*(\d+,\d+,\d+,\d+)/);

=back

=cut

sub FindPatternInFile {
    my ($file, $pat) = @_;
    open(FILE, $file) || return undef;
    while (my $line = <FILE>) {
        if ($line =~ $pat) {
	    close(FILE);
	    return $1;
        }
    }
    close(FILE);
}

1;

__END__

=head1 SEE ALSO

Makes use of XML::Writer to construct the build log.

=head1 AUTHOR

Julian Onions, E<lt>julianonions@yahoo.nospam-co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Julian Onions

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 RULES TO LIVE BY

Don't get caught with your PANT's down.

Don't get your PANT's in a wad.

=cut
