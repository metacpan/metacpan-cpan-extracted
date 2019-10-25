package PostgreSQLHosting;
use strict;
use 5.008_005;
 
1;
__END__


=head1  NAME

	# PostgreSQLHosting

	High Availability, Load Balancing, and Replication for PostgreSQL using Hot Standby at  cloud providers like Linode, Hetzner, Digital Ocean

=head1  SYNOPSIS

	## Install 

	$ sudo apt-get install carton git
	$ git clone git@github.com:ovntatar/PostgreSQLHosting.git
	$ cd PostgreSQLHosting
	$ carton install 


	## Configuration

	Edit `config.yml` according to your needs. 

	> Please, use only alphanumeric characters and underscore to name the hosts

	## Usage

	### Deploy


	PRIVATE_KEY=/path/to/private/key carton exec -- rex deploy


	### List machines

	PRIVATE_KEY=/path/to/private/key carton exec -- rex inventory



	### Remove machines [!!!!]

	PLEASE, BE CAREFUL. THIS COMMAND REMOVES ALL MACHINES

	PRIVATE_KEY=/path/to/private/key carton exec -- rex wipe

=head1 DESCRIPTION
 
	
	High Availability, Load Balancing, and Replication for PostgreSQL using Hot Standby
 
=head1 PERL VERSIONS

	You can also specify the minimum perl required in C<cpanfile>:
 
  	requires 'perl', '5.16.3';

=head1 AUTHOR
 
  	Ovidiu Tatar, Gabriel Andrade
 
=head1 COPYRIGHT
 
 	3Ziele.de - ovntatar
 
=head1 LICENSE
 
  	This software is licensed under the same terms as Perl itself.
 
=head1  SEE ALSO
 
 
L<PostgreSQLHosting|https://github.com/ovntatar/PostgreSQLHosting>
 
 
=cut 
