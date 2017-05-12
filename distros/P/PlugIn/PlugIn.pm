#################################
package PlugIn;

use Archive::Tar;		# (mv0.071) Needed to Open TAR.GZ data files
#################################

$PlugIn::VERSION = '0.01';

#*********************************************************
#*********************************************************
sub Open
	{
	my $file = shift(@_);		# Pass the file name of the plug-in file
	my $switch = shift(@_);		# Pass the optional switch to save the extracted file

	if (!-e $file)
		{
		return;
		}
	if (my $tar = Archive::Tar->new($file, 1))
		{
		my @filelist = $tar->list_files();
		foreach (@filelist)
			{
			$tar->extract($_);
			require $_;
			if (!$switch)
				{
				unlink $_;
				}
			}
		}
	else	{
		return;
		}

	return 1;
	}
#*********************************************************
=pod
=cut
#*********************************************************
sub OpenEval
	{
	my $file = shift(@_);		# Pass the file name of the plug-in file
	my $switch = shift(@_);		# Pass the optional switch to save the extracted file

	if (!-e $file)
		{
		return;
		}
	if (my $tar = Archive::Tar->new($file, 1))
		{
		my @filelist = $tar->list_files();
		foreach (@filelist)
			{
			$tar->extract($_);
			my ($data);
			open (IN, $_) || die "Error: Can't open $file\n";
			read (IN, $data, (-s $_));
			close IN;
			eval ($data);
			if (!$switch)
				{
				unlink $_;
				}
			}
		}
	else	{
		return;
		}

	return 1;
	}
#*********************************************************
=pod
=cut
#*********************************************************
sub Read
	{
	my $file = shift(@_);		# Pass the file name of the plug-in file
	my $switch = shift(@_);		# Pass the optional switch to save the extracted file
	my %readfile;			# Return hash to contain data

	if (!-e $file)
		{
		return;
		}
	if (my $tar = Archive::Tar->new($file, 1))
		{
		my @filelist = $tar->list_files();
		foreach (@filelist)
			{
			my ($data);
			$tar->extract($_);
			open (IN, $_) or return;
			read (IN, $data, (-s $_));
			close IN;
			$readfile{$_} = $data;
			if (!$switch)
				{
				unlink $_;
				}
			}
		}
	else	{
		return;
		}
	return %readfile;
	}
#*********************************************************
=pod
=cut
#*********************************************************
sub Write
	{
	my $output = shift(@_);		# Pass the name of the output Data file
	my @files = @_;			# Pass the list of files to be written to the Data file
	my @filelist;			# The list of filenames to be returned

	my $tar = Archive::Tar->new();
	my $num = $tar->add_files(@files);
	@filelist = $tar->list_files();
	$tar->write($output, 1);

	return @filelist;
	}
#*********************************************************
=pod
=cut
#*********************************************************
sub WriteEval
	{
	my $output = shift(@_);		# Pass the name of the output Data file
	my @files = @_;			# Pass the list of files to be written to the Data file
	my @filelist;			# The list of filenames to be returned

	if (!EvalIt(@files))
		{
		my $tar = Archive::Tar->new();
		my $num = $tar->add_files(@files);
		@filelist = $tar->list_files();
		$tar->write($output, 1);
		}
	else	{
		return;
		}

	return @filelist;
	}
#*********************************************************
=pod
=cut
#*********************************************************
sub EvalIt
	{
	my (@files) = @_;
	my ($data, $return);

	foreach my $file (@files)
		{
		open (IN, $file) or return;
		read (IN, $data, (-s $file));
		close IN;
		if (eval ($data))
			{
			$return = $return | 0;
			}
		else	{
			$return = $return | 1;
			}
		}
	return $return;
	}
=head1 NAME

PlugIn - Create and Access TAR.GZ files containing executible Perl code for dynamic execution

=head1 SYNOPSIS

  use PlugIn;
  my $fileswritten = Write('prog.dat', 'prog1.pl', 'prog2.pl');
  print "$fileswritten files written...\n";
  my %filesread = Read('prog.dat', 1);
  Open('prog.dat', 1);
  OpenEval('prog.dat');

=head1 ABSTRACT

