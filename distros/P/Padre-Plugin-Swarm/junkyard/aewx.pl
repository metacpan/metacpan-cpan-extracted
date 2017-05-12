#!/usr/bin/perl
package MyApp;
use threads;
use threads::shared;
use Thread::Queue;
use Wx ':everything';
use Wx::Event;
use base 'Wx::App';
use strict;
use warnings;
use Data::Dumper;

our $wx_notify : shared;
$wx_notify = Wx::NewEventType();

sub OnInit {
   my $self = shift;
   
   my $queue = Thread::Queue->new;
   my $tid = threads->create(\&background, 1, $queue , $self );
   $self->{queue} = $queue; 
   $self->{mythread} = $tid;
   
   my $frame = Wx::Frame->new( undef,           # parent window
                                -1,              # ID -1 means any
                                'wxPerl rules',  # title
                                [-1, -1],         # default position
                                [250, 150],       # size
                               );

   my $s = Wx::BoxSizer->new( wxVERTICAL );
   my $t = Wx::StaticText->new( $frame , -1 , 'My Static Text' ,  [-1,-1], [-1,-1] );
   $self->{text} = $t;
   
   my $te = Wx::TextCtrl->new( $frame , -1 ,'' ,  [-1,-1] , [-1,-1],
                                wxTE_PROCESS_ENTER );
   $self->{entry} = $te;
   
    $s->Add($t,0, Wx::wxALL | Wx::wxEXPAND );
    $s->Add($te, 0 , Wx::wxALL | Wx::wxEXPAND);
   Wx::Event::EVT_TEXT_ENTER( $self, $te , \&OnTextEnter );
   
   Wx::Event::EVT_COMMAND( $self, -1 , $wx_notify , \&OnThreadEvent );
   $frame->SetSizer($s);
   $frame->Layout;
   $frame->Show(1);


}

sub OnTextEnter {
    my ($self) = @_;
   print STDERR "Button Clicked - @_";
   print STDERR "Enqueued message";
   $self->{queue}->enqueue( $self->{entry}->GetValue );
   $self->{mythread}->kill('SIGINT');

}

sub OnThreadEvent {
    warn "Got thread event @_";
    my ($self,$evt) = @_;
    $self->{text}->SetLabel( $evt->GetData );
    
}
###############################################################################

### Thread
sub background {
   my $freq = shift;
   my $q = shift;
   my $frame = shift;

local $ENV{PERL_ANYEVENT_MODEL} = 'Perl';
require AnyEvent;
require IO::Socket::Multicast;
require JSON;
   my $bailout = AnyEvent->condvar;

   my $timer = AnyEvent->timer( interval => $freq , cb => \&timer_poll );
   
   my $signal= AnyEvent->signal( signal => 'TERM' , cb => $bailout );

   my $client = IO::Socket::Multicast->new(
                LocalPort => 12000,
                ReuseAddr => 1,
   ) or die $!;
   $client->mcast_add('239.255.255.1'); #should have the interface
   $client->mcast_loopback( 1 );
   my $g = AnyEvent->io( poll=>'r' , fh => $client , cb => sub { client_socket_read($client,$frame) } );
   my $wakeup= AnyEvent->signal( signal => 'INT' , cb => sub { wx_queue_read($q,$client) } );

   my $r = $bailout->recv;
   warn "Bailed out with $r";
   return;
}

sub timer_poll {
    my $time = AnyEvent->now;
    warn "Time is now $time";
}

sub client_socket_read {
    my $client = shift;
    my $frame = shift;
    my $message; 
    $client->recv( $message, 65535 );
    warn "Got message : $message";
    my $payload = Wx::PlThreadEvent->new( -1, $wx_notify, $message ) ;
    Wx::PostEvent( $frame, $payload );
}

sub wx_queue_read {
    my $q = shift;
    my $c = shift;
    while ( defined(my $m = $q->dequeue_nb) ) {
        print STDERR "Got message '$m'";
        my $msg = JSON::encode_json( { type=>'chat' , body=>$m , from=>$0.$$ } );
        $c->mcast_send( $msg , '239.255.255.1:12000' ); 
    }

}

1;

package main;


my $app = MyApp->new;
$app->MainLoop;



exit 0;
