package Perl::Critic::OTRS;

use warnings;
use strict;

# ABSTRACT: A collection of handy Perl::Critic policies

our $VERSION = '0.07';

=head1 SYNOPSIS

Perl::Critic::OTRS is a collection of Perl::Critic policies that
will help to program in the OTRS way of programming

=head1 DESCRIPTION

The rules included with the Perl::Critic::OTRS group include:

=head2 L<Perl::Critic::Policy::OTRS::ProhibitFetchrowHashref>

Kernel::System::DB provides a method called C<FetchrowHashref>, but this method
is deprecated as this relies on C<DBI>'s fetchrow_hashref. Some users have
reported problems with it on some database systems.

=head2 L<Perl::Critic::Policy::OTRS::ProhibitDumper>

=head2 L<Perl::Critic::Policy::OTRS::ProhibitLocaltime>

=head2 L<Perl::Critic::Policy::OTRS::ProhibitLowPrecedenceOps>

=head2 L<Perl::Critic::Policy::OTRS::ProhibitOpen>

=head2 L<Perl::Critic::Policy::OTRS::ProhibitPushISA>

=head2 L<Perl::Critic::Policy::OTRS::ProhibitRequire>

=head2 L<Perl::Critic::Policy::OTRS::ProhibitSomeCoreFunctions>

=head2 L<Perl::Critic::Policy::OTRS::RequireCamelCase>

=head2 L<Perl::Critic::Policy::OTRS::RequireParensWithMethods>
 
=head2 L<Perl::Critic::Policy::OTRS::RequireTrueReturnValueForModules>

=head1 WHY A COLLECTION OF OTRS POLICIES?

The policies bundled in this distributions represent the coding guideline
provided by the OTRS project. It's always a good idea to program the way the
project itself does.

So every programmer who is familiar with the OTRS codebase can read and follow
your code.

=head1 ACKNOWLEDGMENTS

Thanks to

=over 4

=item * L<Martin Edenhofer|https://github.com/martini> for creating a great tool like OTRS

=item * L<Martin Gruner|https://github.com/mgruner> for improvements for this module

=item * L<Michiel Beijen|https://github.com/mbeijen> for improvements for this module

=item * L<Ramanan Balakrishnan|https://github.com/ramananbalakrishnan> for fixing test failures

=back

=cut

1; # End of Perl::Critic::OTRS
