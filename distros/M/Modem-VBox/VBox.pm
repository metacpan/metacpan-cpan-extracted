package Modem::VBox;

use strict 'subs';
use Carp;
use bytes;

require Exporter;
use POSIX ':termios_h';
use Fcntl;
use Event qw(unloop one_event time unloop_all);
use Event::Watcher qw(R W);
use Time::HiRes qw/time/; # this is required(!)

BEGIN { $^W=0 } # I'm fed up with bogus and unnecessary warnings nobody can turn off.

@ISA = qw(Exporter);

@_consts = qw(RING RUNG CONNECT BREAK EOTX);
@_funcs = qw();

@EXPORT = @_consts;
@EXPORT_OK = @_funcs;
%EXPORT_TAGS = (all => [@_consts,@_funcs], constants => \@_consts);
$VERSION = '0.051';

# if debug is used, STDIN will be used for events and $play will be used to play messages
$debug = 0;

# hardcoded constants
$HZ=8000;
$PFRAG=8192; # frag size for play_pause

$ETX="\003";
$DLE="\020";
$DC4="\024";

# bit flags for state var
sub VCON	(){ 1 }
sub VTX		(){ 2 }
sub VRX		(){ 4 }

# event types
sub RING	(){ -1 } # a single ring (+ count)
sub RUNG	(){ -2 } # ring timeout
sub CONNECT	(){ -3 } # a single ring (+ count)
sub BREAK	(){ -4 } # break sequence detected
sub EOTX	(){ -6 } # end of current transmissions

sub slog {
   my $self=shift;
   my $level=shift;
   print STDERR $self->{line},": ",@_,"\n" if $level <= $debug;
}

#  port => /dev/ttyI0
sub new {
   my $class = shift;
   my(%attr)=@_;

   croak "line must be specified" unless $attr{line};

   eval { $attr{speed}	||= &B115200 };
   eval { $attr{speed}	||= &B57600  };
   $attr{speed}		||= B38400;
   $attr{timeout}	||= 2;

   $attr{dropdtrtime}	||= 0.25; # dtr timeout
   $attr{modeminit}	||= "ATZ";
   $attr{ringto}	||= 6; # ring-timeout
   $attr{rings}		||= 3; # number of rings

   $attr{ring_cb}	||= sub { };

   my $self = bless \%attr,$class;

   $self->{ringtowatcher} = Event->timer(
      interval => $self->{ringto},
      desc => "RING timeout watcher",
      parked => 1,
      cb => sub {
         $self->rung;
         $self->slog(1, "ring timeout, aborted connection");
      }
   );

   $self->initialize;
   $self->reset;

   $self->{HZ}		||= $HZ;
   $self->{FRAG}	||= 1024;

   $self;
}

sub DESTROY {
   my $self=shift;
   $self->{tio}->setispeed(B0); $self->{tio}->setospeed(B0); $self->sane;
   close $self->{fh} or croak "error during modem-close: $!";
}

sub flush {
   my $self=shift;
   undef $self->{rawinput};
   tcflush $self->{fileno}, TCIOFLUSH;
   my $buf; 1 while (sysread ($self->{fh},$buf,1024) > 0);
}

sub sane {
   my $self=shift;
   $self->{tio}->setiflag(BRKINT|IGNPAR|IXON);
   $self->{tio}->setoflag(OPOST);
   $self->{tio}->setcflag($self->{tio}->getcflag
                  &~(CSIZE|CSTOPB|PARENB|PARODD|CLOCAL)
                  | (CS8|CREAD|HUPCL));
   $self->{tio}->setlflag(ECHOK|ECHOE|ECHO|ISIG|ICANON);
   $self->{tio}->setattr($self->{fileno});
   $self->{tio}->setcc(VMIN,1);
   $self->{tio}->setcc(VTIME,0);
}

sub raw {
   my $self=shift;
   $self->{tio}->setiflag($self->{tio}->getiflag & (IXON|IXOFF));
   $self->{tio}->setoflag(0);
   $self->{tio}->setcflag(0);
   $self->{tio}->setlflag(0);
   $self->{tio}->setcc(VMIN,1);
   $self->{tio}->setcc(VTIME,0);
   $self->{tio}->setattr($self->{fileno});
}

