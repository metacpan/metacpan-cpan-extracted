package Template::Colour::RGB;

use Template::Colour::Class
    version   => 2.10,
    debug     => 0,
    base      => 'Template::Colour',
    constants => 'ARRAY HASH SCHEME :RGB',
    utils     => 'is_object',
    as_text   => 'HTML',
    is_true   => 1,
    throws    => 'Colour.RGB';


sub new {
    my ($proto, @args) = @_;
    my ($class, $self);

    if ($class = ref $proto) {
        $self = bless [@$proto], $class;
    }
    else {
        $self = bless [0, 0, 0], $proto;
    }
    $self->rgb(@args) if @args;
    return $self;
}

sub copy {
    my $self = shift;
    my $args = @_ && ref $_[0] eq HASH ? shift : { @_ };
    $args->{ red   } = $self->[RED]   unless defined $args->{ red   };
    $args->{ green } = $self->[GREEN] unless defined $args->{ green };
    $args->{ blue  } = $self->[BLUE]  unless defined $args->{ blue  };
    $self->new($args);
}

sub rgb {
    my $self = shift;
    my $col;
    
    if (@_ == 1) {
        # single argument is a list or hash ref, or RGB value
        $col = shift;
    }
    elsif (@_ == 3) {
        # three arguments provide red, green, blue components
        $col = [ @_ ];
    }
    elsif (@_ == 6) {
        # list of six items is red => $r, green => $g, blue => $b
        $col = { @_ };
    }
    elsif (@_) {
        # any other number of arguments is an error 
        return $self->error_msg( bad_param => rgb => join(', ', @_) );
    }
    else {
        # return $self when called with no arguments
        return $self;
    }
    
    # at this point $col is a reference to a list or hash, or a rgb value

    if (UNIVERSAL::isa($col, HASH)) {
        # convert hash ref to list
        $col = [  map {
            defined $col->{ $_ } 
            ? $col->{ $_ } 
            : return $self->error_msg( no_param => rgb => $_ );
        } qw( red green blue ) ];
    }
    elsif (UNIVERSAL::isa($col, ARRAY)) {
        # $col list is ok as it is
    }
    elsif (ref $col) {
        # anything other kind of reference is Not Allowed
        return $self->error_msg( bad_param => rgb => $col );
    }
    else {
        $self->hex($col);
        return $self;
    }

    # ensure all rgb component values are in range 0-255
    for (@$col) {
        $_ =   0 if $_ < 0;
        $_ = 255 if $_ > 255;
    }

    # update self with new colour, also deletes any cached HSV
    @$self = @$col;

    return $self;
}

sub hex {
    my $self = shift;

    if (@_) {
        my $hex = shift;
        $hex = '' unless defined $hex;
        if ($hex =~ / ^ 
           \#?            # short form of hex triplet: #abc
           ([0-9a-f])     # red 
           ([0-9a-f])     # green
           ([0-9a-f])     # blue
           $
           /ix) {
            @$self = map { hex } ("$1$1", "$2$2", "$3$3");
        }
        elsif ($hex =~ / ^ 
           \#?            # long form of hex triple: #aabbcc
           ([0-9a-f]{2})  # red 
           ([0-9a-f]{2})  # green
           ([0-9a-f]{2})  # blue
           $
           /ix) {
            @$self = map { hex } ($1, $2, $3);
        }
        else {
            return $self->error_msg( bad_param => hex => $hex );
        }
    }
    return sprintf("%02x%02x%02x", @$self);
}

sub HEX {
    my $self = shift;
    return uc $self->hex(@_);
}

sub html {
    my $self = shift;
    return '#' . $self->hex();
}

sub HTML {
    my $self = shift;
    return '#' . uc $self->hex();
}

sub red { 
    my $self = shift;
    if (@_) {
        $self->[RED]  = shift;
        $self->[RED]  = 0   if $self->[RED] < 0;
        $self->[RED]  = 255 if $self->[RED] > 255;
        delete $self->[SCHEME];
    }
    $self->[RED];
}

sub green { 
    my $self = shift;
    if (@_) {
        $self->[GREEN]  = shift;
        $self->[GREEN]  = 0   if $self->[GREEN] < 0;
        $self->[GREEN]  = 255 if $self->[GREEN] > 255;
        delete $self->[SCHEME];
    }
    $self->[GREEN];
}

sub blue { 
    my $self = shift;
    if (@_) {
        $self->[BLUE]  = shift;
        $self->[BLUE]  = 0   if $self->[BLUE] < 0;
        $self->[BLUE]  = 255 if $self->[BLUE] > 255;
        delete $self->[SCHEME];
    }
    $self->[BLUE];
}

