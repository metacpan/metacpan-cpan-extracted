#!/usr/bin/perl
use warnings;
use strict;


use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Net::Growl;

my $DEBUGGING;
my $help;
my $password = '';


GetOptions("v" => \$DEBUGGING, "p=s"  => \$password,"h" => \$help,   );
pod2usage(-verbose => 2,)  if ($help);
pod2usage(-verbose => 1, 
          -msg => 'A password MUST be supplied',)  if (! $password);




##  Set up the Socket
my %addr = (PeerAddr =>  "localhost",
            PeerPort =>  Net::Growl::GROWL_UDP_PORT,
            Proto => 'udp');
my $s = IO::Socket::INET->new ( %addr ) || die "Could not create socket: $!\n" ;


# Register the app
my $p = Net::Growl::RegistrationPacket->new( application=>"Perl Notifier", password => $password,);
$p->addNotification();
print ($s $p->payload());




# send a notification
$p = Net::Growl::NotificationPacket->new( application=>"Perl Notifier",
                                          title=>'Warning',
                                          description=>'from the OO API ',
                                          priority=>2,
                                          sticky=>'True',
                                          password => $password,
                                        );

print $s $p->payload();
close($s);

## or the easy way -- more sockets are created though
# when outside the module  you can just do 
register(   password => $password);   # register
notify(   password => $password);   # notify, using default values for everything, but the pw


exit;



__END__

=head1 NAME

example.pl   -   Illustrates both the internal and external  Net::Growl API's

=head1 SYNOPSIS

 example.pl <-h>  -p=password 

 Options:
  -h flag displays this help message.
  -p flag allows for you to enter a password on the command line (otherwise edit the script)


=head1 DESCRIPTION

This command is an example -- should send 2 notifications,  plus the fiorst time it may depending on you growl settings display a registration notification




=cut	
