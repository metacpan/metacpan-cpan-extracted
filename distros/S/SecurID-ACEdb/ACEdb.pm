# $Id: ACEdb.pm,v 1.7 1999/01/07 19:21:36 carrigad Exp $

# Copyright (C), 1998, 1999 Enbridge Inc.

package SecurID::ACEdb;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();
@EXPORT_OK = qw(
		Result
		ApiInit
		Commit
		Rollback
		ApiEnd
		ApiRev
		AssignToken
		SetUser
		ListUserInfo
		UnassignToken
		SetCreatePin
		AddUserExtension
		DelUserExtension
		ListUserExtension
		SetUserExtension
		DisableToken
		EnableToken
		ListTokens
		ListTokenInfo
		ResetToken
		NewPin
		AddLoginToGroup
		DelLoginFromGroup
		ListGroupMembership
		ListGroups
		EnableLoginOnClient
		DelLoginFromClient
		ListClientActivations
		ListClientsForGroup
		ListClients
		ListSerialByLogin
		ListHistory
		MonitorHistory
		DumpHistory
	       );
$EXPORT_TAGS{all} = [@EXPORT_OK];
$EXPORT_TAGS{basic} = [qw(ApiInit Result ApiEnd)];
$VERSION = '0.90';

# Call a function which returns a list. For each element of the list,
# split it on / , / and assign it to a hashref using $keys as the keys
# for the hashref. Return a ref to the resulting list of hashrefs.
# Thus, assume:
#
# func returns a list containing
#
#   foo , bar , bat
#   baz , boo , fie
#   bor , fro , toe
# 
# Keys contains qw(key1 keyb keyi)
#
# Returns [{key1 => foo, keyb => bar, keyi => bat},
#          {key1 => baz, keyb => boo, keyi => fie},
#          {key1 => bor, keyb => fro, keyi => toe}]
sub _list_of_hashes {
  my $func = shift;
  my $keys = shift;
  my @result = &{$func}(@_);
  return undef unless shift @result;
  my $ret = [];
  foreach (@result) {
    my @fields = split(/ , /);
    push @{$ret}, {map {$_, shift @fields} @{$keys}};
  }
  return $ret;
}

# Calls a function which returns a single string. Splits up the string
# on the $split variable and assigns it to hashref keyed on the keys
# in the $keys variable
sub _single_hash {
  my $func = shift;
  my $keys = shift;
  my $split = shift;
  my $result;
  return undef unless $result = &{$func}(@_);
  my @fields = split(/$split/, $result);
  return {map {$_, shift @fields} @{$keys}};
}

sub ApiInit {
  if ( ! -w "." ) {
    print STDERR "Warning: current directory is not writable. Changing to writable directory.\n";
    chdir("/tmp") || die "Can't cd to /tmp: $!";
  }
  my $acehome = defined $ENV{ACEHOME}? $ENV{ACEHOME} : "/opt/SecurID/ace";
  my $varace = "$acehome/data";
  my $usrace = "$acehome/prog";
  my $dlc = "$acehome/rdbms";
  $ENV{ACEHOME} = $acehome;
  $ENV{VAR_ACE} = $varace;
  $ENV{USR_ACE} = $usrace;
  $ENV{DLC} = $dlc;
  $ENV{PROPATH} = ".,$usrace,$usrace/progui,$usrace/protrig,$usrace/proapi";
  $ENV{PROTERMCAP} = "$dlc/protermcap";
  $ENV{PROMSGS} = "$dlc/promsgs";
  my %parms = @_;
  $parms{commitFlag} = $parms{commitFlag}? 1 : 0;
  _ApiInit($parms{servDB}, $parms{logDB}, $parms{commitFlag});
}

sub ListUserInfo {
  _single_hash(\&_ListUserInfo, 
	       [qw(userNum lastName firstName defaultLogin createPIN
		   mustCreatePIN defaultShell tempUser dateStart todStart
		   dateEnd todEnd)], " \r ", @_);
}

sub ListTokenInfo {
  _single_hash(\&_ListTokenInfo, 
	       [qw(serialNum pinClear numDigits interval dateBirth todBirth dateDeath
		   todDeath dateLastLogin todLastLogin type hex enabled newPINMode
		   userNum nextTCodeStatus badTokenCodes badPINs datePIN todPIN
		   dateEnabled todEnabled dateCountsLastModified todCountsLastModified
		  )], " , ", @_);
}

sub ListGroupMembership {
  _list_of_hashes(\&_ListGroupMembership, [qw(userName shell group)], @_);
}

sub ListGroups {
  _list_of_hashes(\&_ListGroups, [qw(group siteName)], @_);
}

sub ListClientActivations {
  _list_of_hashes(\&_ListClientActivations, [qw(login shell clientName siteName)], @_);
}

sub ListClientsForGroup {
  _list_of_hashes(\&_ListClientsForGroup, [qw(clientName siteName)], @_);
}

sub ListClients {
  _list_of_hashes(\&_ListClients, [qw(clientName siteName)], @_);
}

