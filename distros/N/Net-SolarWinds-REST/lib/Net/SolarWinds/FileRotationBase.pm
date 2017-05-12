package Net::SolarWinds::FileRotationBase;

use strict;
use warnings;
use IO::File;
use File::Copy qw(move);
use base qw(Net::SolarWinds::ConstructorHash);
use Carp qw(croak);

=pod

=head1 NAME

Net::SolarWinds::FileRotationBase - base file rotation framework

=head1 SYNOPSIS

  use base qw(Net::SolarWinds::FileRotationBase);

=head1 DESCRIPTION

This modle is intended to be used as a base module for modules that require an auto file rotation framework.  Auto file rotation is handled by file size.


=head1 OO Methods


=over 3

=cut

=item * Object constructor

The object constructor for this class has a collection of optional arguments.  Arguments are passed to the constructor in key value pairs.

Constructor useage example:

  my $fr=new Net::SolarWinds::FileRotationBase(folder=>'/var/logs/myapp',basefilename=>'someapp');

Argument list is as follows (default values shown):

  # Fully quallified system path to the log file
  filename=>'/path/to/some/file.log'

  # sets the folder files will be created and rotated under
  folder=>'.',  
  
  # sets the basefilename
  basefilename => 'DefaultFile',
  
  # used to concat the folder and filenames togeather
  pathconncat  => '/',
  
  # sets thefile extention to be used
  ext => 'log',
  
  # sets the number of files to keep in rotation
  maxfilecount => 3,
  
  # sets the max file size ( 8mb )
  maxsize      => 1024 * 1024 * 8,
  
  # sets the autoflush state ( handy for real time info in the file )
  autoflush    => 1,
  
  # sets the file auto rotation flag
  autorotate   => 1,

  # glob ref will be overwritten with the current fh
  mirror=>undef|\*STDERR

=cut

sub new {
	my ( $class, %args ) = @_;

    my $max_size=1024 * 1024 * 8;
	my $self = $class->SUPER::new(
		folder       => '.',
		basefilename => 'DefaultFile',
		pathconncat  => '/',
		ext          => 'log',
		maxfilecount => 3,
		maxsize      => $max_size,
		autoflush    => 1,
		autorotate   => 1,
		mirror       =>undef,
		%args
	);

	return $self;
}

=item * $fr->set_mirror(\*STDERR);

Sets a file handle to be mirroed to:

=cut

sub set_mirror {
  my ($self,$glob)=@_;

  $self->{mirror}=$glob;

  my $fh=$self->get_fh;
  return unless $fh;
  *$glob=$fh;
}

=item * my $filename=$fr->generate_filename;

Retuns the filename of the active file.

=cut

sub generate_filename {
	my ($self) = @_;


    return $self->{filename} if exists $self->{filename};

	my $filename =
	    $self->{folder}
	  . $self->{pathconncat}
	  . $self->{basefilename} . '.'
	  . $self->{ext};
}

=item * my $fh=$fr->get_fh;

Returns the active filehandle.

=cut

sub get_fh {
	my ($self) = @_;

	# assumes this is defined correctly if it exists..
	# if some one mucks with the internals this can be painful!
	return $self->{fh} if exists $self->{fh};

	# if we got here then we have no file handle!

	my $filename = $self->generate_filename;

	my $fh = new IO::File(qq{>>$filename});

	# failed to open the file?
	# well this is pretty much the end of the world..
	# time to blame some one else!
	croak qq{Failed to create file "$filename" error was: $!\n}
	  unless defined($fh);

	$fh->autoflush( $self->{autoflush} );

	$self->{fh} = $fh;
	if(defined($self->{mirror})) {
	  my $mirror=$self->{mirror};
	  *$mirror=$fh;
	}

	return $fh;
}


=item * $fr->rotate_files

Forces log files to be rotated now!

=cut

sub rotate_files {
	my ($self) = @_;

	my $max_files = $self->{maxfilecount};
	my $basefile  = $self->generate_filename;
  ROTATE_LOOP: for ( my $count = $max_files ; $count > 0 ; --$count ) {

		my $targetfile = qq{$basefile.$count};

		# skip this file if it does not exist
		next ROTATE_LOOP unless ( -e $targetfile );

		my $next_count = 1 + $count;
		my $nextfile   = $basefile . '.' . ($next_count);

		# last file check
		if ( $next_count > $max_files ) {

			# this is the last file to manage in the list
			# we look for one after it and remove it as well
			# out of the goodness of our heart
			unlink $nextfile if -e $nextfile;

			# delete the elder file
			unlink $targetfile;
			next ROTATE_LOOP;

		}

		move( $targetfile, $nextfile );

	}
	my $nextfile = qq{$basefile.1};

	# move the current file to the .1 position
	$self->close_fh;
	return move( $basefile, $nextfile );

}


=item * $fr->close_fh;

Closes the current active file handle.

=cut

sub close_fh {
	my ($self) = @_;

	return 1 unless exists $self->{fh};

	my $fh = $self->{fh};

	delete $self->{fh};

	return close($fh);
}

=item * $fr->write_to_file("Something to write to my file\n");

Writes the list of arguments to the target file.

=cut

sub write_to_file {
	my ( $self, @data ) = @_;
	my $fh = $self->get_fh;
	
	return 0 unless $fh;

	return 0 unless print $fh @data;

	return 1 unless $self->{autorotate};

	#auto rotate file checks
	my $pos = tell($fh);

	return 1 unless $pos >= $self->{maxsize};

	return $self->rotate_files;

}

=pod

=back

=head1 AUTHOR

Michael Shipper

=cut

1;
