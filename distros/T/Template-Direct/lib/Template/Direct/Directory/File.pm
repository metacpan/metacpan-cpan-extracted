package Template::Direct::Directory::File;

use strict;
use warnings;

=head1 NAME

Template::Direct::Directory::File - Objectified access to files

=head1 SYNOPSIS

  use Template::Direct::Directory::File;

  my $file1 = $directory->new( File => 'file1.txt' );
  my $file2 = Directory::File->new( File => '/Root/lib/file1.txt' );

=head1 DESCRIPTION
	
  Loads a directory for use with FileDirectives
	
=head1 METHODS

=cut
	
our $VERSION = "1.00";

use overload
	'""'	=> sub { shift->autocontents(@_) },
	'bool'  => sub { shift->exist(@_) },
	'eq'    => sub { shift->autocontents(@_) };

use Carp;

=head2 I<$class>->new( $filename, %p )

  Create a new file object.

=cut
sub new
{
	my ($class, $file, %p) = @_;

	carp "Unable to create valid file object, missing File p" and return if not $file;
	my $self = bless { %p, File => $file }, $class;

	#warn Carp::longmess("\nNew File -> $file (".$self->{'Parent'}.") + ".$p{'Create'}."\n");

	if(not $self->{'Parent'}) {
		my $dir = $file;
		$dir =~ s/\/([^\/]*?)$//;
		warn "\nTurning file into $1! does this make sense?\n";
		$self->{'File'} = $1;

		warn "Creating Directory Parent '$dir'\n" if $ENV{'FILE_DEBUG'};

		$self->{'Parent'} = Template::Direct::Directory->new( $dir, Create => $p{'Create'} );
	}
	if(not $self->{'Parent'}) {
		carp "File Warn: Unable to create file because directory does not exist" if $ENV{'FILE_DEBUG'};
		return;
	}

	if($p{'Create'} and not $self->exist()) {
		$self->save('');
	}

	if(my $cache = $self->parent->loadCache($self->path())) {
		return $cache;
	}

	$self->parent->saveCache($self->path(), $self) if $self->{'Cache'} and ($self->exist() or $p{'Create'});

	return $self;
}

=head1 OVERLOADED

=head2 I<$file>->autocontents( )

  Return the contents of a file when used in string context.

=cut
sub autocontents
{
	my ($self) = @_;
	
	if(not defined($self->{'Data'}) or $self->outofdate()) {
		return $self->load();
	}
	return $self->{'Data'};
}

=head2 I<$file>->save( $new_data, %options )

  Save $new_data as the new file contents.

  Options:

    * Append - Boolean to specifiy data is to be appended.
    * Text   - Treat data as text and do CR/LF filtering

=cut
sub save
{
	my ($self, $data, %p) = @_;

	my $filename = $self->path();
	if(not $filename) {
		carp "File Error: No file name in save file"; return;
	}

	if(defined($data)) {

		if($p{'Text'}) {
			$self->unix(\$filename);
		}

		# Both save and Append functions
		my $method = ">".($p{'Append'} ? ">" : "");

		if(open( FILE, $method.$filename )) {
			$data = join('', $data) if ref($data) eq "Fh";
			print FILE $data;
			close( FILE );

			if(not $p{'nocache'}) {
				$self->{'modtime'} = -M $self->path;
				$self->parent->saveCache($self->path, $self);
				$self->{'Data'} = $data;
			}
			warn "File: Saving $filename\n" if $ENV{'FILE_DEBUG'};
		} else {
			carp "File Error: could not save file: $filename, $!";
		}
	} else {
		carp "File Error: could not save file: $filename, No data provided";
	}
	return 1;
} 

=head2 I<$file>->append( $data, %p )

  Same as save() but specify data is to be appended.

=cut
sub append { my $self = shift; $self->save(@_, Append => 1 ); }



=head2 I<$file>->load( %options )

  Load data from file with options:

    * Quoting - Quote all data
    * Text    - Treat data as text and filter CR/LF

