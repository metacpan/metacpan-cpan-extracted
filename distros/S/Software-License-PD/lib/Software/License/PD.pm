use strict;
use warnings;

package Software::License::PD;
BEGIN {
  $Software::License::PD::VERSION = '1.001';
}
# ABSTRACT: Public Domain pseudo-license

use base 'Software::License';

require Software::License::MIT;
require Software::License::GPL_3;
require Software::License::Artistic_2_0;


sub name { 'Public Domain pseudo-license (GPL, Artistic, MIT or PD)' }
sub url  { 'http://edwardsamuels.com/copyright/beyond/articles/public.html' }
sub meta_name  { 'unrestricted' }
sub meta2_name { 'unrestricted' }

sub _mit {
  my ($self) = @_;
  return $self->{_mit} ||= Software::License::MIT->new({
    year   => $self->year,
    holder => $self->holder,
  });
}

sub _gpl {
  my ($self) = @_;
  return $self->{_gpl} ||= Software::License::GPL_3->new({
    year   => $self->year,
    holder => $self->holder,
  });
}

sub _tal {
  my ($self) = @_;
  return $self->{_tal} ||= Software::License::Artistic_2_0->new({
    year   => $self->year,
    holder => $self->holder,
  });
}

1;



=pod

=head1 NAME

Software::License::PD - Public Domain pseudo-license

=head1 VERSION

version 1.001

=head1 DESCRIPTION

In legal circles, B<Public Domain> is defined as the absence of B<copyright>
(and therefore precludes the need for any B<license>). Artistic works enter
the Public Domain in two common situations:

=over

=item 1

Where the work carries no license or copyright information, and precedes
the ratification of the I<Berne Convention for the Protection of Literary
and Artistic Works>

=item 2

Where the term of copyright has lapsed, the length of which varies between
jurisdictions

=back

Some authors have chosen to disclaim all rights to their works and attempt
to release them into the Public Domain. This is a particularly contentious
issue because some jurisdictions do not recognize an author's perogative to
disclaim all rights to their own work. In European countries, authors can
abandon their claim to copyright, but not Reputation Rights (which prevent
people from removing your name from your work, among other things).

While I have researched the issue to some extent, I am not a lawyer and am
not qualified to provide legal advice. I have used this license for some of
my own packages, but am unsure whether it would stand up in a court of law.

=head2 CREATIVE COMMONS ZERO

The B<Creative Commons Zero> (CC0) license is an extremely liberal license,
which confers rights similar to Public Domain to the extent permissible by
law. However, Creative Commons does not recommend the application of their
licenses to software, see:
L<http://wiki.creativecommons.org/FAQ#Can_I_use_a_Creative_Commons_license_for_software.3F>

=head1 NOTABLE PROJECTS

Several notable Open Source software projects have been released into the
Public Domain:

=over

=item *

SQLite, L<http://sqlite.org>

=item *

L<Math::Random::ISAAC>, as well as the algorithm and accompanying reference
implementation, L<http://burtleburtle.net/bob/rand/isaacafa.html>

=back

=head1 SEE ALSO

=over

=item *

The Berne Convention for the Protection of Literary and Artistic Works,
L<http://wipo.int/treaties/en/ip/berne/index.html>

=item *

The Public Domain in Copyright Law,
L<http://edwardsamuels.com/copyright/beyond/articles/public.html>

=item *

Placing documents into the public domain,
L<http://cr.yp.to/publicdomain.html>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Software-License-PD

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jonathan Yu <jawnsy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Yu <jawnsy@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
__NOTICE__
Legally speaking, this package and its contents are:

  Copyright (c) {{$self->year}} by {{$self->holder}}.

But this is really just a legal technicality that allows the author to
offer this package under the public domain and also a variety of licensing
options. For all intents and purposes, this is public domain software,
which means you can do whatever you want with it.

The software is provided "AS IS", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.

__LICENSE__
Legally speaking, this package and its contents are:

  Copyright (c) {{$self->year}} by {{$self->holder}}.

But this is really just a legal technicality that allows the author to
offer this package under the public domain and also a variety of licensing
options. For all intents and purposes, this is public domain software,
which means you can do whatever you want with it.

SUMMARY

I, the copyright holder of this package, hereby release the entire contents
therein into the public domain. This applies worldwide, to the extent that
it is permissible by law.

In case this is not legally possible, I grant any entity the right to use
this work for any purpose, without any conditions, unless such conditions
are required by law.

If you so choose, or if you are legally compelled to do so, you may use
this software under the terms of your choice of the following licenses:

1. The MIT/X11 License; or,
2. The Perl Artistic License, version 1 or later; or,
3. The GNU General Public License, version 1 or later

For the sake of convenience, the full text of the latest versions of these
licenses (as of writing) follows.

--- {{ $self->_mit->name }} ---

{{ $self->_mit->fulltext }}

--- {{ $self->_tal->name }} ---

{{ $self->_tal->fulltext }}

--- {{ $self->_gpl->name }} ---

{{ $self->_gpl->fulltext }}
