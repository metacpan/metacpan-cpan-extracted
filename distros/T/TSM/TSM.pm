package TSM;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
@EXPORT_OK = qw(

);
$VERSION = '0.60';


# Preloaded methods go here.
#
# Constructor of the TSM instance. This object will be used to authenticate
# at the TSM server
#
sub new {
	my $self = shift;
	my $class = ref $self || $self;
	my $instance = {};
	my $rcfile = undef;
	#
	# Set $rcfile to either .tsmrc or ~/.tsmrc depending on which comes first.
	#
	$rcfile = "$ENV{HOME}/.tsmrc" if (exists $ENV{HOME} && -e "$ENV{HOME}/.tsmrc");
	$rcfile = ".tsmrc" if ( -e ".tsmrc");
	#
	# Populate the parameter hash with default values and overwrite them
	# with the parameter of the caller, if any.
	#
	my %parameter = (id => undef, pa => undef, file => $rcfile, @_);
	#
	# Read the ID and password from the parameters, if provided.
	#
	$instance->{id} = $parameter{id} if ($parameter{id});
	$instance->{pa} = $parameter{pa} if ($parameter{pa});
	#
	# Read the ID and password from $rcfile, if ID has not been 
	# provided yet.
	#
	if (! defined($instance->{id}) and $parameter{file}) {
		open (TSMRC, "$parameter{file}") or croak "Error opening $parameter{file} to read ID and password: $!";
		while (<TSMRC>) {
			chomp($instance->{id} = $1) if (m/^ID\s+(.*)$/);
			chomp($instance->{pa} = $1) if (m/^PA\s+(.*)$/);
		};
		close (TSMRC) or croak "Error closing $parameter{file}: $!";
	};
	#
	# Read ID and/or password from STDIN if not provided yet.
	#
	unless ($instance->{id} and $instance->{pa}) {
		if ( -t STDIN ) {
			my $stty = `stty`;
			unless($instance->{id}){
				print "Enter your user id: ";
				chomp($instance->{id}=<STDIN>);
			};
			unless($instance->{pa}){
				# Turn off echoing
				`stty -echo`;
				print "Enter the password for $instance->{id}: ";
				chomp($instance->{pa}=<STDIN>);
				# Turn on echoing
				`stty echo`;
				print "\n";
			};
		};
	};
	#
	# Test if the ID and password could has been read from somewhere.
	# 
	unless ($instance->{id} and $instance->{pa}){
		croak 	"You have not provided a user ID and/or a password. Exiting";
	};
	#
	# Bless the $instance into the $class package and return it to the caller.
	#
	bless($instance, $class);
	return $instance;
}

sub dsmadmc (@) {
	my $instance = shift;
	my $options = shift;
	my $command = join " ",@_;
	my $start = 0;
	my @output =();
	#
	# Open a session to the TSM server
	#	
	open(DSMADMC, "dsmadmc -ID=$instance->{id} -PA=$instance->{pa} $options \"$command\" </dev/null |" ) 
		or croak "Cannot open TSM session: $!\n";
	#
	# Remove status messages and concatenate the output to a string
	#	
	while(<DSMADMC>)
	{
		last if (m/^(ANS800[12]I).*(\d+)\.$/);
    	if (m/^(ANS8000I)/)
    	{
    		$start = 1; 
    		next;
    	};
    	if ($start and !/^\s*$/)
    	{
    		chomp;
    		push(@output,$_);
    	}; 
	};
	close(DSMADMC) or carp "Cannot close TSM session: $!";
	return @output;
};

