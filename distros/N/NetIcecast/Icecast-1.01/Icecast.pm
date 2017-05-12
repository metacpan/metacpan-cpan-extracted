# Net::Icecast
#
# Copyright (c) 2000-08 Marino Andrès <andres@erasme.org>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

#This package represents the generic icecast object
#which is used to make sources and listeners objects
package Net::Icecast::IceObject;

sub Net::Icecast::IceObject::new
  {
    my $classname = shift;
    my $ice = {};
    bless($ice,$classname);
    my($id,$host,$mountpoint,$connect_for);
    ($id,$host,$mountpoint,$connect_for)=@_;
    $ice->{id}= $id;
    $ice->{host}=$host;
    $ice->{mountpoint}=$mountpoint;
    $ice->{connect_for}= $connect_for;
    return $ice;
  }

#You can add, if you need, other properties to this both objects
package Net::Icecast::Sources;

sub Net::Icecast::Sources::new
  {
    my $classname = shift;
    my ($id,$host,$mountpoint,$connect_for,$ip,$song);
    ($id,$ip,$host,$song,$mountpoint,$connect_for)=@_;

    my $source = Net::Icecast::IceObject->new($id,$host,$mountpoint,$connect_for);

    $source->{ip}=$ip;
    $source->{song}=$song;
    bless($source,$classname);
    return $source;
  }

package Net::Icecast::Listeners;

sub Net::Icecast::Listeners::new
  {
    my $classname = shift;
    my ($id,$host,$mountpoint,$connect_for,$source_id);
    ($host,$mountpoint,$id,$connect_for,$source_id)=@_;

    my $listen = Net::Icecast::IceObject->new($id,$host,$mountpoint,$connect_for);
    $listen->{source_id}=$source_id;
    bless($listen,$classname);
    return $listen;
  }

package Net::Icecast;

use strict;
use vars qw(@ISA @EXPORT @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = "1.02";
@ISA = qw(Exporter);

@EXPORT = qw(Net::Icecast::new DESTROY set_oper sources listeners selection
	     set modify allow deny kick);

#To open a session, you must give the host and the port of the icecast
#server and the password to be ADMIN, after that the
#function gives you a connection to the server ($session->{socket})
#The default protocol is tcp
#The answer of the socket must be read in order to flush the socket buffer.
#Return 0 if you gave a wrong password
sub Net::Icecast::new
  {
    my $classname = shift;
    my $session = {};
    bless($session,$classname);
    my ($host,$port,$pwd);
    
    unless (@_ == 3) { die "defect of parameters\n"; }
    ($host,$port,$pwd)=@_;

    use IO::Socket;

    $session->{socket} = IO::Socket::INET->new(Proto   =>"tcp",
					       PeerAddr=>$host,
					       PeerPort=>$port,
					       Type    =>SOCK_STREAM)
      or die"Connection impossible\n";
    ($session->{socket})->autoflush(1);
    my $s = $session->{socket};
    print $s "ADMIN $pwd\n\n";
    my $ans = <$s>;
    if( $ans =~ /Wrong Password/ )
      {
	return 0;
      }
    return $session;
  }

#The procedure called when the programm is finished
sub DESTROY
  {
    my $session =shift;
    my $s = $session->{socket};
    print $s "quit\n";
    close($s);
  }

#Gives a hash of alls sources
sub sources
  {
    my $session =shift;
    my %hash;
    my $s =$session->{socket};
    print $s "sources\n";
    do
      {
	$_ = <$s>;
	chomp();
	chop();
	if($_ =~ /Id/)
	  {
	    my @tab = split();
	    
	    my $id =@tab[1];
	    chop($id);
	
	    my $i=0;#Be carefull I initialise $i ONCE to 0.
	    while(!($tab[$i] =~ /IP/))
	      {$i++;}
	    my $IP=$tab[++$i];
	    chop($IP);
	     
	    while(!($tab[$i] =~ /Host/))
	      {$i++;}
	    my $HostName=$tab[++$i];
	    chop($HostName);
	  
	    while(!($tab[$i] =~ /Song/))
	      {$i++;}
	    $i++; #To skip 'Title' after 'Song'
	    my $song="";
	    do
	      {
		$i++;
		$song .= $tab[$i]." ";
	      }
	    while(!($tab[$i] =~ /\]/));
	    chop($song); #To cut the last " "
	    chop($song); #To cut "]"
	    
	    while(!($tab[$i] =~ /Mountpoint/))
	      {$i++;}
	    my $mount="";
	    do
	      {
		$i++;
		$mount .= $tab[$i]." ";
	      }
	    while(!($tab[$i] =~ /\]/));
	    chop($mount);
	    chop($mount);
	    
	    while(!($tab[$i] =~ /Connected/))
	      {$i++;}
	    $i++; #To skip 'for' after 'Connected'
	    my $connect="";
	    do
	      {
		$i++;
		$connect .= $tab[$i]." ";
	      }
	    while(!($tab[$i] =~ /\]/));
	    chop($connect);
	    chop($connect);
	    
	    my $source = Net::Icecast::Sources->new($id,$IP,$HostName,$song,$mount,$connect);
	    $hash{$id}=$source;
	  }
      }
    while(!($_ =~ /End of source/));
    return %hash;
  }

