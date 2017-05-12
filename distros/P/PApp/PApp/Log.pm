##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Log - analyze and expire the state/user databases

=head1 SYNOPSIS

 use PApp::Log;

=head1 DESCRIPTION

PApp creates a new database entry for its C<%state> hash for every new
pageview. This state entry is usually between 100-4000 bytes in size, for
an average of about 700-800 bytes, heavily depending on your application.

Clearly, the state database must be wiped clean from old states regularly.
Similarly the user database must be cleaned up from anonymous users that
didn't visit your site for a long time.

This module helps doing this, while at the same time giving you the
ability to analyze the access patterns on your site/application, for
example anonymizing and summarizing user behaviour to get the highly
needed statistics for your customers.

There are two different tasks: logging of state/user entries (as done by
C<log_state>) und cleaning the state/user database of expired entries (done
by C<expire_db>).

C<expire_db> also calls C<log_state> and is usually the function you need to
call.

=cut

package PApp::Log;

use Compress::LZF;

use PApp::Storable;
use PApp::SQL;
use PApp::Config;
use PApp::Env;

use base Exporter;

$VERSION = 2.1;
@EXPORT = qw();

=head2 Callbacks

During logging, the following callbacks will be called for the applications
that define them:

=over 4

=item expire_user $username, $comment

=item expire_state $ctime

=item for_user <BLOCK>;

Add a callback that is called for each user once before she is
removed. The callback is called with (userid, username, comment, prefs),
where C<prefs> is a hash representing the user's preferences in PApp's
internal format which will change anytime.

=item for_state <BLOCK>, [option => value...]

Add a callback that is called for each state (each unique page-view
generates one entry in the state database). The callback is called
with two hashes, the first a hash containing meta information (see below),
the second is just your standard C<%state> hash.

Contents of the meta hash:

 ctime        time this page was last viewed (unix timestamp)
 previd       parent state id
 userid       userid in effect when that state was created
 pmod         the (non-compiled) application

Additional options:

 app          call only for this application
 location     call only for this location
 module       call only for this module

You can get a reference to the location-specific C<%S> by using:

 $S = $state->{$meta->{location}};

Examples:

Define a callback that is called for every state:

   for_state {
      my ($meta, $state) = @_;
      print "STATE ",
            "APP=$meta->{pmod}{name}, ",
            "LOC=$meta->{location}, ",
            "MOD=$state->{papp_module}\n";
   };

Define a callback that's only called for applications with the name "dbedit":

   for_state {
      ...
   } app => "dbedit";

=cut

sub PAPP_LASTLOG (){ "PAPP_LASTLOG" }

my @cb_user;
my @cb_state;

sub for_user (&) {
   my $cb = shift;
   push @cb_user, $cb;
   warn "user loging has not been implemented yet!";
}

sub for_state (&;@) {
   my ($cb, %arg) = @_;
   push @cb_state, [$arg{app}, $arg{location}, $arg{module}, $cb];
}

my %pmod;

sub find_pmod($) {
   my $mntid = shift;
   unless ($pmod{$mntid}) {
      sql_fetch PApp::Config::DBH,
                \my($location, $appid, $config),
                "select location, appid, config from mount where id = ?",
                $mntid;

      sql_fetch PApp::Config::DBH,
                \my($app),
                "select app from app where id = ?",
                $appid;

      $pmod{$mntid}           = $app ? PApp::Storable::thaw decompress $app : die;
      $pmod{$mntid}{location} = $location;
      #FIXME# $config?
   }
   $pmod{$mntid};
}

# decode a state entry (id, unix_timestamp(ctime), previd, userid, state)
# into the meta and state hashes.
sub decode_state {
   my $row = shift;
   my $state = PApp::Storable::thaw decompress $row->[4];
   my $pmod = find_pmod $state->{papp_mntid};
   my %meta = (
         id       => $row->[0],
         ctime    => $row->[1],
         previd   => $row->[2],
         userid   => $row->[3],
         pmod     => $pmod,
         location => $pmod->{location},
   );
   (\%meta, $state);
}

