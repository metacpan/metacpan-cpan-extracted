package RWDE::Exceptions;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 515 $ =~ /(\d+)/;

=pod

=head1 RWDE::Exceptions

Exception container file, contains definitions for RWDE Exceptions

System defined exceptions are based off of the default behaviour of this base exception class

=cut

=head1 Exception class definitions for RWDE

=cut

=head2 RWDE::BaseException()
    
=cut
package RWDE::BaseException;

use strict;
use warnings;

use RWDE::DB::DbRegistry;

use base qw(Error);

use overload ('""' => 'stringify');

=head2 new()

Override for the "new" method in the Error base class, initializes the instance the way we want.

This will return an initialized instance of Error

=cut

sub new {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $info  = defined $$params{info} ? $$params{info} : 'none';
  my $value = defined $$params{value} ? $$params{info} : 'none';

  if (defined $$params{abort_transaction}) {
    RWDE::DB::DbRegistry->abort_transaction();
  }

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1;                   # Enables storing of stacktrace

  my $exception = $class->SUPER::new(-text => $info, -value => $value);

  return $exception;
}

=head2 is_retry()

Determine whether this was a retry attempt

=cut

sub is_retry {
  my ($self) = @_;

  return $self->{'-value'} =~ m/retry/ig;
}

1;

=head1 Exception class definitions for RWDE

=cut

=head2 RWDE::DevelException()

Caught with RWDE::DevelException - developer only exceptions, typically for unplanned behaviour

=cut

package RWDE::DevelException;
use base qw(RWDE::BaseException);

1;

=head2 RWDE::DataMissingException()

caught with RWDE::DataMissingException - missing data detected

=cut

package RWDE::DataMissingException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::DataBadException()

Caught with RWDE::DataBadException - Invalid data detected

=cut

package RWDE::DataBadException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::DataLimitException()

Caught with RWDE::DataLimitException -  Limit or threshold exceeded

=cut

package RWDE::DataLimitException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::DataDuplicateException()

Caught with RWDE::DataDuplicateException - Discovered duplicate data (typically db related)

=cut

package RWDE::DataDuplicateException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::DataNotFoundException()

Caught with RWDE::DataNotFoundException - Expected data does not exist

=cut

package RWDE::DataNotFoundException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::BadPasswordException()

Caught with RWDE::BadPasswordException - Problems accepting a password

=cut

package RWDE::BadPasswordException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::SSLException()

Caught with RWDE::SSLException - Problems with http SSL connections

=cut

package RWDE::SSLException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::Web::SessionMissingException()

Caught with RWDE::Web::SessionMissingException - Problem with the session occurred

=cut

package RWDE::Web::SessionMissingException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::StatusException()

Caught with RWDE::StatusException - Problem with instance status

=cut

package RWDE::StatusException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::DatabaseErrorException()

Caught with RWDE::DatabaseErrorException - Internal db problem detected

=cut

package RWDE::DatabaseErrorException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::PolicyException()

Caught with RWDE::PolicyException - Policy violation occurred

=cut

package RWDE::PolicyException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::PermissionException()

Caught with RWDE::PermissionException - Permission violation occurred

=cut

package RWDE::PermissionException;
use base qw(RWDE::BaseException);
1;

=head2 RWDE::DefaultException()

Caught with RWDE::DefaultException - Default Exception - undefined exceptions are funnelled here

=cut

package RWDE::DefaultException;
use base qw(RWDE::BaseException);
1;
