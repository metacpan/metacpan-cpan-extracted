package Task::Smoke;

use warnings;
use strict;

=head1 NAME

Task::Smoke - Install modules required for Pugs-like smoke system

=cut

our $VERSION = '0.19';

=head1 SYNOPSIS

  cpan Task::Smoke

=head1 DESCRIPTION

L<Perl6::Pugs> is an experimental implementation of Perl 6. It does
not have many prerequisites by itself: merely perl 5.6.1 or 5.8.3,
and a decently new ExtUtils::MakeMaker.

If you wish to run the powerful smoke test system that comes with Pugs,
however, you'll need these modules. Once installed, you can run a smoke
test and generate a colorful smoke.html by running the following command
in the Pugs build directory:

  make smoke

You are encouraged to submit your results to the public smokeserver,
especially if you run on an uncommon platform:

  make upload-smoke

Existing smoke reports can be viewed at L<http://smoke.pugscode.org>.

=head2 Non-Pugs usage

You are invited to use this system in your Perl 5 projects, though
currently this may require some tweaking. Please see the talk
L<http://perlcabal.org/~gaal/pugstest/start.html>, "Reusing the Pugs
Smoke System", for this end.

=head2 Note on YAML providers

This bundle installs either YAML::Syck or YAML.pm, depending on your
environment. YAML::Syck is faster, but requires c build capabilities.

=head1 AUTHOR

Gaal Yahas, C<< <gaal at forum2.org> >>

The Pugs test system was developed by many people; please see the
dependencies of this module.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-task-smoke at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Smoke>.

Or better, come to the C<#perl6> channel on C<irc.freenode.org>.

=head1 SUPPORT

You can look for information at:

=over 4

=item * #perl6 on irc.freenode.net

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Smoke>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Smoke>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Smoke>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Smoke>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006, 2007 Gaal Yahas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__; # End of Task::Smoke
