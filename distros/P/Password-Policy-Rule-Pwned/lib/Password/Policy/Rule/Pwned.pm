#
#===============================================================================
#
#         FILE: Pwned.pm
#
#  DESCRIPTION: Check HIBP to see if this password has been pwned
#
#        FILES: ---
#         BUGS: ---
#        NOTES: https://haveibeenpwned.com/API/v2#PwnedPasswords
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: See $VERSION in code
#      CREATED: 29/05/18 14:44:30
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

package Password::Policy::Rule::Pwned;

use parent 'Password::Policy::Rule';

use Password::Policy::Exception::Pwned;
use Password::Policy::Exception::PwnedError;
use LWP::UserAgent;
use Digest::SHA 'sha1_hex';

our $VERSION = '0.02';
my $ua = __PACKAGE__ . '/' . $VERSION;
my $timeout = 5;
our $base_url = 'https://api.pwnedpasswords.com/range/';

sub check {
	my $self     = shift;
	my $password = $self->prepare (shift);
	my $hash     = uc sha1_hex ($password);
	my $range    = substr ($hash, 0, 5, '');
	my $url      = $base_url . $range;
	my $res      = LWP::UserAgent->new (agent => $ua, timeout => $timeout)->get ($url);
	if ($res->code != 200) {
		warn $res->status_line;
		Password::Policy::Exception::PwnedError->throw;
	}
	if (index ($res->content, "$hash:") > -1) {
		Password::Policy::Exception::Pwned->throw;
	}
	return 1;
}

__END__

=head1 NAME

Password::Policy::Rule::Pwned - Check passwords haven't been pwned

=head1 SYNOPSIS

    use Password::Policy;
    use Try::Tiny;

    my $pass = 'password1';

    my $pp = Password::Policy->new (config => 'policy.yaml');
    try {
        $pp->process({ password => $pass });
    } catch {
        if ($_->isa ("Password::Policy::Exception::PwnedError")) {
            warn "Unable to verify pwned status - try again later\n";
            return;
        }
        warn "'$pass' failed checks: $_ - don't use it\n";
        # Other actions
    }

=head1 DESCRIPTION

Plug this rule into L<Password::Policy> to
validate potential passwords against the list from
L<haveibeenpwned.com|https://haveibeenpwned.com/API/v2>. It
uses the recommended
L<range|https://haveibeenpwned.com/API/v2#SearchingPwnedPasswordsByRange>
function to ensure that neither the password nor its full hash is ever
transferred over the wire.

The Password::Policy configuration file should set the "pwned" attribute
to 1 in any policy where this rule should apply. A trivial example of
such a policy might be:

    ---
    default:
        length: 8
        algorithm: "Plaintext"
        pwned: 1

As with all other L<Password::Policy::Rule> types, this will throw an
exception to indicate an unsafe password. As it relies on a network
service to operate it will also throw an exception if the service is
unavailable for whatever reason. The two exceptions are different and
may be interrogated to determine the difference.

    try {
        $pp->process({ password => $pass });
    } catch {
        if ($_->isa ("Password::Policy::Exception::Pwned")) {
            warn "This password '$pass' is pwned - don't use it";
        } elsif ($_->isa ("Password::Policy::Exception::PwnedError")) {
            warn "Could not check if password is pwned - use at own risk";
        } else {
            warn "Password not pwned but still bad: $_";
        }
        # Other actions
    }

Alternatively the response may be stringified and the messages parsed for
key phrases, although this will be less robust.

    try {
        $pp->process({ password => $pass });
    } catch {
        if (/has been pwned/) {
            warn "This password '$pass' is pwned - don't use it";
        } elsif (/Invalid response/) {
            warn "Could not check if password is pwned - use at own risk";
        } else {
            warn "Password not pwned but still bad: $_";
        }
        # Other actions
    }

=head1 METHODS

=head2 check

    $rule->check ($clearpw);

This method is not expected to be called directly but rather via
C<Password::Policy-E<gt>process>. It takes one argument which is the
password to be checked. If the password is a utf-8 string it must be
encoded first.

The method will throw a L<Password::Policy::Exception::Pwned> exception
if the password is pwned. If the API server is unavailable it will warn
and then throw a L<Password::Policy::Exception::PwnedError> exception. It
will return true if the password is verifiably not pwned.

=head1 DATA SOURCE

Note that this code is merely a user-friendly API client. It relies
entirely upon the data held at api.pwnedpasswords.com and which is made
available free of charge to end users such as your good self. If this
data is useful to you then please consider making a
L<donation|https://haveibeenpwned.com/Donate> to help fund this service
and allow Troy's good work to continue.

=head1 SEE ALSO

To understand how to use this as part of a wider password policy
enforcement program, see L<Password::Policy>.

=head1 REPOSITORY

L<https://gitlab.com/openstrike/password-pwned>

=head1 MAINTAINER

This module is written and maintained by Pete Houston of Openstrike
<cpan@openstrike.co.uk>

=head1 COPYRIGHT

Copyright 2018 by Pete Houston. All Rights Reserved.

Permission to use, copy, and  distribute  is  hereby granted,
providing that the above copyright notice and this permission
appear in all copies and in supporting documentation.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This means that you can, at your option, redistribute it and/or modify
it under either the terms of the GNU Public License (GPL) version 1 or
later, or under the Perl Artistic License.

See L<https://dev.perl.org/licenses/>

=cut

