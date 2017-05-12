# perl
#
# Class Report::Porf::HtmlReportConfigurator
#
# Perl Open Report Framework (Porf)
#
# Configures a Report::Porf::Table::Simple to write out HTML tables
#
# Ralf Peine, Tue May 27 11:29:32 2014
#
# More documentation at the end of file
#------------------------------------------------------------------------------

$VERSION = "2.001";

#------------------------------------------------------------------------------
#
# Example list with 10 lines (html)
# 
# <html>
# <table border='1' rules='groups'>
#                                         
# <thead>
# <tr><th>Coun</th><th>TimeStamp </th><th>Age    </th><th>Prename    </th><th>Surname </th></tr>
# </thead>
#                                         
# <tr><td>1   </td><td>0.000433  </td><td>10     </td><td>Vorname 1  </td><td>Name 1  </td></tr>
# <tr><td>2   </td><td>0.000638  </td><td>20     </td><td>Vorname 2  </td><td>Name 2  </td></tr>
# <tr><td>3   </td><td>0.000781  </td><td>30     </td><td>Vorname 3  </td><td>Name 3  </td></tr>
# <tr><td>4   </td><td>0.000922  </td><td>40     </td><td>Vorname 4  </td><td>Name 4  </td></tr>
# <tr><td>5   </td><td>0.001062  </td><td>50     </td><td>Vorname 5  </td><td>Name 5  </td></tr>
# <tr><td>6   </td><td>0.001203  </td><td>60     </td><td>Vorname 6  </td><td>Name 6  </td></tr>
# <tr><td>7   </td><td>0.001346  </td><td>70     </td><td>Vorname 7  </td><td>Name 7  </td></tr>
# <tr><td>8   </td><td>0.001486  </td><td>80     </td><td>Vorname 8  </td><td>Name 8  </td></tr>
# <tr><td>9   </td><td>0.001631  </td><td>90     </td><td>Vorname 9  </td><td>Name 9  </td></tr>
# <tr><td>10  </td><td>0.001773  </td><td>100    </td><td>Vorname 10 </td><td>Name 10 </td></tr>
#                                         
# </table><p/>
# # Time needed for export of 10 data lines: 0.002013
# 
# </html>
# 

use strict;
use warnings;

#--------------------------------------------------------------------------------
#
#  Report::Porf::Table::Simple::HtmlReportConfigurator;
#
#--------------------------------------------------------------------------------

package Report::Porf::Table::Simple::HtmlReportConfigurator;

use Carp;

use Report::Porf::Util;
use Report::Porf::Table::Simple;

#--------------------------------------------------------------------------------
#
#  Creation / Filling Of Instances
#
#--------------------------------------------------------------------------------

# --- create Instance -----------------
sub new
{
    my $caller = $_[0];
    my $class  = ref($caller) || $caller;
    
    # let the class go
    my $self = {};
    bless $self, $class;

    $self->_init();
    
    return $self;
}

# --- Init ------------------------------------------------------------------

sub _init {
    my ($self        # instance_ref
        ) = @_;
    $self->{AlternateRowColors} = [];
	$self->set_escape_special_chars_action(\&Report::Porf::Util::escape_html_special_chars);
}

# --- verbose ---------------------------------------------------------------

sub set_verbose {
    my ($self,        # instance_ref
        $value        # value to set
        ) = @_;
    
    $self->{verbose} = $value;
}

sub get_verbose {
    my ($self,        # instance_ref
        ) = @_;
    
    return $self->{verbose};
}

# --- Text in op of table ------------------------------------------------------

sub set_table_top_text {
    my $self = shift;        # instance_ref

    $self->{TableTopText} = shift;
}

sub get_table_top_text {
    my $self = shift;        # instance_ref

    return $self->{TableTopText};
}
# --- Alternate Row Colors ------------------------------------------------------

sub set_alternate_row_colors {
    my $self = shift;        # instance_ref

    $self->{AlternateRowColors} = [];
    push (@{$self->{AlternateRowColors}}, @_);
}

