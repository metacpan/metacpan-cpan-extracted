#==============================================================================
# DEMO: Interactive 12-Month Calendar Grid using Tcl::Tk, perl/Tk syntax
#==============================================================================
# This script demonstrates the usage of the native object-oriented syntax of the
# Perl Tcl::Tk module with perl/Tk syntax.
# See also calendar-tcltk.pl for the Tcl/Tk syntax.
#
# Key Features Demonstrated:
#   - Widget creation with perl/Tk syntax ($mw->Frame, $header->TtkCombobox...)
#   - Dynamic canvas graphics ($m_frame->Canvas) drawing an oval shape
#     on top of textual elements to highlight the current system date
#   - Responsive grid layouts utilizing column/row configure scaling
#
# Layout mirrors a traditional 3x4 monthly wall-calendar view.
#==============================================================================

use strict;
use Tcl::Tk;

# Initialize the Tcl/Tk interpreter
my $mw = Tcl::Tk::MainWindow->new();
$mw->title("Calendar Demo (Tcl::Tk)");
$mw->geometry("850x880");
$mw->configure(-bg => "#ffffff");
my $int = $mw->interp;

# Variable for the current viewing year (linked to the Combobox)
my $view_year_var = 2026;

# Get system date components to highlight "today"
my (undef, undef, undef, $current_day, $current_month, $current_year) = localtime(time);
$current_year  += 1900;
$current_month += 1; # Perl months are 0-11, adjusting to 1-12

my @weekdays = ("M", "T", "W", "T", "F", "S", "S");

# Font styles and color palette
my $font_title = ["Segoe UI", 11, "bold"];
my $font_days  = ["Segoe UI", 9];
my $font_weeks = ["Segoe UI", 8];
my $color_gray  = "#888888";
my $color_dark  = "#222222";
my $color_blue  = "#007acc";

# Inject Ttk styles directly via the Tcl interpreter for proper Combobox scaling
$mw->interp->Eval(<<'TCLLOGIC');
    ttk::style configure TclTkCalendar.TCombobox -font {"Segoe UI", 14, "bold"}
    ttk::style configure TclTkCalendar.TCombobox.Listbox -font {"Segoe UI", 12}
TCLLOGIC

# Calculate weekday index (0=Mon, 6=Sun) using Sakamoto's algorithm
sub get_weekday {
    my ($d, $m, $y) = @_;
    my @t = (0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4);
    $y-- if $m < 3;
    return ($y + int($y/4) - int($y/100) + int($y/400) + $t[$m-1] + $d) % 7;
}

# Determine if a year is a leap year
sub is_leap_year {
    my ($y) = @_;
    return (($y % 4 == 0 && $y % 100 != 0) || ($y % 400 == 0)) ? 1 : 0;
}