PlugIn is a convienient way to store 'required' perl scripts in a single accessible file.  It is also
a way to obscure source code from prying eyes by adding your own encryption or obscurement routines.

Since 'required' modules are accessed at run-time, PlugIn can also be used to dynamically configure perl
scripts that have been compiled using one of the commercial Perl compilers.  This gives you the ability 
to create a free-standing EXE, but keep it dynamically configurable through the use of a plug-in data file 
without the need for re-compilation and distribution!

The current version of PlugIn is available at:

  http://home.earthlink.net/~bsturner/perl/index.html

=head1 CREDITS

Thanks go to Indy Singh of WWW.DEMOBUILDER.COM for providing the 'eval' source to obscure run-time compiler messages.

=head1 HISTORY

  0.01 First release

=head1 INSTALLATION

This module is shipped as a basic PM file that should be installed in your
site\lib dir.  This module should work in any Perl port that has the 
Archive::Tar module.

=head1 DEPENDENCIES

Archive::Tar must be installed for this module to function.  Archive::Tar is used as the principle method for the creation 
and reading of data files.

=head1 DESCRIPTION

To use this module put the following line at the beginning of your script:

	use PlugIn;

Any one of the functions can be referenced by:

	var = PlugIn::function

=head1 RETURN VALUES

Unless otherwise specified, all functions return undef if unsuccessful and non-zero data if successful.

=head1 FUNCTIONS

The following functions are available, but not exported.

=head2 PlugIn::Open

	PlugIn::Open($file, $optswitch);

Opens a data file (TAR.GZ), requires it, and then deletes the extracted files by default.  The code in each required 
file is automatically executed and included subroutines are available.

	$file is the filename of the data file to be opened
	$optswitch is an optional boolean switch to prevent deletion of the extracted files

=head2 PlugIn::OpenEval

	PlugIn::OpenEval($file, $optswitch);

Opens a data file (TAR.GZ), evaluates it, and then deletes the extracted files by default.  The code in each required 
file is automatically executed and included subroutines are available.  The evaluation routine should hide run-time 
compiler messages.

	$file is the filename of the data file to be opened
	$optswitch is an optional boolean switch to prevent deletion of the extracted files

=head2 PlugIn::Read

	%hash = PlugIn::Read($file, $optswitch);

Opens a data file (TAR.GZ), extracts the contents, and then deletes them by default.  The code is returned in the 
specified hash.

	%hash is the returned data with the keys listed as the extracted filename
	$hash{filename} is the contents of the specified extracted file

	$file is the filename of the data file to be opened
	$optswitch is an optional boolean switch to prevent deletion of the extracted files

Read is provided as an accessor method if you want to add your own processing to the data before requiring it.  The data 
could be encrypted or otherwise obscured.

=head2 PlugIn::Write

	@list = PlugIn::Write($datfile, @files);
	$files = PlugIn::Write($datfile, @files);

Creates a new data file (TAR.GZ), with the specified list of files.

	@list - in list context it returns the names of files added to the data file
	$files - in scalar context it returns the number of files added to the data file

	$datfile is the name of the data file to be created
	@files is the list of file to be added to the archive

If you wish to store encrypted or obscured code, the input files must already be in this condition.

=head2 PlugIn::WriteEval

	@list = PlugIn::WriteEval($datfile, @files);
	$files = PlugIn::WriteEval($datfile, @files);

Before the data file is created, each file in the filelist is first evaluated for errors.  If all files evaluate successfully 
then a new data file (TAR.GZ) is created.  Files are evaluated through the use of the PlugIn::EvalIt function.

	@list - in list context it returns the names of files added to the data file
	$files - in scalar context it returns the number of files added to the data file

	$datfile is the name of the data file to be created
	@files is the list of file to be added to the archive

=head2 PlugIn::EvalIt

	PlugIn::EvalIt(@files);

The passed data is evaluated using Perl's 'eval' function and returns true only if all data passes.  While this serves to 
provide some quality assurance, it also servers to hide run-time compiler messages in the commercial Perl to EXE compilers.

	@files is the list of files to be evaluated

Based on code by Indy Singh of WWW.DEMOBUILDER.COM (Perl2EXE)

=head1 AUTHOR

Brad Turner ( I<bsturner@sprintparanet.com> ).

=cut
