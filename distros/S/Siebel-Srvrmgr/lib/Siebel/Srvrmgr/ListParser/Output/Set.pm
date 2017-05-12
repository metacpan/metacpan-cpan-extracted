package Siebel::Srvrmgr::ListParser::Output::Set;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Set - subclass to parse set command.

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Carp;

extends 'Siebel::Srvrmgr::ListParser::Output';
our $VERSION = '0.29'; # VERSION

=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output> for example.

=head1 DESCRIPTION

This class is a subclass of L<Siebel::Srvrmgr::ListParser::Output>. In truth, this is not a parser for a C<list> command, but since the usage of
C<load preferences> is strongly recommended but not always possible, this subclasse was added to enable usage of the command C<set> of C<srvrmgr>
in L<Siebel::Srvrmgr::Daemon::Action> subclasses, more specifically the C<set delimiter> command.

In some cases one might not be able to define a delimiter during compile time. That's a good use for this class.

=head1 ATTRIBUTES

=head1 METHODS

=head2 get_location

Returns the C<location> attribute.

=head2 set_location

Set the C<location> attribute. Expects and string as parameter.

=head2 parse

Parses the C<set> output stored in the C<raw_data> attribute, setting the C<data_parsed> attribute.

The C<raw_data> attribute will be set to an reference to an empty array.

=cut

override 'parse' => sub {

    my $self = shift;

    $self->set_raw_data( [] );

    return 1;

};

=pod

=head1 CAVEATS

This class will parse C<set> commands, but L<Siebel::Srvrmgr::ListParser::OutputFactory> is currently configured only to accept
C<set delimiter> commands, anything else will not be recognized.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::OutputFactory>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

L<Moose>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
