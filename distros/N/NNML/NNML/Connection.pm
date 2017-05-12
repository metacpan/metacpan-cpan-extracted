#                              -*- Mode: Perl -*- 
# Connection.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sat Sep 28 15:24:53 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Mon Mar 31 09:19:23 1997
# Language        : CPerl
# Update Count    : 331
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 

package NNML::Connection;
use NNML::Active qw($ACTIVE);
use NNML::Config qw($Config);
use Text::Abbrev;
use Time::Local;
use Socket;
use strict;
use Sys::Hostname;
use IO::Select;

require NNML::Auth;

use vars qw(%ACMD %CMD %MSG %HELP);

my $HOST = hostname;
{
  no strict;
  local *stab = *NNML::Connection::;
  my ($key,$val);
  while (($key,$val) = each(%stab)) {
    next unless $key =~ /^cmd_(.*)/;
    local(*ENTRY) = $val;
    if (defined &ENTRY) {
      $CMD{$1} = \&ENTRY;
    }
  }
}

abbrev(*ACMD, keys %CMD);

sub new {
  my $type = shift;
  my $fh   = shift;
  my $msg  = shift;
  my $self = {_fh => $fh};
  
  my $hersockaddr = $fh->peername();
  my ($port, $iaddr) = unpack_sockaddr_in($hersockaddr);
  my $peer = gethostbyaddr($iaddr, AF_INET);
  $self->{_peer}   = $peer;
  $self->{_user}   = 'nobody';
  $self->{_passwd} = '*';
  print "Connection from $peer\n";
  bless $self, $type;
  $self->msg(200, $msg);
  $self;
}

sub close {
  my $self = shift;

  $self->{_fh}->close;
}

sub dispatch {
  my $self = shift;
  my $cmd  = shift;

  print "$cmd @_\n";
  unless (exists $ACMD{$cmd}) {
    $self->msg(500);
  } else {
    if (NNML::Auth::perm($self, $ACMD{$cmd})) {
      &{$CMD{$ACMD{$cmd}}}($self, @_);
    } else {
      $self->msg(480);
    }
  }
  return $ACMD{$cmd};
}

sub msg {
  my $self = shift;
  my $code = shift;
  my $msg  = $MSG{$code} || '';
  printf("%03d $msg\r\n", $code, @_);
  $self->{_fh}->datasend(sprintf "%03d $msg\r\n", $code, @_);
}

sub end {
  my $self = shift;
  $self->{_fh}->dataend;
}

use IO::Pipe;
use IO::File;

sub output {
  my $self = shift;

  $self->{_fh}->datasend(@_);
}


sub cmd_help {
  my $self = shift;

  $self->msg(100);
  for (sort keys %CMD) {
    $self->output(sprintf("%-15s %s\r\n", $_, $HELP{$_}||''));
  }
  $self->end;
}

sub cmd_authinfo {
  my ($self, $cmd, $arg) = @_;

  if (uc($cmd) eq  'USER') {
    $self->{_user}   = $arg;
    unless (exists $self->{_passwd} and $self->{_passwd} ne '*') {
      $self->msg(381);
      return;
    }
  } elsif (uc($cmd) eq 'PASS') {
    $self->{_passwd} = $arg;
    unless (exists $self->{_user} and $self->{_user} ne 'nobody') {
      $self->msg(382);
      return;
    }
  } else {
    $self->msg(501);
    return;
  }
  
  if (NNML::Auth::check($self->{_user}, $self->{_passwd})) {
    $self->msg(281)
  } else {
    $self->msg(482);
    delete $self->{_passwd};
  }
}

sub cmd_group {
  my ($self, $groupname) = @_;
  my $group = $ACTIVE->group($groupname);

  unless ($group) {
    $self->msg(411);
    return;
  }
  my $max = $group->max;
  my $min = $group->min;

  $self->{_group}   = $group;
  $self->{_article} = $min;
  $self->msg(211, $max-$min+1, $min, $max, $groupname);
}

sub cmd_mode {
  my $self = shift;
  my $mode = uc shift;

  $self->msg(280, $mode);
}

sub cmd_quit {
  my $self = shift;
  $self->msg(205);
}

sub cmd_list {
  my $self  = shift;

  if (@_) {
    my $cmd   = shift;
    my $match = shift;
    
    if ($cmd !~ /NEWSGROUPS/) {
      $self->msg(500);
      return;
    }
    $self->msg(215);
    for ($ACTIVE->list_match($match)) {
      $self->output($_->name, "\r\n");
    }
    $self->end;
  } else {
    $self->msg(215);
    for ($ACTIVE->groups) {
      $self->output(sprintf "%s %d %d %s\r\n",
                    $_->name, $_->max, $_->min, $_->post)
    }
    $self->end;
  }
}

