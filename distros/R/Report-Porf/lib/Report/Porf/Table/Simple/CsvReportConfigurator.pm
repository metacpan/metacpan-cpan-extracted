# perl
#
# Class Report::Porf::Table::Simple::CsvReportConfigurator
#
# Perl Open Report Framework (Porf)
#
# Configures a Report::Porf::Table::Simple to write out ASCII- or UTF-Csv tables
#
# Ralf Peine, Tue May 27 11:29:22 2014
#
# More documentation at the end of file
#------------------------------------------------------------------------------

$VERSION = "2.001";

#------------------------------------------------------------------------------
#
# Example list with 10 lines (csv)
#
# # Count,Prename,Surname,Age,TimeStamp
# 1,Vorname 1,Name 1,10,0.002329
# 2,Vorname 2,Name 2,20,0.003106
# 3,Vorname 3,Name 3,30,0.003822
# 4,Vorname 4,Name 4,40,0.004533
# 5,Vorname 5,Name 5,50,0.005235
# 6,Vorname 6,Name 6,60,0.005944
# 7,Vorname 7,Name 7,70,0.006656
# 8,Vorname 8,Name 8,80,0.007362
# 9,Vorname 9,Name 9,90,0.008069
# 10,Vorname 1,Name 10,100,0.008779
#
# # Time needed for export of 10 data lines: 0.001954
#
#------------------------------------------------------------------------------

use strict;
use warnings;

#--------------------------------------------------------------------------------
#
#  Report::Porf::Table::Simple::CsvReportConfigurator;
#
#--------------------------------------------------------------------------------

package Report::Porf::Table::Simple::CsvReportConfigurator;

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
	$self->set_data_separator_char(',');
	$self->set_data_string_char('"');
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

# --- DataSeparatorChar ---------------------------------------------------------

sub set_data_separator_char {
    my ($self,        # instance_ref
        $value        # value to set
        ) = @_;
    
    $self->{DataSeparatorChar} = $value;
}

sub get_data_separator_char {
    my ($self,        # instance_ref
        ) = @_;
    
    return $self->{DataSeparatorChar};
}

# --- DataStringChar ---------------------------------------------------------

sub set_data_string_char {
    my ($self,        # instance_ref
        $value        # value to set
        ) = @_;
    
    $self->{DataStringChar} = $value;
}

sub get_data_string_char {
    my ($self,        # instance_ref
        ) = @_;
    
    return $self->{DataStringChar};
}

#--------------------------------------------------------------------------------
#
#  Configure format
#
#--------------------------------------------------------------------------------

# --- create new report and configure -------------------------------------------
sub create_and_configure_report {
    my ($self  # instance_ref
        ) = @_;

    return $self->configure_report(Report::Porf::Table::Simple->new());
}

# --- Configure Export For Csv ------------------------------------------------
sub configure_report {
    my ($self,                  # instance_ref
        $report2configure,      # report to be configured
        ) = @_;

    # $report2configure->set_default_column_width (10);
    $report2configure->set_default_align       ('Left');

    $report2configure->set_file_start('');
    $report2configure->set_file_end  ('');

    $report2configure->set_table_start("");
    $report2configure->set_table_end  ("");

    $report2configure->set_row_start("");
    $report2configure->set_row_end  ("\n");
    
    $report2configure->set_header_row_start("# ");
    $report2configure->set_header_row_end  ("\n");
    $report2configure->set_header_start("");
    $report2configure->set_header_end  ($self->get_data_separator_char());
    
    $report2configure->set_cell_start("");
    $report2configure->set_cell_end  ($self->get_data_separator_char());

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

            my $cell_start = $report->get_cell_start();
            my $cell_end   = $report->get_cell_end();

            my $left       = "";   # left from value
            my $right      = "";   # right from value

            # --- default value ---------------------------------------
			my $default_value = get_option_value(\%options, qw (-default_value -def_val -dv));
			$default_value = $report->get_default_cell_value() unless defined $default_value;

            # --- value ---------------------------------------
            my $value         = interprete_value_options(\%options);
            my $value_ref     = ref($value);
            my $value_action;

            die "value action not defined" unless defined $value;
            
            if ($value_ref) {
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

            # --- coloring is not supported for csv ------------------
            my $color = get_option_value(\%options, qw (-color -c));

            print "color cannot be supported for csv (color = $color)\n" if verbose($report, 3)  &&  $color;

            # --- width / align ---------------------------------------
            my $width = get_option_value(\%options, qw (-width -w));
            my $align = get_option_value(\%options, qw (-align -a));

            print "width cannot be supported for csv (width = $width)\n" if verbose($report, 3)  &&  $width;
            print "align cannot be supported for csv (align = $align)\n" if verbose($report, 3)  &&  $align;
            
            # --- configure header ----------------------------

            my $header_text = get_option_value(\%options, qw (-header -h));
            $header_text = '' unless defined $header_text;
            push (@{$report->get_header_texts_ref()}, $header_text);
            
            # --- ---------------------------------------------
            # --- ---------------------------------------------
            # --- escape separator / string char ----------------------------------------

			my $sep_char = $self->get_data_separator_char();
			my $string_char = $self->get_data_string_char();
			
			my $escape_sep_char_sub_ref = sub {
				my $value = $_[0];

				if ($value =~ /$sep_char|$string_char/) {
					$value =~ s/$string_char/$string_char$string_char/g;
					$value = "$string_char$value$string_char";
				}

				return $value;
			};
			
			$left   = '$escape_sep_char_sub_ref->('.$left;
			$right .= ")";
			
            # --- build cell content action ---------------------------------------------
            my $cell_action_str = $left.'$value_action->($_[0])'.$right;

            my $eval_str = 'sub { return $cell_start.'.$cell_action_str.'.$cell_end; }';

            print "### eval_str = sub { return $cell_start$cell_action_str$cell_end; }\n"
                if verbose($report, 3);
            
            my $cell_action = eval ($eval_str);
            
            print "### ref(cell_action) ".ref($cell_action) ."\n" if verbose($report, 3);
            
            $report->add_cell_output_action($cell_action);
        });

    # === Configure Complete Action ====================================================
    $report2configure->set_configure_complete_action(
        sub {
            my ($report,        # instance_ref
                ) = @_;

            $report->set_header_line    ('');
            $report->set_separator_line ('');
            $report->set_bold_header_line('');
        });
    
	my $cell_end = $report2configure->get_cell_end();

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
            my $c = 0;
            foreach my $header_text (@{$data_ref}) {
                $header_string .= $report->get_header_start()
                    .$header_text
                    .$report->get_header_end();
                $c++;
            }

			$header_string =~ s/$cell_end$//;
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

            my $cell_output_actions_ref = $report->get_cell_output_actions();

            my $row_string = '';

            # --- Add something when group changes ----
            my $row_group_changes_action = $report->get_row_group_changes_action();
            
            $row_string .= $row_group_changes_action->($previous_data_ref, $data_ref)
                if $row_group_changes_action;

            $previous_data_ref = $data_ref;

            # --- start new row -----------------------
            $row_string .= $report->get_row_start();
            foreach my $action (@$cell_output_actions_ref) {
                print "### action $action\n" if verbose($report, 4);
                $row_string .= $action->($data_ref);
            }

			$row_string =~ s/$cell_end$//;		
            $row_string .= $report->get_row_end();

            print "### Row String:$row_string" if verbose($report, 2);
            
            return $row_string;
        });

    return $report2configure;
}
1;

=head1 NAME

C<Report::Porf::Table::Simple::CsvReportConfigurator>

Configures a Report::Porf::Table::Simple to write out Csv files.

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
