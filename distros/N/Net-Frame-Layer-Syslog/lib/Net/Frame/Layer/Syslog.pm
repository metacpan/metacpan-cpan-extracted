#
# $Id: Syslog.pm 49 2012-11-19 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::Syslog;
use strict; use warnings;

our $VERSION = '1.05';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_SYSLOG_FACILITY_KERNEL
      NF_SYSLOG_FACILITY_USER
      NF_SYSLOG_FACILITY_MAIL
      NF_SYSLOG_FACILITY_SYSTEM
      NF_SYSLOG_FACILITY_SECURITY
      NF_SYSLOG_FACILITY_INTERNAL
      NF_SYSLOG_FACILITY_PRINTER
      NF_SYSLOG_FACILITY_NEWS
      NF_SYSLOG_FACILITY_UUCP
      NF_SYSLOG_FACILITY_CLOCK
      NF_SYSLOG_FACILITY_SECURITY2
      NF_SYSLOG_FACILITY_FTP
      NF_SYSLOG_FACILITY_NTP
      NF_SYSLOG_FACILITY_AUDIT
      NF_SYSLOG_FACILITY_ALERT
      NF_SYSLOG_FACILITY_CLOCK2
      NF_SYSLOG_FACILITY_LOCAL0
      NF_SYSLOG_FACILITY_LOCAL1
      NF_SYSLOG_FACILITY_LOCAL2
      NF_SYSLOG_FACILITY_LOCAL3
      NF_SYSLOG_FACILITY_LOCAL4
      NF_SYSLOG_FACILITY_LOCAL5
      NF_SYSLOG_FACILITY_LOCAL6
      NF_SYSLOG_FACILITY_LOCAL7
      NF_SYSLOG_SEVERITY_EMERGENCY
      NF_SYSLOG_SEVERITY_ALERT
      NF_SYSLOG_SEVERITY_CRITICAL
      NF_SYSLOG_SEVERITY_ERROR
      NF_SYSLOG_SEVERITY_WARNING
      NF_SYSLOG_SEVERITY_NOTICE
      NF_SYSLOG_SEVERITY_INFORMATIONAL
      NF_SYSLOG_SEVERITY_DEBUG
   )],
   subs => [qw(
      priorityAton
      priorityNtoa
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
   @{$EXPORT_TAGS{subs}},
);

use constant NF_SYSLOG_FACILITY_KERNEL        => 0;
use constant NF_SYSLOG_FACILITY_USER          => 1;
use constant NF_SYSLOG_FACILITY_MAIL          => 2;
use constant NF_SYSLOG_FACILITY_SYSTEM        => 3;
use constant NF_SYSLOG_FACILITY_SECURITY      => 4;
use constant NF_SYSLOG_FACILITY_INTERNAL      => 5;
use constant NF_SYSLOG_FACILITY_PRINTER       => 6;
use constant NF_SYSLOG_FACILITY_NEWS          => 7;
use constant NF_SYSLOG_FACILITY_UUCP          => 8;
use constant NF_SYSLOG_FACILITY_CLOCK         => 9;
use constant NF_SYSLOG_FACILITY_SECURITY2     => 10;
use constant NF_SYSLOG_FACILITY_FTP           => 11;
use constant NF_SYSLOG_FACILITY_NTP           => 12;
use constant NF_SYSLOG_FACILITY_AUDIT         => 13;
use constant NF_SYSLOG_FACILITY_ALERT         => 14;
use constant NF_SYSLOG_FACILITY_CLOCK2        => 15;
use constant NF_SYSLOG_FACILITY_LOCAL0        => 16;
use constant NF_SYSLOG_FACILITY_LOCAL1        => 17;
use constant NF_SYSLOG_FACILITY_LOCAL2        => 18;
use constant NF_SYSLOG_FACILITY_LOCAL3        => 19;
use constant NF_SYSLOG_FACILITY_LOCAL4        => 20;
use constant NF_SYSLOG_FACILITY_LOCAL5        => 21;
use constant NF_SYSLOG_FACILITY_LOCAL6        => 22;
use constant NF_SYSLOG_FACILITY_LOCAL7        => 23;
use constant NF_SYSLOG_SEVERITY_EMERGENCY     => 0;
use constant NF_SYSLOG_SEVERITY_ALERT         => 1;
use constant NF_SYSLOG_SEVERITY_CRITICAL      => 2;
use constant NF_SYSLOG_SEVERITY_ERROR         => 3;
use constant NF_SYSLOG_SEVERITY_WARNING       => 4;
use constant NF_SYSLOG_SEVERITY_NOTICE        => 5;
use constant NF_SYSLOG_SEVERITY_INFORMATIONAL => 6;
use constant NF_SYSLOG_SEVERITY_DEBUG         => 7;

our @FACILITY = qw(kernel user mail system security internal printer news uucp clock security2 FTP NTP audit alert clock2 local0 local1 local2 local3 local4 local5 local6 local7);
our @SEVERITY = qw(Emergency Alert Critical Error Warning Notice Informational Debug);

our @AS = qw(
   facility
   severity
   timestamp
   host
   tag
   content
   msg
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

use Sys::Hostname;

$Net::Frame::Layer::UDP::Next->{514} = "Syslog";

sub new {
   my $time = _getTime();
   my $host = _getHost();
   my $tag  = _getTag();

   shift->SUPER::new(
      facility  => NF_SYSLOG_FACILITY_LOCAL7,
      severity  => NF_SYSLOG_SEVERITY_INFORMATIONAL,
      timestamp => $time,
      host      => $host,
      tag       => $tag,
      content   => 'syslog message',
      @_,
   );
}

sub message {
   my $time = _getTime();
   my $host = _getHost();
   my $tag  = _getTag();

   shift->SUPER::new(
      msg => "<190>$time $host $tag syslog message",
      @_,
   );
}

sub getLength {
   my $self = shift;

   if (defined($self->msg)) {
       return length($self->msg)
   } else {

      my $priority = priorityAton($self->facility, $self->severity);
      my $len =
         length($priority)        +
         length($self->timestamp) +
         length($self->host)      +
         length($self->tag)       +
         length($self->content)   +
         5;

      return $len
   }
}

sub pack {
   my $self = shift;

   my $raw;
   if (defined($self->msg)) {
      $raw = $self->SUPER::pack('a*',
         $self->msg
      ) or return;
   } else {
      my $priority = priorityAton($self->facility, $self->severity);

      $raw = $self->SUPER::pack('a*',
         "<" .
         $priority .
         ">" .
         $self->timestamp .
         " " .
         $self->host .
         " " .
         $self->tag .
         " " .
         $self->content
      ) or return;
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($payload) =
      $self->SUPER::unpack('a*', $self->raw)
         or return;

   my $regex = '<(\d{1,3})>[\d{1,}: \*]*((?:[JFMASONDjfmasond]\w\w) {1,2}(?:\d+)(?: \d{4})? (?:\d{2}:\d{2}:\d{2}[\.\d{1,3}]*)(?: [A-Z]{1,3}:)?)?:?\s*(?:((?:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(?:[a-zA-Z0-9\-]+)|(?:(?:(?:[0-9A-Fa-f]{1,4}:){7}(?:[0-9A-Fa-f]{1,4}|:))|(?:(?:[0-9A-Fa-f]{1,4}:){6}(?::[0-9A-Fa-f]{1,4}|(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9A-Fa-f]{1,4}:){5}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,2})|:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9A-Fa-f]{1,4}:){4}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,3})|(?:(?::[0-9A-Fa-f]{1,4})?:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){3}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,4})|(?:(?::[0-9A-Fa-f]{1,4}){0,2}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){2}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,5})|(?:(?::[0-9A-Fa-f]{1,4}){0,3}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){1}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,6})|(?:(?::[0-9A-Fa-f]{1,4}){0,4}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?::(?:(?:(?::[0-9A-Fa-f]{1,4}){1,7})|(?:(?::[0-9A-Fa-f]{1,4}){0,5}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(?:%.+)?) )?(.*)';
#   my $regex = '<(\d{1,3})>[\d{1,}: \*]*((?:[JFMASONDjfmasond]\w\w) {1,2}(?:\d+)(?: \d{4})* (?:\d{2}:\d{2}:\d{2}[\.\d{1,3}]*)(?: [A-Z]{1,3})*)?:*\s*(?:((?:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(?:[a-zA-Z\-]+)|(?:(?:(?:[0-9A-Fa-f]{1,4}:){7}(?:[0-9A-Fa-f]{1,4}|:))|(?:(?:[0-9A-Fa-f]{1,4}:){6}(?::[0-9A-Fa-f]{1,4}|(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9A-Fa-f]{1,4}:){5}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,2})|:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9A-Fa-f]{1,4}:){4}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,3})|(?:(?::[0-9A-Fa-f]{1,4})?:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){3}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,4})|(?:(?::[0-9A-Fa-f]{1,4}){0,2}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){2}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,5})|(?:(?::[0-9A-Fa-f]{1,4}){0,3}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){1}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,6})|(?:(?::[0-9A-Fa-f]{1,4}){0,4}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?::(?:(?:(?::[0-9A-Fa-f]{1,4}){1,7})|(?:(?::[0-9A-Fa-f]{1,4}){0,5}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(?:%.+)?) )?(.*)';
   my $Cregex = qr/$regex/;

   if ($payload =~ /$Cregex/) {

      my $priority  = $1;
      my $timestamp = $2 || '0';
      my $hostname  = $3 || '0';
      my $message   = $4;
      my ($facility, $severity) = priorityNtoa($priority);

      $self->facility($facility);
      $self->severity($severity);
      $self->timestamp($timestamp);

      $hostname =~ s/\s+//;
      $self->host($hostname);

      my %chars;
      $chars{bracket} = index($message,"]");
      $chars{colon}   = index($message,":");
      $chars{space}   = index($message," ");
      my $win = 0;
      foreach my $ch (sort {$chars{$b} cmp $chars{$a}} keys %chars) {
          if ($chars{$ch} > 0) {
             $win = $ch
          }
      }
      if ($chars{$win} > 0) {
         my $tag     = substr($message, 0, $chars{$win}+1) || '0';
         my $content = substr($message, $chars{$win}+1)    || '0';
         $self->tag($tag);
         $self->content($content)
      } else {
          $self->tag('0');
          $self->content($message)
      }

      my $msg = substr $payload, index($payload,">")+1;
      $self->msg($msg)

   } else {
      $self->facility(undef);
      $self->severity(undef);
      $self->content(undef);
      $self->msg($payload)
   }

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   # Needed?
   if ($self->payload) {
      return 'Syslog';
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf;

   if (defined($self->facility) && defined($self->severity)) {
      $buf = sprintf
         "$l: facility:%d %s  severity:%d %s\n",
            $self->facility,
            (defined $FACILITY[$self->facility]) ? "($FACILITY[$self->facility])" : '',
            $self->severity,
            (defined $SEVERITY[$self->severity]) ? "($SEVERITY[$self->severity])" : '';
   }

   if (not defined($self->content)) {
      $buf .= sprintf
         "$l: message:%s",
            $self->msg;
   } else {
      $buf .= sprintf
         "$l: timestamp:%s  host:%s\n".
         "$l: tag:%s\n".
         "$l: content:%s",
            $self->timestamp, $self->host,
            $self->tag,
            $self->content;
   }

   return $buf;
}

####

sub priorityAton {
   my ($fac, $sev) = @_;

   return undef if not defined $sev;
   return (($fac << 3) | $sev)
}

sub priorityNtoa {
   my ($pri, $flag) = @_;

   return undef if not defined $pri;
   my $sev = $pri % 8;
   my $fac = ($pri - $sev) / 8;

   if (defined($flag)) {
      return ($FACILITY[$fac], $SEVERITY[$sev])
   } else {
      return ($fac, $sev)
   }
}

sub _getTime {
   my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   my @time = localtime();
   my $ts =
        $month[ $time[4] ] . " "
      . ( ( $time[3] < 10 ) ? ( " " . $time[3] ) : $time[3] ) . " "
      . ( ( $time[2] < 10 ) ? ( "0" . $time[2] ) : $time[2] ) . ":"
      . ( ( $time[1] < 10 ) ? ( "0" . $time[1] ) : $time[1] ) . ":"
      . ( ( $time[0] < 10 ) ? ( "0" . $time[0] ) : $time[0] );

   return $ts
}

sub _getHost {
   return Sys::Hostname::hostname;
}

sub _getTag {
   my $name  = $0;
   if ($name =~ /.+\/(.+)/) {
      $name = $1;
   } elsif ($name =~ /.+\\(.+)/) {
      $name = $1;
   }

   return $name . "[" . $$ . "]"
}

1;

__END__

=head1 NAME

Net::Frame::Layer::Syslog - Syslog layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::Syslog qw(:consts);

   my $layer = Net::Frame::Layer::Syslog->new(
      facility  => NF_SYSLOG_FACILITY_LOCAL7,
      severity  => NF_SYSLOG_SEVERITY_INFORMATIONAL,
      timestamp => (current time MMM DD HH:MM:SS),
      host      => (hostname),
      tag       => ($0[$$]),
      content   => 'syslog message',
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::Syslog->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Syslog layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc3164.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<facility>

Syslog facility.  See B<CONSTANTS> for more information.

=item B<severity>

Syslog severity.  See B<CONSTANTS> for more information.

=item B<timestamp>

Timestamp.  Default is set to current time in format:  MMM DD HH:MM:SS

=item B<host>

Hostname.  Default is set to current host.

=item B<tag>

Tag.  Default is set to:  program_name[process_id]

=item B<content>

Syslog message.

=back

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

  <###>Mmm dd hh:mm:ss hostname tag content
  |___||_____________| |______| |_________|
    |     Timestamp    Hostname   Message
    |
   Priority -> (facility and severity)

=item B<message>

=item B<message> (hash)

Object constructor.  Same as B<new> but only takes B<message> as input.  Value of B<message> is the entire Syslog message.  This allows custom messages that do not follow strict RFC 3164 guidelines.  Default message is same as constructed with B<new>.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 USEFUL SUBROUTINES

Load them: use Net::Frame::Layer::Syslog qw(:subs);

=over 4

=item B<priorityAton> (facility, severity)

Takes Syslog facility and severity and returns priority.

=item B<priorityNtoa> (priority [,1])

Takes Syslog priority and returns numeric facility and severity.  Optional
flag returns facility and severity names.

   my ($facility, $severity) = priorityNtoa( ... )

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::Syslog qw(:consts);

=over 4

=item B<NF_SYSLOG_FACILITY_KERNEL>

=item B<NF_SYSLOG_FACILITY_USER>

=item B<NF_SYSLOG_FACILITY_MAIL>

=item B<NF_SYSLOG_FACILITY_SYSTEM>

=item B<NF_SYSLOG_FACILITY_SECURITY>

=item B<NF_SYSLOG_FACILITY_INTERNAL>

=item B<NF_SYSLOG_FACILITY_PRINTER>

=item B<NF_SYSLOG_FACILITY_NEWS>

=item B<NF_SYSLOG_FACILITY_UUCP>

=item B<NF_SYSLOG_FACILITY_CLOCK>

=item B<NF_SYSLOG_FACILITY_SECURITY2>

=item B<NF_SYSLOG_FACILITY_FTP>

=item B<NF_SYSLOG_FACILITY_NTP>

=item B<NF_SYSLOG_FACILITY_AUDIT>

=item B<NF_SYSLOG_FACILITY_ALERT>

=item B<NF_SYSLOG_FACILITY_CLOCK2>

=item B<NF_SYSLOG_FACILITY_LOCAL0>

=item B<NF_SYSLOG_FACILITY_LOCAL1>

=item B<NF_SYSLOG_FACILITY_LOCAL2>

=item B<NF_SYSLOG_FACILITY_LOCAL3>

=item B<NF_SYSLOG_FACILITY_LOCAL4>

=item B<NF_SYSLOG_FACILITY_LOCAL5>

=item B<NF_SYSLOG_FACILITY_LOCAL6>

=item B<NF_SYSLOG_FACILITY_LOCAL7>

Syslog facilities.

=item B<NF_SYSLOG_SEVERITY_EMERGENCY>

=item B<NF_SYSLOG_SEVERITY_ALERT>

=item B<NF_SYSLOG_SEVERITY_CRITICAL>

=item B<NF_SYSLOG_SEVERITY_ERROR>

=item B<NF_SYSLOG_SEVERITY_WARNING>

=item B<NF_SYSLOG_SEVERITY_NOTICE>

=item B<NF_SYSLOG_SEVERITY_INFORMATIONAL>

=item B<NF_SYSLOG_SEVERITY_DEBUG>

Syslog severities.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
