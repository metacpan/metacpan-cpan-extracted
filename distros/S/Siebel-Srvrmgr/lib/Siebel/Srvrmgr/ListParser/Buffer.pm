package Siebel::Srvrmgr::ListParser::Buffer;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Buffer - class to store output of commands

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;

our $VERSION = '0.29'; # VERSION

=pod

=head1 SYNOPSIS

	my $buffer = Siebel::Srvrmgr::ListParser::Buffer->new(
		{
			type     => 'sometype',
			cmd_line => 'list something'
		}
	);

	$buffer->set_content( $cmd_output_line );

=head1 DESCRIPTION

This class is used by L<Siebel::Srvrmgr::ListParser> to store output read (between two commands) while is processing all the output.

=head1 ATTRIBUTES

=head2 type

String that identified which kind of output is being stored. This will be used by abstract factory classes to instantiate objects from 
L<Siebel::Srvrmgr::ListParser::Output> subclasses.

=cut

has 'type' => ( is => 'ro', isa => 'Str', required => 1, reader => 'get_type' );

=pod

=head2 cmd_line

String that contains the identified commands that generated the output.

=cut

has 'cmd_line' =>
  ( is => 'ro', isa => 'Str', required => 1, reader => 'get_cmd_line' );

=pod

=head2 content

An array reference with the output being stored. Each index is one line read stored from the output.

=cut

has 'content' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    reader  => '_get_content',
    writer  => '_set_content',
    default => sub { return [] }
);

=pod

=head1 METHODS

=head2 get_type

Returns the string stored in the attribute C<type>.

=head2 get_cmd_line

Returns the string stored in the attribute C<type>.

=head2 get_content

Returns the buffer content B<without> new lines. This is the expected behavior since parsers will not know what to
do with new lines characters.

=cut

sub get_content {
    my $self    = shift;
    my @content = @{ $self->_get_content };
    chomp( @content );
    return \@content;
}

=head2 get_raw_content

Returns the buffer content B<with> new lines characters.

=cut

sub get_raw_content {
    my $self = shift;
    return $self->_get_content;
}

=head2 set_content

Setter for the C<content> attribute. Expects a string as parameter.

If C<content> already has data, it will be appended as expected.

=cut

sub set_content {
    my ( $self, $value ) = @_;

    if ( defined($value) ) {
        my $buffer_ref = $self->_get_content();
        push( @{$buffer_ref}, $value );
    }

}

=pod

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

__PACKAGE__->meta->make_immutable;
