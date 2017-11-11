package Progress::Awesome;

use strict;
use warnings;
use Carp qw(croak);
use Devel::GlobalDestruction qw(in_global_destruction);
use Encode qw(encode);
use Time::HiRes qw(time);
use Term::ANSIColor qw(colored uncolor);
use Scalar::Util qw(refaddr);

use overload
    '++' => \&inc,
    '+=' => \&inc,
    '-=' => \&dec,
    '--' => \&dec;

our $VERSION = '0.1';

if ($Term::ANSIColor::VERSION < 4.06) {
    for my $code (16 .. 255) {
        $Term::ANSIColor::ATTRIBUTES{"ansi$code"}    = "38;5;$code";
        $Term::ANSIColor::ATTRIBUTES{"on_ansi$code"} = "48;5;$code";
    }
}

# Global bar registry for seamless multiple bars at the same time
our %REGISTRY;

# Basically every call
my $REDRAW_INTERVAL = 0;

# Don't log a crazy amount of times
my $LOG_INTERVAL = 10;

my $DEFAULT_TERMINAL_WIDTH = 80;
my %FORMAT_STRINGS = map { $_ => 1 } qw(
    : bar ts eta rate bytes percent done left total title spacer
);
my $MAX_SAMPLES = 10;
my @MONTH = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

my %STYLES = (
    simple  => \&_style_simple,
    unicode => \&_style_unicode,
    rainbow => \&_style_rainbow,
);

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    # Map ctor arguments to hashref
    my $args = {};
    if (@_ >= 1 && Scalar::Util::looks_like_number($_[0])) {
        $args->{total} = shift;
    }

    if (@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH') {
        $args = { %$args, %{$_[0]} };
    }
    else {
        $args = { %$args, @_ };
    }
    
    # Apply defaults
    my %defaults = (
        fh => \*STDERR,
        format => '[:bar] :done/:total :eta :rate',
        log_format => '[:ts] :percent% :done/:total :eta :rate',
        log => 1,
        color => 1,
        remove => 0,
        title => undef,
        style => 'rainbow',
        done => 0,
        total => undef,
    );  
    $args = { %defaults, %$args };

    $self->{fh} = delete $args->{fh};

    $self->update(delete $args->{done}) if exists $args->{done};
    
    # Set and validate arguments
    for my $key (qw(total format log_format log color remove title style)) {
        $self->$key(delete $args->{$key}) if exists $args->{$key};
    }

    if (keys %$args) {
        croak __PACKAGE__ . "::new(): invalid argument " . join(', ', map { "'$_'" } sort keys %$args);
    }

    # Historic samples used for rate/ETA calculation
    $self->{_samples} = [];
    $self->{_next_draw} = -1;

    _register_bar($self);
    
    # Draw initial bar
    $self->{draw_ok} = 1;
    $self->_force_redraw;
    
    return $self;
}

sub inc {
    my ($self, $amount) = @_;
    
    @_ == 1 and $amount = 1;
    defined $amount or croak "inc: undefined amount";

    $self->update($self->{done} + $amount);
}

sub update {
    my ($self, $count) = @_;
    defined $count or croak "update: undefined count";

    if (defined $self->{total} && $count > $self->{total}) {
        $self->{done} = $self->{total};
    }
    elsif ($count < 0) {
        $self->{done} = 0;
    }
    else {
        $self->{done} = $count;
    }

    $self->_add_sample;
    $self->_redraw;
}

sub dec {
    my ($self, $amount) = @_;

    @_ == 1 and $amount = 1;
    defined $amount or croak "dec undefined amount";

    $self->update($self->{done} - $amount);
}

sub finish {
    my $self = shift;

    if (defined $self->{total}) {
        # Set the bar to maximum
        $self->update($self->{total});
        $self->_force_redraw;
    }
    
    if ($self->remove) {
        # Destroy the bar, assuming nobody has printed anything in the interim
        $self->_wipe_current_line;
    }    

    # TODO self->remove behaviour will change here too
    _unregister_bar($self);
    
}

