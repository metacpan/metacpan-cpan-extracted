
package SysAdmin;

use 5.008;

our $VERSION = '0.11';

#use Moose;
use IO::Socket;
use Carp;

## For SysAdmin::Date
use POSIX qw(strftime);

=head2 _default_socket_ports
    
=cut

sub _check_socket {
	my ($host, $port) = @_;
	
	my $test_port  = SysAdmin::_default_socket_ports($port,"port");
	my $test_proto = SysAdmin::_default_socket_ports($port,"proto");
	
	my $socket_object = new IO::Socket::INET (
		PeerAddr => "$host",
		PeerPort => "$test_port",
		Proto    => "$test_proto",
		);
	
	if($socket_object){
		return 1;
	}
	else{
		return 0;
	}
}

=head2 _default_socket_ports
    
=cut

sub _default_socket_ports {
	my ($port, $proto) = @_;
	
	my %known_port_hash = (
		                    80 => {
								"port"  => "80",
	                            "proto" => "tcp"
							},
		                    5432 => {
								"port"  => "5432",
	                            "proto" => "tcp"
							},
		                    3306 => {
								"port"  => "3306",
	                            "proto" => "tcp"
							},
		                    1521 => {
								"port"  => "1521",
	                            "proto" => "tcp"
							},
		                    161 => {
								"port"  => "161",
	                            "proto" => "udp"
							},
		                    25 => {
								"port"  => "23",
	                            "proto" => "tcp"
							}
						  );
	
	return $known_port_hash{$port}{$proto};
}

=head2 generate_random_string
    
=cut

sub _generate_random_string {

	## Use my $random_password = &generate_random_string("8");

	my ($length_of_randomstring) = @_;
	
	my $random_string = undef;
                         
	my @chars=('a'..'z','A'..'Z','0'..'9','_');
	foreach (1..$length_of_randomstring) {
		# rand @chars will generate a random
		# number between 0 and scalar @chars
		$random_string.=$chars[rand @chars];
	}
	return $random_string;
}

1;
__END__

=head1 NAME

SysAdmin - Parent class for SysAdmin wrapper modules.

=head1 SYNOPSIS

  ###
  ## Using the Net::SMTP/MIME::Lite wrapper module
  ###
  
  use SysAdmin::SMTP;
	
  my $smtp_object = new SysAdmin::SMTP("localhost");
	
  my $from_address = qq("Test User" <test_user\@test.com>);
  my $subject = "Test Subject";
  my $message_body = "Test Message";
  my $email_recipients = ["test_receiver\@test.com"];
	
  $smtp_object->sendEmail(from    => $from_address,
                          to      => $email_recipients,
                          subject => $subject,
                          body    => $message_body);
  
  ---
	
  ###
  ## Using the Net::SNMP wrapper module
  ###
	
  use SysAdmin::SNMP;
	
  my $ip_address = "192.168.1.1";
  my $community  = "public";
	
  my $snmp_object = new SysAdmin::SNMP(ip        => $ip_address,
                                       community => $community);
				  
  my $sysName = '.1.3.6.1.2.1.1.5.0';
	
  my $query_result = $snmp_object->snmpget("$sysName");
	
  print "$ip_address\'s System Name is $query_result\n";

  ---
	
  ###
  ## Using the DBD::Pg wrapper module
  ###
	
  use SysAdmin::DB::Pg;
	
  my $db = "dbd_test";
  my $username = "dbd_test";
  my $password = "dbd_test";
  my $host = "localhost";
  my $port = '5432';
	
  ### Database Table
  ##
  # create table status(
  # id serial primary key,
  # description varchar(25) not null);
  ##
  ###
	
  my $dbd_object = new SysAdmin::DB::Pg(db          => $db,
                                        db_username => $username,
                                        db_password => $password,
                                        db_host     => $host,
                                        db_port     => $port);
	
  ## Select Table Data
	
  ## SQL select statement
  my $select_table = qq(select id,description from status);
	
  ## Fetch table data with "fetchTable"
  my $table_results = $dbd_object->fetchTable("$select_table");
	
  ## Extract table data from $table_results array reference
  foreach my $row (@$table_results) {
	
  	my ($db_id,$db_description) = @$row;
	
	## Print Results
	print "DB_ID $db_id, DB_DESCRIPTION $db_description\n";
	
  }

  ### Insert Data
	
  ## SQL Insert statement
  my $insert_table = qq(insert into status (description) values (?));
	
  ## Insert Arguments, to subsitute "?"
  my @insert_table_values = ("Data");
	
  ## Insert data with "insertData"
  $dbd_object->insertData("$insert_table",\@insert_table_values);
  
  ## The insertData Method could also be expressed the following ways
  
  my $insert_table_values = ["Data"];
  $dbd_object->insertData("$insert_table",$insert_table_values);
  
  # or
  
  $dbd_object->insertData("$insert_table",["Data"]);
	
  ### Select Table Row
	
  ## SQL Stament to fetch last insert
  my $fetch_last_insert = qq(select description 
                             from status 
                             where description = 'Data');
	
  ## Fetch table row with "fetchRow"
  my $row_results = $object->fetchRow("$fetch_last_insert");
	
  ## Print Results
  print "Last Insert: $row_results\n";
  
  ---
	
  ###
  ## Using the IO::File wrapper module
  ###
	
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

This is a master class for SysAdmin wrapper modules. Example SysAdmin modules 
are SysAdmin::DB, SysAdmin::Expect, SysAdmin::SMTP, etc.

=head1 SEE ALSO

SysAdmin::DB

SysAdmin::Expect

SysAdmin::File

SysAdmin::SMTP

SysAdmin::SNMP

=head1 AUTHOR

Miguel A. Rivera 

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