sub cmd_newgroups {
  my $self = shift;
  my $ltime = to_time(@_);
  
  unless (defined $ltime) {
    $self->msg(501);
    return;
  }

  $self->msg(231);
  for ($ACTIVE->newgroups($ltime)) {
     $self->output($_, "\r\n");
  }
  $self->end;
}

sub cmd_newnews {
  my $self  = shift;
  my $match = shift;
  my $ltime = to_time(@_);
  my %msgid;
  
  $self->msg(230);
  for ($ACTIVE->list_match($match)) {
    my %new = $_->newnews($ltime);
    for (keys %new) {
      $msgid{$_} ||= $new{$_};
    }
  }
  for (sort {$msgid{$a} <=> $msgid{$b}} keys %msgid) {
    $self->output($_, "\r\n");
  }
  $self->end;
}

sub cmd_xover {
  my $self = shift;
  my $parm = shift;
  my @range = ($parm =~ m/(\d+)-(\d+)/);
  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }
  my $xover = $self->{_group}->xover(@range);
  $self->msg(224);
  $self->output("$xover");
  $self->end;
}


my %FLD;

BEGIN {
  my $i;

  my @FLD = qw(ano subject from date message-id references size lines xref);

  for ($i=0;$i<@FLD;$i++) {
    $FLD{$FLD[$i]} = $i;
  }
}

sub cmd_xhdr {
  my $self = shift;
  my $fld  = shift;
  my $fno  = $FLD{lc $fld};
  my $parm = shift;
  my @range = ($parm =~ m/(\d+)-(\d+)/ || ($parm, $parm));
  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }
  my $xover = $self->{_group}->xover(@range);
  $self->msg(221, $fld);
  for (split /\n/, $xover) {
    my ($ano, $val) = (split /\t/, $_)[0,$fno];
    $val = "(none)" unless $val; 

    $self->output("$ano $val\r\n");
  }
  $self->end;
}

sub cmd_next {
  my $self = shift;
  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }
  unless ($self->{_article}) {
    $self->msg(420);
    return;
  }
  if ($self->{_article} < $self->{_group}->max) {
    $self->{_article}++;
  } else {
    $self->msg(421);
    return;
  }
  $self->msg(223, $self->{_article},
             $self->{_group}->article_by_no($self->{_article}))
}

sub cmd_last {
  my $self = shift;
  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }
  unless ($self->{_article}) {
    $self->msg(420);
    return;
  }
  if ($self->{_article} > $self->{_group}->min) {
    $self->{_article}--;
  } else {
    $self->msg(422);
    return;
  }
  $self->msg(223, $self->{_article},
             $self->{_group}->article_by_no($self->{_article}))
}

sub cmd_slave {
  my $self = shift;
  $self->{timeout} = $Config->mirror_timeout;
  $self->{slave}   = 1;
  $self->msg(202);
}

# only article number for is supported
sub cmd_stat {
  my $self = shift;
  my $ano  = shift;

  unless (defined $ano) {
    $self->msg(501);
    return;
  }
  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }
  if ($ano >= $self->{_group}->min and $ano <= $self->{_group}->max) {
    $self->{_article} = $ano;
  } else {
    $self->msg(423, $self->{_group}->name);
    return;
  }
  $self->msg(223, $self->{_article},
             $self->{_group}->article_by_no($self->{_article}))
}

sub cmd_xdelete {
  my $self = shift;
  my $ano  = shift || $self->{_article};

  unless (defined $ano) {
    $self->msg(501);
    return;
  }
  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }
  if ($self->{_group}->delete($ano)) {
    $self->msg(285);
  } else {
    $self->msg(485);
  }
}

sub cmd_xdeletegroup {
  my $self = shift;

  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }
  if ($ACTIVE->delete_group($self->{_group}->name)) {
    $self->msg(286);
  } else {
    $self->msg(486);
  }
}

sub cmd_xmovefrom {
  my $self = shift;
  my $ano  = shift || $self->{_article};

  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }

  unless ($ano) {
    $self->msg(420);
    return;
  }

  my ($head, $body) = $self->{_group}->get($ano);
  unless ($head) {
    $self->msg(423, $self->{_group}->name);
    return;
  }
  unless ($self->{_group}->delete($ano)) {
    $self->msg(285);
    return;
  }
  my ($msgid) = ($head =~ /^Message-Id:\s*(<\S+>)/m);
  $self->msg(220,$ano, $msgid);
  $self->output($head, "\n", $body);
}

