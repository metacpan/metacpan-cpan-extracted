package Net::Rsh;

use strict;
use IO::Socket;
use Carp;
use Errno;

require Exporter;

use vars qw($VERSION @ISA @EXPORT);

$VERSION=0.05;

@ISA = qw(Exporter);
@EXPORT = qw(&rsh);

sub new {
	my $class=shift;
	my $self={ };
	return bless $self,$class;
}

sub rsh {
	my ($self,$host,$local_user,$remote_user,$cmd)=@_;
	croak("Usage: \$c->rsh(\$host,\$local_user,\$remote_user,\$cmd)") unless @_ == 5;

	my $start_port=512;                                                                                                                   
	my $end_port=1023;                                                                                                                    

	my $try=1;                                                                                                                            
	my $port=$end_port;                                                                                                                   
	my $socket; 
                                                                                                                                  
	while($try) {                                                                                                                      
		if($port<$start_port) {croak "All ports in use";}                                                            
		$socket = IO::Socket::INET->new(PeerAddr=>$host,
                                		PeerPort=>'514',
                                		LocalPort=>$port,
                                		Proto=>"tcp");

		if(!defined $socket) {
        		if ($!{EADDRINUSE} || $!{ECONNREFUSED}) {
                		$port-=1;
        		} else {
                                croak("$!");
                        }
		} else { $try=0; }
	}                                                                                                                                  

	print $socket "0\0";                                                                                                               
	print $socket "$local_user\0";                                                                                                            
	print $socket "$remote_user\0";                                                                                                           
	print $socket "$cmd\0";                                                                                                           
	my @return=<$socket>;                                                                                                                 
	return @return;                          
}

END { } 

1;

__END__

=head1 NAME

Net::Rsh - perl client for Rsh protocol

=head1 SYNOPSIS

  use Net::Rsh;

  $a=Net::Rsh->new();

  $host="cisco.router.com";
  $local_user="root";
  $remote_user="root";
  $cmd="sh ru";

  @c=$a->rsh($host,$local_user,$remote_user,$cmd);

  print @c;
  

=head1 DESCRIPTION

  Rsh protocol requires that the program be
  run as root or that the program be setuid to root    

=head1 AUTHOR

Oleg Prokopyev, <riiki@gu.net>

=cut
