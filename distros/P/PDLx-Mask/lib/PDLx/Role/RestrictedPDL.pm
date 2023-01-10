package PDLx::Role::RestrictedPDL;

# ABSTRACT: restrict write access to a PDL object as much as possible

use strict;
use warnings;

use PDL::Core ':Internal';
use overload;

our $VERSION = '0.06';

my $_cant_mutate;

BEGIN {
    $_cant_mutate = sub {
        require Carp;
        Carp::croak "restricted piddle: cannot mutate";
    };
}


use Moo::Role;
use namespace::clean 0.16;

use overload
  map  { $_ => $_cant_mutate }
  grep { $_ =~ /=$/ }
  map  { split( ' ', $_ ) } @{overload::ops}{ 'assign', 'mutators', 'binary' };

sub is_inplace  { 0; }
sub set_inplace { goto $_cant_mutate unless @_ > 0 && $_[1] == 0 }

sub inplace;
*inplace = $_cant_mutate;

1;

#
# This file is part of PDLx-Mask
#
# This software is Copyright (c) 2016 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory PDL

=head1 NAME

PDLx::Role::RestrictedPDL - restrict write access to a PDL object as much as possible

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  package MyPDL;

  use Moo;

  with 'PDLx::Role::RestrictedPDL';

=head1 DESCRIPTION

This role overloads assignment operators and the
L<< B<is_inplace>|PDL::Core/inplace >>,
L<< B<is_inplace>|PDL::Core/is_inplace >>,
and
L<< B<set_inplace>|PDL::Core/set_inplace >>,
methods to attempt to prevent mutation of a piddle.

=head1 INTERNALS

=for Pod::Coverage inplace
is_inplace
PDL
set_inplace

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-pdlx-mask@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-Mask

=head2 Source

Source is available at

  https://gitlab.com/djerius/pdlx-mask

and may be cloned from

  https://gitlab.com/djerius/pdlx-mask.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PDLx::Mask|PDLx::Mask>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