sub DESTROY {
    my $self = shift;
    if (in_global_destruction) {
        # We already handle destruction in the END block for all bars, so
        # just return
        return;
    }
    else {
        $self->finish;
    }
}

END {
    # Clean up progress bars before global destruction
    for my $fh (keys %REGISTRY) {
        for my $bar (_bars_for($fh)) {
            $bar->finish;
        }
    }
    %REGISTRY = ();
}

sub total {
    my ($self, $total) = @_;
    @_ == 1 and return $self->{total};
    if (defined $total) {
        $total >= 0 or croak "total: total must be undefined or positive (>=0)";
    }
    $self->{total} = $total;

    if (defined $total && $self->{done} > $total) {
        $self->{done} = $total;
    }

    $self->_redraw;
}

for my $param (qw(format log_format)) {
    no strict 'refs';
    *{$param} = sub {
        my ($self, $format) = @_;
        @_ == 1 and return $self->{$param};
        $self->{$param} = _check_format($param, $format);
        $self->_redraw;
    };
}

for my $param (qw(log color remove title)) {
    no strict 'refs';
    *{$param} = sub {
        my ($self, $new) = @_;
        @_ == 1 and return $self->{$param};
        $self->{$param} = $new;
        $self->_redraw;
    };
}

sub fh { shift->{fh} }

sub style {
    my ($self, $style) = @_;
    if (@_ != 2 or !defined $style or !(ref $style eq 'CODE' || ref $style eq '')) {
        croak "style usage: style(stylename) or style(coderef)";
    }
    if (!ref $style) {
        if (!exists $STYLES{$style}) {
            croak "style: no such style '$STYLES{$style}'. Valid styles are "
                . join(', ', sort keys %STYLES);
        }
        $style = $STYLES{$style};
    }

    $self->{style} = $style;
    $self->_redraw;
}

sub _force_redraw {
    my $self = shift;
    $self->_redraw(1);
}

# Draw all progress bars to keep positioning
sub _redraw {
    my ($self, $force) = @_;

    my $drawn = 0;
    for my $bar (_bars_for($self->{fh})) {
        my $lines += $bar->_redraw_me($force);

        if ($lines == -1) {
            # This indicates we didn't draw as not enough time has passed
            return;
        }

        print {$self->fh} "\n";
        $drawn += $lines;
    }
    # Move back up
    unless ($self->_logging_mode) {
        print {$self->fh} "\033[" . $drawn . "A" if $drawn;
    }
} 

sub _redraw_me {
    my ($self, $force) = @_;

    # Don't draw while setting arguments in constructor
    return 0 if !$self->{draw_ok};
    return -1 if time < $self->{_next_draw} && !$force;

    my ($max_width, $format, $interval);
    if ($self->_logging_mode) {
        $format = $self->log_format . "\n";
        $self->{_next_draw} = time + $LOG_INTERVAL;
    }
    else {
        # Drawing a progress bar
        $max_width = $self->_terminal_width;
        $format = $self->format;
        $self->{_next_draw} = time + $REDRAW_INTERVAL;
    }

    my $title_in_format = $format =~ /:title/;
    
    # Draw the components
    $format =~ s/:(\w+)/$self->_redraw_component($1)/ge;

    if (defined $self->{title} && !$title_in_format) {
        $format = $self->{title} . ": " . $format;
    }
    
    my @lines = split /\n/, $format;
    my $idx = 0;

    for my $format_line (@lines) {
        # Work out format length, spacer/bar length, and fill in spacer/bar
        my $drew_stretchy = 0;

        if ($format_line =~ /:bar/) {
            my $remaining_space = $max_width - length($format_line) + length(':bar');
            if ($remaining_space >= 1) {
                my $bar = $self->{style}->($self->_percent, $remaining_space);
                $format_line =~ s/:bar/$bar/g; 
                $drew_stretchy = 1;
            }
            else {
                # It's already too big
                $format_line =~ s/:bar//g;
            }
        }
        elsif ($format_line =~ /:spacer/) {
            my $remaining_space = $max_width - length($format_line) + length(':spacer');
            if ($remaining_space >= 1) {
                my $spacer = " " x $remaining_space;
                $format_line =~ s/:spacer/$spacer/g; 
                $drew_stretchy = 1;
            }
            else {
                $format_line =~ s/:spacer//g;
            }
        }

        if (!$drew_stretchy && defined $max_width) {
            # XXX this needs to account for ANSI codes + Unicode double-width
            if (length($format_line) > $max_width) {
                $format_line = substr($format_line, 0, $max_width);
            }
            else {
                $format_line .= ' ' x ($max_width - length($format_line));
            }
        }
        # Draw it
        print {$self->fh} $format_line;
        print {$self->fh} "\n" unless $idx++ == $#lines;
    }
    $self->fh->flush;

    return scalar @lines; # indicate we drew the bar
}
    