sub cmd_xaccept {
  my $self = shift;

  unless ($self->{_group}) {
    $self->msg(412);
    return;
  }
  
  unless ($self->post) {
    $self->msg(440);
    return;
  }
  $self->msg(340);
  $self->accept_article(undef,$self->{_group}->name);
}

sub cmd_article { my $self = shift; $self->article('article', join ' ', @_)};
sub cmd_head    { my $self = shift; $self->article('head',    join ' ', @_)};
sub cmd_body    { my $self = shift; $self->article('body',    join ' ', @_)};
sub cmd_xdate   { my $self = shift; $self->article('date',    join ' ', @_)};

sub article {
  my ($self, $cmd, $parm) = @_;
  if (defined $parm and $parm =~ /^\s*<.*>\s*$/) {
    my ($head, $body) = article_msgid($parm);
    if ($head) {
      if ($cmd eq 'article') {
        $self->msg(220,0,$parm);
        $self->output($head, "\n", $body);
      } elsif ($cmd eq 'head') {
        $self->msg(225,0,$parm);
        $self->output($head);
      } else {
        $self->msg(222,0,$parm);
        $self->output($body);
      }
      $self->end;
    } else {
      $self->msg(430);
    }
  } else {
    unless ($self->{_group}) {
      $self->msg(412);
      return;
    }
    my $ano = $parm || $self->{_article};
    unless ($ano =~ /^\d+$/) {
      $self->msg(420);
      return;
    }

    my ($head, $body, $date) = $self->{_group}->get($ano);
    my ($msgid) = ($head =~ /^Message-Id:\s*(<\S+>)/im);

    {                           # fake nnml header
      my %ano = msgid_to_anos($msgid);
      my @newsgroups = keys %ano;
      $head =~ s/^X-nnml-groups:.*\n//mig;
      my $newsgroups = sprintf("X-nnml-groups: %s\n", join(', ', @newsgroups));
      $head .= $newsgroups;
    }
    
    if ($body) {
      $self->{_article} = $ano;
      if ($cmd eq 'article') {
        $self->msg(220,$ano, $msgid);
        $self->output($head, "\n", $body);
      } elsif ($cmd eq 'head') {
        $self->msg(225,$ano, $msgid);
        $self->output($head);
      } elsif ($cmd eq 'date') {
        $self->msg(288,$date >> 16, $date & 0xfffff, $ano, $msgid);
        return;
      } else {
        $self->msg(222,$ano, $msgid);
        $self->output($body);
      }
      $self->end;
    } else {
      $self->msg(423, $self->{_group}->name);
    }
  }
}

sub post {1;}                   # tbs

sub cmd_ihave {
  my ($self, $msgid) = @_;

  unless ($self->post) {
    $self->msg(437);
    return;
  }
  if (article_msgid($msgid)) {
    $self->msg(435);
    return;
  }
  $self->msg(335);
  $self->accept_article($msgid);
}

sub cmd_post {
  my $self = shift;

  unless ($self->post) {
    $self->msg(440);
    return;
  }
  $self->msg(340);
  $self->accept_article();
}


sub accept_article {            # $extra_group also allows overwriting
  my ($self, $msgid, $extra_group) = @_;
  my $art;

  if ($art = $self->{_fh}->read_until_dot()) {
    $art = join '', @$art;
  } else {                      # won't work?
    print "accept_article() timed out\n";
    $self->msg(441);
    return;
  }
  my $create = NNML::Auth::perm($self,'create');

  if ($self->{slave}) {
    $self->msg(spool_article($Config->spool, $art, $msgid,
                             $extra_group, $create));
  } else {
    my ($code, @msg) = inject_article($art, $msgid, $extra_group, $create);
    unless ($code =~ /^2/) {
      spool_article($Config->bad, $art, $msgid, $extra_group, $create);
    }
    $self->msg($code, @msg);
  }
}

sub spool_article {
  my ($spool, $art, $msgid, $extra_group, $create) = @_;
  my $sf    = new IO::File ">> $spool";

  if ($sf) {
    $sf->printf("$;$;$;$;\t%s\t%s\t%d\n", $msgid, $extra_group, $create);
    $sf->print($art);
    return(240);
  } else {
    return(441, "Could not spool article: $!")
  }
}

