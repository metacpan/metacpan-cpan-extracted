package Term::GentooFunctions;

require 5.006001;

use strict;
use utf8;

BEGIN {
    eval "use Term::Size;";               my $old = $@;
    eval "use Term::Size::Win32" if $old; my $new = $@;
    die $old if $old and $new;
    die $new if $new;
}

use Exporter;
use Term::ANSIColor qw(:constants);

our $VERSION = '1.3700';

our @EXPORT_OK = qw(einfo eerror ewarn ebegin eend eindent eoutdent einfon edie edo start_spinner step_spinner end_spinner equiet);
our %EXPORT_TAGS = (all=>[@EXPORT_OK]);

my $is_spinning = 0;
my $post_spin_lines = 0;

use base qw(Exporter);

# Lifted from Term::ANSIScreen (RT #123497)
# -- Sawyer X
our $AUTORESET;

# Lifted and adjusted from Term::ANSIScreen (RT #123497)
# -- Sawyer X
BEGIN {
    my %attributes = (
        'clear'      => 0,    'reset'      => 0,
        'bold'       => 1,    'dark'       => 2,
        'underline'  => 4,    'underscore' => 4,
        'blink'      => 5,    'reverse'    => 7,
        'concealed'  => 8,

        'black'      => 30,   'on_black'   => 40,
        'red'        => 31,   'on_red'     => 41,
        'green'      => 32,   'on_green'   => 42,
        'yellow'     => 33,   'on_yellow'  => 43,
        'blue'       => 34,   'on_blue'    => 44,
        'magenta'    => 35,   'on_magenta' => 45,
        'cyan'       => 36,   'on_cyan'    => 46,
        'white'      => 37,   'on_white'   => 47,
    );

    my %sequences = (
        'up'        => '?A',      'down'      => '?B',
        'right'     => '?C',      'left'      => '?D',
        'savepos'   => 's',       'loadpos'   => 'u',
        'cls'       => '2J',      'clline'    => 'K',
        'cldown'    => '0J',      'clup'      => '1J',
        'locate'    => '?;?H',    'setmode'   => '?h',
        'wrapon'    => '7h',      'wrapoff'   => '7l',
        'setscroll' => '?;?r',
    );

    my $enable_colors = !defined $ENV{ANSI_COLORS_DISABLED};
    no strict 'refs';
    no warnings 'uninitialized';

    foreach my $sub ( keys %sequences ) {
        my $seq = $sequences{$sub};
        *{"Term::GentooFunctions::$sub"} = sub {
            return '' unless $enable_colors;

            $seq =~ s/\?/defined($_[0]) ? shift(@_) : 1/eg;
            return((defined wantarray) ? "\e[$seq"
                                       : print("\e[$seq"));
        };
    }

    foreach my $sub ( keys %attributes ) {
        my $attr = $attributes{lc($sub)};
        my $sub_name = uc($sub);
        *{"Term::GentooFunctions::$sub_name"} = sub {
            if (defined($attr) and $sub_name =~ /^[A-Z_]+$/) {
                my $out = "@_";
                if ($enable_colors) {
                    $out = "\e[${attr}m" . $out;
                    $out .= "\e[0m" if ($AUTORESET and @_ and $out !~ /\e\[0m$/s);
                }
                return((defined wantarray) ? $out
                                           : print($out));
            }
            else {
                require Carp;
                Carp::croak("Undefined subroutine &$sub ($sub_name) called");
            }
        };
    }
}

BEGIN {
    # use Data::Dumper;
    # die Dumper(\%ENV) unless defined $ENV{RC_INDENTATION};
    $ENV{RC_DEFAULT_INDENT} = 2  unless defined $ENV{RC_DEFAULT_INDENT};
    $ENV{RC_INDENTATION}    = "" unless defined $ENV{RC_INDENTATION};
}

my $quiet;
sub equiet {
    $quiet = $_[0] if @_;
    return $quiet;
}

sub edie(@) {
    my $msg = (@_>0 ? shift : $_);
    eerror($msg);
    _pre_print_during_spin() if $is_spinning;
    $is_spinning = 0;
    eend(0);
    exit 0x65;
}

sub einfon($) {
    my $msg = wash(shift);

    return if $quiet;

    local $| = 1;
    print " ", BOLD, GREEN, "*", RESET, $msg;
}

sub eindent()  {
    my $i = shift || $ENV{RC_DEFAULT_INDENT};

    $ENV{RC_INDENTATION} .= " " x $i;
}

sub eoutdent() {
    my $i = shift || $ENV{RC_DEFAULT_INDENT};

    $ENV{RC_INDENTATION} =~ s/ // for 1 .. $i;
}

sub wash($) {
    my $msg = shift;
       $msg =~ s/^\s+//s;

    chomp $msg;
    return "$ENV{RC_INDENTATION} $msg";
}

sub einfo($) {
    my $msg = wash(shift);

    return if $quiet;
    _pre_print_during_spin() if $is_spinning;
    print " ", BOLD, GREEN, "*", RESET, "$msg\n";
    _post_print_during_spin() if $is_spinning;
}

sub ebegin($) {
    goto &einfo;
}

sub eerror($) {
    my $msg = wash(shift);

    return if $quiet;
    _pre_print_during_spin() if $is_spinning;
    print " ", BOLD, RED, "*", RESET, "$msg\n";
    _post_print_during_spin() if $is_spinning;
}

sub ewarn($) {
    my $msg = wash(shift);

    return if $quiet;
    _pre_print_during_spin() if $is_spinning;
    print " ", BOLD, YELLOW, "*", RESET, "$msg\n";
    _post_print_during_spin() if $is_spinning;
}

sub eend(@) {
    my $res = (@_>0 ? shift : $_);

    return if $quiet;

    my ($columns, $rows) = eval 'Term::Size::chars *STDOUT{IO}';
       ($columns, $rows) = eval 'Term::Size::Win32::chars *STDOUT{IO}' if $@;

    die "couldn't find a term size function to use" if $@;

    print up(1), right($columns - 6), BOLD, BLUE, "[ ", 
        ($res ?  GREEN."ok" : RED."!!"), 
        BLUE, " ]", RESET, "\n";

    $res;
}

sub edo($&) {
    my ($begin_msg, $code) = @_;

    ebegin $begin_msg;
    eindent;
    my ($cr, @cr);

    my $wa = wantarray;
    my $r = eval { if( $wa ) { @cr = $code->() } else { $cr = $code->() } 1 };
    edie $@ unless $r;

    eoutdent;
    eend 1;

    return @cr if $wa;
    return $cr;
}

sub _pre_print_during_spin {
    return if $post_spin_lines < 0; # when does this happen?? totally untested condition XXX

    if( $post_spin_lines == 0 ) {
        print "\n";
        $post_spin_lines ++;
    }

    print down($post_spin_lines++), "\e[0G\e[K";
}

sub _post_print_during_spin {
    local $| = 1;
    print up($post_spin_lines);
}

{
    my $spinner_state;
    my $spinner_msg;
    sub start_spinner($) {
        my $msg = wash(shift);

        $spinner_state = "-";
        $spinner_msg = $msg;

        $is_spinning = 1;
        $post_spin_lines = 0;

        einfon $spinner_msg;
    }

    my $spinext = {"-"=>'\\', '\\'=>'|', "|"=>"/", "/"=>"-"};
    sub step_spinner(;$) {
        # NOTE: really I should use savepost and clline from ANSIScreen, but he doesn't have [0G at all.  Meh

        return if $quiet;
        print "\e[0G\e[K";

        if( $_[0] ) {
            einfon("$spinner_msg $spinner_state ... $_[0]");

        } else {
            einfon("$spinner_msg $spinner_state ");
        }

        $spinner_state = $spinext->{$spinner_state};
    }

    sub end_spinner($) {
        return if $quiet;

        $is_spinning = 0;
        print "\e[0G\e[K";
        einfo $spinner_msg;
        $post_spin_lines --;
        _pre_print_during_spin();
        $post_spin_lines = 0;

        goto &eend;
    }

    END {
        if( $is_spinning ) {
            $is_spinning = 0;
            print "\e[0G\e[K";
            einfo $spinner_msg;
            $post_spin_lines --;
            _pre_print_during_spin();
        }
    }
}

"this file is true";
