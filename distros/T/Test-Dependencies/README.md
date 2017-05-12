# Test-Dependencies

Makes sure that all of the modules that are 'use'd are listed in the
Makefile.PL as dependencies.


## INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## RECOMMENDED USE

This module supports the development process of declaring correct dependencies on your
module. As such, it's best to include it as a `develop` dependency.  Additionally, any
tests based on this module best be located outside of the 't/' directory which holds
all tests executed upon installation of your module.  A growing number of authors uses
'xt/' to store tests aiding the development process itself.  If anything, that's a
good place to store your `Test::Dependencies` based tests.

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the perldoc command.

    perldoc Test::Dependencies

You can also look for information at:

    Search CPAN
        http://search.cpan.org/dist/Test-Dependencies

    CPAN Request Tracker:
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Dependencies

    AnnoCPAN, annotated CPAN documentation:
        http://annocpan.org/dist/Test-Dependencies

    CPAN Ratings:
        http://cpanratings.perl.org/d/Test-Dependencies

# LICENCE AND COPYRIGHT
    Copyright (c) 2016, Erik Huelsmann. All rights reserved.
    Copyright (c) 2007, Best Practical Solutions, LLC. All rights reserved.

    This module is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself. See perlartistic.

# DISCLAIMER OF WARRANTY
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
    REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
    TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
    CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
    SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
    RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
    FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
    SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
    DAMAGES.