sub _redraw_component {
    my ($self, $field) = @_;

    if ($field eq 'bar' or $field eq 'spacer') {
        # Skip as these needs to go last
        return ":$field";
    }
    elsif ($field eq ':') {
        # Literal ':'
        return ':';
    }
    elsif ($field eq 'ts') {
        # Emulate the ts(1) tool
        my ($sec, $min, $hour, $day, $month) = gmtime();
        $month = $MONTH[$month] or croak "_redraw_component: unknown month $month ??;";
        return sprintf('%s %02d %02d:%02d:%02d', $month, $day, $hour, $min, $sec);
    }
    elsif ($field eq 'done') {
        return $self->{done};
    }
    elsif ($field eq 'left') {
        return defined $self->{total} ? ($self->{total} - $self->{done}) : '-';
    }
    elsif ($field eq 'total' or $field eq 'max') {
        return defined $self->{total} ? $self->{total} : '-';
    }
    elsif ($field eq 'eta') {
        return $self->_eta;
    }
    elsif ($field eq 'rate') {
        return $self->_percent == 100 ? '-' : _human_readable_item_rate($self->_rate);
    }
    elsif ($field eq 'bytes') {
        return _human_readable_byte_rate($self->_rate);
    }
    elsif ($field eq 'percent') {
        my $pc = $self->_percent;
        return defined $pc ? sprintf('%2.1f', $pc) : '-';
    }
    elsif ($field eq 'title') {
        return $self->{title} || '';
    }
    else {
        die "_redraw_component assert failed: invalid field '$field'";
    }
}

sub _wipe_current_line {
    my $self = shift;
    print {$self->fh} "\r", ' ' x $self->_terminal_width, "\r";
}

# Returns terminal width, or a fake value if we can't figure it out
sub _terminal_width {
    my $self = shift;
    return $self->_real_terminal_width || $DEFAULT_TERMINAL_WIDTH;
}

# Returns the width of the terminal (filehandle) in chars, or 0 if it could not be determined
sub _real_terminal_width {
    my $self = shift;
    eval { require Term::ReadKey } or return 0;
    my $result = eval { (Term::ReadKey::GetTerminalSize($self->fh))[0] } || 0;
    if ($result) {
        # This logic is from Term::ProgressBar
        $result-- if $^O eq 'MSWin32' or $^O eq 'cygwin';
    }
    return $result;
}

# Are we outputting a log instead of a progress bar?
sub _logging_mode {
    my $self = shift;

    if (exists $self->{_cached_logging_mode}) {
        return $self->{_cached_logging_mode};
    }

    $self->{_cached_logging_mode} = (!-t $self->fh);
}

sub _add_sample {
    my $self = shift;
    my $s = $self->{_samples};
    unshift @$s, [$self->{done}, time];
    pop @$s if @$s > $MAX_SAMPLES;
}

# Return ETA for current progress (actually a duration)
sub _eta {
    my $self = shift;

    # Predict finishing time using current rate
    my $rate = $self->_rate;
    return 'finished' if $self->{done} >= $self->{total};

    return 'unknown' if !defined $rate or $rate <= 0;

    my $duration = ($self->{total} - $self->{done}) / $rate;
    return _human_readable_duration($duration);
}

# Return rate for current progress
sub _rate {
    my $self = shift;
    return if !defined $self->{total};

    my $s = $self->{_samples};
    return if @$s < 2;

    # Work out the last 5 rates and average them
    my ($sum, $count) = (0,0);
    for my $i (0..4) {
        last if $i+1 > $#{$s};

        # Sample is a tuple of [count, time]
        $sum += ($s->[$i][0] - $s->[$i+1][0]) / ($s->[$i][1] - $s->[$i+1][1]);
        $count++;
    }

    return $sum/$count;
}

# Return current percentage complete, or undef if unknown
sub _percent {
    my $self = shift;
    return undef if !defined $self->{total};
    my $pc = ($self->{done} / $self->{total}) * 100;
    return $pc > 100 ? 100 : $pc;
}

## Bar styles

sub _style_rainbow {
    my ($percent, $size) = @_;

    my $rainbow = _ansi_rainbow();
    if (!defined $percent) {
        # Render a 100% width gray rainbow instead
        $percent = 100;
        $rainbow = _ansi_holding_pattern();
    }

    my $fillsize = ($size * $percent / 100);

    my $bar = _unicode_block_bar($fillsize);
    my $len = length $bar;
    $bar = _color_bar($bar, $rainbow, 10);
    $bar = encode('UTF-8', $bar);

    return $bar . (' ' x ($size - $len));
}

sub _style_unicode {
    my ($percent, $size) = @_;

    my $fillsize = ($size * $percent / 100);
    my $bar = _unicode_block_bar($fillsize);
    my $len = length $bar;
    $bar = encode('UTF-8', $bar);

    return $bar . (' ' x ($size - $len));
}

sub _color_bar {
    my ($bar, $swatch, $speed) = @_;

    my $t = time * $speed;

    return join('', map {
        colored(
            substr($bar, $_ - 1, 1),
            $swatch->[($_ + $t) % @$swatch],
        )
    } (1..length($bar)));
}

sub _style_simple {
    my ($percent, $size) = @_;
    my $bar;
    if (defined $percent) {
        my $to_fill = int( $size * $percent / 100 );
        $bar = ('#' x $to_fill) . (' ' x ($size - $to_fill));
    }
    else {
        $bar = '-' x $size;
    }
    return $bar;
}

sub _unicode_block_bar {
    my $fillsize = shift;
    return '' if $fillsize == 0;

    my $intpart = int($fillsize);
    my $floatpart = $fillsize - $intpart;

    my $whole_block = chr(0x2588);  # full block

    # Block range is U+2588 (full block) .. U+258F (left one eighth block)
    my $last_block = $floatpart == 0 ? '' : chr(0x2588 + int((1 - $floatpart) * 8));

    return ($whole_block x $intpart) . $last_block;
}

## Utilities

# Check format string to ensure it is valid
sub _check_format {
    my ($param, $format) = @_;
    defined $format or croak "format is undefined";

    for my $line (split /\n/, $format) {

        while ($line =~ /:(\w+)/g) {
            exists $FORMAT_STRINGS{$1} or croak "$param: invalid format string ':$1'";
        }

        if (($line =~ /:(?:bar|spacer)/) > 1) {
            croak "$param: contains more than one bar or spacer, this isn't allowed :(";
        }
    }

    return $format;
}

# Convert (positive) duration in seconds to a human-readable string
# e.g. '2 days', '14 hrs', '2 mins'
sub _human_readable_duration {
    my $dur = shift;
    return 'unknown' if !defined $dur;

    my ($val, $unit) = $dur < 60    ? ($dur,         'sec')
                     : $dur < 3600  ? ($dur / 60,    'min')
                     : $dur < 86400 ? ($dur / 3600,  'hr')
                                    : ($dur / 86400, 'day')
                                    ;
    return int($val) . " $unit" . (int($val) == 1 ? '' : 's') . " left";
}

# Convert rate (a number, assumed to be items/second) into a more
# appropriate form
sub _human_readable_item_rate {
    my $rate = shift;
    return 'unknown' if !defined $rate;

    my ($val, $unit) = $rate < 10**3  ? ($rate,          '')
                     : $rate < 10**6  ? ($rate / 10**3,  'K')
                     : $rate < 10**9  ? ($rate / 10**6,  'M')
                     : $rate < 10**12 ? ($rate / 10**9,  'B')
                                      : ($rate / 10**12, 'T')
                                      ;
    return sprintf('%.1f', $val) . "$unit/s";
}

# Convert rate (a number, assumed to be bytes/second) into a more
# appropriate human-readable unit
# e.g. '3 KB/s', '14 MB/s'
sub _human_readable_byte_rate {
    my $rate = shift;
    return 'unknown' if !defined $rate;

    my ($val, $unit) = $rate < 1024     ? ($rate,           'byte')
                     : $rate < 1024**2  ? ($rate / 1024,    'KB')
                     : $rate < 1024**3  ? ($rate / 1024**2, 'MB')
                     : $rate < 1024**4  ? ($rate / 1024**3, 'GB')
                                        : ($rate / 1024**4, 'TB')
                                        ;
    return int($val) . " $unit/s";
}

sub _term_is_256color {
    return $ENV{TERM} eq 'xterm-256color';
}

sub _ansi_rainbow {
    if (_term_is_256color()) {
        return [map { "ansi$_" } (92, 93, 57, 21, 27, 33, 39, 45, 51, 50, 49, 48, 47, 46, 82, 118, 154, 190, 226, 220, 214, 208, 202, 196)];
    }
    else {
        return [qw(magenta blue cyan green yellow red)];
    }

}

sub _ansi_holding_pattern {
    if (_term_is_256color()) {
        return [map { "grey$_" } (0..23), reverse(1..22)];
    }
    else {
        # Use a dotted pattern. XXX Maybe should be related to rate?
        # XXX in genral animating by rate is good for finished bars too
        # XXX rate does not drop to 0 when finished
        return ['black', 'black', 'black', 'black', 'white'];
    }
}

## Multiple bar support

sub _register_bar {
    my $bar = shift;
    my $data = $REGISTRY{$bar->{fh}} ||= {};
    push @{ $data->{bars} ||= [] }, $bar;
    if (!defined $data->{maxbars} or $data->{maxbars} < @{$data->{bars}}) {
        $data->{maxbars} = @{$data->{bars}};
    }
}

sub _unregister_bar {
    my $bar = shift;
    my $data = $REGISTRY{$bar->{fh}} or return;

    @{$data->{bars}} = grep { refaddr $_ ne refaddr $bar } @{$data->{bars}};

    # Are we the last bar? Move the cursor to the bottom of the bars.
    if (@{$data->{bars}} == 0 && -t $bar->{fh}) {
        print {$bar->{fh}} "\033[" . $data->{maxbars} . "B";
    }
}

sub _bars_for {
    my $fh = shift;
    return if !defined $fh;
    return if !exists $REGISTRY{$fh};
    return @{ $REGISTRY{$fh}{bars} || [] };
}

1;

=pod

=head1 HEAD

 Progress::Awesome - an awesome progress bar that just works

=head1 SYNOPSIS

 my $p = Progress::Awesome->new(100, style => 'rainbow');
 for my $item (1..100) {
     do_some_stuff();
     $p->inc;
 }

 # Multiline progress bars
 my $p = Progress::Awesome(100, format => ":bar\n:left/:total :spacer ETA :eta");

=head1 DESCRIPTION