# Universal ISO 8601 week number calculation logic
sub get_week_number {
    my ($day, $month, $year) = @_;
    return 1 unless $year =~ /^\d+$/;

    my $leap = is_leap_year($year);
    my $feb_days = $leap ? 29 : 28;
    my @days_in_months = (31, $feb_days, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    
    my $total_days = $day;
    for (my $i = 0; $i < $month - 1; $i++) {
        $total_days += $days_in_months[$i];
    }
    
    my $jan1_wd = get_weekday(1, 1, $year);
    $jan1_wd = ($jan1_wd + 6) % 7;
    
    my $start_diff = ($jan1_wd <= 3) ? $jan1_wd : ($jan1_wd - 7);
    my $week = int(($total_days + $start_diff + 6) / 7);
    
    # Handle end-of-year and beginning-of-year overflows
    if ($week == 0) {
        return get_week_number(31, 12, $year - 1);
    }
    if ($month == 12 && $day >= 29) {
        my $dec31_wd = get_weekday(31, 12, $year);
        $dec31_wd = ($dec31_wd + 6) % 7;
        if (($day - $dec31_wd) >= 30) {
            return 1;
        }
    }
    return $week;
}

# --- Header Section (Navigation controls) ---
my $header = $mw->Frame(-bg => "#ffffff", -pady => 10)->pack(-fill => 'x');

# Step backward button
my $btn_prev = $header->Button(
    -text => "<", -font => $font_title, -fg => $color_dark, -bg => "#ffffff",
    -activebackground => "#f0f0f0", -relief => "flat", -overrelief => "raised",
    -command => sub { $view_year_var--; draw_calendar($view_year_var) }
)->pack(-side => 'left', -padx => [50, 10]);

# TtkCombobox for year selection and manual editing
my $combo = $header->TtkCombobox(
    -textvariable => \$view_year_var,
    -style => 'TclTkCalendar.TCombobox',
    -values => [2020..2035],
    -width => 8, -justify => 'center'
)->pack(-side => 'left', -expand => 1);

# Step forward button
my $btn_next = $header->Button(
    -text => ">", -font => $font_title, -fg => $color_dark, -bg => "#ffffff",
    -activebackground => "#f0f0f0", -relief => "flat", -overrelief => "raised",
    -command => sub { $view_year_var++; draw_calendar($view_year_var) }
)->pack(-side => 'right', -padx => [10, 50]);

# Bind Combobox selection and manual Enter key press events to refresh the UI
$combo->bind('<<ComboboxSelected>>', sub { apply_typed_year() });
$combo->bind('<Return>', sub { apply_typed_year() });

# --- Main Calendar Grid Section ---
my $main_frame = $mw->Frame(-bg => "#ffffff", -padx => 10, -pady => 10)->pack(-fill => 'both', -expand => 1);

# Core subroutine to render/refresh the 12-month calendar grid
sub draw_calendar {
    my ($year) = @_;
    
    # Safely clear previous months' widgets before rebuilding the grid
    for my $child ($int->winfo('children',$main_frame)) {
        $int->widget($child)->destroy;
    }
    
    return if !$year || $year !~ /^\d+$/ || $year < 1;
    
    my $leap = is_leap_year($year);
    my $feb_days = $leap ? 29 : 28;
    
    my @months = (
	["January $year", 31],   ["February $year", $feb_days], ["March $year", 31],
	["April $year", 30],     ["May $year", 31],            ["June $year", 30],
	["July $year", 31],      ["August $year", 31],         ["September $year", 30],
	["October $year", 31],   ["November $year", 30],        ["December $year", 31]
    );
    
    # Iterate through each month and render its grid row by row
    for (my $m_idx = 1; $m_idx <= 12; $m_idx++) {
        my $m_data = $months[$m_idx - 1];
        my $m_name = $m_data->[0];
        my $m_days = $m_data->[1];
        
        # Calculate 3x4 grid positions
        my $row = int(($m_idx - 1) / 3);
        my $col = ($m_idx - 1) % 3;
        
        my $m_frame = $main_frame->Frame(-bg => "#ffffff", -padx => 10, -pady => 5);
        $m_frame->grid(-row => $row, -column => $col, -padx => 10, -pady => 5, -sticky => 'nsew');
        
        # Month header label
        my $lbl_title = $m_frame->Label(-text => $m_name, -font => $font_title, -fg => $color_dark, -bg => "#ffffff");
        $lbl_title->grid(-row => 0, -column => 0, -columnspan => 8, -pady => [0, 8]);
        
        # Render weekday column headers
        my $c = 0;
        for my $wd (@weekdays) {
            my $lbl_wd = $m_frame->Label(-text => $wd, -font => $font_days, -fg => $color_gray, -bg => "#ffffff");
            $lbl_wd->grid(-row => 1, -column => $c, -padx => 4, -pady => 1);
            $c++;
        }
        
        # Spacer column for week numbers alignment
        my $lbl_wn_empty = $m_frame->Label(-text => "", -bg => "#ffffff");
        $lbl_wn_empty->grid(-row => 1, -column => 7, -padx => [6, 0]);
        
        # Determine the layout shift offset for the 1st day of the month (0=Mon, 6=Sun)
        my $first_wd = get_weekday(1, $m_idx, $year);
        $first_wd = ($first_wd + 6) % 7;
        
        my $r = 2;
        my $col_curr = $first_wd;
        my %month_weeks;
        
        # Render days
        for (my $d = 1; $d <= $m_days; $d++) {
            # Highlight current real-world date using a small Canvas circle
            if ($year == $current_year && $m_idx == $current_month && $d == $current_day) {
                my $canv = $m_frame->Canvas(-width => 22, -height => 22, -bg => "#ffffff", -highlightthickness => 0);
                $canv->create('oval', 1, 1, 21, 21, -outline => $color_blue, -width => 2);
                $canv->create('text', 11, 11, -text => $d, -font => $font_days, -fill => $color_dark, -justify => 'center');
                $canv->grid(-row => $r, -column => $col_curr, -pady => 1, -padx => 1);
            } else {
                my $lbl_day = $m_frame->Label(-text => $d, -font => $font_days, -fg => $color_dark, -bg => "#ffffff", -width => 3, -anchor => 'center');
                $lbl_day->grid(-row => $r, -column => $col_curr, -pady => 1);
            }
            
            # Map week numbers to active grid rows
            my $w_num = get_week_number($d, $m_idx, $year);
            $month_weeks{$r} = $w_num;
            
            $col_curr++;
            if ($col_curr == 7) {
                $col_curr = 0;
                $r++;
            }
        }
        
        # Render week numbers in the rightmost column (column index 7)
        while (my ($row_id, $wn) = each %month_weeks) {
            my $lbl_wn = $m_frame->Label(-text => $wn, -font => $font_weeks, -fg => $color_gray, -bg => "#ffffff");
            $lbl_wn->grid(-row => $row_id, -column => 7, -padx =>[8, 0], -sticky => 'e');
        }
    }
    
    # Configure 3x4 grid cells weight for uniform window resizing
    $main_frame->gridColumnconfigure($_, -weight => 1) for (0..2);
    $main_frame->gridRowconfigure($_, -weight => 1) for (0..3);
}

# Handler callback for Combobox selection modifications
sub apply_typed_year {
    my $y = $view_year_var;
    if ($y && $y =~ /^\d+$/ && $y > 0) {
        draw_calendar($y);
    }
}

# Fire up the initial layout processing loop
draw_calendar($view_year_var);

# Main Tk window event loop handler processing
Tcl::Tk::MainLoop();

