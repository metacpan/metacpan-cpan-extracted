package Net::SIGTRAN::SCTP;

# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.

use 5.008008;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(new abc
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
);
our $VERSION = '0.1.1';

require XSLoader;
XSLoader::load('Net::SIGTRAN::SCTP', $VERSION);

sub new {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my %args = (@_);

   return undef if (!exists $args{'PORT'});

   $args{'HOST'}='127.0.0.1' if (!exists $args{'HOST'});
   $args{'PPID'}=0 if (!exists $args{'PPID'});
   $args{'FLAGS'}=0 if (!exists $args{'FLAGS'});
   $args{'TIME_TO_LIVE'}=0 if (!exists $args{'TIME_TO_LIVE'});
   $args{'CONTEXT'}=0 if (!exists $args{'CONTEXT'});

# ,ppid,flags,stream_no,timetolive,context
   return bless {
      HOST =>$args{'HOST'},
      PORT =>$args{'PORT'},
      PPID =>$args{'PPID'},
      FLAGS =>$args{'FLAGS'},
      TIME_TO_LIVE =>$args{'TIME_TO_LIVE'},
      CONTEXT =>$args{'CONTEXT'}
   }, $class;
}

sub bind {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=_socket();
   return _bind($sock,$class->{'PORT'});
}

sub connect {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=_socket();
   #my ($conn,$sstat_assoc_id,$sstat_state,$sstat_instrms,$sstat_outstrms) = _connect($sock,$class->{'HOST'},$class->{'PORT'});
   #$class->{'SSTAT_ASSOC_ID'}=$sstat_assoc_id;
   #$class->{'SSTAT_STATE'}=$sstat_state;
   #$class->{'SSTAT_INSTRMS'}=$sstat_instrms;
   #$class->{'SSTAT_OUTSTRMS'}=$sstat_outstrms;
   #return $conn;
   return _connect($sock,$class->{'HOST'},$class->{'PORT'});
}

sub accept {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=shift;
   return _accept($sock);
}

sub recieve {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=shift;
   my $buffsize=shift;
   my $buffer='';
   my $ret= _recieve($sock,$buffer,$buffsize);
   my $newbuffer=$buffer ? $class->hextobin($buffer) : '';
   my $newbuffersize=length($buffer);
   return ($newbuffersize,$newbuffer);
}

sub send {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=shift;
   my $streamno=shift;
   my $buffsize=shift;
   my $buff=shift;
#print "StreamNo:$streamno ($buffsize)\n";
   return _send($sock,$class->{'PPID'},$class->{'FLAGS'},$streamno,$class->{'TIME_TO_LIVE'},$class->{'CONTEXT'},$buffsize,$buff);
}

sub hextobin {
   my $class=shift;
   my $string=shift;
   my $out='';
   my @strings=split "",$string;
   for (my $i=0;$i<@strings-1;$i+=2) {
      $out.= pack('C',hex($strings[$i].$strings[$i+1]));
   }
   return $out;
}

sub close {
   my $class=shift|| undef;
   return undef if (!defined $class);
   my $sock=shift;
   _close($sock) if ($sock);
}


1;
__END__

=head1 NAME

Net::SIGTRAN::SCTP - An implementation to access to lksctp to provide sctp implementation in perl.

=head1 SYNOPSIS

=head2 Server Example

use Net::SIGTRAN::SCTP;

use threads;

my $server=new Net::SIGTRAN::SCTP(
   PORT=>12345
);
my $ssock=$server->bind();
if ($ssock) {
   my $csock;
   while($csock = $server->accept($ssock)) {
      print "New Client Connection\n";
      my $thr=threads->create(\&processRequest,$server,$csock);
      $thr->detach();
   }
}

sub processRequest {
   my $connection=shift;
   my $socket=shift;
   my ($readlen,$buffer)= $connection->recieve($socket,1000);
   print "Recieved ($readlen,$buffer)\n";
}


=head2 Client Example

use Net::SIGTRAN::SCTP;

my $textstring='Hello World';
my $client=new Net::SIGTRAN::SCTP(
   HOST=>'127.0.0.1',
   PORT=>12345
);

my $csock=$client->connect();

$client->send($csock,0,length($textstring),$textstring);
$client->close($csock);


=head1 AUTHOR

Christopherus Goo <software@artofmobile.com>

=head1 COPYRIGHT

Copyright (c) 2012 Christopherus Goo.  All rights reserved.
This software may be used and modified freely, but I do request that this
copyright notice remain attached to the file.  You may modify this module
as you wish, but if you redistribute a modified version, please attach a
note listing the modifications you have made.

=cut

