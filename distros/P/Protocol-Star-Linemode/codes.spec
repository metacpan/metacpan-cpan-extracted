prefix 0x1B
    command_initialization              0   0x40
    select_font                         1   0x1E 0x46
    select_code_page                    1   0x1D 0x74
    set_slash_zero                      1   0x27
    specify_international_charset       1   0x52
    specify_12_dot_pitch                0   0x4D
    specify_15_dot_pitch                0   0x50
    specify_16_dot_pitch                0   0x3A
    specify_14_dot_pitch                0   0x67
    set_expanded_width_height           2   0x69
    set_expanded_width                  1   0x57
    set_expanded_height                 1   0x68
    set_double_high                     0   0x0E
    cancel_double_high                  0   0x14
    set_emphasized_printing             0   0x45
    cancel_emphasized_printing          0   0x46
    select_underline_mode               1   0x2D
    select_upperline_mode               1   0x5F
    select_inverse                      0   0x34
    cancel_inverse                      0   0x35
    feed_n_lines                        1   0x61
    set_page_length                     1   0x43
    set_page_length_in_24mm_units       1   0x43 0x00
    set_left_margin                     1   0x6C
    set_right_margin                    1   0x51
    skip_lines                          1   0x61
    cut                                 0   0x64 0x33
    barcode_ean13                       1   0x62 0x03 0x02 0x01
    barcode_code128                     1   0x62 0x06 0x02 0x01
end

prefix 0x1B 0x1D
    move_absolute_position              2   0x41
    move_relative_position              2   0x52
    specify_alignment                   1   0x61
end

prefix 0x1B 0x1D 0x61
    align_left                          0   0x00
    align_center                        0   0x01
    align_right                         0   0x02
end

set_double_wide     1   0x0E
cancel_double_wide  1   0x14
select_upside_down  0   0x0F
cancel_upside_down  0   0x12
lf                  0   0x0A
cr                  0   0x13
crlf                0   0x13 0x0A
form_feed           0   0x0C
vertical_tab        0   0x0B
horizontal_tab      0   0x09
data_end            0   0x1E
bell                0   0x07