sub reset {
   my $self=shift;

   $self->initialize;
   $self->sane;
   $self->{inwatcher}->stop;

   my $i=$self->{tio}->getispeed; my $o=$self->{tio}->getospeed;
   $self->{tio}->setispeed(B0); $self->{tio}->setospeed(B0);

   $self->{tio}->setattr($self->{fileno});
   my $w = Event->timer(after => $self->{dropdtrtime},
                        cb => sub { $_[0]->w->cancel; unloop },
                        desc => 'Modem DTR drop timeout');

   $self->{tio}->setispeed($i); $self->{tio}->setospeed($o);

   $self->slog(3,"waiting for reset");
   $self->loop;
   $self->slog(3,"line reset");

   $self->{tio}->setattr($self->{fileno});

   $self->raw;
   $self->flush;
   $self->{inwatcher}->start;

   $self->command("AT")=~/^OK/ or croak "modem returned $self->{resp} to AT";
   $self->command($self->{modeminit})=~/^OK/ or croak "modem returned $self->{resp} to modem init string";
   $self->command("AT+VLS=2")=~/^OK/ or croak "modem returned $self->{resp} to AT+VLS=2";
   $self->command("AT+VSM=6")=~/^OK/ or croak "modem returned $self->{resp} to AT+VSM=6";
}

# read a line
sub modemline {
   my $self=shift;
   my $timeout;
   Event->timer (
      after => $self->{timeout},
      desc => "modem response timeout",
      cb => sub { $timeout = 1;
                  $_[0]->w->cancel }
   );
   one_event while !@{$self->{modemresponse}} && !$timeout;
   shift(@{$self->{modemresponse}});
}

sub modemwrite {
   my $self = shift;
   my $cmd = shift;
   fcntl $self->{fh},F_SETFL,0;
   syswrite $self->{fh}, $cmd, length $cmd;
   fcntl $self->{fh},F_SETFL,O_NONBLOCK;
}

sub command {
   my $self = shift;
   my $cmd = shift;
   $self->modemwrite("$cmd\r");
   $self->{resp} = $self->modemline;
   $self->{resp} = $self->modemline if $self->{resp} eq $cmd;
   $self->slog(2,"COMMAND($cmd) => ",$self->{resp});
   $self->{resp};
}

