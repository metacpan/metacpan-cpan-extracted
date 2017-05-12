package Slackware::Slackget::File;

use warnings;
use strict;

=head1 NAME

Slackware::Slackget::File - A class to manage files.

=head1 VERSION

Version 1.0.5

=cut

our $VERSION = '1.0.5';

=head1 SYNOPSIS

Slackware::Slackget::File is the class which represent a file for slack-get. 

Access to hard disk are saved by taking a copy of the file in memory, so if you work on big file it may be a bad idea to use this module. Or maybe you have some interest to close the file while you don't work on it.

	use Slackware::Slackget::File;

	my $file = Slackware::Slackget::File->new('foo.txt'); # if foo.txt exist the constructor will call the Read() method
	$file->add("an example\n");
	$file->Write();
	$file->Write("bar.txt"); # write foo.txt (plus the addition) into bar.txt
	$file->Close(); # Free the memory !
	$file->Read(); # But the Slackware::Slackget::File object is not destroy and you can re-load the file content
	$file->Read("baz.txt"); # Or changing file (the object will be update with the new file)

The main advantage of this module is that you don't work directly on the file but on a copy. So you can make errors, they won't be wrote until you call the Write() method

** ATTENTION ** this module can fail to load file on non-UNIX system because it rely on the "file" and "awk" command line tools. Be sure to use the 'load-raw' => 1 constructor's option on such operating system (most probably the file type will be blank and no problem will happen... but it's still a possibility).

** ATTENTION 2 ** this module rely on bzip2 and gzip command line tools to uncompress the compressed files. On systems which does not support the `gzip -dc` or `bzip2 -dc`, trying to load compressed files will cause crashs, which can eventually lead to the end of the world...

=cut

