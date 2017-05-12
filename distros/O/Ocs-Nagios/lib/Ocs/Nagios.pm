package Ocs::Nagios;

use strict;
use warnings;
use SOAP::Lite;
use XML::Entities;
use XML::Simple;

sub new(){
  my $class=shift;
  my %args=ref($_[0])?%{$_[0]}:@_;
  my $self=\%args;
  bless $self, $class;
  return $self;
};


sub init(){
  my $self = shift;
  my $server=$self->{'server'};
  my $soap_user=$self->{'soap_user'};
  my $soap_pass=$self->{'soap_pass'};
  my $soap_port=$self->{'soap_port'};
  my %devices_list=$self->_get_devices($server,$soap_user,$soap_pass,$soap_port);
  return %devices_list;
}

sub _get_devices(){
  my $self = shift;
  my($s,$u,$pw,$port) = @_;
  my $method="get_computers_V1";
  my $proto;
  my $result;
  my @result;
  my @split;
  my %devices;
  my $devices;
  my $hostname;
  my $hostip;
  if ( $port == 80 ) {
    $proto="http";
  }
  elsif ( $port == 443 ) {
    $proto="https";
  }

  my @params="<REQUEST>
             <ENGINE>FIRST</ENGINE>
             <ASKING_FOR>INVENTORY</ASKING_FOR>
             <CHECKSUM>1</CHECKSUM>
             <OFFSET>0</OFFSET>
             <WANTED>0</WANTED>
             </REQUEST>";

  my $lite = SOAP::Lite
    ->uri("$proto://$s/Apache/Ocsinventory/Interface")
    ->proxy("$proto://$u".($u?':':'').($u?"$pw\@":'')."$s/ocsinterface\n")
    ->$method(@params);

  if($lite->fault){
    print "ERROR:\n\n",XML::Entities::decode( 'all', $lite->fault->{faultstring} ),"\nEND\n\n";
  }  else{
       my $i = 0;
       for( $lite->paramsall ){
         if (/^<COMPUTER>/) {
           $result=$self->_ocs2nagios(XML::Entities::decode( 'all', $_ ));
           @split= split(";",$result);
           $hostname=$split[0];
           $hostip=$split[1];
           $devices{$hostname} = $hostip;
           $i++;
         }
       }
     }
  return %devices;
}

sub _ocs2nagios() {
  my $self = shift;
  my $xml = new XML::Simple;
  my @datas= @_;
  my $data = $xml->XMLin(@datas);
  return ($data->{HARDWARE}->{NAME}.";".$data->{HARDWARE}->{IPADDR});
}

sub host(){
my $self = shift;
my %opts=ref($_[0])?%{$_[0]}:@_;
my $self_host=\%opts;
$self->{'_HOSTNAME'} = $self_host->{'host'};
$self->{'_IP'} = $self_host->{'ip'};
open(FILE,">> $self->{'directory'}/$self_host->{'host'}\.cfg");
print FILE "define host{ \n";
print FILE "\t use        $self_host->{'template'} \n";
print FILE "\t host_name  $self->{'_HOSTNAME'} \n";
print FILE "\t address    $self->{'_IP'} \n";
print FILE "} \n\n";
close(FILE);
return $self_host;
}

sub service(){
my $self = shift;
my %s_opts=ref($_[0])?%{$_[0]}:@_;
my $self_service=\%s_opts;
open(FILE,">> $self->{'directory'}/$self->{'_HOSTNAME'}\.cfg");
print FILE "\n";
print FILE "define service{ \n";
print FILE "\t use                  $self_service->{'template'} \n";
print FILE "\t host_name            $self->{'_HOSTNAME'} \n";
print FILE "\t service_description  $self_service->{'service_description'} \n";
print FILE "\t check_command        $self_service->{'check_command'} \n";
print FILE "} \n";
close(FILE);
}


=head1 NAME

Ocs::Nagios - Import OCS Inventory devices in Nagios 

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Ocs::Nagios;

    my $obj = new Ocs::Nagios( server => $server,
                           soap_user => $soap_user,
                           soap_pass => $soap_pass,
                           soap_port => $soap_port,
                           directory => $directory
    );
    ...


=head1 METHODS

=head2 new() - Create a new OCS::Nagios object 

=head2 init() - Initialize OCS::Nagios object and get devices results 

=head2 host() - Create a Host cfg File 

=head2 service() - Create a Nagios Service in cfg file 

=head1 EXAMPLES

=head2 1. Connect to SOAP OcsInventory Server and generate files for Nagios

This example create a .cfg file for the host, add a host definition and a service ping 

     use strict;
     use warnings;
     use Ocs::Nagios;

     my $server="192.168.0.100";
     my $soap_user="soap";
     my $soap_pass="pass";
     my $soap_port=80;
     my $directory="/etc/nagios2/conf.d/";

     my $obj = new Ocs::Nagios( server => $server,
                           soap_user => $soap_user,
                           soap_pass => $soap_pass,
                           soap_port => $soap_port,
                           directory => $directory
     );

     my %hash=$obj->init();

     while ((my $host,my $ip) = each(%hash)) {
     print "KEY : $host, Value : $ip\n";
     # Create a host Object
     $obj->host( host => $host,
              ip => $ip,
              template => "generic-host"
     );
     # Create a SERVICE for this host
     $obj->service( template => "generic-service",
                 service_description => "PING",
                 check_command => "check_ping!100.0,20%!500.0,60%"
     );
     }


=head1 AUTHOR

Julien SAFAR, C<< <jsasys at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ocs-nagios at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ocs-Nagios>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ocs::Nagios


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ocs-Nagios>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ocs-Nagios>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ocs-Nagios>

=item * Search CPAN

L<http://search.cpan.org/dist/Ocs-Nagios/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Julien SAFAR, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Ocs::Nagios