sub select_single ($) {
	my $instance = shift;
	my $command = shift;
	#
	# Extraxt the column labels from the command
	#
	my @columns = $instance->get_columnlabels($command);
	#
	# Extract the values from the select command
	#
 	my @record = split(/\t/,($instance->dsmadmc("-TAB", "select $command"))[0]);
	#
	# Populate the hash with label/value as pairs
	# 
    my $output =();
    for my $i (0 .. $#columns) 
    {
    	$output->{"$columns[$i]"} = "$record[$i]";
	};
	#
	# Return a pointer to this hash
	#
	return $output;
};

sub select($){
	my $instance = shift;
	my $command = shift;
	#
	# Extraxt the column labels from the command
	#
	my @columns = $instance->get_columnlabels($command);
	#
	# Get the result from the TSM server
	#
	my @select = $instance->dsmadmc("-TAB", "select $command");
	#
	# Populate the array of hashes 
	#
	my $output = ();
	for my $i (0..$#select)
	{
		my @record = split(/\t/,@select[$i]);
		for my $j (0 .. $#columns) 
    	{
    		$output->[$i]{$columns[$j]} = "$record[$j]";
		};
	};
	#
	# Return a pointer to this array
	#
	return $output;
};

sub select_hash (@)
{
	my $instance = shift;
	my $hashref = shift;
	my $command = shift;
	#
	# Extraxt the column labels from the command
	#
	my @columns = $instance->get_columnlabels($command);
	#
	# Get the result from the TSM server
	#
	my @select = $instance->dsmadmc("-TAB", "select $command");
	#
	# Populate the hash of hashes 
	#
	for my $i (0..$#select)
	{
		my @record = split(/\t/,@select[$i]);
		for my $j (1 .. $#columns) 
    	{
    		$hashref->{$record[0]}{$columns[$j]} = "$record[$j]";
		};
	};
	#
	# Return the number of addedd/changed entries
	#
	return scalar @select;
};


sub get_columns($)
{
	my $instance = shift;
	my $table_name = uc(shift);
	#
	# Get the result from the TSM server
	#	
	my @select = $instance->dsmadmc("-TAB", "select colname, colno from columns where tabname='$table_name' order by colno");
	#
	# Populate the columns array 
	#	
	my @columns =();
	foreach my $element (@select)
	{
		push (@columns, $1) if $element =~ (/^(\w+)\t\d{1,2}$/);
	};
	#
	# Return the columns array
	#
	return @columns;
};

sub get_columnlabels($)
{
	my $instance = shift;
	my $command = shift;
	#
	# Extract the table and column info
	#
	$command =~ /(.*)\s+from\s+(\w+)\s*.*/i;
	my $table_name = $2;
	my @columns = split (/\s*,\s*/,$1);
	#
	# Populate the columns array 
	#		
	for my $i (0 .. $#columns) {
		if($columns[$i] =~ /.*\s+as\s+\"*(\w+)\"*/) { $columns[$i] = $1; };
		if($columns[$i] eq '*'){
			@columns = $instance->get_columns($table_name);
		};
   	};
	#
	# Return the columns array
	#   	
   	return @columns;
};
# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

TSM - Perl extension for the Tivoli Storage Manager

=head1 SYNOPSIS

  use TSM;
  my $tsm->new();
  my $tsm->new(id => "user id");
  my $tsm->new(id => "user id", pa => "password");
  my $tsm->new(file => "rcfile");
  
  my $outputstring = $tsm->dsmadmc("options", "tsm_command");
  my @columns = $tsm->get_columns(TABLE_NAME);
  my $arrayref = select("select_string");
  my $entries_added = select_hash($hashref, "select_string");
  my $hashref = select_single("select_string"); 
  
  
=head1 DESCRIPTION

This module will give you a convenient access to the administrative 
console of the TSM server. It has been developed under AIX 4.3.3, 
TSM 4.1.2 and PERL 5.6.0. As of now, I can not guarantee that it will
work on Win32 systems.

=head2 INSTALLATION

The installation works as usual:

	perl Makefile.PL
	make
	make test
	make install

=head2 USAGE

Before using the module, you have to specify its usage with

	use TSM;

The first step of connecting to the TSM server is to create 
a new TSM instance by one of the following ways:

=over 3

=item 1.  my $tsm->new();

This is the default way, which will manage the ID and password 
handling for you. It will look for a file .tsmrc either in the 
current directory or in the HOME directory of the user who 
executs the command (in this order). See below for details about 
.tsmrc. If the files are missing, cannot be read. miss information,
the user will be prompted for the ID (if missing) and the password.

If you don't like this mechanism, you can influence the behaviour 
as follows:

=item 2. my $tsm->new(id => "user_id");

Specify the TSM user, whoc should be used for the command. The 
password can still be provided in the .tsmrc.

=item 3. my $tsm->new(id => "user_id", pa => "password");

Specify user and password (not recommended, since the password is
in clear text).

=item 4. my $tsm->new(file => "rcfile");

Specify another file with a user id and the password.

=back

After initiating an instance with the TSM server, you can use it
to access the tsm server. The most common command is the regular 
administrative console:

	my @output=$tsm->dsmadmc("options", "tsm command");

Please be aware, that output is different of what you usually see 
at the console itself. I am currently using the UNIX pipe mechanism 
which will create an unformatted output stream. If anybody knows a better 
(without going through an outputfile), please let me know. The output 
itself will be an array of output lines.

I have implemented 3 select commands to query the database directly:

=over 3

=item 1. my $arrayref = $tsm->select("select_string");

This select command returns a reference to an array of hashes with the 
output. Each element of the array contains a reference to a hash with 
the column names as the keys and the corresponding values. In the following
example, we print the volume name and the storage pool of all volumes: 

	my $arrayref = $tsm->select("* from volumes");
	foreach my $element (@$arrayref)
	{
		print "$element->{VOLUME_NAME}:\t $element->{STGPOOL_NAME}\n";
	};


If you use the generic "*" for the columns, you can use the following 
function to get an array of the column names: 

	my @columns = $tsm->get_columns(TABLE_NAME);

=item 2. my $hashref = select_single("select_string");

This is a simpler form of the first one, which is more convenient if you 
know, that the query returns only one record, e.g. 

	my $statusref = $tsm->select_single("* from status"};
	print "$statusref->{RESTART_DATE}\n";
	
instead of 

	my $statusref = $tsm->select("* from status"};
	print "$statusref->[0]{RESTART_DATE}\n";
	 

=item 3. my $entries_added = select_hash($hashref, "select_string"); 

This select command can be used, if the values of the first column
are unique. They will be used as the keys of the hash, that must be provided
to the command. This hash will then contain the values of the first column 
as its keys, and a reference to a hash as the value, which contains the 
columns/value of the columns 2-n. This output is usefull, if you want to 
combine different queries to one output, e.g. libvolumes and volumes with 
the volume name as the key. Let's see how it works: In the following example,
we are using an existing hash with a fake entity, and merging it with the
result of the select_hash command.

	my %volumes = ('xxxxxx' => {FAKE_ENTRY => "TEST"});
	my $retval = $tsm->select_hash(\%volumes, "* from volumes where volume_name='xxxxxx'");
	
	print "I'm still there: 'xxxxxx' -> $volumes{'xxxxxx'}{FAKE_ENTRY}\n"; 
	print "$retval elements changed or new\n";
	foreach my $element (sort keys %volumes)
	{
		print "$element: $volumes{$element}{STGPOOL_NAME}\n";
	};

=back

=head2 The file .tsmrc: 

Since this file contains the password, it should not be readable 
for anybody but the owner. If you need more then one instance with different
user ids, you can specify the file name with the "file => file_name" parameter.

The syntax of the .tsmrc is as follows:

	ID	user_id
	PA	password

=head1 COPYRIGHT

Copyright (c) 2001 Joerg Nouvertne. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



=head1 AUTHOR

For any issues, problems, or suggestions for further improvements, 
please do not hesitate to contact me.

	Joerg Nouvertne	joerg.nouvertne@wtal.de

=head1 SEE ALSO

perl(1).

=cut
