package Perl::Critic::Moose;

use 5.008;

use strict;
use warnings;

our $VERSION = '1.05';

1;

# ABSTRACT: Policies for Perl::Critic concerned with using Moose

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Moose - Policies for Perl::Critic concerned with using Moose

=head1 VERSION

version 1.05

=head1 DESCRIPTION

Some L<Perl::Critic> policies that will help you keep your code in good shape
with regards to L<Moose>.

The included policies are:

=over

=item L<Perl::Critic::Policy::Moose::ProhibitDESTROYMethod>

Use C<DEMOLISH()> instead of C<DESTROY()>. [Severity: 3]

=item L<Perl::Critic::Policy::Moose::ProhibitMultipleWiths>

Compose your roles to enjoy safe composition. [Severity: 4]

=item L<Perl::Critic::Policy::Moose::ProhibitNewMethod>

Don't override the built-in constructors. [Severity: 4]

=item L<Perl::Critic::Policy::Moose::RequireCleanNamespace>

Require removing implementation details from you packages. [Severity: 3]

=item L<Perl::Critic::Policy::Moose::RequireMakeImmutable>

Increase performance by freezing your class structures with
C<< __PACKAGE__->meta()->make_immutable() >>. [Severity: 3]

=item L<Perl::Critic::Policy::Moose::ProhibitLazyBuild>

Prevent the use of C< lazy_build > which creates mutability
problems and pollutes namespaces. [Severity: 2]

=back

=head1 AFFILIATION

This module has no functionality, but instead contains documentation for this
distribution and acts as a means of pulling other modules into a bundle. All
of the Policy modules contained herein will have an "AFFILIATION" section
announcing their participation in this grouping.

=head1 CONFIGURATION AND ENVIRONMENT

All policies included are in the "moose" theme. See the L<Perl::Critic>
documentation for how to make use of this.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-perl-critic-moose@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Moose>
(or L<bug-perl-critic-moose@rt.cpan.org|mailto:bug-perl-critic-moose@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 AUTHORS

=over 4

=item *

Elliot Shank <perl@galumph.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTORS

=for stopwords Jeffrey Ryan Thalhammer Karen Etheridge Kieren Diment Noel Maddy Shawn Moore

=over 4

=item *

Jeffrey Ryan Thalhammer <jeff@thaljef.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kieren Diment <kieren.diment@hiivesystems.com>

=item *

Noel Maddy <zhtwnpanta@gmail.com>

=item *

Shawn Moore <cpan@sartak.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 - 2016 by Elliot Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
