package Perl::Critic::Bangs;

use warnings;
use strict;

=for stopwords Siskel Kael Greil Considine perldoc AnnoCPAN CPAN's Oystein Torget

=head1 NAME

Perl::Critic::Bangs - A collection of handy Perl::Critic policies

=head1 VERSION

Version 1.14

=cut

our $VERSION = '1.14';

=head1 SYNOPSIS

Perl::Critic::Bangs is a collection of Perl::Critic policies that
will help make your code better.

=head1 DESCRIPTION

The rules included with the Perl::Critic::Bangs group include:

=head2 L<Perl::Critic::Policy::Bangs::ProhibitBitwiseOperators>

Bitwise operators are usually accidentally used instead of logical boolean operators.

=head2 L<Perl::Critic::Policy::Bangs::ProhibitCommentedOutCode>

Commented-out code is usually noise.  It should be removed.

=head2 L<Perl::Critic::Policy::Bangs::ProhibitFlagComments>

Watch for comments like "XXX", "TODO", etc.

=head2 L<Perl::Critic::Policy::Bangs::ProhibitNoPlan>

Tests should have a plan.

=head2 L<Perl::Critic::Policy::Bangs::ProhibitNumberedNames>

Subroutines and variables like C<$user> and C<$user2> are insufficiently
distinguished.

=head2 L<Perl::Critic::Policy::Bangs::ProhibitRefProtoOrProto>

Determining the class in a constructor by using C<ref($proto) || $proto> is usually
a cut-n-paste that is incorrect.

=head2 L<Perl::Critic::Policy::Bangs::ProhibitUselessRegexModifiers>

Adding modifiers to a regular expression made up entirely of a
variable created with C<qr()> is usually not doing what you expect.

=head2 L<Perl::Critic::Policy::Bangs::ProhibitVagueNames>

Vague variables and subroutines like C<$data> or C<$info> are not
descriptive enough.

=head1 WHY IS IT CALLED Perl::Critic::Bangs?

I didn't want to call it "Perl::Critic::Lester" or "Perl::Critic::Petdance"
since that would make it sound like they were only my rules.  Other people
will likely include their own set of rules, too.

So I started thinking of names of famous critics.  Ebert, Siskel,
Kael, etc. What about music critics?  Greil Marcus, J.D. Considine...
Lester Bangs!  He's even got my name in his!  So there was the name.

See http://en.wikipedia.org/wiki/Lester_Bangs for more on Lester Bangs.

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-perl-critic-bangs at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Critic-Bangs>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl::Critic::Bangs

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl-Critic-Bangs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl-Critic-Bangs>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic-Bangs>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl-Critic-Bangs>

=item * Source code repository

L<http://github.com/petdance/perl-critic-bangs>

=back

=head1 ACKNOWLEDGMENTS

Thanks to
Ville Skyttä,
William Braswell,
Oliver Trosien,
Fred Moyer,
Andy Moore,
Oystein Torget,
Mike O'Regan,
Elliot Shank
and the rest of the Perl::Critic team for ongoing support.

=head1 COPYRIGHT

Copyright 2006-2021 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1; # End of Perl::Critic::Bangs
