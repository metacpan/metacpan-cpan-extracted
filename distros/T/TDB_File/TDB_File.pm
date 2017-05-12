package TDB_File;

use 5.006;
use strict;
use warnings;
use Errno;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = (flags => [ qw(TDB_REPLACE
				  TDB_INSERT
				  TDB_MODIFY
				  TDB_DEFAULT
				  TDB_CLEAR_IF_FIRST
				  TDB_INTERNAL
				  TDB_NOLOCK
				  TDB_NOMMAP
				  TDB_CONVERT
				  TDB_BIGENDIAN
				 ) ],
		    error => [ qw(TDB_SUCCESS
				  TDB_ERR_CORRUPT
				  TDB_ERR_IO
				  TDB_ERR_LOCK
				  TDB_ERR_OOM
				  TDB_ERR_EXISTS
				  TDB_ERR_NOLOCK
				  TDB_ERR_LOCK_TIMEOUT
				  TDB_ERR_NOEXIST
				 ) ] );

our @EXPORT_OK;
Exporter::export_ok_tags(qw(flags error));

Exporter::export_tags(qw(flags error));

$EXPORT_TAGS{all} = \@EXPORT_OK;

our $VERSION = '0.96a';

sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.

  my $constname;
  our $AUTOLOAD;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  if ($constname eq 'constant') {
    require Carp;
    Carp::croak("&TDB_File::constant not defined");
  }
  my ($error, $val) = constant($constname);
  if ($error) { require Carp; Carp::croak($error) }
  {
    no strict 'refs';
    # Fixed between 5.005_53 and 5.005_61
    # or not?
    #if ($] >= 5.00561) {
    #  *$AUTOLOAD = sub () { $val };
    #}
    #else {
    *$AUTOLOAD = sub { $val };
    #}
  }
  goto &$AUTOLOAD;
}

bootstrap TDB_File $VERSION;

1;
__END__

=head1 NAME

TDB_File - Perl access to the trivial database library

=head1 SYNOPSIS

  use TDB_File;

  # tie interface
  tie %hash, 'TDB_File', $filename, TDB_DEFAULT, O_RDWR, 0664;
  $hash{key} = 'value';
  while (my ($k,$v) = each %hash) { print "$k -> $v\n" }

  # OO interface
  my $tdb = TDB_File->open($filename, TDB_CLEAR_IF_FIRST) or die $!;
  $tdb->store(key => 'value') or die $tdb->errorstr;
  $tdb->traverse(sub { print "$_[0] -> $_[1]\n" });

=head1 DESCRIPTION

TDB is a simple database similar to gdbm, but allows multiple
simultaneous writers.

TDB_File provides a simple C<tie> interface, similar to DB_File and
friends; and an object-oriented interface, which provides access to
all of the functions in the tdb library.

=head2 FUNCTIONS

=over 4

=item TDB_File-E<gt>open(FILE [, TDB_FLAGS [, OPEN_FLAGS [, MODE [, HASH_SIZE [, LOG_FN [, HASH_FN]]]]]])

TDB_File constructor. Opens FILE and returns a TDB_File object. The
same arguments may be passed to the C<tie> function. On error, C<$!>
is set and C<undef> is returned.

See tdb_open(3) for the meanings and possible values of TDB_FLAGS and
HASH_SIZE.

OPEN_FLAGS and MODE are standard open(3) options. In perl, the
relevant constants may be imported from L<the Fcntl module|Fcntl>.

LOG_FN is a coderef or the name of a function to be called when this
TDB object encounters errors. See L</$tdb-E<gt>logging_function(SUB)>.

HASH_FN is a coderef or the name of a function to be called to
generate key hashes.  This argument is unsupported in some TDB
libraries and will generate a Perl warning when this arg is specified.
B<NB:> See L</BUGS> for a limitation in the current implementation.

Each argument except FILE has a reasonable default and may be omitted,
so these two function calls are identical:

 TDB_File->open('foo.tdb');
 TDB_File->open('foo.tdb', TDB_DEFAULT, O_RDWR|O_CREAT, 0666,
                0, undef, undef);

B<Note> that the HASH_SIZE argument appears in a different position
than in the C tdb_open(3) function.

There is no explicit close function. The database is closed implicitly
when there are no remaining references.

=item $tdb-E<gt>store(KEY, VALUE [, FLAG])

Store VALUE in the database with key KEY. FLAG defaults to
TDB_REPLACE, see tdb_store(3) for other values.

On failure, a perl false is returned. See L</$tdb-E<gt>error> and
L</$tdb-E<gt>errorstr> for the reason.

=item $tdb-E<gt>fetch(KEY)

