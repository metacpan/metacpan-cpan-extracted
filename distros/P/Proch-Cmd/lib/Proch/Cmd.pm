use strict;
use warnings;
package Proch::Cmd;

$Proch::Cmd::VERSION = 0.0041;
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

version 0.0041

=head1 SYNOPSIS

  use Proch::Cmd;


  # The module is designed with settings affecting every execution
  my $settings = Proch::Cmd->new(
        command => '',
        verbose => 1,
        debug => 1
  );

  # Settings can be edited at any time
  $settings->set_global('working_dir', '/hpc-home/telatina/tmp/');

  # Create a new command object
  my $c1 = Proch::Cmd->new(
                  command => 'ls -lh /etc/passwd /etc/vimrc hello',
                  input_files => ['/etc/passwd' , '/etc/vimrc', 'hello'],
                  output_files => [],
                  debug => 0,
                  verbose => 0,
                  object => \$object,
  );

  my $simple = $c1->simplerun();

  say $simple->{output} if (! $simple->{exit_code});

=head1 NAME

Proch::Cmd - a simple library to execute shell commands

=head1 VERSION

version 0.004

=head1 METHODS

=head2 new()

The method creates a new shell command object, with the followin properties:

=over 4

=item I<command> [required]

The shell command to execute

=item I<workingdir> (default: /tmp) [important]

Command temporary directory, should be the pipeline output directory, can be 
omitted for minor commands like 'mkdir', but should be set for pipeline steps.

=item I<description>

Optional description of the command, for log and verbose mode

=item I<input_files> (array)

A list of files that must exist and be not empty before command execution

=item I<output_files> (array)

A list of files that must exist and be not empty after command execution

=item I<die_on_error> (default: 1)

If command returns non zero value, die (default behaviour)

=item I<verbose>

Enable verbose execution

=item I<no_cache>

Don't skip command execution if the command was already executed

=back

=head2 simplerun()

Executes the shell command returning an object

=head1 ACCESSORY SCRIPTS

The 'scripts' directory contain a I<read_cache_files.pl> that can be used to display the 
content of this module's cache files. The 'data' directory contain a valid example of data
file called 'data.ok'. To view its content:

  perl scripts/read_cache_files.pl -f data/data.ok

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
