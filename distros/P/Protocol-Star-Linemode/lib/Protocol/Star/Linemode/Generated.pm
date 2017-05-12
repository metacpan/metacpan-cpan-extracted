# Generated file - do not modify
# Copyright (c) 2013 Peter Stuifzand
# Copyright (c) 2013 Other contributors as noted in the AUTHORS file
#
# Protocol::Star::Linemode::Generated is part of Protocol::Star::Linemode
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
package Protocol::Star::Linemode::Generated;
use Moo::Role;
sub command_initialization {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x40, );
    return;
}

sub select_font {
    my ($self, $arg0) = @_;
    $self->append_pack("CCCC", 0x1B, 0x1E, 0x46, $arg0);
    return;
}

sub select_code_page {
    my ($self, $arg0) = @_;
    $self->append_pack("CCCC", 0x1B, 0x1D, 0x74, $arg0);
    return;
}

sub set_slash_zero {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x27, $arg0);
    return;
}

sub specify_international_charset {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x52, $arg0);
    return;
}

sub specify_12_dot_pitch {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x4D, );
    return;
}

sub specify_15_dot_pitch {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x50, );
    return;
}

sub specify_16_dot_pitch {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x3A, );
    return;
}

sub specify_14_dot_pitch {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x67, );
    return;
}

sub set_expanded_width_height {
    my ($self, $arg0, $arg1) = @_;
    $self->append_pack("CCCC", 0x1B, 0x69, $arg0, $arg1);
    return;
}

sub set_expanded_width {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x57, $arg0);
    return;
}

sub set_expanded_height {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x68, $arg0);
    return;
}

sub set_double_high {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x0E, );
    return;
}

sub cancel_double_high {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x14, );
    return;
}

sub set_emphasized_printing {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x45, );
    return;
}

sub cancel_emphasized_printing {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x46, );
    return;
}

sub select_underline_mode {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x2D, $arg0);
    return;
}

sub select_upperline_mode {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x5F, $arg0);
    return;
}

sub select_inverse {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x34, );
    return;
}

sub cancel_inverse {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x1B, 0x35, );
    return;
}

sub feed_n_lines {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x61, $arg0);
    return;
}

sub set_page_length {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x43, $arg0);
    return;
}

sub set_page_length_in_24mm_units {
    my ($self, $arg0) = @_;
    $self->append_pack("CCCC", 0x1B, 0x43, 0x00, $arg0);
    return;
}

sub set_left_margin {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x6C, $arg0);
    return;
}

sub set_right_margin {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x51, $arg0);
    return;
}

sub skip_lines {
    my ($self, $arg0) = @_;
    $self->append_pack("CCC", 0x1B, 0x61, $arg0);
    return;
}

sub cut {
    my ($self, ) = @_;
    $self->append_pack("CCC", 0x1B, 0x64, 0x33, );
    return;
}

sub barcode_ean13 {
    my ($self, $arg0) = @_;
    $self->append_pack("CCCCCC", 0x1B, 0x62, 0x03, 0x02, 0x01, $arg0);
    return;
}

sub barcode_code128 {
    my ($self, $arg0) = @_;
    $self->append_pack("CCCCCC", 0x1B, 0x62, 0x06, 0x02, 0x01, $arg0);
    return;
}

sub move_absolute_position {
    my ($self, $arg0, $arg1) = @_;
    $self->append_pack("CCCCC", 0x1B, 0x1D, 0x41, $arg0, $arg1);
    return;
}

sub move_relative_position {
    my ($self, $arg0, $arg1) = @_;
    $self->append_pack("CCCCC", 0x1B, 0x1D, 0x52, $arg0, $arg1);
    return;
}

sub specify_alignment {
    my ($self, $arg0) = @_;
    $self->append_pack("CCCC", 0x1B, 0x1D, 0x61, $arg0);
    return;
}

sub align_left {
    my ($self, ) = @_;
    $self->append_pack("CCCC", 0x1B, 0x1D, 0x61, 0x00, );
    return;
}

sub align_center {
    my ($self, ) = @_;
    $self->append_pack("CCCC", 0x1B, 0x1D, 0x61, 0x01, );
    return;
}

sub align_right {
    my ($self, ) = @_;
    $self->append_pack("CCCC", 0x1B, 0x1D, 0x61, 0x02, );
    return;
}

sub set_double_wide {
    my ($self, $arg0) = @_;
    $self->append_pack("CC", 0x0E, $arg0);
    return;
}

sub cancel_double_wide {
    my ($self, $arg0) = @_;
    $self->append_pack("CC", 0x14, $arg0);
    return;
}

sub select_upside_down {
    my ($self, ) = @_;
    $self->append_pack("C", 0x0F, );
    return;
}

sub cancel_upside_down {
    my ($self, ) = @_;
    $self->append_pack("C", 0x12, );
    return;
}

sub lf {
    my ($self, ) = @_;
    $self->append_pack("C", 0x0A, );
    return;
}

sub cr {
    my ($self, ) = @_;
    $self->append_pack("C", 0x13, );
    return;
}

sub crlf {
    my ($self, ) = @_;
    $self->append_pack("CC", 0x13, 0x0A, );
    return;
}

sub form_feed {
    my ($self, ) = @_;
    $self->append_pack("C", 0x0C, );
    return;
}

sub vertical_tab {
    my ($self, ) = @_;
    $self->append_pack("C", 0x0B, );
    return;
}

sub horizontal_tab {
    my ($self, ) = @_;
    $self->append_pack("C", 0x09, );
    return;
}

sub data_end {
    my ($self, ) = @_;
    $self->append_pack("C", 0x1E, );
    return;
}

sub bell {
    my ($self, ) = @_;
    $self->append_pack("C", 0x07, );
    return;
}

1;