sub new
{
	my ($class,$file,%args) = @_ ;
	my $self={%args};
# 	print "\nActual file-encoding: $self->{'file-encoding'}\nargs : $args{'file-encoding'}\nFile: $file\n";<STDIN>;
	bless($self,$class);
	$self->{'file-encoding'} = 'utf8' unless(defined($self->{'file-encoding'}));
	if(defined($file) && -e $file && !defined($args{'load-raw'}))
	{
		eval {
			$self->{TYPE} = `LC_ALL=C file -b $file | awk '{print \$1}'`;
			chomp $self->{TYPE};
		};
		if($@){
			$self->{TYPE} = `LC_ALL=C file $file | awk '{print \$2}'`;
			chomp $self->{TYPE};
			if($@){
				$self->{TYPE} = 'none' ; # Empty the file type if the `file` syscall failed
				$args{'load-raw'}=1; # and set option to load it raw
			}
		}
		$self->{TYPE} = 'none' unless(defined($self->{TYPE}));
		$self->{TYPE} = 'ASCII' if($self->{TYPE} eq 'empty');
		$self->{TYPE} = 'ASCII' if($self->{TYPE} eq 'XML' || $self->{TYPE} eq 'Quake');
		die "[Slackware::Slackget::File::constructor] unsupported file type \"$self->{TYPE}\" for file $file. Supported file type are gzip, bzip2, ASCII and XML\n" unless($self->{TYPE} eq 'gzip' || $self->{TYPE} eq 'bzip2' || $self->{TYPE} eq 'ASCII' || $self->{TYPE} eq 'XML' || $self->{TYPE} eq 'none') ;
	}else{
		$self->{TYPE} = 'ASCII' ;
	}
# 	print "using $self->{'file-encoding'} as file-encoding for file $file\n";
	$self->{FILENAME} = $file;
	$self->{MODE} = $args{'mode'} if($args{'mode'} && ($args{'mode'} eq 'write' or $args{'mode'} eq 'append' or $args{'mode'} eq 'rewrite'));
	$self->{MODE} = 'append' if(defined($self->{MODE}) && $self->{MODE} eq 'rewrite');
	$self->{BINARY} = 0;
	$self->{BINARY} = $args{'binary'} if($args{'binary'});
	$self->{SKIP_WL} = $args{'skip-white-line'} if($args{'skip-white-line'});
	$self->{SKIP_WL} = $args{'skip-white-lines'} if($args{'skip-white-lines'});
	$self->{LOAD_RAW} = 0;
	$self->{LOAD_RAW} = $args{'load-raw'} if($args{'load-raw'});
	if(defined($file) && -e $file && !defined($self->{'no-auto-load'})){
		$self->Read();
	}
	else
	{
		$self->{FILE} = [];
	}
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

Take a filename as argument.

	my $file = Slackware::Slackget::File->new('foo.txt'); # if foo.txt exist the constructor will call the Read() method
	$file->add("an example\n");
	$file->Write();
	$file->Write("bar.txt");

This class try to determine the type of the file via the command `file` (so you need `file` in your path). If the type of the file is not in gzip, bzip2, ASCII or XML the constructor die()-ed. You can avoid that, if you need to work with unsupported file, by passing a "load-raw" parameter.

Additionnaly you can pass an file encoding (default is utf8). For example as a European I prefer that files are stored and compile in the iso-8859-1 charset so I use the following :

	my $file = Slackware::Slackget::File->new('foo.txt','file-encoding' => 'iso-8859-1');

You can also disabling the auto load of the file by passing a parameter 'no-auto-load' => 1 :

	my $file = Slackware::Slackget::File->new('foo.txt','file-encoding' => 'iso-8859-1', 'no-auto-load' => 1);

You can also pass an argument "mode" which take 'append or 'write' as value :

	my $file = Slackware::Slackget::File->new('foo.txt','file-encoding' => 'iso-8859-1', 'mode' => 'rewrite');

This will decide how to open the file (> or >>). Default is 'write' ('>').

Note: for backward compatibility mode => "rewrite" is still accepted as a valid mode. It is an alias for "append"

You can also specify if the file must be open as binary or normal text with the "binary" argument. This one is boolean (0 or 1). The default value is 0 :

	my $file = Slackware::Slackget::File->new('package.tgz','binary' => 1); # In real usage package.tgz will be read UNCOMPRESSED by Read().
	my $file = Slackware::Slackget::File->new('foo.txt','file-encoding' => 'iso-8859-1', 'mode' => 'rewrite', binary => 0);

If you want to load a raw file without uncompressing it you can pass the "load-raw" parameter :

	my $file = Slackware::Slackget::File->new('package.tgz','binary' => 1, 'load-raw' => 1);

=head1 FUNCTIONS

=head2 Read

Take a filename as argument, and load the file in memory.

	$file->Read($filename);

You can call this method without passing parameters, if you have give a filename to the constructor.

	$file->Read();

This method doesn't return the file, you must call Get_file() to do that.

Supported file formats : gzipped, bzipped and ASCII file are natively supported (for compressed formats you need to have gzip and bzip2 installed in your path).

If you specify load-raw => 1 to the constructor, read will load in memory a file even if the format is not recognize.

=cut

sub Read 
{
        my ($self,$file)=@_;
	if($file)
	{
		$self->{FILENAME} = $file ;
	}
	else
	{
		$file = $self->{FILENAME};
	}
	unless ( -e $file or -R $file)
	{
		warn "[Slackware::Slackget::File] unable to read $file : $!\n";
		return undef ;
	}
	my $tmp;
	my @file = ();
	if((defined($self->{TYPE}) && ($self->{TYPE} eq 'ASCII' || $self->{TYPE} eq 'XML' || $self->{TYPE} eq 'Quake') ) && !$self->{LOAD_RAW})
	{
# 		print "[DEBUG] [Slackware::Slackget::File] loading $file as 'plain text' file.";
		if(open (F2,"<:encoding($self->{'file-encoding'})",$file))
		{
			binmode(F2) if($self->{'BINARY'}) ;
			if($self->{SKIP_WL})
			{
				print "[Slackware::Slackget::File DEBUG] reading and skipping white lines\n";
				while (defined($tmp=<F2>))
				{
					next if($tmp=~ /^\s*$/);
					push @file,$tmp;
				}
			}
			else
			{
				while (defined($tmp=<F2>))
				{
					push @file,$tmp;
				}
			}
			
			close (F2);
			$self->{FILE} = \@file ;
			return 1;
		}
		else
		{
			warn "[Slackware::Slackget::File] cannot open \"$file\" : $!\n";
			return undef;
		}
	}
	elsif($self->{TYPE} eq 'bzip2' && !$self->{LOAD_RAW})
	{
# 		print "[DEBUG] [Slackware::Slackget::File] loading $file as 'bzip2' file.";
# 		my $tmp_file = `bzip2 -dc $file`;
		foreach (split(/\n/,`bzip2 -dc $file`))
		{
			push @file, "$_\n";
		}
		$self->{FILE} = \@file ;
		return 1;
	}
	elsif($self->{TYPE} eq 'gzip' && !$self->{LOAD_RAW})
	{
# 		print "[DEBUG] [Slackware::Slackget::File] loading $file as 'gzip' file.";
# 		my $tmp_file = `gzip -dc $file`;
		foreach (split(/\n/,`gzip -dc $file`))
		{
			push @file, "$_\n";
		}
		$self->{FILE} = \@file ;
		return 1;
	}
	elsif($self->{LOAD_RAW} or $self->{TYPE} eq '')
	{
# 		print "[DEBUG] [Slackware::Slackget::File] loading $file as 'raw' file.";
		if(open(F2,$file))
		{
			binmode(F2) if($self->{'BINARY'}) ;
			while (defined($tmp=<F2>))
			{
				push @file,$tmp;
			}
			close (F2);
			$self->{FILE} = \@file ;
			return 1;
		}
		else
		{
			warn "[Slackware::Slackget::File] cannot (raw) open \"$file\" : $!\n";
			return undef;
		}
	}
	else
	{
		die "[Slackware::Slackget::File] Read() method cannot load file \"$file\" in memory : \"$self->{TYPE}\" is an unsupported format.\n";
	}

}

=head2 Lock_file (deprecated)

Same as lock_file, provided for backward compatibility.

=cut

sub Lock_file {
	return lock_file(@_);
}

=head2 lock_file

This method lock the file for slack-get application (not really for others...) by creating a file with the name of the current open file plus a ".lock". This is not a protection but an information system for slack-getd sub process. This method return undef if the lock can't be made.

	my $file = new Slackware::Slackget::File ('test.txt');
	$file->lock_file ; # create a file test.txt.lock

ATTENTION: You can only lock the current file of the object. With the previous example you can't do :

	$file->Lock_file('toto.txt') ;

ATTENTION 2 : Don't forget to unlock your locked file :)

=cut

sub lock_file
{
	my $self = shift;
	return undef if $self->is_locked ;
# 	print "\t[DEBUG] ( Slackware::Slackget::File in Lock_file() ) locking file $self->{FILENAME} for $self\n";
	Write({'file-encoding'=>$self->{'file-encoding'}},"$self->{FILENAME}.lock",$self) or return undef;
	return 1;
}

=head2 Unlock_file (deprecated)

Same as unlock_file(), provided for backward compatibility.

=cut

sub Unlock_file {
	return unlock_file(@_);
}

=head2 unlock_file

Unlock a locked file. Only the locker object can unlock a file ! Return 1 if all goes well, else return undef. Return 2 if the file was not locked. Return 0 (false in scalar context) if the file was locked but by another Slackware::Slackget::File object.

	my $status = $file->unlock_file ;

Returned value are :

	0 : error -> the file was locked by another instance of this class
	
	1 : ok lock removed
	
	2 : the file was not locked
	
	undef : unable to remove the lock.

=cut

sub unlock_file
{
	my $self = shift;
	if($self->is_locked)
	{
		if($self->_verify_lock_maker)
		{
			unlink "$self->{FILENAME}.lock" or return undef ;
		}
		else
		{
			return 0;
		}
	}
	else
	{
# 		print "\t[DEBUG] ( Slackware::Slackget::File in Unlock_file() ) $self->{FILENAME} is not lock\n";
		return 2;
	}
	return 1;
}

sub _verify_lock_maker
{
	my $self = shift;
	my $file = new Slackware::Slackget::File ("$self->{FILENAME}.lock");
	my $locker = $file->get_line(0) ;
# 	print "\t[DEBUG] ( Slackware::Slackget::File in _verify_lock_maker() ) locker of file \"$self->{FILENAME}\" is $locker and current object is $self\n";
	$file->Close ;
	undef($file);
	my $object = ''.$self;
# 	print "[debug file] compare object=$object and locker=$locker\n";
	if($locker eq $object)
	{
# 		print "\t[DEBUG] ( Slackware::Slackget::File in _verify_lock_maker() ) locker access granted for file \"$self->{FILENAME}\"\n";
		return 1;
	}
	else
	{
# 		print "\t[DEBUG] ( Slackware::Slackget::File in _verify_lock_maker() ) locker access ungranted for file \"$self->{FILENAME}\"\n";
		return undef;
	}
}

=head2 is_locked

Return 1 if the file is locked by a Slackware::Slackget::File object, else return undef.

	print "File is locked\n" if($file->is_locked);

=cut

sub is_locked
{
	my $self = shift;
	return 1 if(-e $self->{FILENAME}.".lock");
	return undef;
}

=head2 Write

Take a filename to write data and raw data 

	$file->Write($filename,@data);

You can call this method with just a filename (in this case the file currently loaded will be wrote in the file you specify)

	$file->Write($another_filename) ; # Write the currently loaded file into $another_filename

You also can call this method without any parameter :

	$file->Write ;

In this case, the Write() method will wrote data in memory into the last opened file (with Read() or new()).

The default encoding of this method is utf-8, pass an extra argument : file-encoding to the constructor to change that.

=cut

sub Write
{
        my ($self,$name,@data)=@_;
	$name=$self->{FILENAME} unless($name);
	@data = @{$self->{FILE}} unless(@data);
#         if(open (FILE, ">$name"))
# 	print "using $self->{'file-encoding'} as file-encoding for writing\n";
	 my $mode = '>';
	if(defined($self->{MODE}) && $self->{MODE} eq 'append')
	{
		$mode = '>>';
	}
	if(open (FILE, "$mode:encoding($self->{'file-encoding'})",$name))
	{
		binmode(FILE) if($self->{'BINARY'}) ;
		# NOTE: In the case you need to clear the white line of your file, their will be a if() test for each array slot
		# This is really time consumming, so id you don't need this feature we just test once for all and gain a lot in performance.
		if($self->{SKIP_WL})
		{
			print "[Slackware::Slackget::File DEBUG] mode 'skip-white-line' activate\n";
			foreach (@data)
			{
				foreach my $tmp (split(/\n/,$_))
				{
					next if($tmp =~ /^\s*$/) ;
					print FILE "$tmp\n" ;
				}
			}
		}
		else
		{
			foreach (@data)
			{
				print FILE $_;
			}
		}
		close (FILE) or return(undef);
	}
	else
	{
		warn "[ Slackware::Slackget::File ] unable to write '$name' : $!\n";
		return undef;
	}
	return 1;
}

=head2 Add (deprecated)

Same as add(), provided for backward compatibility.

=cut

sub Add {
	return add(@_);
}

=head2 add

Take a table of lines and add them to the end of file image (in memory). You need to commit your change by calling the Write() method !

	$file->add(@data);
	or
	$file->add($data);
	or
	$file->add("this is some data\n");

=cut

sub add {
	my ($self,@data) = @_;
	$self->{FILE} = [@{$self->{FILE}},@data];
}

=head2 Get_file (deprecated)

Same as get_file(), provided for backward compatibility.

=cut

sub Get_file {
	return get_file(@_);
}

=head2 get_file

Return the current file in memory as an array.

	@file = $file->get_file();

=cut

sub get_file{
	my $self = shift;
	return @{$self->{FILE}};
}


=head2 Get_line (deprecated)

Same as get_line(), provided for backward compatibility.

=cut

sub Get_line {
	return get_line(@_);
}


=head2 get_line

Return the $index line of the file (the index start at 0).

	@file = $file->get_line($index);

=cut

sub get_line {
	my ($self,$index) = @_;
	return $self->{FILE}->[$index];
}

=head2 Get_selection (deprecated)

Same as get_selection(), provided for backward compatibility.

=cut

sub Get_selection {
	return get_selection(@_);
}

=head2 get_selection

	Same as get file but return only lines between $start and $stop.

	my @array = $file->get_selection($start,$stop);

You can ommit the $stop parameter (in this case Get_line() return the lines from $start to the end of file)

=cut

sub get_selection {
	my ($self,$start,$stop) = @_ ;
	$start = 0 unless($start);
	$stop = $#{$self->{FILE}} unless($stop);
	return @{$self->{FILE}}[$start..$stop];
}


=head2 Close

Free the memory. This method close the current file memory image. If you don't call the Write() method before closing, the changes you have made on the file are lost !

	$file->Close();

=cut

sub Close {
	my $self = shift;
	$self->{FILE} = [];
	return 1;
}


=head2 Write_and_close (deprecated)

Same as write_and_close(), provided for backward compatibility.

=cut

sub Write_and_close {
	return write_and_close(@_);
}

=head2 write_and_close

An alias which call Write() and then Close();

	$file->write_and_close();
	or
	$file->write_and_close("foo.txt");

=cut

sub write_and_close{
	my ($self,$file) = @_;
	$self->Write($file);
	$self->Close();
}

=head2 encoding

Without parameter return the current file encoding, with a parameter set the encoding for the current file.

	print "The current file encoding is ",$file->encoding,"\n"; # return the current encoding
	$file->encoding('utf8'); # set the current file encoding to utf8

=cut

sub encoding
{
	return $_[1] ? $_[0]->{'file-encoding'}=$_[1] : $_[0]->{'file-encoding'};
}

=head2 filename

Return the filename of the file which is currently process by the Slackware::Slackget::File instance.

	print $file->filename

You can also set the filename :

	$file->filename('foo.txt');

=cut

sub filename
{
	return $_[1] ? $_[0]->{FILENAME}=$_[1] : $_[0]->{FILENAME};
}

=head2 type (read only)

Return the current file type.

	print $file->type

=cut

sub type {
	return $_[0]->{TYPE};
}

=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget::File


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::File
