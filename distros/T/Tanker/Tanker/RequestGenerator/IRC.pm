package Tanker::RequestGenerator::IRC;

use strict;
use warnings;
use Tanker::Request;
use Tanker::RequestGenerator;
use vars qw(@ISA $me $running);
use Data::Dumper;
use POE;
use POE::Component::IRC;

@ISA = qw (Tanker::RequestGenerator);

my $NAME    = "tanker" . $$ % 1000;
my $NICK    =  $NAME;
my $CHANNEL = "#tanker";
my $SERVER  = "london.rhizomatic.net";


# this isn't very good and needs to be more flexible but 
# it's a start and shows that the pipeline works concurrently

sub new 
{
      my $proto    = shift;
      my $class    = ref($proto) || $proto;
      my $pipeline = shift;

      my $self  = $class->SUPER::new($pipeline);

      POE::Component::IRC->new($NAME) or die "Oh noooo! $!";

      POE::Session->new
      (   _start     => \&bot_start,
    	  irc_376    => \&on_connect,
    	  irc_public => \&on_message,
      );



      $me = $self;

      return $self;


}

sub bot_start
{
      print STDERR "Attempting to connect\n";


      my $kernel  = $_[KERNEL];
      my $heap    = $_[HEAP];
      my $session = $_[SESSION];

      $kernel->refcount_increment( $session->ID(), "irc bot" );
      $kernel->post( $NAME => register => "all" );


      $kernel->post($NAME, 'connect',
                       { Nick     => $NICK,
                         Server   => $SERVER,
                         Port     => 6667,
                         Username => $NICK,
                         Ircname  => $NICK, } );
}

sub on_connect
{
	print STDERR "Joining\n";
	$_[KERNEL]->post( $NAME => join => $CHANNEL );
}

sub on_message 
{
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick = (split /!/, $who)[0];
  my $channel = $where->[0];

  my $ts = scalar(localtime);
  print STDERR " [$ts] <$nick:$channel> $msg\n";

  my $r = {
		ts      => $ts,
		nick    => $nick,
		channel => $channel,
		msg     => $msg,
	  };
  
   my $req = new Tanker::Request($r); 
    $me->{pipeline}->inject($req);


}



sub run  ($)
{
	my ($self) = @_;
	$poe_kernel->run();	

}

1;
__END__
=head1 NAME

Tanker::RequestGenerator::IRC - a module to inject requests originating from IRC

=head1 SYNOPSIS

use Tanker::RequestGenerator::IRC;

my $rg = new Tanker::RequestGenerator::IRC ($pipeline)

$rg->run();


=head1 DESCRIPTION

This connects to an IRC channel and then pumps requests down the pipeline.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

L<Tanker>, L<Tanker::Config>, L<Tanker::RequestGenerator>, L<Tanker::Plugin>, L<Tanker::ResponseHandler>, L<Tanker::Request>;

=cut
