#==============================================================================
# DEMO: Interactive 12-Month Calendar Grid using Tcl::Tk, Tcl/Tk syntax
#==============================================================================
# This script demonstrates the usage of Perl Tcl::Tk module using Tcl/Tk syntax
# with possible fallback to perl/Tk syntax.
# See also calendar-tcltk.pl for the perl/Tk syntax.
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
my $int = $mw->interp;

$int->Eval(<<'EOS');
# Main window configuration
wm title . "Interactive Calendar (Tcl/Tk)"
wm geometry . "850x880"
. configure -bg "#ffffff"

# Active viewing year variable
set view_year 2026

# Fetch system date properties to dynamic-track the "today" highlight
set system_time [clock seconds]
set current_day   [string trim [clock format $system_time -format "%e" -locale system]]
set current_month [string trim [clock format $system_time -format "%m" -locale system] "0"]
set current_year  [clock format $system_time -format "%Y" -locale system]

# Cyrillic single-letter weekday names matching the user's template
set weekdays {"M" "T" "W" "T" "F" "S" "S"}

# Visual design constants (fonts and colors)
set font_title {"Segoe UI" 11 "bold"}
set font_days  {"Segoe UI" 9}
set font_weeks {"Segoe UI" 8}
set color_gray "#888888"
set color_dark "#222222"
set color_blue "#007acc"

# Apply styling parameters to the Ttk Combobox and its drop-down list box
ttk::style configure Calendar.TCombobox -font {"Segoe UI" 14 "bold"}
ttk::style configure Calendar.TCombobox.Listbox -font {"Segoe UI" 12}

# Compute standard weekday indexes (0=Mon, 6=Sun) via Sakamoto's algorithm
proc get_weekday {d m y} {
    set t {0 3 2 5 0 3 5 1 4 6 2 4}
    if {$m < 3} { incr y -1 }
    return [expr {($y + $y/4 - $y/100 + $y/400 + [lindex $t [expr {$m-1}]] + $d) % 7}]
}

# Determine whether the target year is a leap year
proc is_leap_year {y} {
    return [expr {($y % 4 == 0 && $y % 100 != 0) || ($y % 400 == 0)}]
}

# General-purpose ISO 8601 week number calculation subroutine
proc get_week_number {day month year} {
    if {![string is integer -strict $year]} { return 1 }
    set leap [is_leap_year $year]
    set feb_days [expr {$leap ? 29 : 28}]
    set days_in_months [list 31 $feb_days 31 30 31 30 31 31 30 31 30 31]
    
    set total_days $day
    for {set i 0} {$i < [expr {$month - 1}]} {incr i} {
        set total_days [expr {$total_days + [lindex $days_in_months $i]}]
    }
    
    set jan1_wd [get_weekday 1 1 $year]
    set jan1_wd [expr {($jan1_wd + 6) % 7}]
    
    set start_diff [expr {($jan1_wd <= 3) ? $jan1_wd : ($jan1_wd - 7)}]
    set week [expr {($total_days + $start_diff + 6) / 7}]
    
    # Process boundary adjustment cases safely
    if {$week == 0} {
        return [get_week_number 31 12 [expr {$year - 1}]]
    }
    if {$month == 12 && $day >= 29} {
        set dec31_wd [get_weekday 31 12 $year]
        set dec31_wd [expr {($dec31_wd + 6) % 7}]
        if {[expr {$day - $dec31_wd}] >= 30} {
            return 1
        }
    }
    return $week
}

# --- Top Navigation Header Section ---
frame .header -bg "#ffffff" -pady 10
pack .header -fill x

# Previous year navigation button
button .header.prev -text "<" -font $font_title -fg $color_dark -bg "#ffffff" \
    -activebackground "#f0f0f0" -relief flat -overrelief raised -command { change_year -1 }

# The combobox component containing selectable default choices
ttk::combobox .header.year_combo -textvariable view_year -style Calendar.TCombobox \
    -values {2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034 2035} \
    -width 8 -justify center

# Next year navigation button
button .header.next -text ">" -font $font_title -fg $color_dark -bg "#ffffff" \
    -activebackground "#f0f0f0" -relief flat -overrelief raised -command { change_year 1 }

pack .header.prev -side left -padx {50 10}
pack .header.year_combo -side left -expand yes
pack .header.next -side right -padx {10 50}

# Connect interaction events to UI execution commands
bind .header.year_combo <<ComboboxSelected>> { apply_typed_year }
bind .header.year_combo <Return> { apply_typed_year }

