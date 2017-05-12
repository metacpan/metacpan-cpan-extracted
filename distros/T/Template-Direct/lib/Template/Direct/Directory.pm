package Template::Direct::Directory;

=head1 NAME

Template::Direct::Directory - Controls the access to a set directory

=head1 SYNOPSIS

  use Directory;

  my $directory = Template::Direct::Directory->new( '/etc' );

  my $file = $directory->open( 'foo.txt' );

  my $parent = $directory->parent();

  my @children = $directory->list();

  my @results = $directory->search();

=head1 DESCRIPTION
	
  Loads a directory for use with fileDirectives
	
=head1 METHODS

=cut
	
our $VERSION = "3.02";

use overload
    '""'   => \&autoscalar,
	'bool' => \&autobool,
	'eq'   => \&autoeq,
	'ne'   => \&autone;

use strict;
use Carp qw/carp cluck/;
use Template::Direct::Directory::File;

our %Cache;

=head2 I<$class>->new( $dir )

  Create a new Directory object located at $dir.

=cut
sub new
{
	my ($cache, $dir, %p) = @_;
	my $self = bless {}, $cache;

	carp "Directory Error: 'Directory' is a required field" and return if not $dir;
	($self->{'Directory'}) = $self->_clean_path( Directory => $dir, Parents => 1 );

	if(defined($Cache{$self->{'Directory'}})) {
		warn "Using cached Directory $self->{'Directory'}\n" if $ENV{'DIR_DEBUG'};
		return $Cache{$self->{'Directory'}};
	}

	carp "Directory Error: files are not allowed as Directories (please use Directory::File)"
		and return if -f $dir;

	if( $p{'Create'} ) {
		$self->mkpath( $self->{'Directory'} );
	}

	$Cache{$self->path()} = $self if -f $self->path();

	return $self;
}

=head2 I<$dir>->save( $filename, $data, %options )

  Save a file in this directory (quickly)

=cut
sub save
{
	my ($self, $file, $data, %p) = @_;
	my ($path, $isfile, $parent) = $self->_clean_path(%p, File => $file );

	carp "Directory Error: file is a required field when saving" and return if not $path;
	carp "Directory Error: Directories can not be saved" and return if not $isfile;

	if(defined($data)) {
		if(not -d $parent) {
			$parent->mkpath( $parent->path() );
		}
		my $file = Template::Direct::Directory::File->new( $path, Create => 1, %p, Parent => $parent );
		return if(not defined($file));
		$file->save( $data );
		return $file;
	} else {
		carp "Directory Error: No data to save, required Data\n";
	}
	return;
}

=head2 I<$dir>->loadFile( $filename, %options )

  Load a file object child, options include:

    * Create - Create this file if it doesn't exist

=cut
sub loadFile { shift->load( @_, File => 1 ) }

=head2 I<$dir>->loadDir( $directory, %options )

  Load a sub directory, options include:

    * Create - Create this file if it doesn't exist

=cut
sub loadDir { shift->load( @_ ) }

=head2 I<$dir>->load( $path, %options )

  Generic load a file or sub directory object with options:

    * Create     - Create this filename as a directory if it doesn't exist
    * CreateFile - Create this filename as a file if it doesn't exist
	* File       - Force loading as a file object.

=cut
sub load
{
	my ($self, $file, %p) = @_;
	my ($path, $isfile, $parent) = $self->_clean_path( %p, Directory => $file );
	$p{'Create'} = $p{'CreateFile'} if not $p{'Create'};
	return Template::Direct::Directory::File->new( $path, %p, Parent => $parent ) if $isfile;
	return Template::Direct::Directory->new( $path, %p, Parent => $self );
}

=head2 I<$dir>->delete( $filename, %p )

  Delete a file from this directory.

=cut
sub delete
{
	my ($self, $file, %p) = @_;
	my ($path, $isfile, $parent) = $self->_clean_path( %p, Directory => $file );
	if($isfile) {
		my $file = Template::Direct::Directory::File->new( $path, %p, Parent => $parent );
		if($file) {
			return $file->delete();
		}
	} else {
		return $self->prune( $path );
	}

	return;
}

