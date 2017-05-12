#!/usr/bin/perl

package RT::Extension::SMSNotify::OnShift;

use 5.10.1;
use strict;
use warnings;
use DateTime;

use RT::Extension::SMSNotify::Shifts;

=head1 NAME

 RT::Extension::SMSNotify::IsOnShift

=head1 DESCRIPTION

An example that uses a 'ShiftCode' custom field on users to look shift
definitions up from the RT config file and return user phone numbers only if
they are currently on shift.

=head1 CONFIGURATION

This module must be specified as a phone number lookup function by passing the
module name. L<RT::Extension::SMSNotify> will look for a function named
C<GetPhoneForUser> in the module as per the docs for C<$SMSNotifyGetPhoneForUserFn>.

  Set($SMSNotifyGetPhoneForUserFn, 'RT::Extension::SMSNotify::IsOnShift');

Now the RT config $SMSNotifyShiftMap must be set to a hashref pointing to a
hash where the shift names are keys and the values are arrayrefs pointing to
two-element arrays of integers. Each key is a shift code that matches the
ShiftCode custom field values. Both values are integers representing minutes
since midnight UTC and are in the range 0 <= x < 1440. For example:

  Set($SMSNotifyShiftMap, {
      'AU' => [22*60+0, 4*60+0],
      'UK' => [8*60+30, 17*60+30]
  });

Be careful to avoid leading zeroes, since Perl will interpret the value as octal:

 $ perl -e 'print 0600 . "\n"';
 384

At this point there's no provision for special notification rules if no users
are found on shift, since the filter function only sees one user at a time.
Make sure you define your shifts and user assignments carefully.

=head1 AUTHOR

Craig Ringer <craig@2ndquadrant.com>

=head1 COPYRIGHT

Copyright 2013 2ndQuadrant

Released under the same license as Perl its self.

=cut

our $cf = undef;

# Is the current UTC time within the shift identified by the passed shift code?
#
sub _NowIsInShift {
    my $shiftcode = shift;
    my $shiftmap = RT->Config->Get('SMSNotifyShiftMap');
    if (!defined($shiftmap) || !defined($shiftmap->{$shiftcode})) {
        RT::Logger->error("SMSNotify: Shift code $shiftcode not found in shiftmap or \$SMSNotifyShiftMap not defined in config; assuming on shift");
        return 1;
    }
    my ($shiftstartutcmins,$shiftendutcmins) = @{$shiftmap->{$shiftcode}};
    my $now = DateTime->now( time_zone => 'UTC' );
    my $nowminutes = $now->minute + 60*$now->hour;
    return RT::Extension::SMSNotify::Shifts::_TimeInShiftRange($nowminutes, $shiftstartutcmins, $shiftendutcmins);
}

=head2 GetPhoneForUser

Look up the PagerPhone field of the specified user and return it only if the user is
currently on shift according to their 'ShiftCode' custom field as looked up in
the RT configuration 'SMSNotifyShiftMap'.

See the configuration section and L<RT::Extension::SMSNotify>.

=cut

sub GetPhoneForUser {
    # Cache the custom field on first use to avoid repeat lookups
    if (!defined($cf)) {
        $cf = RT::CustomField->new( RT::SystemUser );
        $cf->Load('ShiftCode');
    }

    my ($u, $ticket, $hint) = @_;
    if (!defined($u)) {
        return undef;
    }
    my $cfv = $cf->ValuesForObject($u)->ItemsArrayRef;
    my $un = $u->Name;
    if ($cfv) {
        my $shiftcode = $cfv->[0];
	if ($shiftcode) {
            if (_NowIsInShift($shiftcode->Content)) {
                RT::Logger->debug("SMSNotify: User $un is on shift in ".$shiftcode->Content." and has phone " . $u->PagerPhone);
                return $u->PagerPhone;
            } else {
                RT::Logger->debug("SMSNotify: User $un is not on shift in ".$shiftcode->Content);
            }
	} else {
            RT::Logger->debug("SMSNotify: Getting phone for $un: has ShiftCode CF but value is undef, skipping user");
        }
    } else {
        RT::Logger->debug("SMSNotify: Getting phone for $un: no ShiftCode field, skipping user");
    }
    return undef;
}

1;
