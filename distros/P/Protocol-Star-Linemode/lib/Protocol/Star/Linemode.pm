# Protocol::Star::Linemode - Generates a formatted byte string for Star POS printers
# Copyright (c) 2013 Peter Stuifzand
# Copyright (c) 2013 Other contributors as noted in the AUTHORS file
# 
# Protocol::Star::Linemode is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the License,
# or (at your option) any later version.
# 
# Protocol::Star::Linemode is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser
# General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

package Protocol::Star::Linemode;
our $VERSION = '1.0.0';
use Moo;
with qw/
Protocol::Star::Linemode::Generated
/;

has _data => (
    is      => 'rw',
    default => sub { '' },
);

sub append {
    my ($self, @data) = @_;
    $self->_data($self->_data . (join '', @data));
    return;
}

sub result {
    my $self = shift;
    return $self->_data;
}

sub append_pack {
    my ($self, $format, @args) = @_;
    $self->append(
        pack($format, @args)
    );
    return;
}

sub create_normal_code {
    my ($nargs, @code) = @_;

    my $len         = $nargs + scalar @code;
    my $pack_format = 'C' x $len;

    return sub {
        my $self = shift;
        my @args = @_;
        $self->append_pack($pack_format, @code, @args);
        return;
    }
}

sub create_escape_code {
    my ($nargs, @code) = @_;

    my $len         = 1 + $nargs + scalar @code;
    my $pack_format = 'C' x $len;

    return sub {
        my $self = shift;
        my @args = @_;
        $self->append_pack($pack_format, 0x1B, @code, @args);
        return;
    }
}

#BEGIN {
#    no strict 'refs';
#    my @escape_specs = (
#        [ 'select_font',                            1, 0x1E, 0x46 ],
#        [ 'select_code_page',                       1, 0x1D, 0x74 ],
#        [ 'set_slash_zero',                         1, 0x27 ],
#        [ 'specify_international_character_set',    1, 0x52 ],
#        [ 'specify_12_dot_pitch',                   0, 0x4D ],
#        [ 'specify_15_dot_pitch',                   0, 0x50 ],
#        [ 'specify_16_dot_pitch',                   0, 0x3A ],
#        [ 'specify_14_dot_pitch',                   0, 0x67 ],
#        [ 'set_expanded_width_height',              2, 0x69 ],
#        [ 'set_expanded_width',                     1, 0x57 ],
#        [ 'set_expanded_height',                    1, 0x68 ],
#        [ 'set_double_high',                        0, 0x0E ],
#        [ 'cancel_double_high',                     0, 0x14 ],
#        [ 'set_emphazied_printing',                 0, 0x45 ],
#        [ 'cancel_emphazied_printing',              0, 0x46 ],
#        [ 'select_underline_mode',                  1, 0x2D ],
#        [ 'select_upperline_mode',                  1, 0x5F ],
#        [ 'select_inverse',                         0, 0x34 ],
#        [ 'cancel_inverse',                         0, 0x35 ],
#        [ 'feed_n_lines',                           1, 0x61 ],
#        [ 'set_page_length',                        1, 0x43 ],
#        [ 'set_page_length_in_24mm_units',          1, 0x43, 0x00 ],
#        [ 'set_left_margin',                        1, 0x6C, ],
#        [ 'set_right_margin',                       1, 0x51, ],
#        [ 'move_absolute_position',                 2, 0x1D, 0x41 ],
#        [ 'move_relative_position',                 2, 0x1D, 0x52 ],
#        [ 'specify_alignment',                      1, 0x1D, 0x61 ],
#        [ 'align_left',                             0, 0x1D, 0x61, 0x00 ],
#        [ 'align_center',                           0, 0x1D, 0x61, 0x01 ],
#        [ 'align_right',                            0, 0x1D, 0x61, 0x02 ],
#    );
#
#    my @specs = (
#        [ 'set_double_wide',                        1, 0x0E ],
#        [ 'cancel_double_wide',                     1, 0x14 ],
#        [ 'select_upside_down',                     0, 0x0F ],
#        [ 'cancel_upside_down',                     0, 0x12 ],
#        [ 'lf',                                     0, 0x0A ],
#        [ 'cr',                                     0, 0x13 ],
#        [ 'form_feed',                              0, 0x0C ],
#        [ 'vertical_tab',                           0, 0x0B ],
#        [ 'horizontal_tab',                         0, 0x09 ],
#    );
#
#    for my $spec (@escape_specs) {
#        my $name = shift @$spec;
#        my $nargs = shift @$spec;
#        *{$name} = create_escape_code($nargs, @$spec);
#    }
#    for my $spec (@specs) {
#        my $name = shift @$spec;
#        my $nargs = shift @$spec;
#        *{$name} = create_normal_code($nargs, @$spec);
#    }
#}

sub text {
    my ($self, $text) = @_;
    $self->append_pack('A*', $text);
    return;
}

1;

=head1 NAME

Protocol::Star::Linemode - Generates a formatted byte string for Star POS printers

=head1 SYNOPSIS

  use Protocol::Star::Linemode;

  my $p = Protocol::Star::Linemode->new;
  $p->set_emphasized_printing;
  $p->text("Hello world");
  $p->cancel_emphasized_printing;

  my $formatted_output = $p->result;
  # Send $formatted_output to printer

=head1 Converting from 0.1.2 to 1.0.0

=over 4

=item * Create a L<Protocol::Star::Linemode> object instead of the L<Protocol::Star::Linemode::Generated> object

=back

=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

=head1 COPYRIGHT

Copyright 2013 - Peter Stuifzand

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