=cut
sub load
{
	my ($self, %p) = @_;

	my $filename = $self->path();
	my $data;

	if(not $filename) {
		carp "File Error: No filename to load file";
		return -1;
	}

	if(open( File, $filename )) {
		$data = join('', <File>);
		warn "File: Loading '$filename'\n" if $ENV{'FILE_DEBUG'};
		close( File );
	} else {
		carp "File Error: Unable to open file: $filename, $!";
		return -1;
	}
	warn "File: NOT Caching $filename\n" if not $self->{'Cache'} and $ENV{'FILE_DEBUG'};
	$self->{'modtime'} = -M $filename;

	if($p{'Quoting'}) {
		$self->quote(\$data);
	}
	if($p{'Text'}) {
		$self->unix(\$data);
	}
	$self->{'modtime'} = -M $self->path;
	$self->{'Data'} = $data;
	return $data;
}

=head2 I<$file>->path( )

  Return the full path to this file objects location.

=cut
sub path {
	my ($self) = @_;
	return $self->parent()->path().$self->filename();
}

=head2 I<$file>->filename( )

=head2 I<$file>->name( )

  Return the files name without path.

=cut
sub filename
{
	my ($self) = @_;
	return $self->{'File'};
}
sub name { shift->filename(); }

=head2 I<$file>->parent( )

  Return the parent Directory object to this file.

=cut
sub parent
{
	my ($self) = @_;
	return $self->{'Parent'};
}

=head2 I<$file>->exist( )

  Return true is this file exists on the disk.

=cut
sub exist {
	my ($self) = @_;
	return -f $self->path() ? 1 : 0;
}

=head2 I<$file>->clearCache( )

  Clear this files cache (if it is cached)

=cut
sub clearCache {
	my ($self) = @_;
	return $self->parent->clearCache( File => $self->filename );
}

=head2 I<$file>->fromCache( )

  Was this file loaded from cache? (used for testing)

=cut
sub fromCache {
	my ($self) = @_;
	return $self->{'fromCache'};
}

=head2 I<$file>->delete( )

  Remove this file fromt he disk and close object.

=cut
sub delete
{
	my ($self) = @_;
	warn "Deleteing file '".$self->path."'\n" if $ENV{'DIR_DEBUG'};
	my $result = unlink($self->path);
	$self->clearCache if $result;
	return $result;
}

=head2 I<$file>->size( $h )

  Returns size of file as number of bytes unless
  $h is true in which case it returns the most
  relivent size metric (i.e KB/MB/GB)

=cut
sub size
{
	my ($self, $h) = @_;
	my $unit = '';
	my $filesize = -s $self->path;
	if($h) {
		$unit = 'Bytes';
		$filesize / 1024 and $unit = 'KB' if $filesize > 1024;
		$filesize / 1024 and $unit = 'MB' if $filesize > 1024;
		$filesize / 1024 and $unit = 'GB' if $filesize > 1024;
	}
	return $filesize.$unit;
}

=head2 I<$file>->outofdate( )

  Returns true if the file is out of date (used internally)
  The file with automatically reload contents if it's out of date
  when used so there isn't a need to use this for content.

=cut
sub outofdate
{
	my ($self) = @_;
	my $newfiletime = -M $self->path;
	#warn "return 1 if not ".length($self->modtime)." or $newfiletime < ".$self->modtime."\n";
	return 1 if(not length($self->modtime) or $newfiletime < $self->modtime);
	return 0;
}

=head2 I<$file>->modtime( )

  When was the last time this file was modified.

=cut
sub modtime
{
	my ($self) = @_;
	return defined($self->{'modtime'}) ? $self->{'modtime'} : '';
}

=head2 I<$file>->isfile( )

  Returns true.

=cut
sub isfile { 1 }

=head2 I<$file>->isdir( )

  Returns false

=cut
sub isdir { 0 }

=head1 AUTHOR

 Copyright, Martin Owens 2008, AGPL

=cut
1;
