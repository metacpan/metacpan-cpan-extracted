#!/usr/bin/perl -w -T
# -*- cperl -*-

our $debug = 2; $|++; use Data::Dumper; # Yes, it's that alpha.

use strict; use warnings; # I normally don't make all my code do this,
                          # but this code is intended to go on the
                          # CPAN and be seen by other people :-)

# BEGIN { push @INC, "/home/mailproxy/lib"; } # You can comment this out if you install Net::Server::POP3 in a normal place.

use Net::Server::POP3; # This handles the server half of the protocol, for talking to clients.
use Mail::POP3Client;  # This handles the client half of the protocol, for talking to servers.
use DateTime; use DateTime::Format::Mail; # retrieve uses these to insert a Received: header.

my $realserver = 'mail.yourisp.net'; # You will surely have to change this.

my %maildrop; # When we lock a maildrop, we hold state in this variable.

my $serv = Net::Server::POP3->new
  (
   serveropts => +{
                   user      => 'mailproxy', # You may need to change this.
                   group     => 'nobody',    # You may also need to change this.
                   log_level => 3,
                  },
   authenticate => \&userauth,
   list => \&msglist,
   retrieve => \&retrieve,
   size => \&sizemsg,
   delete => \&delmsg,
   disconnect => \&discon,
  );


$serv->startserver();

sub userauth {
  my ($user, $pass, $ip) = @_;
  use Mail::POP3Client;
  my $pop = new Mail::POP3Client(AUTH_MODE => 'PASS',
                                 USER => $user, PASSWORD => $pass,
                                 HOST => $realserver, DEBUG => $debug);
  my $popcount = $pop->Count();
  if (defined $popcount and $popcount >= 0) {
    %maildrop = (
                 user  => $user,
                 count => $popcount,
                 capa  => [$pop->Capa()],
                 pop   => $pop,
                );
    warn "Authenticated client at $ip\n" if $debug;
    return $pop;
  } else {
    return 0;
  }
}

sub msglist { # Note that $maildrop{list} caches a list of [number, msgid]
  my ($username) = @_;
  warn "msglist starting with " . Dumper(\$maildrop{list}) . "\n" if $debug;
  if ($username eq $maildrop{user}) {
    return map { $$_[1] } @{$maildrop{list} ||= [
                                                 map {
                                                   my $n = $_;
                                                   local $_ = $maildrop{pop}->Uidl($n); chomp;
                                                   my ($num, $id) = $_ =~ /^\s*(\d+)\s*(.*?)\s*$/;
                                                   ($n==$num) ? [ $n, $_ ] : warn "Server is on drugs: message number for message number $n is $num?"
                                                 } 1..$maildrop{count}
                                                ]};
  } else {
    warn "msglist received unmatching username, $username versus $maildrop{user}\n" if $debug;
    return undef;
  }
}

sub msgnumber {
  # returns the message number for a given msgid.
  my ($msgid) = @_;
  # Ensure that maildrop{list} is populated:
  msglist unless $maildrop{list};
  warn "Finding message number for $msgid in list: " . Dumper(\$maildrop{list}) . "\n" if $debug;
  return (map { $$_[0] } grep { $$_[1] eq $msgid } @{$maildrop{list}})[0];
}

sub retrieve {
  warn "Attempting to retrieve @_\n" if $debug>1;
  my ($username, $msgid) = @_;
  my $num = msgnumber($msgid);
  warn "Attempting to retrieve message (#$num) from server\n" if $debug;
  if ($num) {
    my $msg = $maildrop{pop}->Retrieve($num);
    warn "Got it: $msg\n" if $debug>1;
    $msg =~ s/\r+\n/\n/g;  $msg =~ s/^A(\n|\r)//g;
    my $now = DateTime::Format::Mail->new()->format_datetime(DateTime->now());
    return "Received: from $realserver by $0; $now\n$msg";
  } else {
    return undef;
  }
}

sub sizemsg {
  warn "Attempting to find size of @_\n" if $debug>1;
  my ($username, $msgid) = @_;
  my $num = msgnumber($msgid);
  my ($n, $s) = split('\s+', $maildrop{pop}->List($num));
  warn "Returning $s as size for message $num ($msgid)\n" if $debug;
  return $s;
}

sub delmsg {
  warn "Attempting to delete @_\n" if $debug>1;
  my ($username, $msgid) = @_;
  my $num = msgnumber($msgid);
  warn "Instructing server to delete message number $num ($msgid)\n" if $debug;
  return $maildrop{pop}->Delete($num);
  # Note that we don't need to supply reset and so forth, because
  # Net::Server::POP3 handles that stuff and only calls our delete
  # callback when actual deletion should occur.  We do need to issue a
  # QUIT upon disconnect.
}

sub discon {
  warn "Disconnecting\n" if $debug;
  $maildrop{pop}->Close(); # Exits gracefully, deleting from the server any deleted messages.
}
