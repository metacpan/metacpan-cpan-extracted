package StackTrace::Pretty::Printer;
use strict;
use warnings;
use utf8;

our $COLOR_RAW_LINE = "\e[38;5;252m";
our $COLOR_RAW_LINE_DEST_NAME = "\e[38;5;10m";
our $COLOR_RAW_LINE_DEST_ARGS = "\e[38;5;69m";
our $COLOR_RAW_LINE_FILENAME = "\e[38;5;208m";
our $COLOR_LINENUM = "\e[38;5;239m";
our $COLOR_NORMAL_LINE = "\e[38;5;242m";
our $COLOR_CURRENT_LINE = "\e[38;5;230m\e[48;5;234m";
our $COLOR_RESET = "\e[0m";
our $COLOR_STACK_TRACE_START = "\e[38;5;11m";


sub new {
    my ($class, @args) = @_;
    my $args = (ref $args[0] eq 'HASH') ? $args[0] : { @args };

    bless $args, $class;
}

sub print {
    my ($self, @args) = @_;
    my $args = (ref $args[0] eq 'HASH') ? $args[0] : { @args };

    my $depth = $args->{depth};

    defined $args->{line} or die "'line' required";
    my $extracted_from_line = $self->_extract_func_and_line_num($args->{line});
    my $dest_func = $extracted_from_line->{dest_func} || '';
    my $filename = $extracted_from_line->{filename};
    my $lineno = $extracted_from_line->{lineno};

    if (defined $depth and $depth == 0) {
        $self->_print_start_stack_trace($filename, $lineno);
    }

    my $num_lines_context = $args->{num_lines_context} || 2;

    my $print_start = $lineno - $num_lines_context;
    if ($print_start < 1) {
        $print_start = 1;
    }
    my $print_end = $lineno + $num_lines_context;
    my $line_num_area_width = length $print_end;

    if (defined $depth) {
        print "[$depth] ";
    }
    my $string_printed_raw = $args->{line};
    $string_printed_raw
        =~ s/called at (\S+) line (\d+)$/${COLOR_RAW_LINE}called at${COLOR_RAW_LINE} ${COLOR_RAW_LINE_FILENAME}${1}${COLOR_RAW_LINE} line ${COLOR_RAW_LINE_FILENAME}${2}${COLOR_RAW_LINE}/;
    $string_printed_raw
        =~ s/^([^\(]+)/${COLOR_RAW_LINE_DEST_NAME}${1}${COLOR_RAW_LINE_DEST_ARGS}/;
    print "${COLOR_RAW_LINE}${string_printed_raw}${COLOR_RESET}\n";

    return if $self->_excluded_destination($dest_func);

    my $open_success = open my $IN, '<', $filename;
    if (not $open_success) {
        print "No such file $filename\n";
        return;
    };

    <$IN> for (1 .. $print_start - 1);

    print "----------------------------------------------------\n";
    for my $current_line_no ($print_start .. $print_end) {
        my $line = <$IN>;
        if (not $line) {
            last;
        }
        chomp($line);

        my $color_highlight_code = ($lineno == $current_line_no) ? $COLOR_CURRENT_LINE : $COLOR_NORMAL_LINE;
        print sprintf(
            "${COLOR_LINENUM}%${line_num_area_width}d:${COLOR_RESET} "
            . "${color_highlight_code}%s${COLOR_RESET}"
            . "\n",
            $current_line_no,
            $line
        );
    }
    print "----------------------------------------------------\n";

    close $IN;
}

sub _excluded_destination {
    my ($self, $dest_func) = @_;

    return unless $self->{excluded_modules};

    for my $module_name (@{ $self->{excluded_modules} }) {
        if ($dest_func =~ /$module_name/) {
            return 1;
        }
    }

    return 0;
}

sub _print_start_stack_trace {
    my ($self, $filename, $lineno) = @_;

    print $COLOR_STACK_TRACE_START;
    print "-------------------------------------------------------------------------\n";
    print " Stack trace start at line $lineno of $filename\n";
    print "-------------------------------------------------------------------------\n";
    print $COLOR_RESET;
}

sub _extract_func_and_line_num {
    my ($self, $line) = @_;

    my ($dest_func, $filename, $target_line_num);

    if ($line =~ /^\S/) {  # first line
        ($filename, $target_line_num) = $line =~ /^.*? at (\S+) line (\d+)\.?$/;
    }
    else {
        ($dest_func, $filename, $target_line_num) = $line =~ /^\s+(.*?) called at (\S+) line (\d+)$/;
    }

    return {
        dest_func => $dest_func,
        filename => $filename,
        lineno => $target_line_num,
    };
}


1;