sub MonitorHistory {
  my $file = shift;
  if (defined $file) {
    my $close = shift;
    $close = $close? "-c" : "";
    _MonitorHistory($file, $close);
  }
}

sub ListSerialByLogin {
  my $serial = _ListSerialByLogin(@_);
  return undef unless defined $serial;
  if ($serial eq "Done") {
    return [];
  } else {
    my @serial = split(/ , /, $serial);
    pop @serial;
    return [@serial];
  }
}

sub ListHistory {
  my($days, $token, $filt) = @_;
  $filt = 0 unless defined $filt;
  $filt = $filt? "-f no_admin" : "-f all";
  _list_of_hashes(\&_ListHistory, 
		  [qw(msgString localDate localTOD login
		      affectedUserName groupName clientName
		      siteName serverName messageNum)],
		  $days, $token, $filt);
}

bootstrap SecurID::ACEdb $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SecurID::ACEdb - Perl extension to use the ACE/Server Administration Toolkit API

=head1 SYNOPSIS

  use SecurID::ACEdb qw(:basic func1 func2 ...)
  use SecurID::ACEdb qw(:all);
  ApiInit();
  ...
  ApiEnd();

=head1 DESCRIPTION

The ACE/Server Administration Toolkit API is used to create custom
administration applications for ACE/Server, specifically functions that
can read and modify the ACE/Server databases.

=head1 FUNCTIONS

All functions must be explicitly imported into the namespace. The import
tag B<basic> imports I<ApiInit>, I<ApiEnd>, and I<Result>. The import
tag B<all> imports all functions. 

Unless otherwise documented, all function calls return 1 if the function
succeeded, 0 otherwise.

=head2 Result

  $result = Result();

Returns the result of the last operation as a string. This should be
called whenever any function fails to determine the cause of the
failure.

=head2 ApiInit

  ApiInit([commitFlag => v]);

Initializes and connects to the ACE/Server databases. This is required
before subsequent C<SecurID::ACEdb> functions can be called. The
C<commitFlag> should be set to true to automatically commit database
changes. If not set, then the C<Commit> and C<Rollback> functions can
be used to define transactions. I<This function can only be called
once in any program. It cannot even be called a second time after
calling C<ApiEnd>>. Don't blame me; blame Security Dynamics.

=head2 Commit

  Commit();

Commits all API function calls to the database since the last commit
or rollback. Only needed if C<ApiInit> was not called with a
C<commitFlag> of true.

=head2 Rollback

  Rollback();

Rolls back all API function calls since the last commit or rollback.
Only needed if C<ApiInit> was not called with a C<commitFlag> of true.

=head2 ApiEnd

  ApiEnd();

Finishes the API session. Once this function is called, no subsequent
API functions can be called, I<including C<ApiInit>>.

=head2 ApiRev

  $rev = ApiRev()

Returns the revision number of the API, as a string.

=head2 AssignToken

  AssignToken($lastname, $firstname, $login, $shell, $serial);

Adds a user to the database and assigns the token specified by
C<$serial>. The token is enabled, the PIN is cleared, and both
BadTokenCodes and BadPINs are set to zero.

=head2 SetUser

  SetUser($lastname, $firstname, $login, $shell, $serial);

Sets an existing user's information as specified by the parameters.
The token serial number is used to locate the user in the database, so
this function cannot be used to change a user's token.

=head2 ListUserInfo

  $userinfo = ListUserInfo($serial);

Returns user information for a user who owns the specified token. The
user information is returned in a hashref which contains the keys
I<userNum>, I<lastName>, I<firstName>, I<defaultLogin>, I<createPIN>,
I<mustCreatePIN>, I<defaultShell>, I<tempUser>, I<dateStart>,
I<todStart>, I<dateEnd>, and I<todEnd>. Returns C<undef> if there was
an error.

=head2 UnassignToken

  UnassignToken($serial)

Unassigns the token and deletes the user from the database. The user
must be removed from all groups and not be enabled on any clients
before calling this function.

=head2 SetCreatePin

  SetCreatePin($state, $serial);

Sets the createPIN modes for the user related to C<$serial>. C<$state>
should be a string containing one of the values I<USER>, I<SYSTEM>, or
I<EITHER>.

=head2 AddUserExtension

  AddUserExtension($key, $data, $serial);

Adds a user extension record for the user related to C<$serial>. The
data field can be no more than 80 characters, while the key field must
be no more than 48 characters. 

=head2 DelUserExtension

  DelUserExtension($key, $serial);

Deletes a user extension record for the user related to C<$serial>. 

=head2 ListUserExtension

  $ext = ListUserExtension($key, $serial);

Returns the user extension data for the specified key of the user
related to C<$serial>. Returns C<undef> if there was an error. 

=head2 SetUserExtension

  SetUserExtension($key, $data, $serial);

Sets data in an existing extension field for the user related to
C<$serial>.

=head2 DisableToken

  DisableToken($serial);

Disables the token so that the related user cannot authenticate.

=head2 EnableToken

  EnableToken($serial);

Enables the token so that the related user can authenticate.

=head2 ListTokens

  @list = ListTokens();

