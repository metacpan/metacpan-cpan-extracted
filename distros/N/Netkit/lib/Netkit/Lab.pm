package Lab;

use strict;
use warnings;

use List::Util qw(any);
use File::Copy::Recursive qw(dircopy);

sub new {
	my $class = shift;
	my %params = @_;
	
	die "Must specify data_dir" if not defined($params{data_dir});

	my $self = bless {
		name => $params{name} // 'Unknown',
		description => $params{description} // 'None',
		version => $params{version} // 'None',
		author => $params{author} // 'Unknown',
		email => $params{email} // 'Unknown',
		out_dir => $params{out_dir} // 'lab',
		data_dir => $params{data_dir},
	}, $class;

	return $self;
}

sub dump {
	my $class = shift;
	
	my @machines = @_;
	
	print "Machines: ", scalar @machines, "\n\n";
	
	if (! -e $class->{out_dir}) {
		mkdir($class->{out_dir});
	}
	
	## Create lab.conf
	
	my $conf_file = "$class->{out_dir}/lab.conf";
	
	print "* Dumping $conf_file\n";
	open FH, '>', $conf_file;
	select FH;
	
	print "LAB_DESCRIPTION=$class->{description}
LAB_VERSION=$class->{version}
LAB_AUTHOR=$class->{author}
LAB_EMAIL=$class->{email}\n\n";
	
	for (@machines) {
		$_->dump_conf;
	}
	
	select STDOUT;
	close FH;
	
	print "* Dumping Startup Files\n";
	
	## Create .startup files.
	for (@machines) {
		my $name = $_->{name};
		
		my $fname = "$class->{out_dir}/$name.startup";
		
		print "\t* Dumping $fname\n";
		
		open FH, '>', $fname;
		select FH;
		
		print "****** $name ******\n\n";
		
		$_->dump_startup;
		
		select STDOUT;
		close FH;
	}
	
	print "* Copying Data Folders\n";
	
	## Copy override files
	
	my @machine_names = map {$_->{name}} @machines;
	my $data_dir = $class->{data_dir};
	
	for my $folder (<$data_dir/*>) {
		if($folder =~ s/$data_dir\///g){
			if(any {$_ eq $folder} @machine_names){
			
				print "\t* Copy $folder to $class->{out_dir}/$folder\n";
				dircopy("$data_dir/$folder", "$class->{out_dir}/$folder") or die("$!\n");
			}
		}
	}
	
	## Create lab.dep
	
	open FH, '>', "$class->{out_dir}/lab.dep";
	close FH;
}

1;