Fetch the value associated with KEY, or C<undef> if it is not found.

=item $tdb-E<gt>delete(KEY)

Delete the value associated with KEY.

On failure, a perl false is returned. See L</$tdb-E<gt>error> and
L</$tdb-E<gt>errorstr> for the reason.

=item $tdb-E<gt>exists(KEY)

Return true if the KEY is found, false otherwise.

=item $tdb-E<gt>firstkey

Return the key of the first value in the database. Returns C<undef> on
failure or if there are no keys in the database. See tdb_firstkey(3)
for details.

=item $tdb-E<gt>nextkey(LASTKEY)

Return the next key in the database after LASTKEY. Returns C<undef> on
failure or if there are no more keys in the database. See
tdb_nextkey(3) for details.

=item $tdb-E<gt>error

Returns the current error state of the C<$tdb> object. See the list of
error codes given in L<Exportable constants>.

=item $tdb-E<gt>errorstr

Returns a printable string that describes the error state of the
database.

=item $tdb-E<gt>reopen

Closes and reopens the database. Required after a
L<fork|perlfunc/fork>, if both processes wish to use the database.

B<NB:> If C<reopen> fails (returns false), then it is unsafe to call
any further methods on C<$tdb>. Thus, the only way to find out I<why>
C<reopen> failed is to use a logging function.

=item TDB_File::reopen_all

Closes and reopens all open databases. See L</$tdb-E<gt>reopen>.

B<NB:> If C<reopen_all> fails (returns false), there is no indication
of I<which> C<$tdb> objects failed or why. If you have to survive
failures, you may wish to do your own C<reopen> loop instead.

=item $tdb-E<gt>traverse(SUB)

Call SUB for each entry in the database. SUB should be a coderef or
a string giving the name of a function.

SUB is called with the key and value as arguments and should return a
true value if you wish to continue traversal.

C<traverse> returns the number of elements traversed or C<undef> on
error. If SUB is C<undef>, then this function simply counts the number
of elements.

=item $tdb-E<gt>logging_function(SUB)

Set the logging function to use when this database object encounters
errors. SUB should be a coderef or a string giving the name of a
function.

SUB is called with the severity level (an integer) and the message (a
string).

=item $tdb-E<gt>chainlock(KEY)

Locks a group of keys, returning false on error.

This is unnecessary when using L<C<fetch>|/$tdb-E<gt>fetch(KEY)>,
L<C<store>|/$tdb-E<gt>store(KEY, VALUE [, FLAG])>, etc.  See
tdb_chainlock(3).

=item $tdb-E<gt>chainunlock(KEY)

Unlock a group of keys locked by L</$tdb-E<gt>chainlock(KEY)>.

=item $tdb-E<gt>lockall

Lock an entire database, returning false on error.

=item $tdb-E<gt>unlockall

Unlock an entire database previously locked with
L</$tdb-E<gt>lockall>.

=begin removed_functions

=item $tdb-E<gt>lockkeys(KEY, ...)

Lock a list of keys, returning false on error.

=item $tdb-E<gt>unlockkeys

Unlock the keys previously locked by
L<$tdb-E<gt>lockkeys|/$tdb-E<gt>lockkeys(KEY, ...)>.

=end removed_functions

=item $tdb-E<gt>dump_all

Dump the records and freelist to STDOUT in an almost human readable
form.

=item $tdb-E<gt>printfreelist

Dump the freelist to STDOUT.

=back

=head2 EXPORT

All constants are exported by default.

=head2 Exportable constants

Individually or with the tag C<:flags>:

  TDB_REPLACE
  TDB_INSERT
  TDB_MODIFY
  TDB_DEFAULT
  TDB_CLEAR_IF_FIRST
  TDB_INTERNAL
  TDB_NOLOCK
  TDB_NOMMAP
  TDB_CONVERT
  TDB_BIGENDIAN

Individually or with the tag C<:error>:

  TDB_SUCCESS
  TDB_ERR_CORRUPT
  TDB_ERR_IO
  TDB_ERR_LOCK
  TDB_ERR_OOM
  TDB_ERR_EXISTS
  TDB_ERR_NOLOCK
  TDB_ERR_LOCK_TIMEOUT
  TDB_ERR_NOEXIST

=head1 BUGS

There is no way to survive an error during C<reopen_all>.
Unfortunately this is a limitation in the TDB C API.

Currently the hash function (if set) is set globally, so the last
logging function to be set will be used for all TDB_File objects that
specify a hash function.  This is due to a limitation in the TDB C
API.

=head1 SEE ALSO

tdb(3), L<perltie>.

=head1 AUTHOR

Angus Lees, E<lt>gus@inodes.orgE<gt>

=cut
