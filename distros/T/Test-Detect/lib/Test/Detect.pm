package Test::Detect;

use strict;
use warnings;

$Test::Detect::VERSION = '0.1';

sub import {
    no strict 'refs';    ## no critic
    *{ caller() . '::detect_testing' } = \&detect_testing;
}

sub detect_testing {

    # anything to add/modify/remove? send patches!!
    return 1 if exists $ENV{'TAP_VERSION'} || exists $INC{'Test/More.pm'} || exists $INC{'Test/Builder.pm'};

    # would be nice if we could detect execution of prove *but* $^X is still perl when calling prove

    return;
}

1;

__END__

=head1 NAME

Test::Detect - Detect if the code is running under tests

=head1 VERSION

This document describes Test::Detect version 0.1

=head1 SYNOPSIS

    use Test::Detect;

    if ( detect_testing() ) {
        # do test specific stuff
        $keg->TAP; # i.e. output TAP safe data
    }
    else {
        # do non-test specific stuff
        $keg->pour; # i.e. output non-TAP data
    }

=head1 DESCRIPTION

Heuristically detect if the code is running under tests or not.

Handy, for example, when you may need to enable TAP format safe output.

=head1 INTERFACE 

import() exports detect_testing().

=head2 detect_testing()

Takes no arguments.

Returns true if you are running under tests, false otherwise.

=head1 DIAGNOSTICS

Test::Detect throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Test::Detect requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-detect@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