sub initialize {
   my $self=shift;

   $self->{inwatcher}->cancel  if $self->{inwatcher};
   $self->{outwatcher}->cancel if $self->{outwatcher};

   delete @{$self}{qw(play_queue state context break callerid
                      rawinput rawoutput modemresponse record
                      inwatcher outwatcher tio fh)};

   $self->slog(3,"opening line");

   $self->{fh}=local *FH;
   sysopen $self->{fh},$self->{line},O_RDWR|O_NONBLOCK
      or croak "unable to open device $self->{line} for r/w";
   $self->{fileno}=fileno $self->{fh};

   $self->{tio} = new POSIX::Termios;
   $self->{tio}->getattr($self->{fileno});

   $self->{inwatcher}=Event->io(
      poll => R,
      fd => $self->{fileno},
      desc => "Modem input for $self->{line}",
      parked => 1,
      cb => sub {
         my $ri = \($self->{rawinput});
         if (sysread($self->{fh}, $$ri, 8192, length $$ri) == 0) {
            $self->slog(1, "short read, probably remote hangup");
            if ($self->connected) {
               #$self->{state} &= ~(VCON|VRX|VTX);
               $self->hangup;
            } else {
               $self->slog(0, "WOAW, short read while in command mode, reinitialize");
               $self->initialize;
            }
         } else {
            if ($self->{state} & VRX) {
               my $changed;
               # must use a two-step process
               $$ri =~ s/^((?:[^$DLE]+|$DLE[^$ETX$DC4])*)//o;
               my $data = $1;
               $data =~ s{$DLE(.)}{
                  if ($1 eq $DLE) {
                     $DLE;
                  } else {
                     $self->{break} .= $1;
                     $changed=1;
                     "";
                  }
               }ego;
               $self->{record}->($data) if $self->{record};
               if ($$ri =~ s/^$DLE$ETX//o) {
                  $self->slog(3, "=> ETX, EO VTX|VRX");
                  $self->{state} &= ~VRX;
                  if ($self->{state} & VTX) {
                     $self->{state} &= ~VTX;
                     delete $self->{play_queue};
                     delete $self->{rawoutput};
                     $self->modemwrite("$DLE$ETX");
                  }
                  $$ri =~ s/^[\r\n]*(?:VCON)?[\r\n]+//;
               }
               $self->check_break if $changed;
            }
            unless ($self->{state} & VRX) {
               while ($$ri =~ s/^([^\r\n]*)[\r\n]+//) {
                  local $_ = $1;
                  if (/^CALLER NUMBER:\s+(\d+)$/) {
                     $self->{_callerid}=$1;
                     $self->slog(3,"incoming call has callerid $1");
                  } elsif (/^RING\b/) {
                     my $cid = delete $self->{_callerid} || "0";
                     my $oci = $self->{callerid};
                     $self->{callerid}=$cid;
                     if (defined $oci) {
                        if ($oci ne $cid) {
                           $self->rung;
                        }
                     } else {
                        $self->{ring}=0;
                     }
                     $self->{ringtowatcher}->stop;
                     $self->{ringtowatcher}->again;
                     $self->{ring}++;
                     $self->{ring_cb}->($self->{ring}, $self->{callerid});
                     $self->slog(1, "the telephone rings (#".($self->{ring})."), hurry! (callerid $self->{callerid})");
                     $self->accept if $self->{ring} >= $self->{rings};
                  } elsif (/^RUNG\b/) {
                     $self->rung;
                  } elsif (/\S/) {
                     push @{$self->{modemresponse}}, $_;
                  }
               }
            }
         }
      }
   );
   $self->{outwatcher} = Event->timer(
      parked => 1,
      desc => "Modem sound output for $self->{line}",
      cb => sub {
         my $w = $_[0]->w;
         my $l;
         unless (length $self->{rawoutput}) {
            my $q = $self->{play_queue};
            if (@$q) {
               #$self->slog(7, "(out $q->[0])");
               if (ref \($q->[0]) eq "GLOB") {
                  my $n;
                  $l = sysread $q->[0], $self->{rawoutput}, $self->{FRAG};
                  #$self->slog(7, "reading from file ($l bytes)\n");#d#
                  $self->{rawoutput} =~ s/$DLE/$DLE$DLE/go;
                  if ($l <= 0) {
                    #$self->slog(7, "EOTX\n");#d#
                    $self->event(EOTX, scalar@$q);
                    shift @$q;
                  }
               } else {
                  $self->{rawoutput} = ${shift(@$q)};
               }
            } else {
               $w->stop;
               $self->event(EOTX, 0);
               return;
            }
         }
         if (length $self->{rawoutput}) {
            #$self->slog(7, "(send ".(length $self->{rawoutput})." bytes)");
            $l = syswrite $self->{fh}, $self->{rawoutput}, length $self->{rawoutput};
            #$self->slog(7, "(sent $l bytes)");
            substr($self->{rawoutput}, 0, $l) = "" if $l > 0;
            if (defined $l) {
               $l /= $self->{HZ}; #/
            } else {
               $l = 0.1;
            }
            $self->{vtx_end} += $l;
         }
         $w->at($self->{vtx_end} - 0.01);
         $w->start;
      }
   );

   $self->{tio}->setispeed($self->{speed});
   $self->{tio}->setospeed($self->{speed});

   $self->{ring}=0;
}

sub abort {
   my $self=shift;
   $self->initialize;
   $self->reset;
   $self->slog(1,"modem is now in listening state");
}

sub rung {
   my $self=shift;
   $self->{ringtowatcher}->stop;
   $self->{ring}=0;
   $self->event(RUNG);
   $self->slog(1,"caller ($self->{callerid}) hung up before answering");
   delete $self->{callerid};
}

sub loop {
   local $Event::DIED = sub {
      print STDERR $_[1];
      unloop_all;
   };
   Event::loop;
}

sub accept {
   my $self=shift;
   # DLE etc. handling
   $self->{ringtowatcher}->stop;
   if ($self->command("ATA") =~ /^VCON/) {
      $self->slog(2, "call accepted (callerid $self->{callerid})");
      if ($self->command("AT+VTX+VRX") =~ /^CONNECT/) {
         $self->{state} |= VCON|VTX|VRX;
         delete $self->{event};
         $self->event(CONNECT);
         $self->{connect_cb}->($self);
         delete $self->{event};
      } else {
         $self->rung;
         $self->abort;
         $self->slog(1, "modem did not respond with CONNECT to AT+VTX+VRX command");
      }
   } else {
      $self->slog(1, "modem did not respond with VCON to my ATA");
      $self->rung;
   }
}

