#!/usr/bin/perl -w -T

our $debug = 1; $|++; use Data::Dumper; # Yes, it's that alpha.
use strict; use warnings;

BEGIN { push @INC, "/home/mailproxy/lib"; } # You can comment this out if you install Net::Server::POP3 in a normal place.

use Net::Server::POP3;
use DateTime; use DateTime::Format::Mail;

my @inbox = ();
my $serv = Net::Server::POP3->new
  (
   serveropts => +{
                   user      => 'mailproxy',
                   group     => 'nobody',
                   log_level => 3,
                  },
   authenticate => sub {
     my ($user, $pass, $ip) = @_;
     my %user = ( testuser => 'testpass',
                  jonadab  => 'jonadab',
                );
     if ($user{$user} eq $pass) {
       if (not @inbox) {
         push @inbox, newmessage($user, $ip);
       }
       return 1;
     } else { return 0; }
   },
   list => sub {
     my ($username) = @_;
     return map { $$_[0] } @inbox;
   },
   retrieve => sub {
     warn "Attempting to retrieve @_\n" if $debug;
     my ($username, $msgid) = @_;
     warn "retrieve using inbox:\n".Dumper(\@inbox)."\n" if $debug;
     my @l = grep { $$_[0] eq $msgid } @inbox;
     warn "retrieve found matching messages: " . Dumper(\@l) . "\n" if $debug;
     my $msg = $l[0][1];
     warn "$msg\n" if $debug;
     return $msg;
   },
   size => sub {
     warn "Attempting to find size of @_\n" if $debug;
     my ($username, $msgid) = @_;
     my $msg = (grep {$$_[0] eq $msgid } @inbox)[0];
     warn "Found message: ".Dumper(\$msg)."\n" if $debug;
     my $len = length $$msg[1];
     warn "simpletest:  message $msgid has no size:\n" . Dumper(\$msg) . "\n" unless $len;
     warn "Found size:  $len\n" if $debug;
     return $len;
   },
  );

my $newmsgnum;
sub newmessage {
  ++$newmsgnum;
  my ($username, $ip) = @_;
  my $dt = DateTime->now();
  #my $stamp = sprintf "%04d%02d%02d%02d%02d%02d$username$newmsgnum%07d",
  #  $dt->year(), $dt->month(), $dt->day(), $dt->hour(), $dt->min(), $dt->sec(), int rand 7777777;
  my $stamp = sprintf "%04d%02d%02d%02d%02d%02d$username%05d%07d",
    $dt->year(), $dt->month(), $dt->day(), $dt->hour(), $dt->min(),
      $dt->sec(), $newmsgnum, int rand 7777777;
  my $dateheader = DateTime::Format::Mail->format_datetime($dt);
  my $newmsgid = "testmsg$stamp\@test.jonadab.homeip.net";
  my $newmsgtext = <<"MESSAGE";
Received: from /dev/random by simpletest.pl
From: test\@localhost
To: $username\@localhost
Precedence: bulk
Message-ID: $newmsgid
Subject: Testing...
Content-Type: text/plain; charset=us-ascii
Date: $dateheader

This is a test.  This is only a test.  If this had been an
actual email message, it would have contained useful
information (well, maybe; anyway, it hopefully wouldn't have
rambled on like this about being a test).  This is test
message number $newmsgnum for this test server run.  This
concludes this test.

Incidentally, your IP address appears to be $ip

-- 
GCS(M)>AT d+(?) s? a- C+++ UL(-) P+++>++++ L++ E++ W+(-)@
N++@ o? w(--) O> M-(X+) V(++) PS---- PE+ Y(--) PGP- t+@ !5
!X R- !tv---->? b+(+++) DI UF+ D--- G e++(*) h* !r !y-

P++ c--- P6 R++ M>+ O MA++ E PU BD@ C-(M+) D>+ S++ X WP++
MO! PP! n-() CO! PO-- o+++ G++ OLC-- OLCC--- OLCO--- OLP--
OLL++ OLA+ Ee++ Ev-->++ Eon! uL++>+ w-() m! osBE++
MESSAGE
  return [$newmsgid, $newmsgtext];
}

$serv->startserver();


