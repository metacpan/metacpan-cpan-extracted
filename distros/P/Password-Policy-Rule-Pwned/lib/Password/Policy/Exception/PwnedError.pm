#
#===============================================================================
#
#         FILE: PwnedError.pm
#
#  DESCRIPTION: Throw an exception for failure to check pwned password
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston, cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: See $VERSION in code
#      CREATED: 18/07/18 14:53:15
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

package Password::Policy::Exception::PwnedError;
 
use parent 'Password::Policy::Exception';

our $VERSION = '0.01';

sub error { return 'Invalid response checking for pwned password'; }

=head1 NAME

Password::Policy::Exception::PwnedError - Die if the password pwned API is unreachable

=head1 SYNOPSIS

    use Password::Policy;
    use Try::Tiny;

    my $pass = 'password1';

    my $pp = Password::Policy->new (config => 'policy.yaml');
    try {
        $pp->process({ password => $pass });
    } catch {
        warn "This password '$pass' is pwned - don't use it";
        # Other actions
    }

=head1 DESCRIPTION

This exception is thrown when L<Password::Policy::Rule::Pwned>
cannot determine whether or not a password has been pwned. The
determination depends on a remote service which may not be available for
any number of reasons.

=head1 METHODS

=head2 error

    $exception->error ();

This method is not expected to be called directly but rather via
C<Password::Policy-E<gt>process>. It returns the text of an appropriate
error which in this case is "Invalid response checking for pwned password".

=head1 SEE ALSO

For how to determine if passwords are pwned, see
L<Password::Policy::Rule::Pwned>.

To understand how to use this as part of a wider password policy
enforcement program, see L<Password::Policy>.

=head1 REPOSITORY

L<https://gitlab.com/openstrike/password-pwned>

=head1 MAINTAINER

This module is written and maintained by Pete Houston of Openstrike
<cpan@openstrike.co.uk>

=head1 COPYRIGHT INFORMATION

Copyright 2018 by Pete Houston. All Rights Reserved.

Permission to use, copy, and  distribute  is  hereby granted,
providing that the above copyright notice and this permission
appear in all copies and in supporting documentation.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