sub cmd_xunspool {               # 289 %d/%d articles unspooled
  my $self = shift;

  unless (NNML::Auth::perm($self,'create')) {
    $self->msg(480, "'Need create power'");
    return;
  }
  my ($no_art, $bad) = NNML::Server::unspool();
  $self->msg(289, $no_art, $no_art-$bad);
}

sub NNML::Server::unspool {
  my ($no_art, $bad);
  my $spool = $Config->spool;
  my $sf    = new IO::File "< $spool";

  NNML::Auth::_update();          # just for the message
  NNML::Active::_update();        # just to make sure
  if ($sf) {
    local $/  = "$;$;$;$;\t";
    my $ent;
  
    while (defined ($ent = <$sf>)) {
      chomp($ent);
      next unless $ent;
      my($ctl, $art) = split /\n/, $ent, 2;
      my ($msgid, $extra_group, $create) = split /\t/, $ctl;

      $no_art++;
      my ($code, @msg) = inject_article($art, $msgid, $extra_group, $create);
      unless ($code =~ /^2/) {
        spool_article($Config->bad, $art, $msgid, $extra_group, $create);
        $bad++;
      }
    }
    $sf->close;
    rename $spool, "$spool~"
      or warn "Could not rename '$spool': $!\n";
  }
  return($no_art, $bad);
}

sub inject_article {
  my ($art, $msgid, $extra_group, $create) = @_;
  my %head = (
              subject         => '',
              from            => '',
              date            => '',
              'message-id'    => $msgid || '',
              references      => '',
              lines           => 0,
              xref            => '',
              'x-nnml-groups' => '',
              newsgroups      => '',
             );
  my $header;

  # done by Net::Cmd now
  #$art =~ s/\.\r?\n$//;
  #$art =~ s/\r//g;
  #$art =~ s/^\.\././mg;

  my ($head, $body) = split /^$/m, $art, 2;

  my $headcopy = $head;
  $headcopy =~ s{\s*\n\s+}{ }g;    # fold continue lines
  my ($fron, %thead) = split /^(\S+):/m, $headcopy;
  for (keys %thead) {
    my $val = $thead{$_};
    $val =~ s/\s/ /;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    $head{lc $_} = $val if exists $head{lc $_};
  }
  unless ($head{lines}) {
    $head{lines} = ($body =~ m/(\n)/g);
  }
  unless ($head{'message-id'}) {
    $head{'message-id'} = sprintf "<%d\@unknown%s>", time, $HOST;
    $head .= "Message-Id: $head{'message-id'}\n";
  } else {
    $head{'message-id'} =~ s/^\s+//;
    $head{'message-id'} =~ s/\s+$//;
  }
  for (keys %head) {
    printf "%-15s %s\n", $_, $head{$_} if $head{$_};
  }
  my @newsgroups = split /,\s*/, $head{'x-nnml-groups'};
  unless (@newsgroups) {
    @newsgroups = split /,\s*/, $head{newsgroups};
  }

  my $file;
  if ($extra_group) {
    my %all = msgid_to_anos($head{'message-id'});
    @newsgroups = keys %all;
    for (@newsgroups) {
      my $any   = $newsgroups[0];
      my $group = $ACTIVE->group($any);
      my $dir   = $group->dir;
      if (-f "$dir/$all{$any}") {
        $file = "$dir/$all{$any}";
        last;
      }
    }
    push @newsgroups, $extra_group unless exists $all{$extra_group};
  }
  unless (@newsgroups) {
    return(441, "No newsgroups specified");
  }
  if (!$extra_group and article_msgid($head{'message-id'})) {
    print "POSTER lied about 'message-id'}\n";
    return(441, "alreday have $head{'message-id'}");
  }

  unless ($ACTIVE->accept_article(\%head, $head, $body, $create, $file,
                                  $extra_group,
                                  @newsgroups)) {
    return(441, "Something went wrong");
  }
  if ($extra_group) {
    my %all = msgid_to_anos($head{'message-id'});
    if ($all{$extra_group}) {
      return(287,$all{$extra_group},$extra_group);
    } else {
      return(441, "Article '$head{'message-id'}' not arrived in $extra_group");
    }
  } else {
    return(240);
  }
}