sub grey  { 
    my $self = shift;

    if (@_) {
        delete $self->[SCHEME];
        return ($self->[RED] = $self->[GREEN] = $self->[BLUE] = shift);
    }
    else {
        return int( $self->[RED]  * 0.222 
                  + $self->[GREEN]* 0.707 
                  + $self->[BLUE] * 0.071 );
    }
}

sub update {
    my $self = shift;
    my $args = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $value;
    if (defined ($value = $args->{ red })) {
        $self->[RED]  = $value;
        $self->[RED]  = 0   if $self->[RED] < 0;
        $self->[RED]  = 255 if $self->[RED] > 255;
    }
    if (defined ($value = $args->{ green })) {
        $self->[GREEN]  = $value;
        $self->[GREEN]  = 0   if $self->[GREEN] < 0;
        $self->[GREEN]  = 255 if $self->[GREEN] > 255;
    }
    if (defined ($value = $args->{ blue })) {
        $self->[BLUE]  = $value;
        $self->[BLUE]  = 0   if $self->[BLUE] < 0;
        $self->[BLUE]  = 255 if $self->[BLUE] > 255;
    }
    delete $self->[SCHEME];
    return $self;
}

sub adjust {
    my $self = shift;
    my $args = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $delta;
    if (defined ($delta = $args->{ red })) {
        $self->[RED] += $delta;
        $self->[RED]  = 0   if $self->[RED] < 0;
        $self->[RED]  = 255 if $self->[RED] > 255;
    }
    if (defined ($delta = $args->{ green })) {
        $self->[GREEN] += $delta;
        $self->[GREEN]  = 0   if $self->[GREEN] < 0;
        $self->[GREEN]  = 255 if $self->[GREEN] > 255;
    }
    if (defined ($delta = $args->{ blue })) {
        $self->[BLUE] += $delta;
        $self->[BLUE]  = 0   if $self->[BLUE] < 0;
        $self->[BLUE]  = 255 if $self->[BLUE] > 255;
    }
    delete $self->[SCHEME];
    return $self;
}

sub range {
    my $self   = shift;
    my $steps  = shift;
    my $target = $self->SUPER::new(@_)->rgb();
    my $dred   = ($target->[RED]   - $self->[RED])   / $steps;
    my $dgreen = ($target->[GREEN] - $self->[GREEN]) / $steps;
    my $dblue  = ($target->[BLUE]  - $self->[BLUE])  / $steps;
    my ($n, @range);
    
    for ($n = 0; $n <= $steps; $n++) {
        push(@range, $self->copy->adjust({
            red   => $dred   * $n,
            green => $dgreen * $n,
            blue  => $dblue  * $n,
        }));
    }
    return wantarray ? @range : \@range;
}

#------------------------------------------------------------------------
# hsv()
# hsv($h, $s, $v)
#
# Convert RGB to HSV, with optional $h, $s and/or $v arguments.
#------------------------------------------------------------------------

sub hsv {
    my ($self, @args) = @_;
    my $hsv;

    # generate HSV values from current RGB if no arguments provided
    unless (@args) {
        my ($r, $g, $b) = @$self;
        my ($h, $s, $v);
        my $min   = $self->min($r, $g, $b);
        my $max   = $self->max($r, $g, $b);
        my $delta = $max - $min;
        $v = $max;                              

        if($delta){
            $s = $delta / $max;
            if ($r == $max) {
                $h = 60 * ($g - $b) / $delta; 
            }
            elsif ($g == $max) {
                $h = 120 + (60 * ($b - $r) / $delta); 
            }
            else { # if $b == $max 
                $h = 240 + (60 * ($r - $g) / $delta);
            }
            
            $h += 360 if $h < 0;  # hue is in the range 0-360
            $h = int( $h + 0.5 ); # smooth out rounding errors
            $s = int($s * 255);   # expand saturation to 0-255
        }
        else {
            $h = $s = 0;
        }
        @args = ($h, $s, $v);
    }

    $self->HSV(@args);
}


1;

=head1 NAME

Template::Colour::RGB - module for RGB colour manipulation

=head1 SYNOPSIS

See L<Template::Colour>

=head1 DESCRIPTION

See L<Template::Plugin::Colour::RGB> until I get around to updating
the docs to show examples of use from Perl.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Colour::RGB>, L<Template::Colour>, L<Template::Colour::HSV>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

