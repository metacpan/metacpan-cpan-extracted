#!/usr/bin/perl

package RT::Extension::SMSNotify::PagerForUser;

use 5.10.1;
use strict;
use warnings;
use DateTime;

=head1 NAME

 RT::Extension::SMSNotify::PagerForUser

=head1 DESCRIPTION

The default PagerForUser, just returns the user's pagerphone attribute.

=head1 CONFIGURATION

No configuration is available. 

=head1 AUTHOR

Craig Ringer <craig@2ndquadrant.com>

=head1 COPYRIGHT

Copyright 2013 2ndQuadrant

Released under the same license as Perl its self.

=cut

=head2 GetPhoneForUser

Look up the PagerPhone field of the specified user and return it.

See the configuration section and L<RT::Extension::SMSNotify>.

=cut

sub GetPhoneForUser {
    RT::Logger->debug("SMSNotify: Using default \$SMSNotifyGetPhoneForUserFn");
    return $_[0]->PagerPhone if $_[0];
}

1;
