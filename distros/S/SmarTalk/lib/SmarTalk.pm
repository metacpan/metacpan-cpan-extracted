package SmarTalk;

#import
use 5.006001;
use strict;
use warnings;
use IO::Socket;
require Exporter;
    
#export
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ('all' => [ qw(new setServer serverUp setClient clientUp)]);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});
our @EXPORT = qw();
our $VERSION = '0.10';
        
#declaration
my ($tunnel,$settingServer,$settingClient,$pcremoto,
$comunicazione,$paroleClient,$paroleServer,$class,
$this,$usr,$cl);

#constructor
sub new{
	     #new istance of class
        $class = shift;
        $usr = shift;
        $this = {username=>$usr->{username}, from=>$usr->{country}};
        bless $this,$class;
        return $this;   
}
#method
sub setServer{
	     #server object settings
        $this = shift;
        $settingServer = shift;
        $this->{porta} = $settingServer->{porta};
}
#method
sub serverUp{
        #socket connection
        $tunnel = IO::Socket::INET->new
        (
        Proto     => 'tcp',
        LocalPort => $this->{porta},
        Listen    => SOMAXCONN,
        Reuse     => 1
        );

        print "\nSmarTalk server online, port: $this->{porta},
        protocol: tcp, wait for connections...\n\t";
        die "\nProblems with port $this->{porta}...
        Port in use?\n\n" unless $tunnel;

        while ( $pcremoto = $tunnel->accept() ){
        		$pcremoto->autoflush(1);
				#fork for bidirectional communication
        		$comunicazione = fork();
				if ($comunicazione){
        				while ( defined( $paroleClient = <$pcremoto> ) ){
       	 					print STDOUT $paroleClient;
						}
        		kill( "TERM", $comunicazione );
				}
        		else{
       				while ( defined( $this->{parolemie} = <> ) ){
								$this->{message} = "*$this->{username}"."(from $this->{from}): "."$this->{parolemie}";
     							print $pcremoto "$this->{message}";
               	}
				}
		  }
}
#method
sub setClient{
        #base client object settings
        $this = shift;
        $settingClient = shift;
        $this->{macchinadiarrivo} = $settingClient->{server},
        $this->{portadiarrivo} = $settingClient->{porta};
}
#method
sub clientUp{
        #socket connection
        $this = shift;
        $tunnel = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => $this->{macchinadiarrivo},
        PeerPort => $this->{portadiarrivo}
        );

        if ($tunnel){
        		$tunnel->autoflush(1) or die "Can't connect to port $this->{portadiarrivo} on
        		$this->{macchinadiarrivo}"; 
        		print "Connected to SmarTalk server $this->{macchinadiarrivo} on port: $this->{portadiarrivo},
       		protocol: tcp...\n Talk!...\n";
        
				#fork for bidirectional communication
        		$comunicazione = fork();
        		if ($comunicazione){
        				while ( defined ( $paroleServer = <$tunnel> ) ){
        						print STDOUT $paroleServer;
						}
        				kill( "TERM", $comunicazione );
				}
        		else{
        				print $tunnel "Client $this->{username} from $this->{from} connected!\n Talk!...\n\r";    
        						while ( defined( $this->{parolemie} = <STDIN> ) ){
        								chomp $this->{parolemie};
        								$this->{message} = "*$this->{username}"."(from $this->{from}): "."$this->{parolemie}";
        								print $tunnel "$this->{message}\n\r";
        						}
				}
			}
        	else{
	      		print STDOUT "\nNo connection...
        			Server $this->{macchinadiarrivo} OFFLINE on port $this->{portadiarrivo}\n\n";
			}        
}
1;


__END__


=head1 NAME

SmarTalk - Simple Client-Server Chat

=head1 SYNOPSIS

#Server example
use strict;

use warnings;

use SmarTalk;

my (%newUser,%setting,$server);

my @country = qw - ENG IT -;

%newUser = (username => "Max", country => "$country[1]");

$server = SmarTalk->new(\%newUser);

%setting = (porta => "9995");

$server->setServer(\%setting);

$server->serverUp();

############***##############

#Client example

use strict;

use warnings;

use SmarTalk;

my (%newUser,%setting,$client);

my @country = qw - GB IT -;

%newUser = (username => "John", country => $country[1]);

$client = SmarTalk->new(\%newUser);

%setting = (server => 'localhost', porta => 9995);

$client->setClient(\%setting);

$client->clientUp();


=head1 DESCRIPTION


Simple Client-Server Chat


=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Cladi, E<lt>cladi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Cladi Di Domenico

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut