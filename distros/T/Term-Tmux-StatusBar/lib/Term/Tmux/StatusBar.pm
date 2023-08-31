package Term::Tmux::StatusBar;
$Term::Tmux::StatusBar::VERSION = '0.0.1.0';
use strict;
use warnings;
use base 'Term::Tmux';
use Exporter qw(import);
our @EXPORT = qw( main window_status_current_format_left parse
  window_status_current_format_right status_left status_right );

my $delimiter = ';';
my $sub_delimiter = ',';
my $default_left_sep  = '';
my $default_right_sep = '';
my $default_format    = ' %s ';

sub change_format_sep {
    my $i = shift;
    if ( defined $i and $i =~ /%s/ ) {
        $_[0] = $i;
    }
    else {
        $_[1] = $i;
    }
    return @_;
}

sub get_tokens {
    my @tokens = parse( $sub_delimiter, $_[0] );
    $tokens[3] = sprintf $_[1], $tokens[2];
    return @tokens;
}

sub window_status_current_format_left {
    my $out     = '';
    my $sep     = $default_left_sep;
    my $format  = $default_format;
    my $fg      = '';
    my $bg      = '';
    my $text    = '';
    my $old_text = '';
    foreach (@_) {
        unless (/$sub_delimiter/) {
            ( $format, $sep ) = change_format_sep( $_, $format, $sep );
            next;
        }
        ( $fg, $bg, $old_text, $text ) = get_tokens( $_, $format );
        $out .= "#[reverse,fg=$bg]$sep#[noreverse,fg=$fg,bg=$bg]$text";
    }
    $out .= "#[fg=$bg,bg=default]$sep";
    return $out;
}

sub status_left {
    my $last_bg = '';
    my $out     = '';
    my $sep     = $default_left_sep;
    my $format  = $default_format;
    my $fg      = '';
    my $bg      = '';
    my $text    = '';
    my $old_text = '';
    foreach (@_) {
        unless (/$sub_delimiter/) {
            ( $format, $sep ) = change_format_sep( $_, $format, $sep );
            next;
        }
        ( $fg, $bg, $old_text, $text ) = get_tokens( $_, $format );
        if ( $last_bg eq '' ) {
            $out .= "#[fg=$fg,bg=$bg]$text";
        }
        else {
            $out .= "#[fg=$last_bg,bg=$bg]$sep#[fg=$fg]$text";
        }
        $last_bg = $bg;
    }
    $out .= "#[fg=$bg,bg=default]$sep";
    return $out;
}

sub right {
    my $out    = '';
    my $sep    = $default_right_sep;
    my $format = $default_format;
    my $fg     = '';
    my $bg     = '';
    my $text   = '';
    my $old_text = '';
    foreach (@_) {
        unless (/$sub_delimiter/) {
            ( $format, $sep ) = change_format_sep( $_, $format, $sep );
            next;
        }
        ( $fg, $bg, $old_text, $text ) = get_tokens( $_, $format );
        $out .= "#[fg=$bg]$sep#[fg=$fg]#[bg=$bg]$text";
        # $out .= "#{?#{==:$old_text,},,#[fg=$bg]$sep#[fg=$fg]#[bg=$bg]$text}";
    }
    return ( $out, $sep );
}

sub window_status_current_format_right {
    my ( $out, $sep ) = right(@_);
    $out .= "#[fg=default]$sep";
    return $out;
}

sub status_right {
    my ( $out, $sep ) = right(@_);
    return $out;
}

sub parse {

    # 0: normal
    # 1: #
    # 2: #[
    # 3: #[...#
    # 4: #[...#[
    # ...
    my $status = 0;
    my @tokens = ();
    my $token  = '';
    my %braces = (
        '[' => ']',
        '(' => ')',
        '{' => '}',
    );
    my $last_brace = '';
    my @braces = ();
    my @status = ();
    foreach ( split( '', $_[1] ) ) {
        if ( $status == 0 and $_ eq $_[0] ) {
            push @tokens, $token;
            $token = '';
        }
        else {
            $token .= $_;
        }
        if ( $status % 2 == 0 ) {
            if ( $_ eq '#' ) {
                $status += 1;
            }
            elsif ( $last_brace ne '' and $_ eq $braces{$last_brace} ) {
                $status -= 2;
                $last_brace = pop @braces;
            }
        }
        else {
            if ( $_ =~ /\[|\{|\(/ ) {
                $status += 1;
                $last_brace = $_;
                push @braces, $_;
            }
            else {
                $status -= 1;
            }
        }
        push @status, $status,
    }
    push @tokens, $token;
    # print @status;
    # print("\n" . join("\n", @tokens,) . "\n");
    return @tokens;
}

sub do_interpolation {
    $_[0] =~ s/#\{status-left:(.*)\}/status_left(parse($delimiter, $1))/ge;
    $_[0] =~ s/#\{status-right:(.*)\}/status_right(parse($delimiter, $1))/ge;
    $_[0] =~
s/#\{window-status-current-format-left:(.*)\}/window_status_current_format_left(parse($delimiter, $1))/ge;
    $_[0] =~
s/#\{window-status-current-format-right:(.*)\}/window_status_current_format_right(parse($delimiter, $1))/ge;
    return $_[0];
}

sub main {
    my @array =
      ( 'status-left', 'status-right', 'window-status-current-format', );
    foreach my $option (@array) {
        my $value = `tmux show-option -gqv '$option'`;
        if ( $value ne '' ) {
            $value = do_interpolation($value);
            `tmux set-option -gq '$option' '$value'`;
        }
    }
}

1;

__END__

=head1 NAME

Tmux::StatusBar - change tmux status bar.

=head1 VERSION

version 0.0.1.0

=head1 DESCRIPTION
