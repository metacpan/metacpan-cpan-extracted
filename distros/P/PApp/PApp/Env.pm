##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Env - communicate between processes and the outside.

=head1 SYNOPSIS

 use PApp::Env;
 # See also PApp::Prefs and PApp::Session

=head1 DESCRIPTION

This module can be used to get and set some kind of "environment"
variables shared between all papp applications. When inside a PApp
environment (e.g. inside a papp program) this module uses PApp's state
database handle. Outside the module it tries to open a connection to the
database itself, so it can be used e.g. from shell script to communicate
data asynchronously to the module.

If you pass in a reference, the Storable module (L<Storable>) will be used
to serialize and deserialize it.

Environment variable names (often referred as key in this document) are
treated case-insensitive if the database allows it. The contents will be
treated as opaque binary objects (again, if the database supports it).

The only database supported by this module is MySQL, so the above is
currently true in all cases.

=over 4

=cut

package PApp::Env;

use PApp::Config qw(DBH $DBH); DBH;
use PApp::SQL;
use PApp::Exception;

use Compress::LZF ();

use base Exporter;

$VERSION = 2.3;
@EXPORT = qw(setenv getenv unsetenv modifyenv lockenv listenv);

=item setenv key => value

Sets a single environment variable to the specified value. (mysql-specific ;)

=cut

sub setenv($$) {
   sql_exec $DBH, "replace into env (name, value) values (?, ?)",
            $_[0], Compress::LZF::sfreeze_cr $_[1];
}

=item unsetenv key

Unsets (removes) the specified environment variable.

=cut

sub unsetenv($) {
   my $key = shift;
   sql_exec $DBH, "delete from env where name = ?", $key;
}

=item getenv key

Return the value of the specified environment value

=cut

sub getenv($) {
   Compress::LZF::sthaw
      sql_fetch $DBH, "select value from env where name = ?",
                $_[0];
}

=item lockenv BLOCK

Locks the environment table against modifications (this is, again,
only implemented for mysql so far), while executing the specified
block. Returns the return value of BLOCK (which is called in scalar
context).

=cut

sub lockenv(&) {
   sql_fetch $DBH, "select get_lock('PAPP_ENV_LOCK_ENV', 60)"
      or fancydie "PApp::Env::lockenv: unable to aquire database lock";
   my $res = eval {
      local $SIG{__DIE__};
      $_[0]->();
   };
   {
      local $@;
      sql_exec $DBH, "do release_lock('PAPP_ENV_LOCK_ENV')";
   }
   die if $@;
   $res;
}

=item modifyenv BLOCK key

Modifies the specified environment variable atomically by calling code-ref
with the value as first argument. The code-reference must modify the
argument in-place, e.g.:

   modifyenv { $_[0]++ } "myapp_counter";

The modification will be done atomically. C<modifyenv> returns whatever
the BLOCK returned.

=cut

sub modifyenv(&$) {
   my ($code, $key) = @_;
   my $res;
   lockenv {
      my $val = getenv $key;
      $res = $code->($val);
      setenv $key, $val;
   };
   $res;
}

=item @list = listenv

Returns a list of all environment variables (names).

=cut

sub listenv {
   sql_fetchall $DBH, "select name from env";
}

1;

=back

=head1 BUGS

 - should also support a tied hash interface.

 - setenv requires mysql (actually the replace sql command), but it's so
   much easier & faster that way.

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

