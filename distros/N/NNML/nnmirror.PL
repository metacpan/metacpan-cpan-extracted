#!/app/unido-i06/magic/perl
#                              -*- Mode: Perl -*- 
use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($^O eq 'VMS' or $^O eq 'os2');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'} 
!GROK!THIS!
# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
#                              -*- Mode: Perl -*- 
# nnmirror -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sun Sep 29 11:50:11 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Mar 30 21:33:03 1997
# Language        : CPerl
# Update Count    : 92
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 
eval 'exec perl  -S $0 "$@"'
    if 0;
        
BEGIN {$0 = 'nnmirror ....'; }
use Getopt::Long;
use Time::Local;
use Net::NNTP ();
use NNML::Config qw($Config);
use strict;
use vars qw(%OPT);

%OPT = (
        fhost   => $Config->mirror_host,
        fpass   => $Config->remote_passwd,
        fport   => $Config->mirror_port,
        fuser   => $Config->remote_user,
        thost   => 'localhost',
        tpass   => $Config->local_passwd,
        tport   => $Config->port,
        tuser   => $Config->local_user,
       );

GetOptions(\%OPT,
           'fhost=s',
           'thost=s',
           'fport=i',
           'tport=i',
           'date=i',
           'time=i',
           'tuser=s',
           'fuser=s',
           'tpass=s',
           'fpass=s',
           'group=s@',
           'only=s',
           'ignore=s',
           'reverse!',
           'verbose!',
          ) or die;

if ($OPT{'reverse'}) {
  @OPT{qw(fhost fpass fport fuser thost tpass tport tuser)} =
    @OPT{qw(thost tpass tport tuser fhost fpass fport fuser)};
}
if ($OPT{verbose}) {
  for (keys %OPT) {
    printf "%-15s = %s\n", $_, $OPT{$_};
  }
}

my $time;
if (exists $OPT{date}) {
  $time = to_time($OPT{date}, $OPT{'time'})
} else {
  $time = time - 3600 * 24;
}

my $group;
if (exists $OPT{group}) {
  $group = join ',', @{$OPT{group}}
} else {
  $group = '*',
}

my $from = new Net::NNTP $OPT{fhost}, Port => $OPT{fport};
my $to   = new Net::NNTP $OPT{thost}, Port => $OPT{tport};

# We should care if authinfo failes?
if ($OPT{tpass}) {
  $to->authinfo($OPT{tuser}, $OPT{tpass});
}
if ($OPT{fpass}) {
  $from->authinfo($OPT{fuser}, $OPT{fpass});
}
die unless defined $from and defined $to;

$to->slave();

my $messages;

unless ($messages = $from->newnews($time, $group)) {
  unless ($messages = my_newnews($from, $time, $group)) {
    die "Could not run newnews $group $time";
  }
}

my $togo   = scalar(@$messages);
my $msgid;
my $IHAVE_ALLOWED = 1;

