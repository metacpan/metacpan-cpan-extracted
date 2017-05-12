package Test::Chimps;

=head1 NAME

Test::Chimps - Collaborative Heterogeneous Infinite Monkey Perfectionification Service

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

Why run tests yourself?  Let an infinite number of monkeys do it
for you!  Take the monkey work out of testing!  Remove the monkey
wrench from your development process!  Alright, I'm done.  Sorry
about that.  I got a little carried away...

The Collaborative Heterogeneous Infinite Monkey Perfectionification
Service (CHIMPS) is a generalized testing framework designed to
make integration testing easy.  You use L<Test::Chimps::Server> to
create your CGI script for viewing and submitting reports, and you
use L<Test::Chimps::Client> for submitting reports.  You will find
some scripts in the examples directory which should get you
started.

=head1 PHILOSOPHY

Tests are good.  Testing is easy thanks to modules like
L<Test::Simple> and L<Test::More>.  However, it's easy to forget to
run C<make test> every time you commit.  Worse, you might have
forgotten to add a file that will cause tests to fail on a freshly
checked out copy.  Additionally, your tests might only pass on your
version of perl or with specific module versions.

Chimps aims to solve these problems.  However, it tries to make as
few assumptions about how your integration testing architecture
should work as possible.  Want to allow anyone to submit smoke
reports?  Just write a wrapper around C<Test::Chimps::Client>.
Want to have dedicated build hosts that continuously check out and
test projects?  Just use C<Test::Chimps::Client::Poller>.  Whatever
your integration testing architecture, you can probably use Chimps
to simplify the process.

=head1 REPORT VARIABLES

Chimps does not make any assumptions about what kind of data is
carried in your smoke reports.  These data are called I<report
variables>.  When creating a server with C<Test::Chimps::Server>,
you can specify which variables must be submitted with each
report.  Unfortunately, if we I<never> made any assumptions, it
would be hard to write any utility code.  Therefore, several Chimps
modules have documentation sections describing variables that it
assumes are passed to the server.  These are probably pretty
reasonable assumptions for most set ups.  However, if they do not
meet your needs, it should be fairly easy to subclass the
appropriate classes and add the functionality and variables you
require.

=head1 AUTHOR

Zev Benjamin, C<< <zev at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-chimps at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Chimps>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Chimps

You can also look for information at:

=over 4

=item * Mailing list

Chimps has a mailman mailing list at
L<chimps@bestpractical.com>.  You can subscribe via the web
interface at
L<http://lists.bestpractical.com/cgi-bin/mailman/listinfo/chimps>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Chimps>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Chimps>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Chimps>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Chimps>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

