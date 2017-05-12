package Task::Perl::Critic;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.008';


1; # Magic true value required at end of module

__END__

=head1 NAME

Task::Perl::Critic - Install everything Perl::Critic.


=head1 VERSION

This document describes Task::Perl::Critic version 1.8.0.


=head1 SYNOPSIS

This module does nothing but act as a placeholder.  See L<Task>.


=head1 DESCRIPTION

This module does nothing but act as a placeholder.  See L<Task>.

B<WARNING>: Installing this distribution will install Policies that
directly conflict with each other.  If you do not use a
F<.perlcriticrc> file, and your severity is set high enough, there is
no way for your code to not have violations.  A specific example:
L<Perl::Critic::Policy::Compatibility::ProhibitThreeArgumentOpen> and
L<Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen> directly
contradict each other.


=head1 INTERFACE

None.


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

Task::Perl::Critic requires no configuration files or environment
variables.


=head1 DEPENDENCIES

L<Perl::Critic>

L<Test::Perl::Critic>

L<Test::Perl::Critic::Progressive>

L<criticism>

L<Perl::Critic::Bangs>

L<Perl::Critic::Compatibility>

L<Perl::Critic::Dynamic>

L<Perl::Critic::Itch>

L<Perl::Critic::Lax>

L<Perl::Critic::Moose>

L<Perl::Critic::More>

L<Perl::Critic::Nits>

L<Perl::Critic::PetPeeves::JTRAMMELL>

L<Perl::Critic::Pulp>

L<Perl::Critic::Storable>

L<Perl::Critic::StricterSubs>

L<Perl::Critic::Swift>

L<Perl::Critic::Tics>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-task-perl-critic@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C)2007-2008, Elliot Shank C<< <perl@galumph.com> >>. All
rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 70
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=70 ft=perl expandtab :