Similar to the venerable L<Term::ProgressBar> with several enhancements:

=over

=item *

Does the right thing when non-interactive - hides the progress bar and logs
intermittently with timestamps.

=item *

Completes itself when C<finish> is called or it goes out of scope, just in case
you forget.

=item *

Customisable format includes number of items, item processing rate, file transfer
rate (if items=bytes) and ETA. When non-interactive, logging format can also be
customised.

=item *

Gets out of your way - won't noisily complain if it can't work out the terminal
size, and won't die if you set the progress bar to its max value when it's already
reached the max (or for any other reason).

=item *

Can be incremented using C<++> or C<+=> if you like.

=item *

Works fine if max is undefined, set halfway through, or updated halfway through.

=item *

Estimates ETA with more intelligent prediction than simple linear.

=item *

Colours!!

=item *

Multiple process bars at once 'just work'.

=back

=head1 METHODS

=over

=item new ( %args )

=item new ( total, %args )

Create a new progress bar, passing arguments as a hash or hashref. If the first
argument looks like a number then it will be used as the bar's total number of
items.

=over

=item total (optional)

Total number of items to be processed. (items, bytes, files, etc.)

=item format (default: '[:bar] :done/:total :eta :rate')

Specify a format for the progress bar (see L</FORMATS> below).
C<:bar> or C<:spacer> parts will fill to all available space.

=item style (optional)

Specify the bar style. This may be a string ('rainbow' or 'boring') or a function
that accepts the percentage and size of the bar (in chars) and returns ANSI data
for the bar.

=item title (optional)

Optional bar title.

=item log_format (default: '[:ts] :percent% :done/:total :eta :rate')

Specify a format for log output used when the script is run non-interactively.

=item log (default: 1)

If set to 0, don't log anything when run non-interactively.

=item color (default: 1)

If set to 0, suppress colors when rendering the progress bar.

=item remove (default: 0)

If set to 1, remove the progress bar after completion via C<finish>.

=item fh (default: \*STDERR)

The filehandle to output to.

=item done (default: 0)

Starting number of items done.

=back

=item update ( value )

Update the progress bar to the specified value. If undefined, the progress bar will go into
a spinning/unknown state.

=item inc ( [value] )

Increment progress bar by this many items, or 1 if omitted.

=item finish

Set the progress bar to maximum. Any further updates will not take effect. Happens automatically
when the progress bar goes out of scope.

=item total ( [value] )

Updates the total number of items. May be set to undef if unknown. With zero arguments,
returns the current total.

=item dec ( [value] )

Decrement the progress bar by this many items, or 1 if omitted.

=back

=head1 FORMATS

A convenient way to specify what fields go where in your progress bar or log output.

Format strings may span multiple lines, and may contain any of the below fields:

=over

=item :bar

The progress bar. Expands to fill all available space not used by other fields.

=item :spacer

Expands to fill all available space. Items before the spacer will be aligned to
the left of the screen, and items after the spacer will be aligned to the right.
In this respect it's like a progress bar that's invisible.

=item ::

Literal ':'

=item :ts

Current timestamp (month, day, time) - intended for logging mode.

=item :done

Number of items that have been completed.

=item :left

Number of items remaining

=item :total

Maximum number of items.

=item :eta

Estimated time until progress bar completes.

=item :rate

Number of items being processed per second.

=item :bytes

Number of bytes being processed per second (expressed as KB, MB, GB etc. as needed)

=item :percent

Current percent completion (without % sign)

=item :title

Bar title. Title will be prepended automatically if not included in the
format string.

=back

=head1 REPORTING BUGS

It's early days for this module so bugs are possible and feature requests are warmly
welcomed. We use L<Github Issues|https://github.com/richardjharris/perl-Progress-Awesome/issues>
for reports.

=head1 AUTHOR

Richard Harris richardjharris@gmail.com

=head1 COPYRIGHT

Copyright (c) 2017 Richard Harris.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

__END__
