package Perl::Metrics2::Parse;

# Delegatable PPI caching parser.
# Takes a PPI::Cache directory and a list of files to parse.

use strict;
use warnings;
use Process              ();
use Process::Storable    ();
use Process::Delegatable ();
use PPI::Util            ();
use PPI::Cache           ();
use PPI::Document        ();
use Params::Util         '_ARRAY';

our $VERSION = '0.06';
our @ISA     = qw{
	Process::Delegatable
	Process::Storable
	Process
};

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( -d $self->cache ) {
		die "Missing or invalid cache directory";
	}
	unless ( _ARRAY($self->files) ) {
		die "Missing or invalid file list";
	}

	return $self;
}

sub cache {
	$_[0]->{cache};
}

sub files {
	$_[0]->{files};
}

sub ok {
	$_[0]->{ok};
}

sub prepare {
	my $self = shift;

	# Set the default PPI document cache
	$self->{ppi_cache} = PPI::Cache->new(
		path => $self->cache,
	);
	unless ( PPI::Document->set_cache( $self->{ppi_cache} ) ) {
		die "Failed to set PPI parser cache";
	}

	return 1;
}

sub run {
	my $self  = shift;
	my @files = @{$self->files};

	# Prepare the accounting
	$self->{stats}->{files}  = scalar @files;
	$self->{stats}->{parsed} = 0;
	$self->{stats}->{error}  = 0;
	$self->{messages}        = [];

	# Process the files
	foreach my $file ( @files ) {
		# Skip if already cached
		my $md5 = PPI::Util::md5hex_file($file);
		my (undef, $path) = $self->{ppi_cache}->_paths($md5);
		next if -f $path;

		# Parse and cache the file, ignoring errors
		my $document = eval {
			PPI::Document->new($file)
		};
		if ( $@ ) {
			push @{$self->{messages}}, "CRASHED while parsing $file";
			$self->{stats}->{error}++;
		} elsif ( ! $document ) {
			my $errstr = PPI::Document->errstr;
			push @{$self->{messages}}, "Failed to parse $file";
			$self->{stats}->{error}++;
		} else {
			push @{$self->{messages}}, "Parsed $file";
			$self->{stats}->{parsed}++;
		}
	}

	# Success means we ran without errors, EVEN if we
	# didn't actually need to parse anything.
	if ( $self->{stats}->{error} ) {
		$self->{ok} = 0;
	} else {
		$self->{ok} = 1;
	}

	return 1;
}

1;