=head2 I<$dir>->_clean_path( %p )

  Takes %p and returns corrected, localised paths.

=cut
sub _clean_path
{
	my ($self, %p) = @_;

	my $path = ($p{'File'} and not $p{'Directory'}) ? $p{'File'} : $p{'Directory'};
	return if not $path;

	if(not $p{'Parents'}) {
		carp "Unable to clean path because Diretory object is involid" and return if not $self->path;
		$path = $self->path.$path;
	}

	#carp "Cleaning path $path ".(-d $path ? 1 : 0)."/".(-f $path ? 1 : 0)."\n";

	if($p{'CreateFile'} or -f $path) {
		$p{'Create'} = 1;
		$p{'File'}   = 1;
	}

    $path = $self->useElements($path, $p{'Elements'}) if $p{'Elements'};
	
	$path .= "/" if not $p{'File'};
	$path =~ s/([^\/]+)\/\.\.\///g; # No parent directories allowed in children
	warn "Removing Parent $1\n" if $1 and $ENV{'DIR_DEBUG'};
	$path =~ s/\/\.\//\//g; # No current directories allowed
	$path =~ s/\/+/\//g; # Remove double directories.

	if($p{'File'}) {
		my ($dir, $filename) = $path =~ /^(.+)\/([^\/]+)$/;
		my $parent = $dir ? Template::Direct::Directory->new( $dir, Create => $p{'CreatePath'} ) : $self;
		return ($filename, 1, $parent);
	} else {
		return ($path, 0);
	}
}

=head2 I<$dir>->clearCache( %p )

  Clear directory and file objects that are cached.

=cut
sub clearCache
{
	my ($self, %p) = @_;
	my ($file, $isfile, $parent) = $self->_clean_path(%p);

	if($isfile) {
		return delete($parent->{'Cache'}->{$file});
	} elsif($file) {
		my $dir = Template::Direct::Directory->new( $file );
		return $dir->clearCache;
	} else {
		warn "Clearing Cache for ".$self->path."\n" if $ENV{'DIR_DEBUG'};
		$self->{'Cache'} = {};
		return 1;
	}
}

=head2 I<$ir>->clearCaches()

  Clear all directory and file objects that are cached.

=cut
sub clearCaches
{
	my ($self) = @_;
	foreach my $dir (values(%Cache)) {
		$dir->clearCache;
	}
	%Cache = ();
	return;
}

=head2 I<$dir>->fromCache( )

  Was this object loaded from cache (for testing)

=cut
sub fromCache { shift->{'fromCache'} }

=head2 I<$dir>->saveCache( $filename, $data )

  Save a cache for filename with data.

=cut
sub saveCache
{
	my ($self, $filename, $data) = @_;
	if($data) {
		warn "DIR,Cache,save DONE $filename\n" if $ENV{'DIR_DEBUG'};
		$self->{'Cache'}->{$filename} = $data;
	} else {
		warn "DIR,Cache,save FAILED (No Data) $filename\n" if $ENV{'DIR_DEBUG'};
	}
	return 1;
}

=head2 I<$dir>->loadCache( $filename )

  Load a specific cache at filename if it exists.

=cut
sub loadCache
{
	my ($self, $filename) = @_;
	if($self->{'Cache'}->{$filename}) {
		warn "DIR,Cache,load DONE $filename\n" if $ENV{'DIR_DEBUG'};
		$self->{'Cache'}->{$filename}->{'fromCache'} = 1;
		return $self->{'Cache'}->{$filename};
	} else {
		warn "DIR,Cache,load FAILED $filename\n" if $ENV{'DIR_DEBUG'};
		return;
	}
}

=head2 I<$dir>->path( )

  Returns this directories full path.

=cut
sub path
{
	my ($self) = @_;
	return $self->{'Directory'};
}

=head2 I<$dir>->name( )

  Returns this folders name.

