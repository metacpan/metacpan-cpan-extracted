package Template::Colour::HSV;

use Template::Colour::Class
    version   => 2.10,
    debug     => 0,
    base      => 'Template::Colour',
    constants => 'ARRAY HASH SCHEME :HSV',
    utils     => 'is_object',
    as_text   => 'HTML',
    is_true   => 1,
    throws    => 'Colour.HSV',
    methods   => {
        sat   => \&saturation,
        val   => \&value,
    };


sub new {
    my ($proto, @args) = @_;
    my ($class, $self);

    if ($class = ref $proto) {
        $self = bless [@$proto], $class;
    }
    else {
        $self = bless [0, 0, 0], $proto;
    }
    $self->hsv(@args) if @args;
    return $self;
}

sub copy {
    my $self = shift;
    my $args = @_ && ref $_[0] eq HASH ? shift : { @_ };

    # default HSV to $self values.  Note that we use the longer
    # form of 'saturation' and 'value', allowing the user to 
    # specify the shorter form of 'sat' or 'val' which gets 
    # detected before the longer 'saturation' and 'value' in 
    # the hsv() method below
    $args->{ hue } = $self->[HUE] 
        unless defined $args->{ hue };
    $args->{ saturation } = $self->[SAT] 
        unless defined $args->{ saturation };
    $args->{ value } = $self->[VAL] 
        unless defined $args->{ value };

    $self->new($args);
}

sub hsv {
    my $self = shift;
    my $hsv;

    if (@_ == 1) {
        # single argument is a list or hash ref
        $hsv = shift;
    }
    elsif (@_ == 3) {
        # three arguments provide hue, saturation, and value components
        $hsv = [ @_ ];
    }
    elsif (@_ == 6) {
        # list of six items is hue => $h, saturation => $s, value => $v
        $hsv = { @_ };
    }
    elsif (@_) {
        # any other number of arguments is an error 
        return $self->error_msg( bad_param => hsv => join(', ', @_) );
    }
    else {
        # return $self when called with no arguments
        return $self;
    }

    # at this point $hsv is a reference to a list or hash, or hsv value

    if (UNIVERSAL::isa($hsv, HASH)) {
        # convert hash ref to list
        $hsv->{ sat } = $hsv->{ saturation } unless exists $hsv->{ sat };
        $hsv->{ val } = $hsv->{ value      } unless exists $hsv->{ val };
        $hsv = [  map {
            defined $hsv->{ $_ } 
            ? $hsv->{ $_ } 
            : return $self->error_msg( no_param => hsv => $_ );
        } qw( hue sat val ) ];
    }
    elsif (UNIVERSAL::isa($hsv, ARRAY)) {
        # $hsv list is ok as it is
    }
    else {
        # anything else is Not Allowed
        return $self->error_msg( bad_param => hsv => $hsv );
    }

    $self->hue($hsv->[HUE]);
    $self->sat($hsv->[SAT]);
    $self->val($hsv->[VAL]);

    return $self;
}

sub hue { 
    my $self = shift;
    if (@_) {
        my $hue = shift;
        $self->[HUE] = $hue % 360;
        delete $self->[SCHEME];
    }
    return $self->[HUE];
}

sub saturation { 
    my $self = shift;
    if (@_) {
        my $sat = shift;
        $sat = 0   if $sat < 0;
        $sat = 255 if $sat > 255;
        $self->[SAT] = $sat;
        delete $self->[SCHEME];
    }
    return $self->[SAT];
}

sub value { 
    my $self = shift;
    if (@_) {
        my $val = shift;
        $val = 0   if $val < 0;
        $val = 255 if $val > 255;
        $self->[VAL] = $val;
        delete $self->[SCHEME];
    }
    return $self->[VAL];
}

sub update {
    my $self = shift;
    my $args = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $value;
    
    $args->{ sat } = $args->{ saturation } unless exists $args->{ sat };
    $args->{ val } = $args->{ value      } unless exists $args->{ val };
    
    $self->hue($value)
        if defined ($value = $args->{ hue });

    $self->saturation($value)
        if defined ($value = $args->{ sat });
    
    $self->value($value)
        if defined ($value = $args->{ val });

    delete $self->[SCHEME];
    return $self;
}

