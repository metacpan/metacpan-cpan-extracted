package MogileFS::Client::Fuse::BufferedFile;

use strict;
use warnings;
use MRO::Compat;
use mro 'c3';
use threads::shared;
use base qw{MogileFS::Client::Fuse::File};

Class::C3::initialize();

our $VERSION = '0.05';

use constant BUFFERSIZE => 64*1024;

use MogileFS::Client::Fuse::Constants qw{:LEVELS};

##Instance Methods

sub _flushBuffer {
	my $self = shift;

	#lock the buffer while processing
	{
		my $buffer = $self->{'buffer'};
		lock($buffer);

		#write buffered data if any exists
		if($buffer->{'start'} != $buffer->{'end'}) {
			my $data = $buffer->{'data'};
			$self->_write($buffer->{'start'}, \$data, '_bypassBuffer' => 1);
		}

		#reset the buffer
		$buffer->{'data'} = '';
		$buffer->{'end'} = $buffer->{'start'} = 0;
	}

	return 1;
}

sub _fsync {
	my $self = shift;

	# flush the write buffer
	$self->_flushBuffer();

	# process any other fsync methods as necessary
	return $self->next::method(@_);
}

# method that will (re)initialize the I/O buffer
sub _initIo {
	my $self = shift;

	# (re)initialize the buffer data structure
	$self->{'buffer'} = shared_clone({
		'data'  => '',
		'start' => 0,
		'end'   => 0,
	});

	# (re)initialize the base object
	return $self->next::method();
}

sub _read {
	my $self = shift;
	my ($offset, $buf, %opt) = @_;

	#flush the write buffer if this is an output file read
	$self->_flushBuffer() if($opt{'output'});

	#issue actual read request
	return $self->next::method($offset, $buf, %opt);
}

#write data to the file buffer
#	_bypassBuffer => flag indicating that the buffer should be bypassed, should only be used internally
sub _write {
	my $self = shift;
	my ($offset, $buf, %opt) = @_;

	#short-circuit if the buffer is being bypassed
	return $self->next::method($offset, $buf, %opt) if($opt{'_bypassBuffer'});

	#short-circuit if there is no data being added to the buffer
	return 0 if(!defined($buf));

	#throw an error if an invalid data buffer was provided
	if(defined($buf) && ref($buf) ne 'SCALAR') {
		$self->fuse->log(ERROR, 'Invalid Buffer passed to _write for ' . $self->path);
		die;
	}

	#lock the buffer while interacting with it
	{
		my $buffer = $self->{'buffer'};
		lock($buffer);

		#flush the buffer if it is full or current data isn't adjacent to the buffer
		if($offset != $buffer->{'end'} || $buffer->{'end'} - $buffer->{'start'} > BUFFERSIZE) {
			$self->_flushBuffer();
			$buffer->{'end'} = $buffer->{'start'} = $offset;
		}

		#write the data to the buffer
		my $len = length($$buf);
		substr($buffer->{'data'}, $offset - $buffer->{'start'}, $len, $$buf);
		$buffer->{'end'} = $offset + $len;

		#return the amount of data written to the buffer
		return $len;
	}
}

1;