sub check_break {
   my $self=shift;
   while(my($k,$v) = each %{$self->{context}}) {
      if ($self->{break} =~ /$k/) {
         ref $v eq "CODE" ? $v->($self, $self->{break})
                          : $self->event(BREAK, $v);
      }
   }
}

sub hangup {;
   my $self=shift;
   $self->event(undef) if $self->connected;
   $self->abort;
}

sub connected {
   $_[0]->{state} & VCON;
}

# return the number of pending events
sub pending {
   @{$_[0]->{event}};
}

sub wait_event {
   my $self = shift;
   one_event while !$self->pending;
}

sub event {
   my $self=shift;
   #$self->slog(3, "EVENT ".(scalar@_)." :@_:");
   if (@_) {
      push @{$self->{event}},
         defined $_[0] ? bless [@_], "Modem::VBox::Event" 
                       : undef;
   } else {
      $self->wait_event;
      defined $self->{event}->[0] ? shift @{$self->{event}}
                                  : undef;
   }
}

sub play_file($$) {
   my $self = shift;
   my $path = shift;
   my $fh = do { local *FH };
   $self->slog(5, "play_file $path");
   open $fh,"<$path" or croak "unable to open ulaw file '$path' for playing";
   $self->play_object($fh);
}

sub play_data($$) {
   my $self=shift;
   my $data=shift;
   $data=~s/$DLE/$DLE$DLE/go;
   $self->play_object(\$data);
}

sub play_object($$) {
   my $self=shift;
   my $obj=shift;
   $self->{state} & VCON or return;
   unless ($self->{outwatcher}->is_active) {
      $self->{outwatcher}->at($self->{vtx_end} = time);
      $self->{outwatcher}->start;
   }
   push @{$self->{play_queue}}, $obj;
}

sub play_pause($$) {
   my $self=shift;
   $self->slog(5, "play_pause $_[0]");
   my $len = int($self->{HZ}*$_[0]+0.999);
   my $k8  = "\xFE" x $PFRAG;
   while ($len>length($k8)) {
      $self->play_object(\$k8);
      $len-=length($k8);
   }
   $self->play_object(\("\xFE" x $len));
}

sub play_count($) {
   scalar @{$_[0]->{play_queue}};
}

sub play_flush($) {
   my $self=shift;
   #tcflush $self->{fileno}, TCOFLUSH;
   @{$self->{play_queue}} = ();
   delete $self->{rawoutput};
   one_event;
}

sub play_drain($) {
   my $self=shift;
   my $waiting = 1;
   one_event while $self->play_count;
   Event->timer(at => $self->{vtx_end},
                desc => "play_drain timer",
                cb => sub { $waiting = 0;
                            $_[0]->w->cancel }
               );
   one_event while $waiting;
}

sub record($$) {
   my $self = shift;
   $self->{record} = shift;
}

sub record_file($$) {
   my $self = shift;
   my $fh = shift;
   $self->record (sub { print $fh $_[0] });
}

sub callerid($) { $_[0]->{callerid} }

sub context($) {
   my $self=shift;
   bless [$self, {%{$self->{context}}}], "Modem::VBox::context";
}

package Modem::VBox::Event;

sub type($$)	{ $_[0]->[0] == $_[1] }
sub isbreak($)	{ $_[0]->[0] == Modem::VBox::BREAK }
sub iseotx($;$)	{ $_[0]->[0] == Modem::VBox::EOTX && ( @_ < 2 || $_[1] >= $_[0]->[1] ) }
sub data($)	{ $_[0]->[1] }

package Modem::VBox::context;

sub set {
   my $self=shift;
   %{$self->[0]{context}} = @_;
   $self;
}

*clr = \&set;

sub add {
   my $self=shift;
   while(@_) {
      $self->[0]{context}{$_[0]} = $_[1];
      shift; shift;
   }
   $self;
}

sub del {
   my $self=shift;
   for(@_) {
      delete $self->[0]{context}{$_};
   }
   $self;
}

sub DESTROY {
   my $self=shift;
   my($vbox,$ctx)=@$self;
   $vbox->{context}=$ctx;
}

1;
__END__

=head1 NAME

Modem::VBox - Perl module for creation of voiceboxes.

=head1 SYNOPSIS

  use Modem::VBox;

=head1 DESCRIPTION

Oh well ;) Not written yet! An example script (C<vbox>) is included in the distro, though.

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>.

=head1 SEE ALSO

perl(1), L<Modem::Vgetty> a similar but uglier interface.

=cut
