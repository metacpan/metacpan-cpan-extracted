package Nabaztag;

use warnings;
use strict;

use base qw/Class::AutoAccess/ ;

use Carp ;

use LWP::UserAgent ;
use URI::Escape ;

=head1 NAME

Nabaztag - A module to interface your nabaztag!

=head1 VERSION

Version 0.03

=head1 ABOUT

Nabaztag.pm  complies with nabaztag API V1 from violet company.

old APIV01 :http://www.nabaztag.com/vl/FR/nabaztag_api_version01.pdf

API V1 WILL BE SOON PUBLISHED.

See api mailing list at http://fr.groups.yahoo.com/group/nabaztag_api/

See help at http://www.nabaztag.com/ 

=cut

our $VERSION = '0.03';
our $BASE_URL = "http://www.nabaztag.com/vl/FR/api.jsp" ;
our $ID_APP = 11 ;

=head1 DESCRIPTION

This module is designed to allow you to control a nabaztag with perl programming language.
See ABOUT section to know which api it fits.

It has been tested with my own nabaztag and seems to work perfectly.

It also provide a simple command line tool to try your nabaztag: nabaztry (see SYNOPSIS).
This tool is install in /usr/bin/

It makes great use of LWP::Simple to interact with the rabbit.

PROXY issues:

 If you're behind a proxy, see LWP::Simple proxy issues to know how to deal with that.
 Basically, set env variable HTTP_PROXY to your proxi url in order to make it work.
 For instance : export HTTP_PROXY=http://my.proxy.company:8080/ 


=head1 SYNOPSIS

Commandline:

    $ nabaztry.pl MAC TOKEN POSLEFT POSRIGHT

Perl code:


    use Nabaztag ; # OR
    # use Nabaztag { 'debug' => 1 } ;

    
    my $nab = Nabaztag->new();
    
    # MANDATORY
    $nab->mac($mac);
    $nab->token($tok);
   
    # See new function to have details about how to get these properties.
 
    $nab->leftEarPos($left);
    $nab->rightEarPos($right);

    $nab->syncState();

    $nab->sayThis("Demain, il pleuvra des grillons jusqu'a extinction totale de la race humaine.");
    .....

See detailled methods for full possibilities.

Gory details :

You can access or modify BASE_URL by accessing:
   $Nabaztag::BASE_URL ;

For application id :
   $Nabaztag::ID_APP ; 


=head1 FUNCTIONS

=head2 new

Returns a new software nabaztag with ears position fetched from the hardware one if the mac and token is given.

It has following properties:

  mac : MAC Adress of nabaztag - equivalent to Serial Number ( SN ). Written at the back
        of your nabaztag !!
  token :  TOKEN Given by nabaztag.com to allow interaction with you nabaztag. See
           http://www.nabaztag.com/vl/FR/api_prefs.jsp to obtain yours !!
  leftEarPos : position of left ear.
  rightEarPos : position of right ear.

usage:
    my $nab = Nabaztag->new($mac , $token );
    print $nab->leftEarPos();
    print $nab->rightEarPos();

OR:

    my $nab = Nabaztag->new();
    $nab->mac($mac);
    $nab->token($token);
    $nab->fetchEars();

    print $nab->leftEarPos();
    print $nab->rightEarPos();

=cut

my $debug = undef ;
sub import{
    #my $callerPack = caller ;
    my ($class, $options) = @_ ;
    if(  ! defined $debug ){
    	$debug = $options->{'debug'} || 0 ;
    }
    print "\n\nDebug option : $debug \n\n" if ($debug);
}


sub new {
    my ($class , $mac, $token ) = @_ ;
    
    my $self = {
	'mac' => undef , # MAC Adress of nabaztag - equivalent to Serial Number ( SN )
	'token' => undef , # TOKEN Given by nabaztag.com to allow interaction with you nabaztag
	'leftEarPos' => undef , # Position of left ear
	'rightEarPos' => undef  # Position of right ear
	};
    
    $self = bless $self, $class ;
    
    $self->mac($mac) ;
    $self->token($token);
    if( $self->mac() && $self->token() ){
	print "Trying to fetch ears position" if ( $debug );
	$self->fetchEars();
    }
    return $self ;
}

=head2 leftEarPos

Get/Sets the left ear position of the nabaztag.

Usage:
    $nab->leftEarPos($newPos);

The new position has to be between 0 (vertical ear) and 16 included

=cut

sub leftEarPos{
    my ($self, $pos) = @_ ;
    if( defined $pos ){
	if ( ( $pos >= 0 )  && ( $pos <= 16 )){
	    return $self->{'leftEarPos'} = $pos ;
	}else{
	    confess("Position has to be between 0 and 16");
	}
    }
    return $self->{'leftEarPos'} ;
}


=head2 rightEarPos

 See leftEarPos. Same but for right.

=cut

sub rightEarPos{
    my ($self, $pos) = @_ ;
    if( defined $pos ){
	if ( ( $pos >= 0 )  && ( $pos <= 16 )){
	    return $self->{'rightEarPos'} = $pos ;
	}else{
	    confess("Position has to be between 0 and 16");
	}
    }
    return $self->{'rightEarPos'} ;
}


=head2 sendMessageNumber

Given a message number, sends this message to this nabaztag.

To obtain message numbers, go to http://www.nabaztag.com/vl/FR/messages-disco.jsp and
choose a message !!

Usage:
    $nab->sendMessageNumber($num);

=cut