sub get_alternate_row_colors {
    my ($self,        # instance_ref
        ) = @_;
    
    return @{$self->{AlternateRowColors}};
}

# --- escape special chars ---------------------------------------------------------------

sub set_escape_special_chars_action {
    my ($self,        # instance_ref
        $value        # value to set
        ) = @_;

    $self->{escape_special_chars_action} = $value;
}

sub get_escape_special_chars_action {
    my ($self,        # instance_ref
        ) = @_;
    
    return $self->{escape_special_chars_action};
}

# --- Add Attribute bgColor ------------------------------------------------------
sub add_background_color_attribute {
    return add_optional_attribute('bgcolor', @_);
}

# --- Add Attribute ------------------------------------------------------
sub add_optional_attribute {
    my $name      = shift;
    my $value_str = shift;

    return " $name=\"$value_str\"" if (defined $value_str && $value_str ne '');

    return '';
}
#--------------------------------------------------------------------------------
#
#  Configure formats
#
#--------------------------------------------------------------------------------

# --- create new report and configure -------------------------------------------
sub create_and_configure_report {
    my ($self  # instance_ref
        ) = @_;

    return $self->configure_report(Report::Porf::Table::Simple->new());
}

# --- Configure Export For Html ------------------------------------------------
sub configure_report {
    my ($self,                  # instance_ref
        $report2configure,      # report to be configured
        ) = @_;

    $report2configure->set_format('HTML');

    # $self->set_default_column_width (10);
    $report2configure->set_default_align       ('Left');

    $report2configure->set_file_start("<html>\n");
    $report2configure->set_file_end  ("</html>\n");

    my $tableTopText = $self->get_table_top_text();
    $tableTopText = '' unless $tableTopText;
    $tableTopText = "<h2>$tableTopText</h2>\n" if $tableTopText;

    $report2configure->set_table_start("$tableTopText<table border='1'  rules='all'>\n");
    $report2configure->set_table_end  ("</table><p/>\n");

    my @row_colors = $self->get_alternate_row_colors();
    my $switch = -1;

    if ( scalar @row_colors) {
        $report2configure->set_table_start("$tableTopText<table border='1' rules='cols'>\n");
        $report2configure->set_row_start(
            sub
            {
                $switch++;
                $switch = $[ if $switch >= scalar @row_colors;
                return '<tr bgcolor="'.$row_colors[$switch].'">';
            });
    }
    else {
        $report2configure->set_row_start('<tr>');
    }
    
    $report2configure->set_row_end  ("</tr>\n");
    
    $report2configure->set_header_row_start("<thead>\n<tr>");
    $report2configure->set_header_row_end  ("</tr>\n</thead>\n");
    $report2configure->set_header_start("<th>");
    $report2configure->set_header_end  ("</th>");
    
    $report2configure->set_cell_start( sub { return "'<td '".$_[0].".'>'"; });
    $report2configure->set_cell_end  ('</td>');

    $report2configure->set_horizontal_separation_start           ("<hr>");
    $report2configure->set_horizontal_separation_end             ("</hr>\n");

    my %AlignmentToHtml = (
        Left   => 'left',
        Center => 'center',
        Right  => 'right'
        );
    
    #===================================================================================
    #
    #  Configure Actions, no need to speed up
    #
    #===================================================================================

    # === Column store Action ============================================================
    $report2configure->set_configure_column_action(
        sub {
            my $report  = shift; # instance_ref
            my %options = @_;    # options
            
            print_hash_ref(\%options) if verbose($report, 2);
            
            my $left  = "";   # left from value
            my $right = "";   # right from value

            my $column_attributes = ""; # Attributes in td-Element

            # --- default value ---------------------------------------
			my $default_value = get_option_value(\%options, qw (-default_value -def_val -dv));
			$default_value = $report->get_default_cell_value() unless defined $default_value;

            # --- value ---------------------------------------
            my $value         = interprete_value_options(\%options);
            my $value_ref     = ref($value);
            my $value_action;

            die "value action not defined" unless defined $value;
            
            if ( $value_ref) {
                if ($value_ref =~ /^CODE/) {
                    $value_action = $value;
                }
                else {
                    # or what ??
                    die "# ref(value_ref) = $value_ref unknown";
                    # $value_action = eval ("sub { return $$value; };");
                }
            }
            else {
				$value        = complete_value_code($value, $default_value);
                $value_action = $report->create_action("$value;");
            }

            # --- format value ----------------------------------------
            my $format = get_option_value(\%options, qw (-format -f));

            if ($format) {
                my $format_ref = ref($format);

                die "You used a '$format_ref' type to set the 'Format', "
                    ."but currently only strings are supported!"
                    if $format_ref;
                
                print "format $format\n" if verbose($report, 3);

                $left   = "sprintf(\"$format\", ".$left;
                $right .= ")";
            }

            # --- escape special chars ----------------------------------------
            my $escape_special_chars = get_option_value(\%options, qw (-escape_special_chars -esc_spec_chr -esc));

			my $do_escape_special_chars = 1;
			if (defined $escape_special_chars) {
				$do_escape_special_chars = $escape_special_chars;
			}

			my $esc_action = $self->get_escape_special_chars_action();
			$do_escape_special_chars = 0 unless $esc_action;

			if ($do_escape_special_chars) {
                $left   = '$esc_action->('.$left;
                $right .= ')';
			}
	
            # --- coloring --------------------------------------------
            my $color = get_option_value(\%options, qw (-color -c));
            my $color_action = undef;

            if ($color) {
                my $color_ref = ref($color);
                
                if ( $color_ref) {
                    if ($color_ref =~ /^CODE/) {
                        $color_action = $color;
                        $column_attributes .= '. add_background_color_attribute($color_action->($_[0]))';
                    }
                    else {
                        # or what ??
                        die "# ref(color_ref) = $color_ref unknown";
                    }
                }
                else {
                    $column_attributes .= ".'" . add_background_color_attribute($color) ."'";
                }
            }

            # --- width is currently not supported ---------------------
            my $width = get_option_value(\%options, qw (-width -w));

            print "width is currently not supported for html (width = $width)\n" if verbose($report, 3)  &&  $width;
            
            # --- align -----------------------------------------------
            my $align = get_option_value(\%options, qw (-align -a));

            if ($align) {
                my $align_ref = ref($align);

                die "You used a '$align_ref' type to set the 'Align', "
                    ."but currently only strings are supported!"
                    if $align_ref;

                $align = interprete_alignment($align);
            }
            else {
                $align = $report->get_default_align();
            }

            print "align $align\n" if verbose($report, 3);
            my $column_align = $AlignmentToHtml{$align};

            $column_attributes .= '.\' align="'.$column_align.'"\'';
            
            # --- configure header ----------------------------

            my $header_text = get_option_value(\%options, qw (-header -h));
            $header_text = '' unless defined $header_text;
            push (@{$report->get_header_texts_ref()}, $header_text);
            
            # --- ---------------------------------------------
            # --- ---------------------------------------------
            # --- ---------------------------------------------

            # --- build cell content action ---------------------------------------------
            my $cell_action_str = $left.'$value_action->($_[0])'.$right;

            my $cell_start = $report->get_cell_start()->($column_attributes);
            my $cell_end   = $report->get_cell_end();

            my $eval_str = 'sub { return '.$cell_start.".".$cell_action_str.'.$cell_end; }';

            print "### eval_str = $eval_str\n"
                if verbose($report, 3);
            
            my $cell_action = eval ($eval_str);

            die $@ if $@;
            
            print "### ref(cell_action) ".ref($cell_action) ."\n" if verbose($report, 3);
            
            $report->add_cell_output_action($cell_action);
        });

    # === Configure Complete Action ====================================================
    $report2configure->set_configure_complete_action(
        sub {
            my ($report,        # instance_ref
                ) = @_;

            my $row_start     = $report->get_row_start();
            my $row_start_ref = ref($row_start);

            if ( $row_start_ref) {
                if ($row_start_ref =~ /^CODE/) {
                    $row_start = $row_start->(); # replace sub by content of call
                }
                else {
                    # or what ??
                    die "# ref(row_start_ref) = $row_start_ref unknown";
                    # $value_action = eval ("sub { return $$value; };");
                }
            }

            my $cell_start     = $report->get_cell_start();
            my $cell_start_ref = ref($cell_start);

            if ( $cell_start_ref) {
                if ($cell_start_ref =~ /^CODE/) {
                    $cell_start = eval ($cell_start->('')); # replace sub by content of call
                }
                else {
                    # or what ??
                    die "# ref(cell_start_ref) = $cell_start_ref unknown";
                    # $value_action = eval ("sub { return $$value; };");
                }
            }

            my $sep = $row_start;
            
            foreach my $idx (1..scalar(@{$report->get_cell_output_actions()})) {
                $sep .= $cell_start."<hr/>".$report->get_cell_end();
            }

            $sep .= $report->get_row_end();
            
            $report->set_header_line    ($sep);
            $report->set_separator_line ($sep);
        });
    
    #===================================================================================
    #
    #  Runtime Actions, no need to speed up
    #
    #===================================================================================

    # === Header Output Action ============================================================
    $report2configure->set_header_output_action(
        sub {
            my ($report,        # instance_ref
                $data_ref       # data to output
                ) = @_;

            my $header_string = $report->get_header_row_start();
            foreach my $header_text (@{$data_ref}) {
                $header_string .= $report->get_header_start()
                    .$header_text
                    .$report->get_header_end();
            }

            $header_string .= $report->get_header_row_end();

            print "### Header String:$header_string" if verbose($report, 2);
            
            return $header_string;
        });

    # === Start Table Output Action ============================================================
    $report2configure->set_start_table_output_action(
        sub {
            my ($report,        # instance_ref
                $data_ref       # data to output
                ) = @_;

            return $report->get_file_start()
                .$report->get_table_start()
                .$report->get_header_output();
            
        });

    # === End Table Output Action ============================================================
    $report2configure->set_end_table_output_action(
        sub {
            my ($report,        # instance_ref
                $data_ref       # data to output
                ) = @_;

            return $report->get_table_end()
                .$report->get_file_end();
        });

    #===================================================================================
    #
    #  Runtime Mass Data Actions, be careful, don't slow it down !!
    #
    #===================================================================================

    my $previous_data_ref = '';

    # === Row Output Action ============================================================
    $report2configure->set_row_output_action(
        sub {
            my ($report,        # instance_ref
                $data_ref       # data to output
                ) = @_;

            my $row_start     = $report->get_row_start();
            my $row_start_ref = ref($row_start);

            if ( $row_start_ref) {
                if ($row_start_ref =~ /^CODE/) {
                    $row_start = $row_start->(); # replace sub by content of call
                }
                else {
                    # or what ??
                    die "# ref(row_start_ref) = $row_start_ref unknown";
                    # $value_action = eval ("sub { return $$value; };");
                }
            }

            my $row_string = '';

            # --- Add something when group changes ----
            my $row_group_changes_action = $report->get_row_group_changes_action();

            $row_string .= $row_group_changes_action->($previous_data_ref, $data_ref)
                if $row_group_changes_action;

            $previous_data_ref = $data_ref;

            # --- start new row -----------------------
            $row_string .= $row_start;

            my $cell_output_actions_ref = $report->get_cell_output_actions();

            foreach my $action (@$cell_output_actions_ref) {
                print "### action $action\n" if verbose($report, 4);
                $row_string .= $action->($data_ref);
            }

            $row_string .= $report->get_row_end();

            print "### Row String:$row_string" if verbose($report, 2);
            
            return $row_string;
        });

    return $report2configure;
}

1;

=head1 NAME

C<Report::Porf::Table::Simple::HtmlReportConfigurator>

Configures a Report::Porf::Table::Simple to write out HTML tables.

Part of Perl Open Report Framework (Porf).

=head1 Documentation

See Report::Porf::Framework.pm for documentation of features and usage.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 by Ralf Peine, Germany.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
