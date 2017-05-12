
package SysAdmin::File;
use Moose;

extends 'SysAdmin';
use IO::File;

our $VERSION = 0.03;

has 'name' => (isa => 'Str', is => 'rw', required => 1);

__PACKAGE__->meta->make_immutable;

sub readFile {
	
	my ($self) = @_;

	my $filename = $self->name();
	
	if (-r $filename){
	
		my @array_to_return = ();
		
		my $fh = IO::File->new("< $filename")
			or Carp::croak "Couldn't open $filename for reading: $!\n";
			
		@array_to_return = <$fh>;
		
		$fh->close;
		
		return \@array_to_return;
	}
	else{
		Carp::croak "## WARNING $filename is not readable\n";
	}
}

sub writeFile {
	
	my ($self, $array_ref) = @_;
	
	my $filename = $self->name();
	
	my @array_to_return = ();
	
	my $fh = IO::File->new("> $filename")
		or Carp::croak "Couldn't open $filename for writing: $!\n";
	
	foreach my $row (@$array_ref){
		print $fh "$row";
	}
	
	$fh->close;
}

sub appendFile {
	
	my ($self, $array_ref) = @_;
	
	my $filename = $self->name();
	
	if (-w $filename){
		my @array_to_return = ();
		
		my $fh = IO::File->new(">> $filename")
			or Carp::croak "Couldn't append data to \"$filename\": $!\n";
		
		foreach my $row (@$array_ref){
			print $fh "$row";
		}
		
		$fh->close;
	}
	else{
		Carp::croak "## WARNING $filename is not writable\n";
	}
	
	
}

sub fileExist {
	my ($self) = @_;
	
	my $filename = $self->name();
	
	my $what_to_return = undef;
	
	if (-e $filename){
		$what_to_return = 1;
	}
	
	return $what_to_return;
}

sub directoryExist {
	my ($self) = @_;
	
	my $filename = $self->name();
	
	my $what_to_return = undef;
	
	if (-d $filename){
		$what_to_return = 1;
	}
	
	return $what_to_return;
}

sub clear {
	my $self = shift;
	$self->name(0);
}

1;
__END__

=head1 NAME

SysAdmin::File - Perl IO::File wrapper module..

=head1 SYNOPSIS
  
	use SysAdmin::File;
	
	## Declare file object
	my $file_object = new SysAdmin::File(name => "/tmp/test.txt");
	
	## Read file and dump contents to array reference
	my $array_ref = $file_object->readFile();
	
	foreach my $row (@$array_ref){
		print "Row $row\n";
	}
	
	## Write to file
	my @file_contents = ("First Line", "Second Line");
	$file_object->writeFile(\@file_contents);
	
	## Append file
	my @file_contents_append = ("Third Line", "Fourth Line");
	$file_object->appendFile(\@file_contents_append);
	
	## Check File Exist
	my $file_exist = $file_object->fileExist();
	
	if($file_exist){
		print "File exists\n";
	}
	
	## Declare directory object
	my $directory_object = new SysAdmin::File(name => "/tmp");
	
	## Check Directory Exist
	my $directory_exist = $directory_object->directoryExist();
	
	if($directory_exist){
		print "Directory exists\n";
	}
				    

=head1 DESCRIPTION

This is a sub class of SysAdmin. It was created to harness Perl Objects and keep
code abstraction to a minimum.

SysAdmin::File uses IO::File to interact with files.

=head1 METHODS

=head2 C<new()>

	## Declare file object
	my $file_object = new SysAdmin::File(name => "/tmp/test.txt");
	
=head2 C<readFile()>

	## Read file and dump contents to array reference
	my $array_ref = $file_object->readFile();
	
	foreach my $row (@$array_ref){
		print "Row $row\n";
	}

=head2 C<writeFile()>

	## Write to file
	my @file_contents = ("First Line", "Second Line");
	$file_object->writeFile(\@file_contents);
	
=head2 C<appendFile()>

	## Append file
	my @file_contents_append = ("Third Line", "Fourth Line");
	$file_object->appendFile(\@file_contents_append);
	
=head2 C<fileExist()>

	## Check File Exist
	my $file_exist = $file_object->fileExist();
	
=head2 C<directoryExist()>
	
	## Declare directory object
	my $directory_object = new SysAdmin::File(name => "/tmp");
	
	## Check Directory Exist
	my $directory_exist = $directory_object->directoryExist();
	
	if($directory_exist){
		print "Directory exists\n";
	}
	
=head1 SEE ALSO

IO::File - supply object methods for filehandles

=head1 AUTHOR

Miguel A. Rivera

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