# --- Main Grid Frame Section ---
frame .main -bg "#ffffff" -padx 10 -pady 10
pack .main -fill both -expand yes

# Redraw event cycle handling function
proc draw_calendar {year} {
    global weekdays font_title font_days font_weeks color_gray color_dark color_blue
    global current_year current_month current_day
    
    # Wipe the existing canvas layout structure clean
    foreach child [winfo children .main] { destroy $child }
    
    if {![string is integer -strict $year] || $year < 1} { return }
    
    set leap [is_leap_year $year]
    set feb_days [expr {$leap ? 29 : 28}]
    
    # Month string arrays matched against year values
    set months [list \
	"January $year" 31 "February $year" $feb_days "March $year" 31 \
	"April $year" 30 "May $year" 31    "June $year" 30 \
	"July $year" 31   "August $year" 31  "September $year" 30 \
	"October $year" 31 "November $year" 30 "December $year" 31 \
    ]
    
    set current_month_idx 1
    
    foreach {m_name m_days} $months {
        set row [expr {($current_month_idx - 1) / 3}]
        set col [expr {($current_month_idx - 1) % 3}]
        
        set m_frame [frame .main.m$current_month_idx -bg "#ffffff" -padx 10 -pady 5]
        grid $m_frame -row $row -column $col -padx 10 -pady 5 -sticky nsew
        
        # Month header text
        label $m_frame.title -text $m_name -font $font_title -fg $color_dark -bg "#ffffff"
        grid $m_frame.title -row 0 -column 0 -columnspan 8 -pady {0 8}
        
        # Weekday headers
        set c 0
        foreach wd $weekdays {
            label $m_frame.wd$c -text $wd -font $font_days -fg $color_gray -bg "#ffffff"
            grid $m_frame.wd$c -row 1 -column $c -padx 4 -pady 1
            incr c
        }
        label $m_frame.wn_title -text "" -bg "#ffffff"
        grid $m_frame.wn_title -row 1 -column 7 -padx {6 0}
        
        # Locate day cell index positioning offset shift
        set first_wd [get_weekday 1 $current_month_idx $year]
        set first_wd [expr {($first_wd + 6) % 7}]
        
        set r 2
        set c $first_wd
        set month_weeks {}
        
        # Process individual numeric days configuration loop
        for {set d 1} {$d <= $m_days} {incr d} {
            # Render a dedicated tiny Canvas block to encircle today's date dynamically
            if {$year == $current_year && $current_month == $current_month_idx && $current_day == $d} {
                canvas $m_frame.d$d -width 22 -height 22 -bg "#ffffff" -highlightthickness 0
                $m_frame.d$d create oval 1 1 21 21 -outline $color_blue -width 2
                $m_frame.d$d create text 11 11 -text $d -font $font_days -fill $color_dark -justify center
                grid $m_frame.d$d -row $r -column $c -pady 1 -padx 1
            } else {
                label $m_frame.d$d -text $d -font $font_days -fg $color_dark -bg "#ffffff" -width 3 -anchor center
                grid $m_frame.d$d -row $r -column $c -pady 1
            }
            
            set w_num [get_week_number $d $current_month_idx $year]
            dict set month_weeks $r $w_num
            
            incr c
            if {$c == 7} {
                set c 0
                incr r
            }
        }
        
        # Write structural week numbers down on the rightmost matrix border column
        dict for {row_id wn} $month_weeks {
            label $m_frame.wn$row_id -text $wn -font $font_weeks -fg $color_gray -bg "#ffffff"
            grid $m_frame.wn$row_id -row $row_id -column 7 -padx {8 0} -sticky e
        }
        
        incr current_month_idx
    }
    
    grid columnconfigure .main {0 1 2} -weight 1
    grid rowconfigure .main {0 1 2 3} -weight 1
}

# Sequential navigation shifting execution command
proc change_year {delta} {
    global view_year
    if {![string is integer -strict $view_year]} { set view_year 2026 }
    set view_year [expr {$view_year + $delta}]
    draw_calendar $view_year
}

# Combobox target synchronization change execution command
proc apply_typed_year {} {
    global view_year
    if {[string is integer -strict $view_year] && $view_year > 0} {
        draw_calendar $view_year
    }
}

# Trigger initial setup calendar build structure
draw_calendar $view_year
EOS

Tcl::Tk::MainLoop;