sub adjust {
    my $self = shift;
    my $args = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $delta;
    
    $args->{ sat }  = $args->{ saturation } unless exists $args->{ sat };
    $args->{ val }  = $args->{ value      } unless exists $args->{ val };
    
    if ($delta = $args->{ hue }) {
        $delta = int($delta * 3.59 + 0.5) 
            if $delta =~ s/(\d+)%$/$1/;   # 0-100% -> 0-359
        $self->hue($self->[HUE] + $delta)
    }

    if ($delta = $args->{ sat }) {
        $delta = int($delta * 2.55 + 0.5) 
            if $delta =~ s/(\d+)%$/$1/;   # 0-100% -> 0-255
        $self->sat($self->[SAT] + $delta);
    }
    
    if ($delta = $args->{ val }) {
        $delta = int($delta * 2.55 + 0.5) 
            if $delta =~ s/(\d+)%$/$1/;   # 0-100% -> 0-255
        $self->val($self->[VAL] + $delta);
    }

    delete $self->[SCHEME];
    return $self;
}

sub rgb {
    my ($self, @args) = @_;
    my $rgb;

    # generate RGB values from current HSV if no arguments provided
    unless (@args) {
        my ($h, $s, $v) = @$self;
        my ($r, $g, $b);

        if ($s == 0) {
            # TODO: make this truly achromatic
            @args = ($v) x 3;
        }
        else {
            # normalise saturation from range 0-255 to 0-1
            $s /= 255;

            $h /= 60;                          ## sector 0 to 5
            my $i = POSIX::floor( $h );
            my $f = $h - $i;                   ## factorial part of h
            my $p = $v * ( 1 - $s );
            my $q = $v * ( 1 - $s * $f );
            my $t = $v * ( 1 - $s * ( 1 - $f ) );

            if    ($i == 0) { $r = $v; $g = $t; $b = $p }
            elsif ($i == 1) { $r = $q; $g = $v; $b = $p }
            elsif ($i == 2) { $r = $p; $g = $v; $b = $t }
            elsif ($i == 3) { $r = $p; $g = $q; $b = $v }
            elsif ($i == 4) { $r = $t; $g = $p; $b = $v }
            else            { $r = $v; $g = $p; $b = $q }

            @args = map { int } ($r, $g, $b);
        }
    }

    return $self->RGB(@args);
}

sub hex {
    my $self = shift;
    $self->rgb->hex;
}

sub HEX {
    my $self = shift;
    $self->rgb->HEX;
}

sub html {
    my $self = shift;
    $self->rgb->html;
}

sub HTML {
    my $self = shift;
    $self->rgb->HTML;
}

sub range {
    my $self   = shift;
    my $steps  = shift;
    my $target = $self->SUPER::new(@_)->hsv();
    my $dhue   = ($target->[HUE] - $self->[HUE]) / $steps;
    my $dsat   = ($target->[SAT] - $self->[SAT]) / $steps;
    my $dval   = ($target->[VAL] - $self->[VAL]) / $steps;
    my ($n, @range);
    
    for ($n = 0; $n <= $steps; $n++) {
        push(@range, $self->copy->adjust({
            hue => $dhue * $n,
            sat => $dsat * $n,
            val => $dval * $n,
        }));
    }
    return wantarray ? @range : \@range;
}

sub percent {
    my $self = shift;
    sprintf(
        '%d/%d%%/%d%%',
        $self->[HUE],
        $self->[SAT] * 100 / 255,
        $self->[VAL] * 100 / 255,
    );
}

1;

__END__

=head1 NAME

Template::Colour::HSV - module for HSV colour manipulation

=head1 SYNOPSIS

See L<Template::Colour>

=head1 DESCRIPTION

See L<Template::Plugin::Colour::HSV> until I get around to updating
the docs to show examples of use from Perl.

=head1 AUTHOR

Andy Wardley E<lt>abw@cpan.orgE<gt>, L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Colour>, L<Template::Plugin::Colour::RGB>,
L<Template::Plugin>


