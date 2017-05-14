use strict;
use warnings;
package Task::OSDC2012;

# ABSTRACT: Install all the modules from PJF's talk at OSDC 2012

=head1 ABSTRACT

Task::OSDC2012 - Install all modules from PJF's talk at OSDC 2012

=head1 DESCRIPTION

This task installs all the modules mentioned in Paul Fenwick's
talk at OSDC 2012, including:

=over

=item L<App::cpanminus>

=item L<autodie>

=item L<Dancer>

=item L<Dist::Zilla>

=item L<local::lib>

=item L<Moose>

=item L<MooseX::Declare>

=item L<MooseX::Method::Signatures>

=item L<Perl::Critic>

=item L<Plack>

=item L<Regexp::Debugger>

=back

The L<Task::Kensho> group is not installed due to size, but it's
I<hugely> recommended.

=cut

1;
