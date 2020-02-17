##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::User - manage users, preferences and access rights

=head1 SYNOPSIS

 use PApp::User;

=head1 DESCRIPTION

This module helps administrate users and groups (groups are more commonly
called "access rights" within PApp). Wherever a so-called "group" or
"access right" is required you can either use a string (group name) or a
number (the numerical group id).

Both usernames and group names must be valid XML-Names (this might or
might not be enforced).

=cut

package PApp::User;

use Convert::Scalar ();

use PApp::SQL;
use PApp::Exception qw(fancydie);
use PApp::Callback ();
use PApp::Config qw(DBH $DBH); DBH;
use PApp::Event ();
use PApp qw($userid *state getuid);

use base Exporter;

$VERSION = 2.2;
@EXPORT = qw( 
   authen_p access_p

   grant_access revoke_access find_access

   grpid
);

DBH;

sub PAPP_USER_MAX_CACHE (){ 1000 }

=head2 Functions

=over 4

=cut

=item grpid grpname-or-grpid

Return the numerical group id of the given group.

=cut

sub grpid($) {
   $gid_cache{$_[0]} ||= 
       ($_[0] > 0
          ? $_[0]
          : sql_fetch $DBH, "select id from grp where name = ?",
                       "$_[0]") || -1;
}

my %access_cache;
my @access_cache; # "splay-lru"(tm) ;^>

PApp::Event::on papp_user => sub {
   shift; # skip event_type
   delete $access_cache{$_} for @_;
};

# get access info from database
sub _fetch_access() {
   delete $access_cache{shift @access_cache}
      while @access_cache > PAPP_USER_MAX_CACHE;

   my $st = sql_exec $DBH, \my($name),
                     "select name
                      from usergrp inner join grp
                           on usergrp.grpid = grp.id
                      where userid = ?",
                     $userid;

   push @access_cache, $userid;

   undef $access_cache{$userid}{$name} while $st->fetch;

   $access_cache{$userid};
}

=item authen_p

Return true when the user has logged in ("authenticitated herself") using
this module

=cut

sub authen_p() {
   $state{papp_auth};
}

=item access_p $grp

Return true when the user has the specified access right (and is logged
in!). This function checks first for the given global access right and
then for the app-specific access right of the same name (by prepending
<appname>\x00 to the name).

=cut

sub access_p($) {
   my $access = $access_cache{$userid} || _fetch_access;
   $state{papp_auth}
      and (exists $access->{$_[0]} or exists $access->{"$papp::papp->{name}\000$_[0]"});
}

=item enum_access [$uid]

Return all access rights of the logged-in (or specified) user.

=cut

sub enum_access {
   die "enum_access NYI";
}

=item grant_access [$userid, ]accessright

Grant the specified access right to the logged-in (or specified) user.

=cut

sub grant_access($;$) {
   my $uid = @_ > 1 ? shift : getuid;
   my $right = shift;
   if (authen_p) {
      sql_exec $DBH, "replace into usergrp values (?, ?)", $uid, grpid $right;
      PApp::Event::broadcast papp_user => $uid;
   } else {
      fancydie "Internal error", "grant_access was called but no user was logged in";
   }
}

=item revoke_access [$userid, ]accessright

Revoke the specified access right to the logged-in (or specified) user.

=cut

sub revoke_access($;$) {
   my $uid = @_ > 1 ? shift : getuid;
   my $right = shift;
   if (authen_p) {
      sql_exec $DBH, "delete from usergrp where userid = ? and grpid = ?", $uid, grpid $right;
      PApp::Event::broadcast papp_user => $uid;
   } else {
      fancydie "Internal error", "revoke_access was called but no user was logged in";
   }
}

=item find_access $accessright

Find all users (uid's) with the given access right.

=cut

sub find_access {
   sql_fetchall $DBH, "select userid from usergrp where grpid = ?", grpid $_[0];
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

