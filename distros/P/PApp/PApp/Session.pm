##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Session - manage session-specific data.

=head1 SYNOPSIS

 use PApp::Session;
 # see also PApp::Prefs and PApp::Env

=head1 DESCRIPTION

This module manages session-specific variables, that is, values that get
associated with all accesses within a single session. Session variables
keep their value when old states get re-requested, as opposed to state
variables that change back to their old value, and can be used for
transactions or other data that belongs to a whole session and not a
single access.

=cut

package PApp::Session;

use Compress::LZF qw(:freeze);

use PApp::SQL;
use PApp::Exception qw(fancydie);
use PApp::Callback ();
use PApp::Config qw(DBH $DBH); DBH;

use base Exporter;

$VERSION = 2.1;
@EXPORT = qw( 
   locksession
);

use Convert::Scalar ();

=head2 Functions

=over 4

=item locksession { BLOCK }

Execute the given block while the session table is locked against changes
from other processes. Needless to say, the block should execute as fast
as possible. Returns the return value of BLOCK (which is called in scalar
context).

=cut

sub locksession(&) {
   sql_fetch $DBH, "select get_lock('PAPP_SESSION_LOCK_SESSION', 60)"
      or fancydie "PApp::Session::locksession: unable to aquire database lock";
   my $res = eval { $_[0]->() };
   {
      local $@;
      sql_exec $DBH, "select release_lock('PAPP_SESSION_LOCK_SESSION')";
   }
   die if $@;
   $res;
}

=back

=head2 Methods

=over 4

=item PApp::Session::get ($key)

Return the named session variable (or undef, when the variable does not
exist).

=item PApp::Session::set ($key, $value)

Set the named session variable. If C<$value> is C<undef>, then the
variable will be deleted. You can pass in (serializable) references.

=item PApp::Session::ref ($key)

Return a reference to the session value (i.e. a L<PApp::DataRef>
object). Updates to the referend will be seen by all processes.

=cut

sub get ($) {
   sthaw sql_ufetch $DBH, "select value from session where sid = ? and name = ?",
                    $PApp::sessionid, Convert::Scalar::utf8_upgrade "$_[0]";
}

sub set ($;$) {
   if (defined $_[1]) {
      sql_exec $DBH, "replace into session (sid, name, value) values (?, ?, ?)",
               $PApp::sessionid, Convert::Scalar::utf8_upgrade "$_[0]", 
               sfreeze_cr $_[1];
   } else {
      sql_exec $DBH, "delete from session where sid = ? and name = ?",
               $PApp::sessionid, Convert::Scalar::utf8_upgrade "$_[0]";
   }
}

sub ref($) {
   require PApp::DataRef;

   \(new PApp::DataRef 'DB_row',
         database => $PApp::Config::Database,
         table    => "session", 
         key      => [qw(sid name)],
         id       => [$PApp::sessionid, $_[0]],
         utf8     => 1,
   )->{
      ["value", PApp::DataRef::DB_row::filter_sfreeze_cr]
   };
}

=back

=head1 SEE ALSO

L<PApp::Prefs>, L<PApp::Env>, L<PApp>, L<PApp::User>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

