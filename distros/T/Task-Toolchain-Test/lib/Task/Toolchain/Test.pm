package Task::Toolchain::Test;

use warnings;
use strict;

=head1 NAME

Task::Toolchain::Test - Install most common test toolchain modules

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SUMMARY

It's annoying sitting down at a new box and discovering that you don't have
the latest testing modules installed. Or you're writing a test and and you
find out that you didn't have L<Test::Exception> installed after all.

=head2 Test Modules

This task installs relatively new versions of the following modules:

=over 4

=item * L<Test::Simple>

=item * L<Test::Harness>

=item * L<Test::Exception>

=item * L<Test::NoWarnings>

=item * L<Test::Builder::Tester>

=item * L<Test::Deep>

=item * L<Test::Pod>

=item * L<Test::Pod::Coverage>

=item * L<Test::Kwalitee>

=item * L<Test::Distribution>

=item * L<Test::Warn>

=item * L<Test::Differences>

=item * L<Test::Spelling>

=item * L<Test::MockObject>

=item * L<Test::UseAllModules>

=item * L<Test::Most>

=item * L<Test::Class>

=item * L<Test::Class::Most>

=back

=head2 How Were They Chosen?

Three criteria were used to choose the above list:

=over 4

=item * Ovid's list of most popular testing modules.

L<http://blogs.perl.org/users/ovid/2010/01/most-popular-testing-modules---january-2010.html>

=item * Modules that are easy to install.

I love L<Test::WWW::Mechanize>, but its high failure rate means that it was
left off this list.

=item * Modules which should be more popular.

This is where people might gripe because I not only included L<Test::Class>,
but also two of my C<*::Most> testing modules.  Though to be fair, I've
written, have commit access or patches to much of the above list, so maybe all
of this is an exercise in vanity.  Sue me :)

=back

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-toolchain-test at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Toolchain-Test>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Toolchain::Test

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Toolchain-Test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Toolchain-Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Toolchain-Test>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Toolchain-Test/>

=back

=head1 ACKNOWLEDGEMENTS

Vienna.pm (L<http://vienna.pm.org/>) sponsored the 2010 Perl QA Hackathon
(L<http://2010.qa-hackathon.org/qa2010/>).  Some bootstrapping issues we were
trying to resolve led to his module.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; 
