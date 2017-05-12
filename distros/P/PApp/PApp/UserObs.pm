##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::UserObs - manage user and access rights

=head1 SYNOPSIS

 use PApp::UserObs;
 # this module is obsolete

=head1 DESCRIPTION

This is an obsolete module. See also the L<PApp::User> module for additional documentation.

=cut

package PApp::UserObs;

use PApp::SQL;
use PApp::Exception qw(fancydie);
use PApp::Callback ();
use PApp::Config qw(DBH $DBH); DBH;
use PApp qw(*state $userid getuid);
use PApp::Prefs;
use PApp::Event ();

use base Exporter;

$VERSION = 2.1;
@EXPORT = qw( 
   authen_p access_p admin_p known_user_p update_username choose_username
   update_password update_comment username user_login user_logout userid
   SURL_USER_LOGOUT user_delete grant_access revoke_access verify_login
   newgrp rmgrp user_create find_access

   grpid grpname
);

use Convert::Scalar ();

use PApp::User qw(
      
      authen_p access_p grant_access revoke_access
      find_access grpid

);

sub grpid($);

=head2 Functions

=over 4

=item admin_p

Return true when user has the "admin" access right.

=cut

sub admin_p() {
   access_p "admin";
}

=item known_user_p [access]

Check wether the current user is already known in the access
database. Returns his username (login) if yes, and C<undef> otherwise.

If the optional argument C<access> is given, it additionally checks wether
the user has the given access right (even if not logged in).

=cut

sub known_user_p(;$) {
   my $user = $PApp::prefs->get("papp_username");
   if (@_) {
      (sql_exists $DBH, "usergrp where userid = ? and grpid = ?",
                  $userid, grpid shift) ? $user : undef;
   } else {
      $user;
   }
}

=item update_username [$userid, ]$user

Change the login-name of the current user (or the user with id $userid)
to C<$user> and return the userid. If another user of that name already
exists, do nothing and return C<undef>. (See C<choose_username>).

=cut

sub update_username($;$) {
   my $uid = @_ > 1 ? shift : getuid;
   my $user = Convert::Scalar::utf8_upgrade "$_[0]";
   lockprefs {
      if ($PApp::prefs->find_value(papp_username => $user)) {
         undef $uid;
      } else {
         $PApp::prefs->user_set($uid, papp_username => $user);
      }
   };
   $uid;
}

=item choose_username $stem

Guess a more-or-less viable but very probable unique username from the
stem given. To create a new username that is unique, use something like
this pseudo-code:

   while not update_username $username; do
      $username = choose_username $username
   done

=cut

sub choose_username($) {
   my $stem = $_[0];
   my $id;
   for(;;) {
      my $user = Convert::Scalar::utf8_upgrade $stem.$id;
      if (!$PApp::prefs->find_value(papp_username => $user)) {
         return $user;
      }
      $id += 1 + int rand 20;
   }
}

=item update_password $pass

Set the (non-crypted) password of the current user to C<$pass>. If
C<$pass> is C<undef>, the password will be deleted and the user cannot
log-in using C<verify_login> anymore. This is not the same as an empty
password, which is just that: a valid password with length zero.

=cut

sub update_password($) {
   my ($pass) = @_;
   Convert::Scalar::utf8_off Convert::Scalar::utf8_upgrade "$pass";
   $pass = defined $pass
              ? crypt $pass, join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64]
              : "";
   $PApp::prefs->set(papp_password => $pass);
}

=item update_comment $comment

Change the comment field for the current user by setting it to C<$comment>.

=cut

sub update_comment($) {
   $PApp::prefs->set(papp_comment => $_[0]);
}

=item username [$userid]

Return the username of the user with id C<$userid> or of the current user,
if no arguments are given.

=cut

sub username(;$) {
   $PApp::prefs->user_get(@_ ? $_[0] : $userid, "papp_username");
}

=item userid $username

Return the userid associated with the given user.

=cut

sub userid($) {
   $PApp::prefs->find_value(papp_username => $_[0]);
}

=item $uid = user_create

Creates a new anonymous user and returns her user-id.

=cut

sub user_create() {
   $PApp::st_newuserid->execute;
   sql_insertid $PApp::st_newuserid;
}

=item user_login $userid[, $level]

Log out the current user, switch to the userid C<$userid> and
UNCONDITIONALLY FETCH ACCESS RIGHTS FROM THE USER DB. For a safer
interface using a password, see C<verify_login>.

If the C<$userid> is zero creates a new user without any access rights but
keeps the state otherwise unchanged. You might want to call C<save_prefs>
to save the user preferences (for the current application only, the other
preferences currently are discarded).

The C<$level> argument can be used to differentiate between various
levels of certainty (1 == http-password, 3 = tls-password, 4 =
tls-certificate). The default is 1.

=cut

sub user_login($;$) {
   user_logout;
   PApp::switch_userid $_[0];
   $state{papp_auth} = $_[1] || 1;
}

=item user_logout

Log the current user out (remove any access rights fromt he current
session).

=cut

sub user_logout() {
   delete $state{papp_auth};
}

my $surl_logout_cb = PApp::Callback::create_callback {
   &user_logout;
} name => "papp_logout";

=item SURL_USER_LOGOUT

This surl-cookie (see C<PApp::surl> logs the user out (see C<user_logout>)
when the link is followed.

=cut

sub SURL_USER_LOGOUT (){ $surl_logout_cb }

=item user_delete $userid

Deletes the given userid from the system, i.e. the user with the given ID
can no longer log-in or do useful things. Other sessions using this userid
will get errors, so don't use this function lightly.

=cut

sub user_delete(;$) {
   my $uid = shift || getuid;
   user_login 0 if $userid == $uid;
   sql_exec $DBH, "delete from usergrp where userid = ?", $uid;
   sql_exec $DBH, "delete from prefs where uid = ?", $uid;
}

=item verify_login $user, $pass

Try to login as user $user, with pass $pass. If the password verifies
correctly, switch the userid (if necessary), add any access rights and
return true. Otherwise, return false and do nothing else.

Unlike the unix password system, empty password fields (i.e. set to undef)
never log-in successfully using this function.

=cut

sub verify_login($$) {
   my ($user, $pass) = @_;
   Convert::Scalar::utf8_off Convert::Scalar::utf8_upgrade "$pass";
   my $userid = userid $user;
   if ($userid) {
      my $xpass = $PApp::prefs->user_get($userid, "papp_password");
      Convert::Scalar::utf8_off $xpass;
      if ($xpass ne "" and $xpass eq crypt $pass, substr($xpass,0,2)) {
         user_login $userid;
         return 1;
      }
   }
   sleep 1;
   return 0;
}

=item grpname $gid

Return the group name associated with the given id.

=cut

sub grpname($) {
   sql_fetch $DBH, "select name from grp where id = ?", $_[0];
}

=item newgrp $grpname, $comment

Create a new group with the given name, updates the comment only if the
group already exists.

=cut

sub newgrp($;$) {
   my ($grp, $comment) = @_;
   eval {
      local $SIG{__DIE__};
      sql_exec $DBH, "insert into grp (name, comment) values (?, ?)",
               "$grp", "$comment";
   };
   if ($@) {
      my $st = sql_exec $DBH, "update grp set comment = ? where name = ?", $comment, $grp;
      $st->rows == 1 or die;
   }
}

=item rmgrp $group

Delete the group with the given name.

=cut

sub rmgrp($) {
   sql_exec $DBH, "delete from usergrp where grpid = ?", grpid $_[0];
   sql_exec $DBH, "delete from grp where id = ?", grpid $_[0];
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

