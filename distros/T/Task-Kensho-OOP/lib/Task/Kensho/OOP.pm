use strict;
use warnings;
package Task::Kensho::OOP; # git description: v0.41-8-gf83cef5
# ABSTRACT: A Glimpse at an Enlightened Perl: Object Oriented Programming

our $VERSION = '0.41';

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::Kensho::OOP - A Glimpse at an Enlightened Perl: Object Oriented Programming

=head1 VERSION

version 0.41

=head1 SYNOPSIS

    > cpanm --interactive Task::Kensho::OOP

=head1 DESCRIPTION

=for stopwords Buddhism EPO Kenshō nonduality amongst Organisation installable

From L<http://en.wikipedia.org/wiki/Kensho>:

=over 4

Kenshō (見性) (C. Wu) is a Japanese term for enlightenment
experiences - most commonly used within the confines of Zen
Buddhism - literally meaning "seeing one's nature"[1] or "true
self."[2] It generally "refers to the realization of nonduality of
subject and object."[3]

=back

L<Task::Kensho> is a list of recommended modules
for Enlightened Perl development. CPAN is wonderful, but there are too
many wheels and you have to pick and choose amongst the various
competing technologies.

The plan is for L<Task::Kensho> to be a rough testing ground for ideas that
go into among other things the Enlightened Perl Organisation Extended
Core (EPO-EC).

The modules that are bundled by L<Task::Kensho> are broken down into
several categories and are still being considered. They are all taken
from various top 100 most used perl modules lists and from discussions
with various subject matter experts in the Perl Community. That said,
this bundle does I<not> follow the guidelines established for the EPO-EC
for peer review via industry advisers.

Starting in 2011, L<Task::Kensho> split its sub-groups of modules into
individually-installable tasks.  Each L<Task::Kensho> sub-task is listed at the
beginning of its section in this documentation.

When installing L<Task::Kensho> itself, you will be asked to install each
sub-task in turn, or you can install individual tasks separately. These
individual tasks will always install all their modules by default. This
facilitates the ease and simplicity the distribution aims to achieve.

=head1 RECOMMENDED MODULES

=head2 L<Task::Kensho::OOP>: Object Oriented Programming

=head3 L<Moo>

Minimalist Object Orientation (with Moose compatibility)

=head3 L<Moose>

a postmodern object system for Perl5 (see also Task::Moose for a larger list of Moose extensions)

=head3 L<MooseX::Aliases>

easy aliasing of methods and attributes in Moose

=head3 L<MooseX::Getopt>

a Moose role for processing command line options

=head3 L<MooseX::NonMoose>

easy subclassing of non-Moose classes

=head3 L<MooseX::Role::Parameterized>

Moose roles with composition parameters

=head3 L<MooseX::SimpleConfig>

a Moose role for setting attributes from a simple configuration file

=head3 L<MooseX::StrictConstructor>

a Moose extension that makes your object constructors blow up on unknown attributes

=head3 L<Package::Variant>

Parameterizable packages

=head3 L<Type::Tiny>

tiny, yet Moo(se)-compatible type constraints

=head3 L<namespace::autoclean>

keep imports out of your namespace (Moose-aware)

=head1 INSTALLING

Since version 0.34, L<Task::Kensho> has made use of the C<optional_features> field
in distribution metadata. This allows CPAN clients to interact with you
regarding which modules you wish to install.

The C<cpanm> client requires interactive mode to be enabled for this to work:

    cpanm --interactive Task::Kensho::OOP

=head1 SEE ALSO

L<http://www.enlightenedperl.org/>,
L<Perl::Dist::Strawberry|Perl::Dist::Strawberry>

=head1 BUGS AND LIMITATIONS

This list is by no means comprehensive of the "Good" Modules on CPAN.
Nor is this necessarily the correct path for all developers. Each of
these modules has a perfectly acceptable replacement that may work
better for you. This is however a path to good perl practice, and a
starting place on the road to Enlightened Perl programming.

Please report any bugs or feature requests to
L<https://github.com/EnlightenedPerlOrganisation/task-kensho/issues>.

Bugs may be submitted through L<https://github.com/EnlightenedPerlOrganisation/task-kensho/issues>.

There is also an irc channel available for users of this distribution, at
L<C<#epo> on C<irc.perl.org>|irc://irc.perl.org/#epo>.

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Leo Lapworth Dan Book Chris Nehren Mohammad S Anwar Olaf Alders Rachel Kelly Shawn Sorichetti Rick Leir Tina Müller

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Leo Lapworth <leo@cuckoo.org>

=item *

Dan Book <grinnz@grinnz.com>

=item *

Chris Nehren <apeiron@cpan.org>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Dan Book <grinnz@gmail.com>

=item *

Rachel Kelly <rkellyalso@gmail.com>

=item *

Shawn Sorichetti <shawn@coloredblocks.com>

=item *

Rick Leir <rleir@leirtech.com>

=item *

Tina Müller <cpan2@tinita.de>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