Returns a list of all tokens in the database, or an empty list if
there was an error. Note that the underlying C API requires this
function to be called multiple times to get the entire list; the Perl
version does not require this. If a call to the function other than
the first results in an error, C<ListTokens> will return a partial
list, and will not notify the caller of any error condition. The
caller should examine the value of C<Result()>; if it is not I<Done>,
then the entire list was not returned.

=head2 ListTokenInfo

  $info = ListTokenInfo($serial);

Returns a hashref containing token information, or C<undef> if there
was an error. The hashref contains the keys I<serialNum>,
I<pinClear>, I<numDigits>, I<interval>, I<dateBirth>, I<todBirth>,
I<dateDeath>, I<todDeath>, I<dateLastLogin>, I<todLastLogin>, I<type>,
I<hex>, I<enabled>, I<newPINMode>, I<userNum>, I<nextTCodeStatus>,
I<badTokenCodes>, I<badPINs>, I<datePIN>, I<todPIN>, I<dateEnabled>,
I<todEnabled>, I<dateCountsLastModified>, and I<todCountsLastModified>.

=head2 ResetToken

  ResetToken($serial);

Resets the token to a known state, so that the token is enabled, next
token code mode is off, bad token codes is zero, and bad PINs is zero.
This should be done before assigning the token to a user or to remedy
token problems.

=head2 NewPin

  NewPin($serial)

Puts the token into new PIN mode.

=head2 AddLoginToGroup

  AddLoginToGroup($login, $group, $shell, $serial);

Adds the user login to a group in the database. The group must exist
and the login must be unique to the group. The shell can be an empty
string.

=head2 DelLoginFromGroup

  DelLoginFromGroup($login, $group);

Deletes the login name from a group.

=head2 ListGroupMembership

  $groups = ListGroupMembership($serial);

Lists the groups that a token has been assigned to. Returns a listref
or C<undef> if there was a problem. Each element of the list is a
hashref containing the keys I<userName>, I<shell>, and I<group>.

=head2 ListGroups

  $groups = ListGroups();

Lists the groups in the ACE/Server database. Returns a listref or
C<undef> if there was a problem. Each element of the list is a hashref
containing the keys I<group> and I<siteName>.

=head2 EnableLoginOnClient

  EnableLoginOnClient($login, $client, $shell, $serial);

Enables a user login on a client. The client must exist and the login
must be unique to the client. The shell can be an empty string.

=head2 DelLoginFromClient

  DelLoginFromClient($login, $client);

Disables a user login from a client.

=head2 ListClientActivations

  $list = ListClientActivations($serial);

Lists the clients that a token is activated on. Returns a listref or
C<undef> if there was an error. Each element of the list is a hashref
containing the keys I<login>, I<shell>, I<clientName>, and I<siteName>.

=head2 ListClientsForGroup

  $list = ListClientsForGroup($group);

Lists the clients associated with a group. Returns a listref or
C<undef> if there was a problem. Each element of the list is a hashref
containing the keys I<clientName> and I<siteName>.

=head2 ListClients

  $list = ListClients();

Returns a list of all clients in the database. Returns a listref or
C<undef> if there was a problem. Each element of the list is a hashref
containing the keys I<clientName> and I<siteName>.

=head2 ListSerialByLogin

  @serial = ListSerialByLogin($login, [$count]);

Looks up the token serial number belonging to the user with login name
C<$login>. C<$count> specifies which instance of C<$login> to use if
there are multiple instances, and defaults to 1. Returns a listref to
the serial numbers assigned to C<$login>. Returns an empty listref if
the user does not exist, or if the count was too high, and returns
C<undef> if there was another error.

=head2 ListHistory

  $hist = ListHistory($days, $serial, [$filter]);

Lists the events in the activity log affecting token C<$serial>.
C<$days> specifies the number of days prior to the present date to
list the history for. If C<$filter> is true, events performed by an
administrator will be filtered from the list, making it easier to view
authentication events. Returns a listref or C<undef> if there was a
problem. Each element of the list is a hashref containing the keys
I<msgString>, I<localDate>, I<localTOD>, I<login>,
I<affectedUserName>, I<groupName>, I<clientName>, I<siteName>,
I<serverName>, and I<messageNum>.

=head2 MonitorHistory

  MonitorHistory([$filename, [$close]]);

Docs tbd.

=head2 DumpHistory

  DumpHistory($month, $day, $year, [$days, [$filename, [$truncate]]]);

Dumps the affected events in the log. If C<$filename> is provided,
specifies a filename to dump the log to. C<$filename> can also be the
empty string. The affected events start at the beginning of the log
and end one day prior to the date specified by the C<$month>, C<$day>,
and C<$year> parameters. C<$year> should be a 4-digit number. If the
C<$days> parameter is non-zero, then the first three parameters are
ignored, and the C<$days> parameters specifies the number of days
prior to today's date that are not affected. If the C<$truncate>
option is set, the entries will be removed from the log.

=head1 AUTHOR

Dave Carrigan <Dave.Carrigan@cnpl.enbridge.com>

=head1 SEE ALSO

perl(1).

=cut