sub sendMessageNumber{
    my ($self, $num ) = @_ ;
    
    my $url =  $self->_cookUrl();
    unless( defined $num ){
	confess("No message number given");
    }
  
    $url .= '&idmessage='.$num ;

    print "Accessing URL : $url\n" if ($debug);

    my $content = $self->_getUserAgent->()->get($url)->content();
    
    print "content :".$content."\n" if ($debug);
    unless( defined $content ){
	confess("An error occured while processing request");
    }
}


=head2 syncState

Synchronise the current state of the soft nabaztag with the hardware one.
Actually sends the state to the hardware nabaztag.

Usage:
    
    $nab->syncState();

=cut

sub syncState{
    my ($self) = @_ ;
    
    my $url = $self->_cookUrl();

    if( defined $self->leftEarPos() ){
	$url .=	'&posleft='.$self->leftEarPos() ;
    }
    if( defined $self->rightEarPos() ){
	$url .= '&posright='.$self->rightEarPos();
    }

    print "Getting url:".$url."\n" if ($debug);
    my $content = $self->_getUserAgent()->get($url)->content();
    print "Content:".$content."\n" if ($debug);
    unless( defined $content ){
	confess("An error occured while processing request");
    }
    
}

=head2 fetchEars

Fetches the real position of ear from the device and fill
the leftEarPos and the rightEarPos properties.

=cut

sub fetchEars{
    my ($self) = @_ ;
    
    my $url = $self->_cookUrl();
    $url .= '&ears=ok' ;
    
    print "Accessing: ".$url."\n" if ($debug);
    my $content = $self->_getUserAgent()->get($url)->content();
    print "Ear content \n".$content."\n" if ($debug);
    
    my ($left , $right) =  $content =~ /([0-9]+)/g  ;

    #print "Left :".$left."\n";
    #print "Right:".$right."\n";
    
    $self->leftEarPos($left);
    $self->rightEarPos($right);
    
}

=head2 sayThis

Makes the rabbit tell the sentence you give as parameter

Usage:
    
    $nab->sayThis("Demain, il pleuvra des grillons jusqu'a extinction totale de la race humaine."); # (example)

=cut

sub sayThis{
    my ($self, $text ) = @_ ;
    my $url = $self->_cookUrl();
    $url .= '&tts='.uri_escape($text) ;
    my $content = $self->_getUserAgent()->get($url)->content();
    print "TTS: ".$content."\n" if ($debug);
}

=head2 danceThis

Sends a choregraphy to the rabbit, with the optionnaly given title

Please refer to the APIV1 documentation to know how to compose your choregraphy

Usage:
    my $chor = '10,0,motor,1,20,0,0,0,led,2,0,238,0,2,led,1,250,0,0,3,led,2,0,0,0' ;
    my $title = 'example' ;
    $nab->danceThis($chor, $title);

=cut

sub danceThis{
    my ($self, $chor, $title) = @_ ;
    my $url = $self->_cookUrl();
    $url .= '&chor='.uri_escape($chor) ;
    $url .= '&chortitle='.uri_escape($title) if (defined $title);
    print "Getting url:".$url."\n" if ($debug);
    my $content = $self->_getUserAgent()->get($url)->content();
    print "Content :".$content."\n" if ($debug);
}

=head2 nabcastMessage

Sends the given message id to the given nabcast id with given title

Please refer to nabaztag website to get these identifiers.

usage:
    $nab->nabcastMessage($nabcastId, $title, $idMessage);

=cut

sub nabcastMessage{
    my ($self, $nabcastID, $title, $idmessage) = @_ ;
    my $url = $self->_cookUrl();
    
    $url .= '&nabcast='.$nabcastID ;
    $url .= '&nabcasttitle='.$title ;
    $url .= '&idmessage='.$idmessage ;
    
    print "Accessing :".$url."\n" if ($debug);
    my $content = $self->_getUserAgent()->get($url)->content();
    print "Content:".$content."\n" if ($debug) ;
}

=head2 nabcastText

Sends the given texttosay to the given nabcast id with given title

Please refer to nabaztag website to get these identifiers.

usage:
    $nab->nabcastText($nabcastId, $title, $texttosay);


=cut

sub nabcastText{
    my ($self, $nabcastID, $title, $text) = @_ ;
    my $url = $self->_cookUrl();
    
    $url .= '&nabcast='.$nabcastID ;
    $url .= '&nabcasttitle='.$title ;
    $url .= '&tts='.uri_escape($text) ;
    
    print "Getting url.".$url."\n" if ($debug);
    my $content = $self->_getUserAgent()->get($url)->content();
    print "Content:".$content."\n" if ($debug) ;
}

=head2 _cookUrl

Returns a cooked url ready for sending something usefull

Usage:
    
    my $url = $this->_cookUtl();

=cut

sub _cookUrl{
    my ($self) = @_ ;
    my $url =  $BASE_URL.'?idapp='.$ID_APP ;
    
    $self->_assume('mac');
    $self->_assume('token');
       
    $url .= '&sn='.$self->mac() ;
    $url .= '&token='.$self->token() ;

    return $url ;
}

sub _getUserAgent{
    my ($self) = @_ ;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(60);
    $ua->env_proxy;
    $ua->default_headers->push_header('Accept-Language' => "fr");
    return $ua ;
}


sub _assume{
    my ($self, $propertie ) = @_ ;
    unless( defined $self->$propertie() ){
	confess($propertie." is not set in $self\n Please set it first !");
    }
}

=head1 AUTHOR

Jerome Eteve, C<< <jerome@eteve.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-nabaztag@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nabaztag>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jerome Eteve, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Nabaztag