foreach $msgid (@$messages) {
  $togo--;
  chomp($msgid);
  next unless $msgid;           # sanity check
  next if exists $OPT{ignore} and $msgid =~ /$OPT{ignore}/o;
  next if exists $OPT{only}   and $msgid !~ /$OPT{only}/o;

  my $art;
  if ($IHAVE_ALLOWED and $to->ihave($msgid)) {
    print STDERR "$togo: FETCH $msgid";

    if ($art = $from->article($msgid)) {
      printf STDERR " %d lines ", scalar(@$art);
      $to->datasend($art);
      $to->dataend();
      print STDERR "done\n";
    } else {
      # We promised to send an article. Now we are not able to.
      # send a dummy article without 'Newsgroups:' header. The server
      # will not acept it.
      $to->datasend("head", "\n", "body");
      $to->dataend();
      printf "FAILED\n\t%s", $from->message;
    }
  } elsif ($to->postok) {
    # We are not allowed to use IHAVE :-(
    $IHAVE_ALLOWED = 0 if $to->code >= 400;
    unless ($to->head($msgid)) {
      # $to seems not to have it
      print STDERR "$togo: FETCH $msgid";

      if ($art = $from->article($msgid)) {
        # ... and we could fetch it
        printf STDERR " %d lines ", scalar(@$art);
        $to->post($art);
        print STDERR ($to->ok)?"done\n":"FAILED";
      }
    }
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

sub my_newnews {
  my($con, $time_bound, $group_pat) = @_;
  my %result;
  my @result;

  #$con->debug(1);
  require Date::Parse;

  for my $pat (split ',', $group_pat) {
    my $groups = $con->newsgroups($pat);
    for my $group (keys %$groups) {
      print "group: $group\n";
      my ($count,$min,$max) = $con->group($group);
    ARTICLE:
      while ($max > $min) {
        print "ARTICLE $max\n";
        my $date = $con->xhdr('Date', $max);
        my $time = Date::Parse::str2time($date->{$max});
        last ARTICLE if $time < $time_bound;
        my $msg  = $con->xhdr('Message-Id', $max);
        $result{$msg->{$max}}= $time;
        $max--;
      }
    }
  }
  for (sort {$result{$a} <=> $result{$b}} keys %result) {
    push @result, $_;
  }
  #$con->debug(0);
  \@result;
}
__END__


=head1 NAME

nnmirror - update an nntp server with respect to another server

=head1 SYNOPSIS

B<nnmirror>
[B<-fhost> I<hostname]
[B<-thost> I<hostname]
[B<-fport> I<port>]
[B<-tport> I<port>]
[B<-fuser> I<user>]
[B<-fpass> I<passwd>]
[B<-tuser> I<user>]
[B<-tpass> I<passwd>]
[B<-date>  I<yymmdd>]
[B<-time>  I<hhmmss>]
[B<-reverse>]
[B<-only> I<regexp>]
[B<-ignore> I<regexp>]
[B<-group> I<group expression>] ...

=head1 DESCRIPTION

B<Nnmirror> connects a B<FROM> and a B<TO> server using
B<Net::NNTP>. It asks the B<FROM> server for new articles using
the C<NEWNEWS> command. For each returned message-id, the B<TO> server
is asked using C<IHAVE>. If B<TO> wants the article, it is fetched
from B<FROM> and forwarded to B<TO>.

With respect to the configuration, the I<"normal"> oeration is polling
from a remote server. It you specify B<-reverse> the roles of the are
reversed and an upload is perlformed. For uploading to a real NNTP
server you should use the B<-only> I<regexp> option with an rexexp,
which matches the message ids your system generates.


The date/time for the B<NEWNEWS> command defaults to the current time
minus one day.

After connecting the servers, an B<AUTHHINFO> request is send if the
options B<-fpasswd> or B<-tpasswd> are given.

=head1 EXAMPLES

Assuming you are at your linux box 'C<hobbit>' at home. Your box in
the office is called 'C<sun44>', your NNTP-Server 'B<news>'. On
'C<sun44>' you have a NNML server running on port 3000 with user
'C<lwall>' passwd 'C<foo>'. On your linux box, you run the NNML server
at port 2000 without authorisation.

=head2 Fetch mail from office

  nnmirror -fhost sun44 -fport 3000 -fuser lwall -fpasswd foo \
           -thost localhost -fpasswd '' -tport 2000

=head2 Write back the carbon copies you generated

  nnmirror -fhost sun44 -fport 3000 -fuser lwall -fpasswd foo \
           -thost localhost -fpasswd '' -tport 2000 \
           -reverse -only /hhobbit/

=head2 Get some news from the NNTP server

  nnmirror -fhost news -fport 119 -fpasswd '' \
           -thost localhost -fpasswd '' -tport 2000 \
           -group comp.lang.perl.* -group \!*.misc

=head2 Forward your postings

  nnmirror -fhost news -fport 119 -fpasswd '' \
           -thost localhost -fpasswd '' -tport 2000 \
           -reverse -only /hobbit/

For real use, you may better set the right defaults during
configuration and only give the passwords n the command line.

=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@ls6.informatik.uni-dortmund.de>E<gt>




!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