=back

=head2 Functions

=over 4

=item expire_db keepuser => <seconds>, keepstate => <seconds>, keepreguser => <seconds>.

Clean the user and state databases from old states, generating log events
for state and user-entries that expire but haven't been logged. This is
not (yet) atomic, so do not call this function concurrently.

 keepuser => <seconds> (default 60 days)
   the time after which unused anonymous users expire
 keepreguser => <seconds> (default 1 year)
   the time after which even registered users expire
 keepstate => <seconds> (default 14 days)
   the time after which unused state-entries expire
 
=cut

sub expire_db {
   my %arg = @_;
   my $now = time - 1;
   my $keepuser    = $now - ($arg{keepuser}    || 86400* 60);
   my $keepreguser = $now - ($arg{keepreguser} || 86400*365);
   my $keepstate   = $now - ($arg{keepstate}   || 86400* 14);

   local $DBH = PApp::Config::DBH;

   log_state($keepstate);

# update last seen marker.
{
  my $st = sql_exec \my($uid, $ctime), "select userid, unix_timestamp(max(ctime)) from state group by userid";
  while($st->fetch) {
       sql_exec "replace into prefs (uid, path, name, value) values (?, '', 'papp_lastvisit', ?)", $uid, $ctime;
  }
}
#blow away old states (sessions in fact)
{
  my @delstates = sql_fetchall "select sessid from state group by sessid having max(ctime) < from_unixtime(?)", $keepstate;
  scalar @delstates && sql_exec "delete from state where sessid in (".join( ",", @delstates).")";
}
#expire users...
$st = sql_exec \my($uid, $visited, $known), "select uid, value,max(grpid) from prefs left join usergrp on (uid=userid) where path='' and name='papp_lastvisit' group by uid";
while($st->fetch) {
   $known ||= 0;
   next if $visited >= ($known ? $keepreguser : $keepuser);
   sql_exec "delete from prefs where uid = ?", $uid;
   sql_exec "delete from usergrp where userid = ?", $uid if $known;
}
   
}

=item log_state

Run through the whole state database (not the user database) and log all
state entries that have not been logged before. This is not (yet) atomic,
so do not call this function concurrently.

=cut

sub log_state {
   my %arg = @_;
   my $now = time - 1;
   my $lastlog = getenv PAPP_LOG_STATE || 0;

   local $DBH = PApp::Config::DBH;
   return; #NYI

   # TODO: state loggin, NO user logging

   my $st = sql_exec "select id, unix_timestamp(ctime), previd, userid, state from state
                      where ctime > from_unixtime(?) and ctime <= from_unixtime(?)",
                     $lastlog, $upto;

   my ($app, $loc, $mod);
   
   # compile the decision logic
   my $dec = <<'EOF';
      sub {
         while (my $row = $st->fetchrow_arrayref) {
            my ($meta, $state) = decode_state ($row);
            $app = $meta->{pmod}{name};
            $loc = $meta->{location};
            $mod = $state->{papp_module};
EOF

   for (0..$#cb_state) {
      my $cb = $cb_state[$_];
      my @tst;
      push @tst, "\$app eq \"".quotemeta($cb->[0])."\"" if defined $cb->[0];
      push @tst, "\$loc eq \"".quotemeta($cb->[1])."\"" if defined $cb->[1];
      push @tst, "\$mod eq \"".quotemeta($cb->[2])."\"" if defined $cb->[2];

      $dec .= "\$cb_state[$_][3](\$meta, \$state)";
      $dec .= " if ".join(" && ", @tst) if @tst;
      $dec .= ";\n";

   }

   $dec .= <<'EOF';
         }
      }
EOF

   $dec = eval $dec;
   die if $@;
   $dec->();
   $st->finish;

   setenv PAPP_LASTLOG, $upto;
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