#Gives a hash of alls listeners
sub listeners
  {
    my $session =shift;
    my %hash;
    my $s =$session->{socket};
    print $s "listeners\n";
    do
      {
	$_ = <$s>;
	chomp;
	chop;
	if($_ =~ /Id/)
	  {
	    my @tab = split();
	    
	    my $host =@tab[1];
	    chop($host);

	    my $i=0;
	    while(!($tab[$i] =~ /Mountpoint/))
	      {$i++;}
	    my $mount="";
	    do
	      {
		$i++;
		$mount .= $tab[$i]." ";
	      }
	    while(!($tab[$i] =~ /\]/));
	    chop($mount);
	    chop($mount);
	    
	    while(!($tab[$i] =~ /Id/))
	      {$i++;}
	    my $id = $tab[++$i];
	    chop($id);
	    
	    while(!($tab[$i] =~ /Connected/))
	      {$i++;}
	    my $connect="";
	    $i++;#To skip 'for' after 'Connected'
	    do
	      {
		$i++;
		$connect .= $tab[$i]." ";
	      }
	    while(!($tab[$i] =~ /\]/));
	    chop($connect);
	    chop($connect);
	    
	    while(!($tab[$i] =~ /Source/))
	      {$i++;}
	    $i ++;#To skip 'Id' after 'Source'
	    my $source_id ="";
	    do
	      {
		$i ++;
		$source_id .= $tab[$i]." ";
	      }
	    while(!($tab[$i] =~ /\]/));
	    chop($source_id);
	    chop($source_id);
	    
	    my $listener=Net::Icecast::Listeners->new($host,$mount,$id,$connect,$source_id);
	    $hash{$id}=$listener;
	  }
      }
    while(!($_ =~ /End of listener/));
    return %hash;    
  }

#Generic function called by the other commands
sub generic
  {   
    unless (@_ == 3) { die "defect of parameters\n"; }
    
    my $session = shift(@_);
    my $s= $session->{socket};
    my $command =shift(@_);
    my $selection =shift(@_);
    my $rep = $command." ".$selection;

    print $s "$rep\n";
    #If we read a list, we stop a the 'end'
    if($selection =~ /list/)
      {
	my $ans;
	do
	  {
	    $ans = <$s>;
	  }
	while(($ans=~/End/) || ($ans=~/end/));
      }
    else
      {
	my $ans = <$s>;
	chomp($ans);
	chop($ans);
	return $ans;
      }
  }

#Command SET
#The function receives the parameters that the user
#should give to an icecast server
#And it's the same for the other functions behind
#For more details see the exemple!
#The function "generic" returns you the answer, but only if there's
#one answer. For me it was not interesting to develop the
#generic function because the functions that I used are very simple,
#and the answers of the commands depends of the icecast version.
#So the job is more difficult if you want to do an real 
#'generic' function, that do not depend of the version of icecast.
sub set
  {   
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command SET\n"; }
  
    unshift(@_,$session,"set");
    &generic(@_);
  }

#Give the operator_password to become operator
sub set_oper
  {
    my $session =shift;
    unless (@_ == 1) { die "Doesn't contain password to become operator\n"; }

    unshift(@_,$session,"oper");
    my $ans = &generic(@_);
    if($ans =~ /Invalid password/)
      {
	return 0;
      }
    return 1;
  }

#Icecast modify command 
sub modify
  {   
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command MODIFY\n"; }

    unshift(@_,$session,"modify");
    &generic(@_);
  }

