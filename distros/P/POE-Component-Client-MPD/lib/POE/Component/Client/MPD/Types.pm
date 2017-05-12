#
# This file is part of POE-Component-Client-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use warnings;
use strict;

package POE::Component::Client::MPD::Types;
# ABSTRACT: types used in the distribution
$POE::Component::Client::MPD::Types::VERSION = '2.001';
use Moose::Util::TypeConstraints;
use Sub::Exporter -setup => { exports => [ qw{
    Cooking Transform
} ] };

enum Cooking   => [ qw{ raw as_items as_kv strip_first } ];
enum Transform => [ qw{ as_scalar as_stats as_status } ];

1;

__END__

=pod

=head1 NAME

POE::Component::Client::MPD::Types - types used in the distribution

=head1 VERSION

version 2.001

=head1 DESCRIPTION

This module implements the specific types used by the distribution, and
exports them. It is using L<Sub::Exporter> underneath, so you can use
all the shenanigans to change the export names.

Current types defined and exported:

=over 4

=item * C<Cooking> - a simple enum to know what to do about that data

=over 4

=item * C<raw> - data should not be touched

=item * C<as_items> - data is to be transformed as L<Audio::MPD::Common::Item>

=item * C<as_kv> - data is to be cooked as key/values (hash)

=item * C<strip_first> - data should have its first field stripped

=back

=item * C<Transform> - a simple enum to know what to do about the data,
B<after> it has been cooked. Possible values are:

=over 4

=item * C<as_scalar> - return the first element instead of the full list

=item * C<as_stats> - transform the data from key/value to
C<Audio::MPD::Common::Stats>

=item * C<as_status> - transform the data from key/value to
C<Audio::MPD::Common::Status>

=back

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
