Module-Lazy

# NAME

Module::Lazy - postpone loading a perl module until it's actually used

# USAGE

    use Module::Lazy "My::Module";
    # the module is not required at this point, speeding up the startup

    my $new = My::Module->new;
    # My::Module is loaded now and real new() method is called

    no Module::Lazy;
    # Force loading of all postponed modules, in alphabetical order

# DESCRIPTION

In a big project with large dependency footprint
loading modules may take quite a while.
This is not a problem for daemons or long-running apps.
However, time saving for simple command-line tools or test scripts
may be significant.

# CONTENTS OF THIS PACKAGE

* `lib` - libraries & modules

* `t` - tests

* `xt` - author tests (not required for installation)

* `README`/`README.md` - this file

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Module::Lazy

You can also look for information at:

    Github:
        https://github.com/dallaylaen/module-lazy-perl

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Lazy

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Module-Lazy

    CPAN Ratings
        http://cpanratings.perl.org/d/Module-Lazy

    Search CPAN
        http://search.cpan.org/dist/Module-Lazy/


# LICENSE AND COPYRIGHT

Copyright (C) 2019 Konstantin S. Uvarin

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