sub article_msgid {
  my $msgid = shift;
  my ($groupname);
  my %ano = msgid_to_anos($msgid);
  my @newsgroups = keys %ano;
  my ($head, $body);
  
  for $groupname (@newsgroups) {
    my $group = $ACTIVE->group($groupname);

    ($head, $body) = $group->get($ano{$groupname});
    last if defined $head;
  }
  return unless $head;
  $head =~ s/^X-nnml-groups:.*\n//mig;
  my $newsgroups = sprintf("X-nnml-groups: %s\n", join(', ', @newsgroups));
  return $head . $newsgroups, $body;
}

sub msgid_to_anos {
  my $msgid = shift;
  my $group;
  my %ano;
  for $group ($ACTIVE->groups) {
    my $ano = $group->article_by_id($msgid);
    if (defined $ano) {
      $ano{$group->name} = $ano;
    }
  }
  %ano;
}

sub cmd_xtest {
  my ($self,$msgid) = @_;
  my %anos = msgid_to_anos(@_);
  my ($grp, $ano);

  while (($grp, $ano) = each %anos) {
    printf "%s %d\n", $grp, $anos{$grp};
  }
}

sub to_time {
  my ($date, $time, $gmt) = @_;

  return unless defined $date;
  if (length($date)<8) {
    $date =~ m/^(\d\d)/;
    if ($1 > 30) {
      $date = "19$date";          # not strictly RCS 977
    } else {
      $date = "20$date";          # not strictly RCS 977
    }
  }
  unless (defined $time) {
    $time = "000000";
  }

  $date .= $time;
  my ($year,$mon,$mday,$hours,$min,$sec) =
    ($date =~ m/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/);
  return unless defined $sec;

  my $ltime;
  $mon--;
  if (defined $gmt) {
    eval { $ltime = timegm($sec,$min,$hours,$mday,$mon,$year) };
  } else {
    eval { $ltime = timelocal($sec,$min,$hours,$mday,$mon,$year)};
  }
  return if $@ ne '';
  return $ltime;
}


# read status messages
my $line;
while (defined ($line = <DATA>)) {
  chomp($line);
  my ($cmd, $msg) = split ' ', $line, 2;
  last unless $cmd;
  $HELP{$cmd} = $msg;
}
while (defined ($line = <DATA>)) {
  chomp($line);
  next unless $line =~ /^\d/;
  my ($code, $msg) = split ' ', $line, 2;
  $MSG{$code} = $msg;
}


1;

__DATA__
authinfo user Name|pass Password
article [MessageID|Number]
body [MessageID|Number]
date
group newsgroup
head [MessageID|Number]
help
ihave MessageID
last
list [active|newsgroups|distributions|schema]
listgroup newsgroup
mode reader
newgroups yymmdd hhmmss ["GMT"] [<distributions>]
newnews newsgroups yymmdd hhmmss ["GMT"] [<distributions>]
next
post
slave register as non-human. Timeout will be set to mirror_timeout
stat [MessageID|Number]
xdelete [Number] delete article in selected group
xdeletegroup delete selected group
xmovefrom [Number] delete article in selected group and deliver it
xaccept insert article in selected group
xgtitle [group_pattern]
xhdr header [range|MessageID]
xover [range]
xpat header range|MessageID pat [morepat...]
xpath xpath MessageID

100 help follows
200 NNML server %s ready - posting allowed
201 NNML server %s ready - no posting allowed
202 slave status noted
205 closing connection - goodbye!
211 %d %d %d %s group selected
215 list of newsgroups follows
220 %d %s article retrieved - head and body follow
221 %s  fields follows
222 %d %s article retrieved - body follows
223 %d %s article retrieved - request text separately 230 list of new articles by message-id follows
224 overview follows
225 %d %s article retrieved - head follows
230 list of new articles by message-id follows
231 list of new newsgroups follows
235 article transferred ok
240 article posted ok
280 mode %s noted (x)
281 Authentication accepted
285 delete article ok
286 delete group ok
287 article accepted as %d in group %s
288 %d %d date of article %d %s 
289 %d/%d articles unspooled
335 send article to be transferred.  End with <CR-LF>.<CR-LF>
340 send article to be posted. End with <CR-LF>.<CR-LF>
381 PASS required
400 service discontinued
411 no such news group
412 no newsgroup has been selected
420 no current article has been selected
421 no next article in this group
422 no previous article in this group
423 no such article number in this group '%s'
430 no such article found
435 article not wanted - do not send it
436 transfer failed - try again later
437 article rejected - do not try again.
440 posting not allowed
441 posting failed: '%s'
480 Authentication required: %s
482 Authentication rejected
482 USER required
485 delete article failed
486 delete group failed

500 command not recognized
501 command syntax error
502 access restriction or permission denied
503 program fault - command not performed