=cut
sub name
{
	my ($self) = @_;
	my $path = $self->path();
	($self->{'Name'}) = $path =~ /([^\/]+)\/*$/ if not $self->{'Name'};
	return $self->{'Name'};
}

=head2 I<$dir>->mkpath( $directory )

  Create a directory and all parents from this directory.

=cut
sub mkpath
{
	my ($self, $newdir) = @_;

	my @dirs = split('/', $newdir);
	my $path = $newdir =~ /^\// ? '/' : $self->path;
	
	foreach my $dir (@dirs)
	{
		if($dir and not -d $path.$dir)
		{
			warn "file: Creating directory '$path$dir'\n" if $ENV{'DIR_DEBUG'};
			if(mkdir($path.$dir))
			{
				$path = $path.$dir."/";
			} else {
				carp "file Error: Could not create directory '$path$dir' ($!)" if $ENV{'DIR_DEBUG'};
				return;
			}
		} else {
			$path = $path.$dir."/";
		}
	}

	return $self;
}

=head2 I<$dir>->prune( $path )

  Removes all empty directories from path to this directory.

=cut
sub prune
{
	my ($self, $path) = @_;
	
	$path = '' if not $path;
	if($path !~ /^\//) {
		$path = $self->path.$path;
	}
	
	my @dirs = split('/', $path);
	my $removed = '';

	while(my $dir = pop(@dirs)) {
		if(-d $path) {
			if(rmdir($path)) {
				# Ensure the directory is no longer cached
				delete($Cache{$path});
				# A record of removal route
				$removed = $dir.'/'.$removed;
				# Next path to try and remove
				$path = join('/', @dirs);
			} else {
				last;
			}
		} else {
			carp "file Error: Could not prune directory '$path'";
            return;
		}
	}

	return $removed;
}

=head2 <$class>->useElements( $path, $elements )

  Should parts of the path or filename be replaced by a defined hash? (used by load, save, delete)

=cut
sub useElements
{
	my ($self, $path, $elements) = @_;

	carp "file Error: Filename is a required field\n" and return if not $path;
	$path =~ s/(?<!\\)\$([\w\-_]+)/ defined $elements->{$1} ? $elements->{$1} : "\$".$1 /eg;

	return $path;
}

=head2 I<$dir>->exist( %p )

  Does this directory or child exist.

=cut
sub exist {
	my ($self) = @_;
	return -d $self->path() ? 1 : 0;
}

=head2 <$dir>->parent( )

  Return a new directory object containing the parent directory.

=cut
sub parent
{
	my ($self) = @_;

	if($self->path =~ /^(.+)\/[^\/]+?\/$/)
	{
		my $newpath = $1;
		my $parent = Template::Direct::Directory->new( $newpath );
		return $parent;
	}
	return $self;
}

=head2 I<$dir>->list( %p )

  List all directories and files in this directory, load each as an object.

=cut
sub list
{
	my ($self, %p) = @_;

	my @results;
	opendir( LISTDIR, $self->path ) or return [];
	foreach my $dir (readdir( LISTDIR )) {
		if($dir ne "." and $dir ne "..") {
			push @results, $dir and next if $p{'Text'};
			push @results, $self->load( $dir );
		}
	}
	closedir( LISTDIR ); 
	return \@results;
}

=head2 I<$dir>->hlist( )

  Return a clean list of filename children.

=cut
sub hlist
{
	my ($self) = @_;
	my %results;
	foreach (@{$self->list}) {
		$results{$_->name} = $_;
	}
	return \%results;
}

=head2 I<$dir>->isfile( )

  Returns false

=cut
sub isfile { 0 }

=head2 I<$dir>->isdir( )

  Returns true

=cut
sub isdir { 1 }

=head1 OVERLOADED

=head2 I<$dir>->autoeq( $cmp )

  Compare directory location string.

=cut
sub autoeq { shift()->path() eq shift(); }

=head2 I<$dir>->autone( $cmp )

  Compare directory location string does not equal.

=cut
sub autone { shift()->path() ne shift(); }

=head2 I<$dir>->autoscalar( $cmp )

  Return path of this directory in string context.

=cut
sub autoscalar
{
    my ($self) = @_;
    return $self->path();
}

=head2 I<$dir>->autobool( $cmp )

  Does this directory exist when used in a boolean context.

=cut
sub autobool
{
    my ($self) = @_;
    my ($package) = caller;
    return $self->exist if $package ne ref($self);
    return $self;
}

=head1 AUTHOR

 Copyright, Martin Owens 2008, AGPL

=cut
1;
