#
# This file is part of Software-License-GPL3andArtistic2
#
# This software is copyright (c) 2010 by Caleb Cushing.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
package Software::License::GPL3andArtistic2;
BEGIN {
  $Software::License::GPL3andArtistic2::VERSION = '0.07';
}
use strict;
use warnings;
use parent 'Software::License';

use Software::License::GPL_3;
use Software::License::Artistic_2_0;

sub name { 'GNU GPLv3 and Artistic 2.0' }
sub url  { 'http://www.gnu.org/licenses/gpl-3.0.txt http://www.perlfoundation.org/artistic_license_2_0' }
sub meta_name { 'open_source' }

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
# ABSTRACT: GPL 3 and Artistic 2.0 Dual License



=pod

=head1 NAME

Software::License::GPL3andArtistic2 - GPL 3 and Artistic 2.0 Dual License

=head1 VERSION

version 0.07

=head1 NOTICE

This license is probably not needed (IANAL) and unmaintained because the
Artistic 2.0 Licensed Code can be used in GPL 3 Code and even Re-Licensed as
it. In this L<http://bit.ly/dfBgPn> interview on
L<http://www.theperlreview.com> Allison Randal states (full URI below)

=over 4

I<Two concepts were added in the Artistic 2.0: relicensing and patent
protection. The relicensing section 4(c)(ii) means that projects no longer need
to dual-license with the GPL, because the Artistic License itself allows
redistribution of the code under the GPL (or any "copyleft" license). The
patent protection language was added in response to the increased patent
litigation and threats of patent litigation against open source software in the
past few years.>

=back

and

=over 4

I<Artistic 2.0 is compatible with the GPL version 2 and version 3. This
is an improvement over Artistic 1.0, which the FSF never considered compatible
with the GPL. Artistic 2.0 code may also be redistributed under the LGPL, MPL
or any pure "copyleft" license.>

=back

so this module is probably not necessary unless you know something else

interview URI for the paranoid
L<http://www.theperlreview.com/Interviews/allison-randal-artistic-license.html>

=head1 SYNOPSIS

  use Software::License::GPL3andArtistic2;

  my $license = Software::License::GPL3andArtistic2->new({
    holder => 'Caleb Cushing',
  });

  open (my $license_file, '>', 'LICENSE') or die $!;
  print $license_file $license->fulltext;

=head1 DESCRIPTION

This package provides a Dual Licence for GPLv3 and Artistic 2.0. Written
Because as of yet Software::License (and Dist::Zilla )  doesn't provide a way
to multilicense

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Caleb Cushing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
__NOTICE__

This software is copyright (c) {{$self->year}} by {{$self->holder}}.

This is free software; you can redistribute it and/or modify it under
one of the following licenses

a) the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any
   later version, or
b) the "Artistic License 2.0"
__LICENSE__

--- {{ $self->_gpl->name }} ---

{{$self->_gpl->fulltext}}

--- {{ $self->_tal->name }} ---

{{$self->_tal->fulltext}}
