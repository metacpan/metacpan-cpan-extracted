#
#===============================================================================
#
#         FILE: Pwned.pm
#
#  DESCRIPTION: Throw an exception for a pwned password
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston, cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: See $VERSION in code
#      CREATED: 29/05/18 14:42:12
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

package Password::Policy::Exception::Pwned;
 
use parent 'Password::Policy::Exception';

our $VERSION = '0.01';

sub error { return 'The specified password has been pwned'; }

__END__

=head1 NAME

Password::Policy::Exception::Pwned - Die if a password has been pwned

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
determines that a password has been pwned.

=head1 METHODS

=head2 error

    $exception->error ();

This method is not expected to be called directly but rather via
C<Password::Policy-E<gt>process>. It returns the text of an appropriate
error which in this case is "The specified password has been pwned".

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
