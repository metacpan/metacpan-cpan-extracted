package PDF::Table::Settings;

use strict;
use warnings;

use Carp;

our $VERSION = '1.003'; # VERSION
our $LAST_UPDATE = '1.003'; # manually update whenever code is changed

###########################################################
# move deprecated settings names to current names, and delete old
# assume any leading '-' already removed
# warning if both deprecated and new name given (use new)
# release at T-6 months, consider issuing warning to remind update needed
# release at T-0 months, give warning on use of deprecated items
# release at T+12 months, remove deprecated names
############################################################

sub deprecated_settings {
    my ($data, $row_props, $col_props, $cell_props, $header_props, $argref) = @_;
# 1 $row_props, 2 $col_props, 3 $cell_props, 4 $header_props
# need to use $_[n] form so that its call be reference, not value
#my $data = $_[0]; 
#my $argref = $_[5];
#my %arg = %{$argref};

    my %cur_names = (
        # old deprecated name        new current name
        #  (old_key)
        'start_y'               => 'y',
        'start_h'               => 'h',
        'row_height'            => 'min_rh',
        'background_color'      => 'bg_color',
        'background_color_odd'  => 'bg_color_odd',
        'background_color_even' => 'bg_color_even',
        'font_color'            => 'fg_color',
        'font_color_odd'        => 'fg_color_odd',
        'font_color_even'       => 'fg_color_even',
        'font_underline'        => 'underline',
       #'justify'               => 'align',  # different set of values allowed
        'lead'                  => 'leading',
        'border'                => 'border_w',
        'horizontal_borders'    => 'h_border_w',
        'vertical_borders'      => 'v_border_w',
        'border_color'          => 'border_c',
        # currently same color for H and V borders
    );

    # global arg
    foreach my $old_key (keys %cur_names) {
        if (defined $argref->{$old_key}) {
            # set deprecated name setting (need to transfer to new name).
            # did we also set new name setting?
            if (defined $argref->{$cur_names{$old_key}}) {
                carp "!! Warning !! both deprecated global name '$old_key' and current name '$cur_names{$old_key}' given, current name's value used.";
            } else {
                $argref->{$cur_names{$old_key}} = $argref->{$old_key};
                delete $argref->{$old_key};
                # eventually given warning to stop using $old_key
            }
        }
    }

    # row properties
    foreach my $old_key (keys %cur_names) {
        for (my $row = 0; $row < scalar(@$data); $row++) {
            if (defined $row_props->[$row]->{$old_key}) {
                # set deprecated name setting (need to transfer to new name).
                if (defined $row_props->[$row]->{$cur_names{$old_key}}) {
                    # did we also set new name setting?
                    carp "!! Warning !! both deprecated name '$old_key' and current name '$cur_names{$old_key}' given in row_props[$row], current name's value used.";
                } else {
                    # transfer deprecated setting to new
                    $row_props->[$row]->{$cur_names{$old_key}} = $row_props->[$row]->{$old_key};
                    delete $row_props->[$row]->{$old_key};
                    # eventually given warning to stop using $old_key
                }
            }
        }
    }

    # column properties
    foreach my $old_key (keys %cur_names) {
        for (my $col = 0; $col < scalar(@{$col_props}); $col++) {
            if (defined $col_props->[$col]->{$old_key}) {
                # set deprecated name setting (need to transfer to new name).
                if (defined $col_props->[$col]->{$cur_names{$old_key}}) {
                    # did we also set new name setting?
                    carp "!! Warning !! both deprecated name '$old_key' and current name '$cur_names{$old_key}' given in column_props[$col], current name's value used.";
                } else {
                    # transfer deprecated setting to new
                    $col_props->[$col]->{$cur_names{$old_key}} = $col_props->[$col]->{$old_key};
                    delete $col_props->[$col]->{$old_key};
                    # eventually given warning to stop using $old_key
                }
            }
        }
    }

    # cell properties
    foreach my $old_key (keys %cur_names) {
        for (my $row = 0; $row < scalar(@$data); $row++) {
            for ( my $col = 0; 
              $col < scalar(@{$data->[$row]}); 
              $col++ ) {
                if (defined $cell_props->[$row][$col]->{$old_key}) {
                    # set deprecated name setting (need to transfer to new name).
                    if (defined $cell_props->[$row][$col]->{$cur_names{$old_key}}) {
                        # did we also set new name setting?
                        carp "!! Warning !! both deprecated name '$old_key' and current name '$cur_names{$old_key}' given in cell_props[$row][$col], current name's value used.";
                    } else {
                        # transfer deprecated setting to new
                        $cell_props->[$row][$col]->{$cur_names{$old_key}} = $cell_props->[$row][$col]->{$old_key};
                        delete $cell_props->[$row][$col]->{$old_key};
                        # eventually given warning to stop using $old_key
                    }
                }
            }
        }
    }

    # header properties
    if ($header_props) {
        foreach my $old_key (keys %cur_names) {
            if (defined $header_props->{$old_key}) {
                # set deprecated name setting (need to transfer to new name).
                # did we also set new name setting?
                if (defined $header_props->{$cur_names{$old_key}}) {
                    carp "!! Warning !! both deprecated header name '$old_key' and current name '$cur_names{$old_key}' given, current name's value used.";
                } else {
                    $header_props->{$cur_names{$old_key}} = $header_props->{$old_key};
                    delete $header_props->{$old_key};
                    # eventually given warning to stop using $old_key
                }
            }
        }
    }

    return;
} # end of deprecated_settings()

############################################################
# validate/fix up settings and parameters as much as possible     TBD per #12
############################################################

sub check_settings {
    my (%arg) = @_;

    # TBD $arg{} values, some col, row, cell, header?
    # x, y >= 0; w, h >= 0; x+w < page width; y+h < page height
    # next_h (if def) > 0, next_y (if def) >= 0; next_y+next_h < page height
    # line widths >= 0, min_rh > 0
    # TBD in general, validate integer values and possibly some
    #     other values, per #12
    return;
} # end of check_settings()

1;