#Icecast allow command 
sub allow
  {
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command ALLOW\n"; }

    #The problem with the command 'allow ... list' is that I can't
    #say to the function when it must stop to read the socket!
    #They should add something like "End of allow ... listing"
    if (@_ =~ /list /) { die "Operation not allowed in the command ALLOW\n"; }

    unshift(@_,$session,"allow");
    &generic(@_);
  }

#Icecast deny command 
sub deny
  {
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command DENY\n"; }

    #The same problem that we have with allow
    if (@_ =~ /list /) { die "Operation not allowed in the command DENY\n"; }

    unshift(@_,$session,"deny");
    &generic(@_);
  }

#Icecast kick command
sub kick
  {
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command KICK\n"; }

    unshift(@_,$session,"kick");
    &generic(@_);
  }

#Icecast select command 
sub selection
  {   
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command SELECTION\n"; }
    unshift(@_,$session,"select");
    &generic(@_);
  }

#Icecast alias command
sub alias
  {
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command ALIAS\n"; }

    unshift(@_,$session,"alias");
    &generic(@_);
  }

#Icecast dir command
sub dir
  {
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command DIR\n"; }

    unshift(@_,$session,"dir");
    &generic(@_);
  }

#Icecast touch command
sub touch
  {
    my $session =shift;
    unless (@_ == 0) { die "defect of parameters in the command TOUCH\n"; }
    
    my $s = $session->{socket};
    print $s "touch\n";
    my $ans = <$s>;
  }

#Icecast status command
sub status
  {
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command STATUS\n"; }

    unshift(@_,$session,"status");
    &generic(@_);
  }

#Icecast debug command
sub debug
  {
    my $session =shift;
    unless (@_ == 1) { die "defect of parameters in the command DEBUG\n"; }

    unshift(@_,$session,"debug");
    &generic(@_);
  }


1;
__END__


=head1 NAME
  
Net::Icecast - Object oriented functions to run your icecast server by bash operations.


=head1 SYNOPSIS
  
require Net::Icecast;


=head1 DESCRIPTION

WARNING!!! This module can only be use if your icecast server is older than version 1.3.7

The commands you're used to find in an icecast server are in this module (Not all but only the ones i needed!).
They can permit you to create programs that configure your icecast server by bash operations.
If you find that there are importants functions that need to be add,
you can modify it under the same terms as Perl itself!
(If you want more details about the functions see the icecast commands documentation) 

So good fun...

=head1 OBJECTS

(be careful with the orthography of the objects, the orthography is the same that the icecast's commands)

=over 3

=item Sources object :
Properties:
id : source's id
host : source's host

=item mountpoint : source's mountpoint
connect for : source connection time
ip : source's ip
song : song sent by the source

=item Listeners object :
Properties:
id : listener's id
host : listener's host
mountpoint : listener's mountpoint
connect for : listener connection time
source_id : listener's source id.

=back

=head1 METHODS
To be connected to the icecast server as an admin
Net::Icecast->new($host,$port,$admin_password)

Returns a hash table of alls connected sources / listeners
$my_session->sources()
$my_session->listeners()

Differents methods
$my_session->set()
$my_session->modify()
$my_session->allow() you can't do "allow ... list"
$my_session->deny() you can't do "deny ... list"
$my_session->kick()
$my_session->selection()
$my_session->alias()
$my_session->dir()
$my_session->touch()
$my_session->status()
$my_session->debug()

=head1 EXAMPLE

First of all you have to run your icecast server, run a source encoder, and a client
(to do this take a look at the doc). Then execute this code in a perl programm:

#Programme gives you informations about the clients and sources in your icecast server

#!/usr/bin/perl

require Icecast;

my $session = Net::Icecast->new("icecast.computer.host",$port?,"ADMIN_Password");

$session->set_oper("OPER_Password");

my %sources = $session->sources;

print "Sources:\n";

foreach $key (keys %sources)
  {
    #To print the IP address, ...
    print "Id : $key, host : $sources{$key}->{host}\n";
  }

my %clients = $session->listeners;
print "Clients:\n";

foreach $key (keys %clients)
  {
    #To print the source id, the mount point...
    print "Id : $key, host : $clients{$key}->{host}\n";
  }

#And if you want to change the admin_password 
#$session->set("admin_password my_new_password");

#or client_password:
#$session->set("client_password secret_password");

#And you can test other functions with the same way 
#that you test this one!

#Isn't it very simple to use it :)

=head1 AUTHOR

Andrès Marino

=cut

