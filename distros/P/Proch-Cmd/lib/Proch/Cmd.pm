use strict;
use warnings;
package Proch::Cmd;

$Proch::Cmd::VERSION = 0.001;
# ABSTRACT: Execute shell commands controlling inputs and outputs


use 5.014;
use Moose; 
use Data::Dumper;
use Digest::MD5;
use Storable qw(lock_store lock_nstore lock_retrieve);
use Carp qw(confess);
use File::Slurp;
use Time::HiRes qw(gettimeofday tv_interval);
use Time::Piece;

our %GLOBAL = (
	'working_dir' => '/tmp',
	'description' => '<Bash command>',
);

has debug        => ( is => 'rw', isa => 'Bool');
has verbose      => ( is => 'rw', isa => 'Bool');
has die_on_error => ( is => 'rw', isa => 'Bool', default => 1);
has no_cache     => ( is => 'rw', isa => 'Bool');
has save_stderr  => ( is => 'rw' );

has command => (
    is => 'rw',  
    required => 1, 
    isa => 'Str',
);

has description => (
	is => 'ro',
	required => 1,
	isa => 'Str',
	default => $GLOBAL{description},
);
has logfile => (
	is => 'ro',
	isa => 'Str',
);

has input_files => (
	is => 'ro',
	isa => 'ArrayRef',
);

has output_files => (
	is => 'ro',
	isa => 'ArrayRef',
);

has cache_file => (
	is => 'ro',
	isa => 'Str', 
);



has working_dir => (
	is => 'rw',
	isa => 'Str',
	default => '/tmp/',
	#builder => '_readdefault_working_dir',
);
 
sub _readdefault_working_dir {
	my ($self) = @_;
	say Dumper $self;
	return $GLOBAL{"working_dir"};
}

sub _check_input_files_exist {
	# All {input_files} need to be found
	my ($self) = @_;
	my @msg = ();
	my $errors = 0;
	my $output;
	
	# Check input input_files
	foreach my $file (@{ $self->{input_files} }) {
		if (! -s "$file") {
			$errors++;
			push(@msg, qq("$file") );
		} 
	}

	$output->{errors} = $errors;
	$output->{raw_messages} = \@msg;
	$output->{message} = "Required INPUT file not found: [" . join(', ', @msg) ."] when executing <" .$self->{command} .'>';

	if ($self->{die_on_error} and $output->{errors}){
		confess($output->{message});
	} else {
		return $output;
	}
}
sub _check_output_files_exist {
	# All {input_files} need to be found
	my ($self) = @_;
	my @msg = ();
	my $errors = 0;
	my $output;
	
	# Check input input_files
	foreach my $file (@{ $self->{output_files} }) {
		if (! -s "$file") {
			$errors++;
			push(@msg, qq("$file") );
		} 
	}

	$output->{errors} = $errors;
	$output->{raw_messages} = \@msg;
	$output->{message} = "Required OUTPUT file not found: [" . join(', ', @msg) ."] when executing <" .$self->{command} .'>';

	if ($self->{die_on_error} and $output->{errors}){
		confess($output->{message});
	} else {
		return $output;
	}
}
sub simplerun {
	my ($self) = @_;
	my $start_date = localtime->strftime('%m/%d/%Y %H:%M');
	my $start_time = [gettimeofday];
	my $output;
	$output->{success} = 1;
	$output->{input}->{command} = $self->{command};
	$output->{input}->{description} = $self->{description};
	$output->{input}->{files} = $self->{input_files};

	# Get cache
	my ($cache, $cache_file) = _get_cache($self);
	if (! $self->{no_cache} and defined $cache) {
		return $cache;
		confess();
	}
	my $stderr_file = "$cache_file.stderr";
	if (defined $self->{save_stderr} and $self->{save_stderr} ne "1") {
		$stderr_file = $self->{save_stderr};
	}

	# Check input files
	my $check_input = $self->_check_input_files_exist;
	
	# COMMAND EXECUTION
	my $cmd = $self->command;
	$cmd .= qq( 2> "$stderr_file") if (defined $self->{save_stderr});

	my $command_output = `$cmd`;
	$output->{output} = $command_output;
	$output->{exit_code} = $?;

	# Check exit status
	if ( $self->{die_on_error} and $output->{exit_code} ) {
		confess("ERROR EXECUTING COMMAND ". $self->{description} . " \nCommand returned <" . $output->{exit_code} . ">:\n<" . $output->{input}->{command} .">");
	}
	$output->{stderr} =  read_file("$stderr_file") if (defined $self->{save_stderr} and $self->{save_stderr} ne '1');

	# Check input output files
	my $check_output = $self->_check_output_files_exist;

	# Save cache
	_save_cache($self, $output) if (!$self->{no_cache});
	
	if ($self->{die_on_error} and ! $output->{success}) {
		confess($output->{message})
	} else {

		return $output;
	}

} 
sub _error_header {
	my ($command_string) = @_;
	 
	return "<Error when executing command '$command_string'>\n";
}

sub _md5 {
 my ($file) = @_;
 my $checksum = Digest::MD5->new;
 open my $fh, '<', "$file" || confess("Unable to read file <$file> to calculate it's MD5 checksum.");
 binmode($fh);

 while (<$fh>) {
 	$checksum->add($_);
 }
 close($fh);
 return $checksum->hexdigest;
 
}




sub _get_cache {
	my ($self) = @_;
 
	my $md5 = Digest::MD5->new;
	my $WD = defined $self->{working_dir} ? $self->{working_dir} : $GLOBAL{'working_dir'};

    $md5->add($self->{command}, $self->{description}, $WD);
    my $md5sum = $md5->hexdigest;
    my $cache_file = $WD . '/.' . $md5sum;
    my $output;
    $self->{cache_file} = $cache_file;
    if (-e "$cache_file") {
    	eval { $output = lock_retrieve($cache_file); };
    	if ($@) {
    		_verbose($self, "Cache file found <$cache_file> but corrupted: skipping");
    		return (undef, $cache_file);
    	} else {
    		return ($output, $cache_file);
    	}
    } else {
    	return (undef, $cache_file);
    }
}

sub _save_cache {
	my ($self, $data) = @_;
	confess("Hey, where is your filename?") unless (defined $self->{cache_file});
	lock_store($data, $self->{cache_file});
}


sub _debug {

	my ($self, $message) = @_;
	return 0 if ($self->{debug} < 1);
	say STDERR "[Debug] ", $message;
}

sub _verbose {
	my ($self, $message) = @_;
	if ($self->{verbose} > 0 or $self->{debug} > 0) {
		say STDERR "[Info] ", $message;
	}
}
sub get_global {
	my ($self, $key) = @_;
	if (defined $GLOBAL{$key}) {
		return $GLOBAL{$key};
	} else {
		_verbose("Value not found for setting key <$key>");
		return '<undef>';
	}
}
sub set_global {
	my ($self, $key, $value) = @_;
	if (defined $GLOBAL{$key}) {
		$GLOBAL{$key} = $value;
		$self->{$key} = $value;
		_debug($self, "Setting $key -> $value");
	} else {
		confess("Error setting <$key>: this is not a valid property");
	}
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proch::Cmd - Execute shell commands controlling inputs and outputs

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  ...

=head1 NAME

Proch::Cmd - a simple library to execute shell commands

=head1 VERSION

version 0.001

=head1 METHODS

=head2 method_x

This method does something experimental.

=head2 method_y

This method returns a reason.

=head1 AUTHOR

  Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is free software under MIT Licence.

=head1 AUTHOR

Andrea Telatin <andrea.telatin@quadram.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
