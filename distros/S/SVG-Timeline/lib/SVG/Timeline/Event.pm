=head1 NAME

SVG::Timelime::Event - A single event in an SVG timeline.

=head1 SYNOPSIS

See L<SVG::Timeline>.

=cut

package SVG::Timeline::Event;

use 5.010;

use Moose;
use Moose::Util::TypeConstraints;

coerce __PACKAGE__,
  from 'HashRef',
  via  { __PACKAGE__->new($_) };

has text => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has start => (
  is => 'ro',
  isa => 'Int',
  required => 1,
);

has end => (
  is => 'ro',
  isa => 'Int',
  required => 1,
);

has colour => (
  is => 'ro',
  isa => 'Maybe[Str]',
  required => 0,
);

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2017, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
